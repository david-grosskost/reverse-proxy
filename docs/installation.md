# Installation

Une seule commande installe le projet, sur un poste comme sur un serveur :
`make app@install`. Elle peut être relancée sans risque : ce qui est déjà fait est sauté.

Dans l'ordre, elle :

1. vérifie les prérequis (Docker démarré, ports 80 et 443 libres…) avant de toucher à quoi que ce soit ;
2. crée le fichier `.env` à partir de `.env.example`, avec l'environnement choisi ;
3. génère la clé partagée entre Traefik et CrowdSec (`secrets/crowdsec-bouncer.key`) ;
4. en local uniquement : active les hooks Git, télécharge gitleaks, shellcheck et mkcert,
   installe l'autorité de certification mkcert et génère le certificat `*.dev.localhost` ;
5. sur un serveur : active les hooks Git (pour les rappels après un `git pull`) ;
6. démarre Traefik, le socket proxy et CrowdSec.

## Environnement

L'environnement (`local` ou `prod`) est lu dans cet ordre :

1. le paramètre de la commande : `make app@start APP_ENV=prod` ;
2. sinon le fichier `.env` (`APP_ENV=…`), écrit par `make app@install` ;
3. sinon `local`.

Le paramètre ne vaut que pour la commande en cours. Pour changer l'environnement d'une
machine, modifier son `.env`.

## Poste local

### Windows

Tout se fait dans **Git Bash**. PowerShell ne sait pas exécuter les scripts bash des
commandes `make`.

1. Installer [Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/)
   et le démarrer.
2. Installer make, dans PowerShell :

   ```powershell
   winget install ezwinports.make
   ```

3. Ouvrir un **nouveau** terminal Git Bash, puis :

   ```bash
   git clone git@github.com:<compte>/reverse-proxy.git
   cd reverse-proxy
   make app@install
   ```

   Windows demande de confirmer l'ajout de l'autorité de certification mkcert : accepter.

4. Fermer complètement le navigateur, le rouvrir, puis ouvrir https://traefik.dev.localhost :
   le tableau de bord de Traefik s'affiche, avec le cadenas.

Firefox sous Windows : si un avertissement de sécurité s'affiche, ouvrir `about:config` et
passer `security.enterprise_roots.enabled` à `true`.

### Linux

1. Installer [Docker Engine](https://docs.docker.com/engine/install/), make et git.
   Vérifier que `docker ps` fonctionne sans `sudo`, sinon :

   ```bash
   sudo usermod -aG docker $USER    # puis se déconnecter et se reconnecter
   ```

2. Pour que Chrome et Firefox reconnaissent les certificats locaux, installer `certutil`
   (paquet `libnss3-tools` sous Debian et Ubuntu).
3. Cloner et installer :

   ```bash
   git clone git@github.com:<compte>/reverse-proxy.git
   cd reverse-proxy
   make app@install
   ```

   Le mot de passe `sudo` est demandé pour installer l'autorité de certification mkcert.

4. Redémarrer le navigateur, puis ouvrir https://traefik.dev.localhost.

### Vérifier le WAF

```bash
make waf@test
```

Réponse attendue : `WAF actif : https://traefik.dev.localhost/.env bloqué (403).`

## Serveur

### 1. DNS

Faire pointer les noms des projets vers l'adresse IPv4 du serveur. Un enregistrement
générique couvre tous les projets d'un coup :

| Type | Nom | Valeur |
|---|---|---|
| A | `*.example.com` | `203.0.113.10` |

Ne pas créer d'enregistrement AAAA (IPv6) tant que le serveur n'est pas joignable en IPv6 :
Let's Encrypt l'essaierait en priorité, et la demande de certificat échouerait.

Vérifier depuis n'importe quelle machine :

```bash
nslookup monsite.example.com                  # → l'adresse du serveur
nslookup -type=AAAA monsite.example.com       # → aucun enregistrement
```

### 2. Pare-feu

Les ports 80 et 443 doivent être ouverts. Avec `ufw`, en autorisant SSH en premier :

```bash
sudo ufw allow OpenSSH && sudo ufw allow 80/tcp && sudo ufw allow 443/tcp
```

Le port 80 est nécessaire même si tout est en HTTPS : Let's Encrypt l'utilise pour
vérifier le domaine, et Traefik y redirige les visiteurs vers HTTPS.

### 3. Accès au dépôt

Sur un serveur, utiliser une **deploy key** : elle ne donne accès qu'à ce dépôt, en
lecture seule.

```bash
ssh-keygen -t ed25519 -C "serveur reverse-proxy" -f ~/.ssh/reverse-proxy -N ""
cat ~/.ssh/reverse-proxy.pub
```

Sur GitHub, dans le dépôt : *Settings → Deploy keys → Add deploy key*, coller la clé, et
laisser *Allow write access* décoché. Puis, sur le serveur :

```bash
cat >> ~/.ssh/config <<'CONF'
Host github-reverse-proxy
  HostName github.com
  User git
  IdentityFile ~/.ssh/reverse-proxy
  IdentitiesOnly yes
CONF
chmod 600 ~/.ssh/config
ssh -T git@github-reverse-proxy     # → Hi <compte>/reverse-proxy!
```

### 4. Installer, sur le serveur de test de Let's Encrypt

Let's Encrypt limite le nombre de certificats délivrés. Pour une première installation,
utiliser son serveur de test (*staging*), qui délivre des certificats sans valeur mais
sans limite :

```bash
git clone git@github-reverse-proxy:<compte>/reverse-proxy.git ~/reverse-proxy
cd ~/reverse-proxy
make app@install APP_ENV=prod ACME_EMAIL=moi@example.com \
  ACME_CA_SERVER=https://acme-staging-v02.api.letsencrypt.org/directory
```

`APP_ENV` et `ACME_EMAIL` sont enregistrés dans `.env` : les commandes suivantes n'en ont
plus besoin. L'e-mail est facultatif (Let's Encrypt n'envoie plus d'avis d'expiration) ;
il sert de contact pour le compte. Le serveur de test, lui, ne vaut que pour cette
commande.

> Tout réglage de `.env.example` peut être donné ainsi à `make app@install` ; il est
> écrit dans `.env` à sa création. Ensuite, on modifie `.env` à la main.

### 5. Vérifier, puis passer aux vrais certificats

Lancer un projet de test (voir [Brancher un projet](projets.md)), puis vérifier
l'émetteur du certificat :

```bash
curl -skv https://monsite.example.com 2>&1 | grep -i issuer
# → issuer: … (STAGING) …
```

Si tout fonctionne, passer aux vrais certificats :

```bash
make app@stop
rm certs/acme.json
make app@start
```

Puis vérifier le WAF sur le site de test :

```bash
make waf@test SITE=monsite.example.com
```

## Mettre à jour

```bash
git pull
```

Après un `git pull`, le hook `post-merge` signale ce qui reste à faire à la main :

- les réglages ajoutés à `.env.example` mais absents du `.env` de la machine ;
- `make app@update` si un fichier compose a changé (nouvelle version d'une image, par exemple).

`make app@update` télécharge les images à jour et recrée les conteneurs concernés.
