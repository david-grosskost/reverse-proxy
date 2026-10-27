# Développement

Ce qu'il faut savoir pour modifier le projet lui-même.

## Hooks Git

Les hooks sont versionnés dans `.githooks/` et activés par `make app@install` en local
(ou `make git@hooks`), qui règle `core.hooksPath`. Ils fonctionnent à l'identique sous
Linux, macOS et Windows (Git Bash).

| Hook | Quand | Ce qu'il fait |
|---|---|---|
| `commit-msg` | à chaque commit | refuse un message qui ne suit pas le format attendu |
| `pre-commit` | à chaque commit | lance toutes les vérifications de `.githooks/pre-commit.d/` et refuse le commit si l'une échoue |
| `post-merge` | après un `git pull` | signale les réglages à ajouter au `.env` et les conteneurs à recréer ; ne bloque jamais |

Toutes les vérifications sont lancées à chaque fois : un commit refusé affiche tous les
problèmes d'un coup, chacun avec la commande pour le corriger.

### Vérifications avant commit

| Script | Vérifie |
|---|---|
| `scripts.sh` | les scripts (`*.sh` et `.githooks/*`) sont exécutables dans Git, commencent par `#!/usr/bin/env bash` et ne contiennent pas de marqueurs de conflit oubliés |
| `shellcheck.sh` | les scripts n'ont pas d'erreur ni de construction risquée, selon [shellcheck](https://www.shellcheck.net/) |
| `sensitive-files.sh` | aucun fichier sensible n'est ajouté : `.env`, clés privées, certificats, `acme.json`… (même avec `git add -f`) |
| `secrets.sh` | aucun secret (clé d'API, jeton, mot de passe…) dans les modifications, selon [gitleaks](https://github.com/gitleaks/gitleaks) |

Pour ajouter une vérification, déposer un script dans `.githooks/pre-commit.d/` : il est
lancé automatiquement. Il doit accepter le paramètre `--all` (vérifier tous les fichiers
versionnés, utilisé par GitHub Actions) et sortir en erreur pour refuser le commit.

En cas de besoin, `git commit --no-verify` contourne les hooks. GitHub Actions refait
toutefois les mêmes vérifications après le push.

## Format des commits

Les messages suivent [Conventional Commits](https://www.conventionalcommits.org/fr/) :

```
type(portée): description
```

| Élément | Règle |
|---|---|
| type | `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert` |
| portée | facultative, en minuscules : `feat(make): …` |
| `!` | changement incompatible : `feat!: …` |
| longueur | 72 caractères au plus pour la première ligne |

Exemples :

```
feat(waf): add waf@metrics
fix: keep .env values containing an equals sign
docs: describe the prod installation
```

Les messages générés par Git (`Merge …`, `Revert …`, `fixup! …`) sont acceptés tels quels.

## GitHub Actions

Les mêmes vérifications tournent sur GitHub à chaque push et à chaque pull request, pour
attraper les commits faits sans les hooks (interface web, autre clone…).

| Workflow | Fichier | Vérifie |
|---|---|---|
| Commit Messages | `.github/workflows/commit-msg.yml` | le message de chaque nouveau commit, avec `.githooks/commit-msg` |
| Pre-commit Checks | `.github/workflows/pre-commit.yml` | tous les fichiers versionnés et tout l'historique, avec `.githooks/pre-commit --all` |

Ils installent gitleaks et shellcheck avec les mêmes scripts et dans les mêmes versions
qu'en local.

## Dependabot

`.github/dependabot.yml` vérifie chaque semaine les nouvelles versions :

- des images Docker des fichiers compose (`build(deps): …`) ;
- des actions GitHub utilisées par les workflows (`ci(deps): …`).

Il ouvre une pull request par mise à jour, avec un message de commit déjà conforme. Avant
de l'accepter, lire les notes de version (Traefik et CrowdSec changent parfois leurs
options), puis, après le merge, `git pull` et `make app@update` sur chaque machine.

Les versions du plugin CrowdSec de Traefik (`--experimental.plugins.bouncer.version`) et
des outils (mkcert, gitleaks, shellcheck) ne sont pas suivies par Dependabot : les mettre à
jour à la main.

## Ajouter une commande

Une commande `make <domaine>@<action>` lance `.make/scripts/<domaine>/<action>.sh`.

1. Écrire le script `.make/scripts/<domaine>/<action>.sh` :

   ```bash
   #!/usr/bin/env bash
   # Shows the Traefik version.
   #
   # @usage make app@version
   set -euo pipefail
   . "$(dirname "$0")/../lib.sh"

   load_env app@version

   compose exec traefik traefik version
   ```

2. Le rendre exécutable, aussi dans Git (indispensable sous Windows) :

   ```bash
   chmod +x .make/scripts/app/version.sh
   git add .make/scripts/app/version.sh
   git update-index --chmod=+x .make/scripts/app/version.sh
   ```

3. Déclarer la cible dans `.make/<domaine>.mk` (nouveau fichier pour un nouveau domaine),
   et l'ajouter à la ligne `.PHONY` pour qu'elle apparaisse dans `make` :

   ```make
   .PHONY: app@check app@install … app@version

   app@version:
   	@$(APP_SCRIPTS)/app/version.sh
   ```

   La ligne de commande commence par une **tabulation**, pas par des espaces.

Un paramètre (`make app@version FORMAT=json`) se déclare dans le `.mk` avec `FORMAT ?=`
et `export FORMAT`, puis se lit dans le script avec `${FORMAT:-}`.

### Conventions des scripts

- Nommer par rôle, pas par outil : `waf@decisions`, pas `crowdsec@decisions`.
- Commentaires en anglais, en tête de script et de fonction, avec `@usage`, `@param`,
  `@return`. Messages affichés en français.
- Toujours `set -euo pipefail` et `lib.sh`, qui fournit :

  | Fonction | Rôle |
  |---|---|
  | `load_env <commande>` | lit le `.env` et vérifie `APP_ENV` |
  | `require_app_env <commande> local\|prod` | refuse la commande dans l'autre environnement |
  | `compose …` | `docker compose` avec les fichiers de l'environnement |
  | `run …` | affiche une commande en grisé, puis l'exécute |
  | `info …` / `die …` | message / erreur et arrêt |
  | `tool <nom>` | chemin d'un outil : `.tools/bin/` en priorité, sinon celui du système |
  | `ensure_network`, `proxy_running` | réseau `proxy`, état de Traefik |

- Un message d'erreur indique toujours quoi faire : `… — lancer « make cert@create »`.
- Une commande peut être relancée sans risque : ce qui est déjà fait est sauté.

## Outils en version fixée

mkcert, gitleaks et shellcheck sont téléchargés dans `.tools/bin/` (non versionné), dans
une version fixée, et leur empreinte SHA-256 est vérifiée avant installation. Ainsi chaque
poste et GitHub Actions utilisent exactement le même outil.

Pour changer de version, modifier la variable `*_VERSION` en tête du script
(`.make/scripts/cert/mkcert.sh`, `.make/scripts/git/gitleaks.sh` ou
`.make/scripts/git/shellcheck.sh`). gitleaks publie ses empreintes, qui sont vérifiées
automatiquement. Pour mkcert et shellcheck, les empreintes sont écrites dans le script :
les mettre à jour pour chaque système, à partir des fichiers officiels.

## Fins de ligne et Windows

`.gitattributes` impose des fins de ligne LF à tous les fichiers : un script bash ou un
Makefile en CRLF ne fonctionne pas. Si des fichiers ont été récupérés avant ce réglage :

```bash
git add --renormalize . && git status
```

Sous Windows, le droit d'exécution n'existe pas dans le système de fichiers : il est
stocké dans Git, d'où `git update-index --chmod=+x`. La vérification `scripts.sh` le
rappelle si on l'oublie.

`.shellcheckrc` permet à shellcheck de suivre le `. "$(dirname "$0")/../lib.sh"` de chaque
script, et donc de connaître les fonctions de `lib.sh`.
