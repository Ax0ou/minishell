# GETTING_STARTED — finir le setup

> Le repo est créé, les 55 issues sont là, Davi est invité.
> Reste **3 actions manuelles** : créer le board, Davi accepte l'invite, vous clonez chez vous.

## 1. Axel — créer le board GitHub Projects (5 min)

1. Va sur https://github.com/Ax0ou/minishell
2. Onglet **"Projects"** (en haut, à côté de Issues / Pull requests / Actions)
3. Clique **"New project"** (ou "Link a project")
4. Choisis le template **"Board"** (Kanban)
5. Nomme-le **"Minishell"**, clique **Create**
6. Dans le board, **renomme** les colonnes par défaut et ajoute les manquantes pour avoir :
   - `Backlog`
   - `Sprint`
   - `In Progress`
   - `In Review`
   - `Done`
7. **Importer les issues du repo** :
   - Bouton **+** dans la colonne "Backlog"
   - **"+ Add item"** → tape `#` → toutes les 55 issues du repo apparaissent
   - Sélectionne-les toutes, ajoute-les au board
   - Ou utilise le bouton **"Add items"** en bas, filtre par repo, sélectionne tout

8. **Activer les automations** :
   - Bouton **"⚙ Workflows"** (en haut à droite du board)
   - Active :
     - `Item added to project` → Status: **Backlog**
     - `Pull request opened` → Status: **In Review**
     - `Pull request merged` → Status: **Done**
     - `Issue closed` → Status: **Done**

9. Déplace les **issues du Sprint 1** (#1 à #18) de Backlog vers Sprint

10. Copie le lien du board (URL dans le navigateur) et remplace la ligne du README qui dit "à créer manuellement".

## 2. Davi — accepter l'invitation

Davi reçoit un mail "Ax0ou invited you to Ax0ou/minishell". Sinon :
- Va sur https://github.com/Ax0ou/minishell/invitations
- Clique **"Accept invitation"**

Une fois accepté, Davi peut push, ouvrir des PR, etc.

## 3. Tous les deux — cloner le repo

Chacun de son côté (dans le dossier de son choix) :

```bash
git clone git@github.com:Ax0ou/minishell.git
cd minishell
git checkout dev
```

> ⚠️ **Important** : Axel a déjà le dossier `/Users/alvrd/Documents/42_Cursus/Milestone_3/` qui EST le repo (init en place). Pas besoin de re-cloner — c'est déjà lié.

## 4. Premier flux — tester le workflow ensemble (30 min en pair)

1. **Axel** prend l'issue #1 (Setup repo) :
   - Sur le board, drag #1 dans "In Progress"
   - `git checkout dev && git pull`
   - `git checkout -b feat/setup-makefile`
   - Crée le `Makefile`, le dossier `includes/`, `src/`, `libft/`, etc.
   - `git add . && git commit -m "chore: initial Makefile + folders"`
   - `git push -u origin feat/setup-makefile`
   - Sur GitHub, ouvre une **Pull Request** vers `dev` avec dans la description : `Closes #1`

2. **Davi** review :
   - Reçoit la notif, va sur la PR
   - Onglet "Files changed", commente si besoin
   - Si OK : **"Approve"** + **"Squash and merge"**
   - L'issue #1 se ferme automatiquement, la carte va dans "Done"

3. **Axel** :
   - `git checkout dev && git pull` → récupère le merge
   - `git branch -d feat/setup-makefile` → supprime la branche locale

4. **Davi** fait pareil avec l'issue #12 (env: init depuis envp).

Une fois ce premier cycle fait, vous avez le workflow en main pour les ~50 issues restantes.

---

## Référence rapide — workflow type pour UNE issue

```bash
# 1. Récupérer dev à jour
git checkout dev && git pull

# 2. Créer ta branche
git checkout -b feat/<scope>-<courte-description>
# ex : feat/lexer-tokenize, feat/builtin-cd, fix/heredoc-eof

# 3. Coder + tester
# (...)
bash tests/run_sprint.sh 1   # vérifie que rien n'est cassé

# 4. Sauvegarder
git add <fichiers>
git commit -m "feat(<scope>): <description courte>"
git push -u origin feat/<scope>-<courte-description>

# 5. Ouvrir une PR sur github.com (vers dev)
#    Description : Closes #<num_issue>
#    Attendre review du binôme → squash and merge

# 6. Nettoyer
git checkout dev && git pull
git branch -d feat/<scope>-<courte-description>
```

---

**Lis maintenant `docs/ROLES.md` puis `docs/WORKFLOW.md`** pour comprendre toutes les conventions (types de commits, conventions de branche, format des PR).
