# Brancher un projet

Un projet n'a rien à demander au reverse proxy : il rejoint le réseau `proxy` et décrit,
avec des labels Docker, sous quelle adresse il veut être servi. Traefik le détecte dès son
démarrage et obtient son certificat.

## L'essentiel

Dans le `compose.yaml` du projet :

```yaml
services:
  app:
    image: mon-image
    networks:
      - proxy
    labels:
      traefik.enable: "true"
      traefik.http.routers.monprojet.rule: Host(`monprojet.dev.localhost`)
      traefik.http.routers.monprojet.entrypoints: websecure

networks:
  proxy:
    name: proxy
    external: true
```

Trois choses suffisent :

1. **le réseau `proxy`**, déclaré `external` : il appartient au reverse proxy, le projet
   ne fait que le rejoindre ;
2. **`traefik.enable: "true"`** : rien n'est publié sans ce label ;
3. **un routeur** (`traefik.http.routers.<nom>`) avec l'adresse (`rule`) et le point
   d'entrée HTTPS (`websecure`).

Le nom du routeur (`monprojet` ci-dessus) doit être **unique sur toute la machine** : deux
projets qui utilisent le même nom se mélangent. Prendre le nom du projet est une bonne
habitude.

Rien d'autre à configurer : HTTPS, la redirection depuis HTTP, le certificat et le WAF sont
appliqués automatiquement à tous les sites.

## Exemple : whoami

Le dossier [`docs/examples/whoami/`](examples/whoami/compose.yaml) contient un projet
minimal : une page qui affiche la requête reçue. Pratique pour vérifier une installation.

```bash
cd docs/examples/whoami
docker compose up -d
```

Puis ouvrir https://whoami.dev.localhost. Sur un serveur, donner l'adresse du site :

```bash
SITE=whoami.example.com docker compose up -d
```

Pour l'arrêter : `docker compose down`.

## Une adresse différente en local et en prod

Plutôt que d'écrire l'adresse en dur, la lire dans le `.env` du projet :

```yaml
    labels:
      traefik.http.routers.monprojet.rule: Host(`${APP_HOST}`)
```

```bash
# .env en local
APP_HOST=monprojet.dev.localhost

# .env sur le serveur
APP_HOST=monprojet.example.com
```

En local, le certificat couvre un seul niveau sous `dev.localhost` :
`monprojet.dev.localhost` fonctionne, `api.monprojet.dev.localhost` non. Utiliser plutôt
`monprojet-api.dev.localhost`.

## Le port

Traefik utilise le port exposé par l'image (`EXPOSE` dans le Dockerfile). Si l'image n'en
expose pas, ou en expose plusieurs, l'indiquer :

```yaml
      traefik.http.services.monprojet.loadbalancer.server.port: "8080"
```

Il ne faut **pas** publier ce port sur la machine (`ports:`) : Traefik passe par le réseau
`proxy`. Publier un port contournerait le reverse proxy, et donc HTTPS et le WAF.

## Plusieurs adresses ou plusieurs services

Plusieurs noms pour un même service :

```yaml
      traefik.http.routers.monprojet.rule: Host(`example.com`) || Host(`www.example.com`)
```

Un front et une API dans le même projet : un routeur par service, chacun avec son nom.
La règle la plus longue est essayée en premier : `/api` va donc à l'API, le reste au front.

```yaml
# images et réseaux omis
services:
  front:
    labels:
      traefik.enable: "true"
      traefik.http.routers.monprojet-front.rule: Host(`monprojet.example.com`)
      traefik.http.routers.monprojet-front.entrypoints: websecure
  api:
    labels:
      traefik.enable: "true"
      traefik.http.routers.monprojet-api.rule: Host(`monprojet.example.com`) && PathPrefix(`/api`)
      traefik.http.routers.monprojet-api.entrypoints: websecure
```

## Base de données et services internes

Seuls les services servis par Traefik rejoignent `proxy`. Les autres (base de données,
cache…) restent sur le réseau propre au projet :

```yaml
services:
  app:
    networks:
      - proxy
      - default      # pour joindre la base
    labels:
      traefik.enable: "true"
      # …
  db:
    image: mariadb:11
    # pas de réseau proxy, pas de label : invisible depuis l'extérieur

networks:
  proxy:
    name: proxy
    external: true
```

Quand un conteneur est sur plusieurs réseaux, Traefik utilise toujours `proxy` pour le
joindre.

## Protéger un site par mot de passe

Avec un middleware `basicauth`. Générer la ligne utilisateur (ici avec l'image `httpd`) :

```bash
docker run --rm httpd:2.4-alpine htpasswd -nbB admin 'mon-mot-de-passe'
# → admin:$2y$05$…
```

Dans les labels, chaque `$` doit être doublé (`$$`), sinon Docker Compose le prend pour
une variable :

```yaml
      traefik.http.middlewares.monprojet-auth.basicauth.users: "admin:$$2y$$05$$…"
      traefik.http.routers.monprojet.middlewares: monprojet-auth
```

Le WAF reste appliqué : les middlewares du routeur s'ajoutent à ceux du point d'entrée.

## Vérifier

```bash
make network@ls               # le conteneur est-il sur le réseau proxy ?
make app@logs                 # erreurs de Traefik (label mal écrit, certificat…)
```

En local, le tableau de bord (https://traefik.dev.localhost, onglet *HTTP*) liste tous les
routeurs détectés, avec leurs erreurs éventuelles.

Si le site répond `404 page not found`, Traefik ne connaît aucun routeur pour cette adresse :
vérifier `traefik.enable`, la règle `Host` et le réseau. S'il répond `502` ou
`Gateway Timeout`, le routeur existe mais Traefik ne joint pas le conteneur : vérifier le
port. Voir aussi le [dépannage](depannage.md).
