# Guide pratique — Axel & Davi

> [!NOTE]
> **Pour qui** : Axel et Davi, première fois avec GitHub Projects.
> **But** : que vous puissiez bosser à 2 SANS jamais vous demander "j'ai oublié quoi faire" ou "j'ai cassé le code de l'autre".
> **Format** : exemples concrets, commandes à copier-coller, schémas visuels.

> [!IMPORTANT]
> Ce doc se lit en entier (20 min) AVANT de toucher au code. Sinon vous allez vous tromper sur des trucs basiques et le board va perdre toute sa valeur.

---

## ⚡ Le concept en 1 minute

> [!TIP]
> **À retenir** : tout ce que tu codes passe par ce cycle ↓. Aucune exception.

```
1 ISSUE  =  1 TÂCHE  =  1 BRANCHE  =  1 PR  =  1 MERGE
```

Si tu sors de ce cycle, le board devient faux et l'autre ne sait plus où tu en es.

---

## 🎬 Le cycle complet — exemple concret de A à Z

> [!NOTE]
> **Brief** : on déroule l'issue #5 ("lexer: tokenisation basique") du début à la fin. Ce flow est le MÊME pour les 50+ issues à venir. Apprends-le par cœur sur celle-ci.

### Étape 1 — Tu choisis la carte sur le board

Va sur https://github.com/Ax0ou/minishell → onglet **Projects** → ouvre le board "Minishell".

Tu vois tes issues dans la colonne **Todo**. Filtre par label : tape `label:sprint:S1` dans la barre de recherche du board → tu vois les 18 issues du Sprint 1.

```
[BOARD]
┌─────────────────┬──────────────┬─────────────┬───────────┬──────┐
│      Todo       │ In Progress  │  In Review  │   Done    │ ...  │
├─────────────────┼──────────────┼─────────────┼───────────┼──────┤
│ #5 lexer:tok    │              │             │           │      │
│ #6 lexer:quotes │              │             │           │      │
│ #8 echo         │              │             │           │      │
│ ...             │              │             │           │      │
└─────────────────┴──────────────┴─────────────┴───────────┴──────┘
                                                                    
```

**Drag&drop** #5 de Todo vers **In Progress**.

> [!TIP]
> C'est la SEULE action manuelle du cycle. Tout le reste (passage en In Review, Done, etc.) se fait automatiquement grâce aux workflows GitHub Projects.

### Étape 2 — Tu prépares ta branche sur ton Mac

Ouvre ton terminal dans le dossier du projet :

```bash
cd ~/Documents/42_Cursus/Milestone_3   # ou ton chemin clone si tu es Davi

# Toujours partir de dev à jour
git checkout dev
git pull

# Créer ta branche
git checkout -b feat/lexer-tokenize
```

✅ Tu es maintenant sur **ta** branche. Ce que tu fais ici est isolé de Davi.

### Étape 3 — Tu codes

> [!NOTE]
> **Brief** : tu es maintenant en mode "tunnel". Tu codes ta feature, tu testes, sans toucher au reste du projet.

Tu crées `src/lexer/tokenize.c`, tu codes la fonction, tu testes. Pendant ce temps, **Davi sur sa branche est totalement isolé**, vous ne pouvez pas vous gêner.

Si tu veux sauvegarder ton avancée en cours de route (sans finir la tâche) :

```bash
git add src/lexer/tokenize.c
git commit -m "feat(lexer): start tokenize function"
git push -u origin feat/lexer-tokenize   # premier push : -u (pour lier)
```

Plus tard, juste :

```bash
git add <fichiers>
git commit -m "feat(lexer): handle whitespace splitting"
git push
```

### Étape 4 — Tu finis et tu lances les tests

```bash
# Vérifie que ça compile + tests
make
bash tests/run_sprint.sh 1     # tous les tests du sprint en cours
norminette src/                 # norme 42 OK ?

# Si tout est vert → push final
git push
```

> [!CAUTION]
> **Si UN test fail, NE FAIS PAS LA PR.** Corrige d'abord. Une PR avec tests cassés c'est non — ça crée du bruit, casse la confiance et fait perdre du temps à Davi en review.

### Étape 5 — Tu ouvres la Pull Request (PR)

