# Dépannage

Premier réflexe, quel que soit le problème :

```bash
make app@check       # prérequis
make app@status      # les trois conteneurs tournent-ils ?
make app@logs        # erreurs de Traefik (SERVICE=crowdsec pour CrowdSec)
```

## Installation

### `make: command not found` (Windows)

make vient d'être installé : fermer Git Bash et en ouvrir un **nouveau**. Sinon,
l'installer : `winget install ezwinports.make` (dans PowerShell).

### `Docker ne répond pas`

Docker Desktop n'est pas démarré (Windows, macOS), ou le service Docker est arrêté
(Linux : `sudo systemctl start docker`). Attendre que Docker Desktop indique *Engine
running* avant de relancer la commande.

### `Docker refuse l'accès` (Linux)

L'utilisateur n'est pas dans le groupe `docker` :

```bash
sudo usermod -aG docker $USER
```

Puis se déconnecter et se reconnecter (ou redémarrer la session SSH).

### `les ports 80 ou 443 sont déjà utilisés`

Un autre programme écoute déjà sur ces ports : un autre serveur web (Apache, nginx, IIS),
un autre reverse proxy, ou les conteneurs d'un autre projet qui publient `80:80`.

```bash
sudo ss -ltnp | grep -E ':(80|443) '            # Linux
netstat -ano | findstr ":80 :443"               # Windows (PowerShell ou cmd)
docker ps --format '{{.Names}}\t{{.Ports}}'     # un conteneur ?
```

### `/usr/bin/env: 'bash\r': No such file or directory`

Les scripts ont des fins de ligne Windows (CRLF), souvent parce que le dépôt a été
récupéré avec un réglage Git qui les convertit. Le dépôt impose LF (`.gitattributes`) ;
récupérer les fichiers à nouveau (les modifications non commitées sont perdues) :

```bash
git rm -r --cached -q . && git reset --hard
```

### `Permission denied` en lançant une commande make

Le script n'est pas exécutable. Vérifier le mode dans Git (`100755` attendu) :

```bash
git ls-files -s .make/scripts | grep -v 100755
```

## Certificats en local

### Le navigateur affiche un avertissement de sécurité

- Fermer **complètement** le navigateur puis le rouvrir : l'autorité de certification
  mkcert n'est lue qu'au démarrage.
- Firefox sous Windows : dans `about:config`, passer `security.enterprise_roots.enabled`
  à `true`.
- Linux : installer `certutil` (`libnss3-tools`), puis `make cert@install`.
- Vérifier que l'adresse n'a qu'un niveau sous `dev.localhost` :
  `api.monprojet.dev.localhost` n'est pas couvert par le certificat.

### `certificat local absent — lancer « make cert@create »`

```bash
make cert@create && make app@restart
```

### Changement de PC

L'autorité de certification mkcert est propre à chaque poste : sur un nouveau PC,
`make app@install` en crée une et régénère le certificat. Sur l'ancien, on peut la
retirer avec `.tools/bin/mkcert -uninstall`.

## Certificats en prod (Let's Encrypt)

Les erreurs apparaissent dans les journaux de Traefik :

```bash
make app@logs | grep -i acme
```

| Symptôme | Cause probable |
|---|---|
| `Timeout during connect`, `Connection refused` | le port 80 est fermé (pare-feu du serveur ou de l'hébergeur) |
| `no valid A records found`, `NXDOMAIN` | le DNS ne pointe pas (encore) vers le serveur ; la propagation peut prendre du temps |
| échec alors que le DNS IPv4 est bon | un enregistrement AAAA (IPv6) existe et pointe ailleurs : Let's Encrypt l'essaie en premier |
| `too many certificates`, `rateLimited` | limite de Let's Encrypt atteinte : attendre (jusqu'à une semaine) ; faire ses essais sur le serveur de test |
| `permissions 644 for /certs/acme.json are too open` | `chmod 600 certs/acme.json` (`make app@start` le fait) |

Le site affiche un certificat `TRAEFIK DEFAULT CERT` : Traefik n'a pas (encore) obtenu le
certificat. Voir les journaux ci-dessus.

Le certificat est émis par `(STAGING)` : l'installation a été faite sur le serveur de test.
Passer aux vrais certificats :

```bash
make app@stop && rm certs/acme.json && make app@start
```

## Un projet ne répond pas

| Réponse | Signification | À vérifier |
|---|---|---|
| `404 page not found` | Traefik ne connaît aucun routeur pour cette adresse | `traefik.enable: "true"`, la règle `Host(…)` (avec des accents graves), `entrypoints: websecure` |
| `502 Bad Gateway`, `Gateway Timeout` | le routeur existe, mais Traefik ne joint pas le conteneur | le réseau `proxy` (`make network@ls`), le port (`loadbalancer.server.port`) |
| `403 Forbidden` | le WAF a bloqué la requête ou l'adresse | `make waf@decisions`, voir [ci-dessous](#un-visiteur-légitime-est-bloqué) |
| le navigateur ne trouve pas le site | le nom ne mène pas au serveur | en local, rien à faire pour `*.dev.localhost` ; en prod, le DNS |

