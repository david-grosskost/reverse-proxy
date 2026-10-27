# reverse-proxy

Reverse proxy [Traefik](https://doc.traefik.io/traefik/) partagé par tous les projets Docker
d'une machine, en HTTPS partout, avec un pare-feu applicatif (WAF) devant chaque site.

| Environnement | Adresse des projets | Certificats |
|---|---|---|
| local | `https://<projet>.dev.localhost` | [mkcert](https://github.com/FiloSottile/mkcert), générés sur le poste |
| prod | `https://<projet>.example.com` | [Let's Encrypt](https://letsencrypt.org/), obtenus et renouvelés automatiquement |

Un projet se branche sur le reverse proxy avec quelques labels Docker : aucune
modification du reverse proxy n'est nécessaire.

## Prérequis

- [Docker](https://docs.docker.com/get-docker/) avec Docker Compose v2 (Docker Desktop sous Windows et macOS)
- [Git](https://git-scm.com/downloads)
- `make` et `bash` : sous Windows, utiliser Git Bash et installer make (`winget install ezwinports.make`)

Les autres outils (mkcert, gitleaks, shellcheck) sont téléchargés automatiquement dans le
projet, dans une version fixée, avec vérification de leur empreinte.

## Démarrage rapide

```bash
git clone git@github.com:<compte>/reverse-proxy.git
cd reverse-proxy
make app@install
```

Le tableau de bord de Traefik est alors disponible sur https://traefik.dev.localhost.

Sur un serveur : `make app@install APP_ENV=prod ACME_EMAIL=moi@example.com` (voir [l'installation](docs/installation.md)).

`make` sans argument liste toutes les commandes disponibles.

## Documentation

| Page | Contenu |
|---|---|
| [Installation](docs/installation.md) | poste local (Windows, Linux), serveur, mise à jour |
| [Commandes](docs/commandes.md) | toutes les commandes `make`, par domaine |
| [Architecture](docs/architecture.md) | fonctionnement du projet, fichiers, local et prod |
| [Brancher un projet](docs/projets.md) | exposer un projet Docker derrière le reverse proxy |
| [WAF](docs/waf.md) | CrowdSec : ce qui est bloqué, tester, débloquer une adresse |
| [Développement](docs/developpement.md) | hooks Git, format des commits, GitHub Actions, Dependabot |
| [Dépannage](docs/depannage.md) | erreurs connues et leurs solutions |