Sur GitHub :
- Va sur https://github.com/Ax0ou/minishell
- Tu verras un bandeau jaune **"feat/lexer-tokenize had recent pushes — Compare & pull request"**
- Clique dessus.

OU manuellement :
- Onglet **"Pull requests"** → bouton vert **"New pull request"**
- `base: dev` ← `compare: feat/lexer-tokenize`
- Clique **"Create pull request"**

### Étape 6 — RÈGLE ABSOLUE : tu mets `Closes #5` dans la description

> [!IMPORTANT]
> **La seule règle indispensable de tout le workflow.** Sans `Closes #N`, l'automatisation casse intégralement.

Le template de PR s'ouvre. **DANS LA DESCRIPTION** (pas juste le titre), tu mets :

```
## What
Implémente la tokenisation basique (whitespace + mots)

## Why
Closes #5

## How to test
- bash tests/unit/test_lexer.sh
- Doit retourner ≥ 16 cas verts

## Checklist
- [x] make compile sans warning
- [x] norminette OK
- [x] tests passent
- [x] no leaks
```

> [!WARNING]
> **Si tu oublies `Closes #5`** :
> - L'issue #5 reste coincée dans "In Progress" pour toujours
> - Le board ne reflète plus la réalité
> - Tu galères à comprendre où t'en es au sprint suivant
>
> Solution : éditer la PR (bouton "Edit"), ajouter `Closes #5` dans la description, save. Le workflow se redéclenche.

> [!TIP]
> Synonymes acceptés : `Closes #5`, `Fixes #5`, `Resolves #5` (tous fonctionnent pareil).

### Étape 7 — La carte bouge TOUTE SEULE

Dès que tu cliques "Create pull request" :

```
[BOARD — automatique]
┌─────────────────┬──────────────┬─────────────┬───────────┐
│      Todo       │ In Progress  │  In Review  │   Done    │
├─────────────────┼──────────────┼─────────────┼───────────┤
│ #6 lexer:quotes │              │ #5 lexer:tok│           │  ← #5 a bougé !
│ #8 echo         │              │             │           │
└─────────────────┴──────────────┴─────────────┴───────────┘
```

Tu n'as **rien fait sur le board**. C'est le workflow GitHub Projects qui a vu la PR et a déplacé la carte. Magie.

### Étape 8 — Davi review

Davi reçoit une notif GitHub : "Axel asked for your review on PR #N".

Il va sur la PR, onglet **"Files changed"**, lit ton code :
- Si OK → bouton **"Review changes"** → **"Approve"** → submit
- Si pas OK → bouton **"Review changes"** → **"Request changes"** + commentaires sur les lignes problématiques

### Étape 9 — Tu merges

Une fois approuvé, tu vois le bouton vert **"Merge pull request"** (la branche `main` est protégée donc tu ne pouvais pas merger SANS approval).

> [!IMPORTANT]
> **Choisis "Squash and merge"** (déroule le menu si tu vois autre chose).
>
> Pourquoi squash : tes 8 commits "feat: WIP", "fix typo" deviennent UN seul commit propre dans `dev`. L'historique reste lisible.

Clique **"Confirm squash and merge"**.

### Étape 10 — Tout se nettoie automatiquement

```
[BOARD — automatique]
┌─────────────────┬──────────────┬─────────────┬───────────┐
│      Todo       │ In Progress  │  In Review  │   Done    │
├─────────────────┼──────────────┼─────────────┼───────────┤
│ #6 lexer:quotes │              │             │ #5 ✓      │  ← #5 fermée + Done
│ #8 echo         │              │             │           │
└─────────────────┴──────────────┴─────────────┴───────────┘
```

- L'issue #5 est fermée (à cause du `Closes #5`)
- La carte passe en **Done** (workflow "Item closed")
- La branche `feat/lexer-tokenize` peut être supprimée (clique le bouton "Delete branch" sur GitHub)

### Étape 11 — Tu reviens sur ton Mac, tu nettoies

```bash
git checkout dev
git pull                            # tu récupères le merge
git branch -d feat/lexer-tokenize   # supprime la branche locale (proprement)
```

Et voilà. Tu repars à l'étape 1 avec la prochaine issue.