En local, le tableau de bord (https://traefik.dev.localhost) montre les routeurs détectés
et leurs erreurs. Voir aussi [Brancher un projet](projets.md).

### `network proxy declared as external, but could not be found`

Le réseau partagé n'existe pas encore : démarrer le reverse proxy d'abord
(`make app@start`), ou `make network@create`.

## WAF

### Le WAF ne bloque pas

`make waf@test` répond autre chose que `403` :

| Code | Cause probable |
|---|---|
| `000` | le site est injoignable : reverse proxy arrêté, mauvaise adresse (`SITE=`) |
| `404` | la requête est passée sans être inspectée : CrowdSec arrêté, en cours de démarrage, ou clé refusée |
| `200` | idem, et le site sert un fichier `/.env` : à corriger d'urgence |

Le WAF laisse passer le trafic quand CrowdSec ne répond pas (voir [WAF](waf.md)). Vérifier :

```bash
make app@status                        # crowdsec tourne-t-il ?
make app@logs SERVICE=crowdsec         # erreurs au démarrage
make app@logs | grep -i crowdsec       # erreurs du plugin dans Traefik
```

Au premier démarrage, CrowdSec télécharge ses règles et redémarre une fois (`Restarting`
dans `make app@status`) : attendre une trentaine de secondes avant `make waf@test`.

`cscli bouncers list` affiche une colonne *Last API pull* vide tant qu'aucun site n'est
branché sur le proxy : le plugin de Traefik ne contacte CrowdSec que lorsqu'un site
l'utilise. Lancer un projet, par exemple [whoami](projets.md#exemple--whoami).

### Changer la clé CrowdSec

Un message `403` ou `access forbidden` du plugin dans les journaux de Traefik indique que
CrowdSec refuse la clé, par exemple si `secrets/crowdsec-bouncer.key` a été régénéré après
le premier démarrage. Supprimer l'enregistrement de l'ancienne clé, puis redémarrer :
CrowdSec enregistre la clé actuelle.

```bash
docker compose exec crowdsec cscli bouncers list
docker compose exec crowdsec cscli bouncers delete traefik
make app@restart
make waf@test
```

### Un visiteur légitime est bloqué

```bash
make waf@decisions                  # retrouver l'adresse et la raison
make waf@unban IP=198.51.100.7
```

Si un même comportement normal du site déclenche des blocages à répétition (un outil
interne qui appelle beaucoup de pages, par exemple), noter le scénario indiqué par
`waf@decisions` : il faudra ajouter une exception dans CrowdSec.

### `manifest for crowdsecurity/crowdsec:vX.Y.Z not found`

La version indiquée dans `compose.yaml` n'existe pas sur Docker Hub : une version publiée
sur GitHub n'a pas toujours son image. Vérifier les versions disponibles sur
[Docker Hub](https://hub.docker.com/r/crowdsecurity/crowdsec/tags).

### `read-only file system` au démarrage de Traefik

Un fichier a été monté **à l'intérieur** de `/etc/traefik/dynamic`, alors que ce dossier
est déjà monté en lecture seule. Monter un dossier à côté des autres
(`/etc/traefik/dynamic/<nom>`) plutôt qu'un fichier dedans (voir
[Architecture](architecture.md#configuration-dynamique)).

## Hooks Git

### Commit refusé

Chaque message indique le fichier en cause et la commande pour corriger. Les cas les plus
courants :

| Message | Correction |
|---|---|
| `message refusé` | réécrire le message au format `type(portée): description` ([Développement](developpement.md#format-des-commits)) |
| `non exécutable dans Git (100644)` | `git update-index --chmod=+x <fichier>` |
| `fichier sensible, à ne jamais commiter` | `git rm --cached <fichier>` |
| `gitleaks introuvable` / `shellcheck introuvable` | `make git@hooks` |
| un secret détecté par gitleaks | retirer le secret du fichier ; s'il a déjà été commité, le considérer comme compromis et le changer |

Un faux positif de gitleaks (une valeur d'exemple, par exemple) s'ignore en ajoutant le
commentaire `gitleaks:allow` en fin de ligne.

### Le hook ne se déclenche pas

Les hooks ne sont pas activés sur ce clone :

```bash
git config core.hooksPath      # doit afficher .githooks
make git@hooks
```

### `post-merge : nouveaux réglages dans .env.example`

Après un `git pull`, `.env.example` contient un réglage absent du `.env` de la machine.
Ajouter la ligne indiquée au `.env`, avec la valeur adaptée, puis `make app@restart`.
