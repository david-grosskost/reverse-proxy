# Commandes

Toutes les commandes suivent la même forme : `make <domaine>@<action>`. Chacune lance le
script `.make/scripts/<domaine>/<action>.sh`, qui contient toute la logique.

```bash
make                 # liste toutes les commandes disponibles
make app@status      # exemple
```

Chaque commande affiche, en grisé, les commandes Docker ou Git qu'elle exécute : on voit
toujours ce qui est fait.

## Paramètres

Les paramètres se donnent après la commande, sous la forme `NOM=valeur` :

```bash
make app@logs SERVICE=crowdsec
make waf@unban IP=198.51.100.7
```

| Paramètre | Commandes | Rôle |
|---|---|---|
| `APP_ENV` | toutes | `local` ou `prod`, pour cette commande seulement (par défaut : le `.env`, sinon `local`) |
| `SERVICE` | `app@logs` | service à suivre : `traefik` (par défaut), `crowdsec` ou `socket-proxy` |
| `IP` | `waf@unban` | adresse à débloquer |
| `SITE` | `waf@test` | site à tester (obligatoire en prod) |

Pour `app@install`, tout réglage de `.env.example` peut aussi être donné en paramètre : il
est écrit dans le `.env` créé (voir [l'installation](installation.md)).

## app : le reverse proxy

| Commande | Rôle |
|---|---|
| `make app@check` | vérifie les prérequis (git, Docker démarré et accessible, ports 80 et 443 libres) et indique comment corriger chaque problème |
| `make app@install` | installe tout depuis zéro, puis démarre ; peut être relancée sans risque |
| `make app@start` | démarre Traefik, CrowdSec et le socket proxy ; crée le réseau `proxy` s'il manque |
| `make app@stop` | arrête et supprime les conteneurs ; le réseau `proxy` et les données de CrowdSec sont conservés |
| `make app@restart` | `app@stop` puis `app@start`, par exemple après un changement de certificat local |
| `make app@status` | état des conteneurs |
| `make app@logs` | suit les journaux d'un service, à partir des 100 dernières lignes (`Ctrl+C` pour quitter) |
| `make app@update` | télécharge les images à jour et recrée les conteneurs qui ont changé |
| `make app@config` | affiche la configuration Docker Compose complète, telle que Docker va l'exécuter |

`app@config` est utile pour vérifier ce qu'un fichier compose produit réellement, par
exemple la valeur de `ACME_EMAIL` en prod.

## cert : les certificats locaux

Réservées à l'environnement `local`. En prod, les certificats viennent de Let's Encrypt et
aucune commande n'est nécessaire.

| Commande | Rôle |
|---|---|
| `make cert@install` | installe mkcert et son autorité de certification, pour que les navigateurs fassent confiance aux certificats locaux ; une fois par poste |
| `make cert@create` | génère le certificat `*.dev.localhost` dans `certs/` |
| `make cert@mkcert` | télécharge seulement mkcert, dans sa version fixée, dans `.tools/bin/` |

Après un `cert@create`, lancer `make app@restart` pour que Traefik charge le nouveau
certificat.

## network : le réseau partagé

Tous les projets exposés rejoignent le réseau Docker `proxy`, sur lequel Traefik les trouve.

| Commande | Rôle |
|---|---|
| `make network@create` | crée le réseau `proxy` s'il n'existe pas (`app@start` le fait déjà) |
| `make network@ls` | liste les conteneurs branchés sur le réseau `proxy` |

`network@ls` est le premier réflexe quand un projet n'apparaît pas derrière le reverse proxy.

## waf : le pare-feu applicatif

Voir la page [WAF](waf.md) pour le fonctionnement.

| Commande | Rôle |
|---|---|
| `make waf@test` | envoie une attaque typique (`/.env`) et vérifie qu'elle est bloquée (403) |
| `make waf@decisions` | liste les adresses bloquées, avec la raison et la durée restante |
| `make waf@unban IP=…` | débloque une adresse (la sienne, après un faux positif par exemple) |
| `make waf@metrics` | ce que CrowdSec a analysé : requêtes vérifiées et bloquées, lignes de journal lues, scénarios déclenchés |
| `make waf@key` | génère la clé partagée entre Traefik et CrowdSec si elle manque (`app@install` le fait déjà) |

En local, `waf@test` utilise le tableau de bord (`traefik.dev.localhost`). En prod, il n'y a
pas de tableau de bord : préciser un site servi par le reverse proxy :

```bash
make waf@test SITE=monsite.example.com
```

## git : l'outillage du dépôt

Utiles surtout pour développer le projet (voir [Développement](developpement.md)).

| Commande | Rôle |
|---|---|
| `make git@hooks` | active les hooks Git du dépôt et installe gitleaks et shellcheck ; `app@install` le fait en local |
| `make git@gitleaks` | télécharge seulement gitleaks, dans sa version fixée, dans `.tools/bin/` |
| `make git@shellcheck` | télécharge seulement shellcheck, dans sa version fixée, dans `.tools/bin/` |

## Commandes propres à une machine

Un fichier `local.mk` à la racine, s'il existe, est chargé en plus des autres. Il est fait
pour ses propres raccourcis, propres à sa machine : ne pas le commiter.

```make
.PHONY: perso@dashboard

perso@dashboard:
	@start https://traefik.dev.localhost
```

Les cibles déclarées dans une ligne `.PHONY` et contenant un `@` apparaissent dans la liste
affichée par `make`.