---

## 🛡️ Les 5 règles d'or — à TATOUER sur le bras

> [!IMPORTANT]
> **Brief** : ces 5 règles couvrent 95% des problèmes possibles. Les respecter = pas de drame de la session.

### 1. Toujours `Closes #N` dans la description de la PR

> [!CAUTION]
> Sans ça, l'automatisation casse. Pas de Closes = pas de merge (politique d'équipe, pas une règle GitHub).

### 2. Jamais `git push` direct sur `main` ou `dev`

> [!WARNING]
> - `main` est protégée (GitHub refusera de toute façon)
> - `dev` n'est pas protégée techniquement, mais on s'interdit d'y pusher direct. Toujours via PR.

### 3. Une issue = une branche = une PR

> [!NOTE]
> Pas de "je fais 3 issues sur ma branche, je fais une grosse PR". Trop dur à reviewer, trop dur à revert si bug.

### 4. Avant de pusher, tu lances les tests

```bash
make && bash tests/run_sprint.sh <N> && norminette src/
```

> [!CAUTION]
> Si UN seul truc fail → tu corriges, tu pushes PAS.

### 5. Pull souvent, push souvent

> [!TIP]
> - Le matin : `git checkout dev && git pull` AVANT de créer une branche
> - Le soir : `git push` même si pas fini (au moins ton code est en ligne)
> - Plus tu attends, plus les conflits sont gros

---

## 🚨 Les erreurs classiques (et comment les éviter)

> [!NOTE]
> **Brief** : tout le monde fait ces erreurs au moins une fois. Pas grave si tu les attrapes tôt. Voici la procédure pour chacune.

### "J'ai modifié `main` au lieu de `dev`"
```bash
git status   # → "On branch main"
# Si tu n'as pas commit : git stash && git checkout dev && git stash pop
# Si tu as déjà commit : git log → note le hash, git reset --hard HEAD~1, git checkout dev, git cherry-pick <hash>
# En cas de doute → demande avant de toucher
```

### "J'ai oublié `Closes #N` dans la PR"
1. Sur la PR ouverte, clique "Edit" (à côté du titre)
2. Ajoute `Closes #N` dans la description
3. Save — le workflow se redéclenche

### "Mon binôme a pushé entre temps, j'ai un conflit"
1. **NE PAS PANIQUER.** Les conflits sont normaux.
2. `git pull origin dev` (sur ta branche)
3. Git te dit "CONFLICT in <fichier>"
4. Ouvre le fichier dans VS Code, tu verras :
   ```
   <<<<<<< HEAD
   ton code
   =======
   le code de Davi
   >>>>>>> origin/dev
   ```
5. Tu choisis : ton code, son code, ou les deux. Tu supprimes les marqueurs `<<<`, `===`, `>>>`.
6. `git add <fichier>` puis `git commit` (le message est pré-rempli)
7. `git push`

Si tu ne comprends pas le code de l'autre → **PING-le, résolution en pair (5 min).**

### "Je veux annuler mon dernier commit local (pas encore push)"
```bash
git reset --soft HEAD~1   # le commit est annulé, tes modifs restent
# OU
git reset --hard HEAD~1   # ⚠️ DESTRUCTIF : annule le commit ET les modifs
```

### "J'ai déjà push et je veux annuler"

> [!CAUTION]
> Ne fais PAS `git push --force` sur `dev` ou `main`. Ça réécrit l'historique, ça peut écraser le travail de Davi.

À la place :
```bash
git revert <hash_du_commit>   # crée un nouveau commit qui annule l'ancien
git push
```

> [!TIP]
> `revert` est non-destructif : il ajoute un commit qui défait l'ancien. L'historique reste propre et lisible.

---

## 📝 Conventions de commit (rapide)

