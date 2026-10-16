# reverse-proxy

Reverse proxy [Traefik v3](https://doc.traefik.io/traefik/) commun à tous mes projets Docker,
**en HTTPS partout** :

| Environnement | URL des projets                    | Certificats                  |
|---------------|------------------------------------|------------------------------|
| `local`       | `https://<projet>.dev.localhost`   | [mkcert](https://github.com/FiloSottile/mkcert) |
| `prod`        | `https://<projet>.david-grosskost.fr` | Let's Encrypt (automatique) |

## Comment c'est organisé

```
Makefile              point d'entrée : liste et inclut .make/*.mk
.githooks/            hooks Git versionnés (vérification des messages de commit)
.make/                commandes make : un .mk par domaine (app.mk…)
.make/scripts/        la logique de chaque commande (scripts/app/start.sh…)
compose.yaml          socle commun (Traefik + socket-proxy, réseau "proxy")
compose.local.yaml    surcouche locale : mkcert, ports sur 127.0.0.1, logs DEBUG, tableau de bord
compose.prod.yaml     surcouche prod : Let's Encrypt, en-têtes de sécurité, logs d'accès
traefik/local/        config dynamique locale (certificat mkcert)
traefik/prod/         config dynamique prod (middlewares, TLS 1.2 min)
.env.example          modèle du .env (versionné)
.env                  APP_ENV de la machine, local ou prod (copié par app@install)
```

Les commandes `make` assemblent automatiquement `compose.yaml` + `compose.$(APP_ENV).yaml`.
Le **même code** est déployé partout ; seul le `.env` (non commité) change d'une machine à
l'autre : `APP_ENV=local` sur ton poste, `APP_ENV=prod` sur le serveur.

## Commandes

`make` sans argument liste toutes les commandes.

| Commande | Rôle |
|---|---|
| `make app@install` | installation de zéro sur la machine (relançable sans risque) |
| `make app@start` | démarre |
| `make app@stop` | arrête (le réseau `proxy` est conservé) |
| `make app@restart` | redémarre, après un changement de certificat |
| `make app@status` | état des conteneurs |
| `make app@logs` | suit les logs de Traefik (`SERVICE=socket-proxy` pour l'autre service) |
| `make app@update` | récupère les images à jour et recrée les conteneurs |
| `make app@config` | configuration compose finale, telle que Docker la lance |
| `make cert@install` | *local* — installe l'autorité mkcert (une fois par poste) |
| `make cert@create` | *local* — génère le certificat `*.dev.localhost` (une seule fois) |
| `make network@create` | crée le réseau partagé `proxy` |
| `make network@ls` | liste les conteneurs branchés sur `proxy` |
| `make git@hooks` | active la vérification des messages de commit (fait par `app@install` en local) |

**Environnement** : le paramètre `APP_ENV=…` s'il est passé, sinon le `.env` s'il existe,
sinon `local`. Exemple : `make app@config APP_ENV=prod`. Le paramètre ne vaut que pour
cette commande ; pour changer durablement, on modifie le `.env`.

Convention : `make <domaine>@<action>` exécute `.make/scripts/<domaine>/<action>.sh`.
`.make/<domaine>.mk` ne fait que déclarer les cibles (dans `.PHONY`, ce qui les fait
apparaître dans la liste) ; toute la logique vit dans les scripts, et ce qui est
commun à tous dans `.make/scripts/lib.sh`. Chaque commande affiche les commandes
Docker qu'elle lance.

## Installation en local

Prérequis : Docker, `make`, [mkcert](https://github.com/FiloSottile/mkcert#installation).

```bash
make app@install     # écrit .env (APP_ENV=local), hooks Git, autorité mkcert, certificat, démarrage
```

→ Tableau de bord : https://traefik.dev.localhost

> **WSL :** si Docker tourne dans WSL et le navigateur sous Windows, installe aussi mkcert
> côté Windows (`mkcert -install`), puis dans WSL :
> `export CAROOT="/mnt/c/Users/<toi>/AppData/Local/mkcert"` avant `make cert@create`,
> pour que les deux utilisent la même autorité.

Les `*.localhost` pointent tout seuls vers 127.0.0.1 (Chrome, Firefox, Edge) : pas besoin de
toucher au fichier `hosts`.

**Nouveau projet en local :** rien à faire côté reverse-proxy. Le certificat `*.dev.localhost`
couvre déjà `<projet>.dev.localhost`. (Un joker `*.localhost` serait refusé par Chrome et
Firefox, d'où le niveau `dev` en plus.)

## Installation en production (VPS)

1. Les DNS des projets (`<projet>.david-grosskost.fr`) pointent vers l'IP du VPS
   (enregistrement A chez OVH, ou un `*.david-grosskost.fr` pour tout couvrir).
2. Ports 80 et 443 ouverts sur le pare-feu.
3. Sur le serveur :

```bash
git clone git@github.com:david-grosskost/reverse-proxy.git && cd reverse-proxy
make app@install APP_ENV=prod   # écrit .env (APP_ENV=prod), puis démarre
```

> Premier essai ? Démarre sur le serveur *staging* de Let's Encrypt, pour ne pas griller
> le quota si un DNS n'est pas encore bon :
> `make app@install APP_ENV=prod ACME_CA_SERVER=https://acme-staging-v02.api.letsencrypt.org/directory`
> Une fois OK, supprime `certs/acme.json` puis `make app@restart`.

## Brancher un projet

Le projet rejoint le réseau `proxy` et déclare son nom d'hôte via des labels — c'est tout.
Voir [`examples/whoami/compose.yaml`](examples/whoami/compose.yaml) :

```yaml
services:
  app:
    networks: [proxy]
    labels:
      traefik.enable: "true"
      traefik.http.routers.monapp.rule: Host(`${APP_HOST}`)
      traefik.http.routers.monapp.entrypoints: websecure

networks:
  proxy:
    name: proxy
    external: true
```

Avec `APP_HOST=monapp.dev.localhost` en local et `APP_HOST=monapp.david-grosskost.fr` en prod,
les mêmes labels fonctionnent partout : HTTPS, redirection HTTP→HTTPS et certificat sont
gérés par le reverse-proxy.

## Messages de commit

Format [Conventional Commits](https://www.conventionalcommits.org/), vérifié à chaque commit
par `.githooks/commit-msg` : `type(portée): description`, 72 caractères maximum.
Le même hook est rejoué par GitHub Actions (`.github/workflows/commit-msg.yml`) sur
chaque push et pull request, pour les commits faits sans le hook local.

```
feat(make): add app@logs
fix: restore HTTP to HTTPS redirect
docs: explain local certificates
```

Types : `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.

## Sécurité

- Traefik n'accède au socket Docker qu'en **lecture**, via `docker-socket-proxy`.
- En local, les ports ne sont ouverts que sur `127.0.0.1`.
- En prod : HSTS, en-têtes de sécurité, TLS 1.2 minimum, et pas de tableau de bord exposé.
- Certificats et clés sont exclus de Git (`.gitignore`).