> [!NOTE]
> **Brief** : on suit le standard [Conventional Commits](https://www.conventionalcommits.org/fr/). Avantage : l'historique git devient lisible en un coup d'œil ("ah, 5 feat, 2 fix, 1 refactor cette semaine").

Format : `<type>(<scope>): <description>`

| Type | Quand |
|------|-------|
| `feat` | Nouvelle fonctionnalité |
| `fix` | Correction de bug |
| `refactor` | Restructuration sans changer le comportement |
| `test` | Ajout/correction de tests |
| `docs` | Documentation |
| `chore` | Makefile, config, housekeeping |

**Exemples** :
```
feat(lexer): handle single-quote tokenization
fix(executor): close pipe fds in parent before wait
test(parser): cover unclosed quote error
docs(architecture): clarify heredoc handling
chore(makefile): add bonus rule
```

Le `<scope>` = le module touché (lexer, parser, executor, etc.). Optionnel mais super utile.

---

## 🧭 Cheat sheet — commandes git que tu utiliseras 1000 fois

> [!TIP]
> Imprime cette section et colle-la à côté de ton écran les 2 premières semaines. Après ça devient un réflexe.

```bash
# Vue d'ensemble
git status              # qu'est-ce qui a changé ?
git log --oneline -5    # 5 derniers commits
git branch              # quelles branches j'ai en local ?

# Changer de branche
git checkout dev
git checkout -b feat/nouvelle-branche   # créer + switcher

# Sauvegarder
git add <fichier>           # marquer un fichier
git add .                   # marquer TOUT (attention aux .DS_Store)
git commit -m "message"     # créer un commit
git push                    # envoyer sur GitHub

# Récupérer
git pull                    # récupérer les changements de la branche distante
git fetch                   # voir les changements sans les appliquer

# En cas de pépin
git stash                   # mettre de côté ce qui n'est pas commit
git stash pop               # remettre ce qui était de côté
git checkout -- <fichier>   # ANNULER les modifs non commit sur ce fichier
```

---

## 📺 Ressources pour visualiser

**À voir AVANT d'attaquer la première issue** :

1. **Atlassian — Workflow de branche de fonctionnalité** (15 min lecture, FR)
   https://www.atlassian.com/fr/git/tutorials/comparing-workflows/feature-branch-workflow
   → le pattern exact qu'on utilise (branche par feature → PR → merge)

2. **Atlassian — Qu'est-ce qu'une pull request** (10 min, FR)
   https://www.atlassian.com/fr/git/tutorials/making-a-pull-request
   → explique en français le concept de PR de A à Z

3. **Microsoft Tech Community — Initiation à GitHub Projects** (FR)
   https://techcommunity.microsoft.com/blog/educatordeveloperblog/initiation-%C3%A0-github-projects---partie-i-tableau-kanban/3784393
   → tour du board Kanban en français avec captures d'écran

4. **GitHub Docs — GitHub Projects Quickstart** (EN, 5 min)
   https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/quickstart-for-projects
   → la doc officielle

5. **Grafikart — Git Workflow** (vidéo FR)
   https://grafikart.fr/tutoriels/git-workflow-478
   → vidéo de référence en français sur les workflows Git

**Vidéos YouTube à chercher** (mots-clés) :
- "GitHub Projects 2024 tutorial français"
- "Git workflow équipe pull request"
- "GitHub Pull Request tuto français"

Recommandation : regarde Grafikart (lien ci-dessus) AVANT de commencer, c'est 30 min et ça te débloque visuellement.

---

## 🎯 Si tu te perds — l'ordre des choses

> [!IMPORTANT]
> **Brief** : à chaque blocage, regarde cette liste. La réponse à 95% de tes questions est dans un fichier `docs/` ou ce guide.

1. **Tu ne sais pas quelle issue prendre ?** → board → filtre `label:sprint:S1` → prends-en une assignée à toi ou non assignée
2. **Tu sais pas comment faire ?** → ce fichier, partie "Le cycle complet"
3. **Tu as un bug bizarre dans ton code minishell ?** → `docs/EDGE_CASES.md`
4. **Tu doutes du comportement attendu ?** → `docs/PARSING_RULES.md` (ou compare avec bash)
5. **Tu sais pas si ta feature est complète ?** → `docs/TESTS.md §<sprint en cours>` → fais passer tous les tests listés
6. **Tu vas rendre dans 24h ?** → `docs/CHECKLIST.md`
7. **Tu vas passer l'éval ?** → `docs/DEFENSE.md`

---

**Quand vous avez TOUS LES DEUX lu ce fichier, vous êtes prêts. Pas avant.**
