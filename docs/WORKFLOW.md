# Workflow Git + GitHub — Minishell

> Comment on bosse à deux **sans se marcher dessus**, avec un board qui se met à jour tout seul.

## Branches

```
main         ← rendu final, protégée, jamais de push direct
 │
 └─ dev      ← intégration, c'est ici qu'on merge les features
     │
     ├─ feat/lexer-tokens          (Personne A)
     ├─ feat/executor-pipes        (Personne B)
     ├─ feat/builtin-cd            (Personne B)
     ├─ fix/heredoc-eof            (Personne A)
     └─ docs/readme-final          (commun)
```

**Règles** :
- Jamais de push direct sur `main` ou `dev`.
- Une issue = une branche = une PR.
- Branch name : `<type>/<scope>` — types : `feat`, `fix`, `refactor`, `docs`, `test`, `chore`.

## Cycle d'une tâche

```
1. Choisir une issue sur le board → la passer en "In Progress"
2. git checkout dev && git pull
3. git checkout -b feat/lexer-tokens
4. Code + commits (cf. convention plus bas)
5. git push -u origin feat/lexer-tokens
6. Ouvrir une PR vers dev
   - Titre : "feat(lexer): tokenize basic words and operators"
   - Description : "Closes #5"
7. Demander la review du binôme
8. Une fois approuvée : merge (squash) → la PR ferme l'issue
9. git branch -d feat/lexer-tokens (local)
```

## Convention de commits (Conventional Commits)

```
<type>(<scope>): <description courte>

[body optionnel]
```

**Types** :
- `feat` — nouvelle fonctionnalité
- `fix` — bug fix
- `refactor` — restructuration sans changement de comportement
- `test` — ajout/correction de tests
- `docs` — documentation
- `chore` — Makefile, config, housekeeping

**Exemples** :
```
feat(lexer): add single-quote handling
fix(executor): close pipe fds in parent before wait
test(parser): cover unclosed quote error
docs(readme): add installation steps
```

## Pull Requests

### Template (cf. `.github/PULL_REQUEST_TEMPLATE.md`)

```
## What
[1-2 lignes : qu'est-ce qui change]

## Why
Closes #<numéro_issue>

## How to test
- Commande/scénario à reproduire
- Output attendu

## Checklist
- [ ] make compile sans warning
- [ ] norminette OK
- [ ] tests passent
- [ ] no leaks (valgrind)
```

### Règles de review

- **Toute PR doit être reviewée par le binôme** avant merge.
- Review ≠ tampon : lire le code, commenter ce qui n'est pas clair.
- Si la PR touche un module que tu n'as pas écrit, c'est encore plus important : c'est ton moment pour comprendre.
- Demander des modifs > approuver vite fait.

### Quand merger ?

- Approval reçu
- CI verte (norminette + compile)
- Pas de conflits avec `dev`

Préférer **squash and merge** pour garder l'historique de `dev` propre (un commit par feature).

## GitHub Projects — Board

### Structure du board (Kanban)

| Colonne          | Quand y mettre les issues ?                  |
|------------------|----------------------------------------------|
| **Backlog**      | À traiter plus tard, pas prioritaire         |
| **Sprint (S1-4)**| Sélectionnées pour la semaine en cours       |
| **In Progress**  | Quelqu'un bosse dessus (max 2 par personne)  |
| **In Review**    | PR ouverte, en attente de review             |
| **Done**         | Mergé sur `dev`                              |

### Automation (configurée une fois)

Dans Settings → Workflows du Project :
- Issue ouverte → ajoutée auto à **Backlog**
- Issue assignée à quelqu'un → passe en **Sprint**
- PR ouverte qui mentionne `Closes #N` → l'issue passe en **In Review**
- PR mergée → l'issue passe en **Done** et se ferme

Résultat : tu n'as **rien à mettre à jour manuellement**, le board reflète le repo.

### Champs custom utiles

- `Sprint` (single select) : S1, S2, S3, S4, Bonus
- `Module` (single select) : Lexer, Parser, Expander, Executor, Builtins, Signals, Env, Tests, Docs
- `Owner` (single select) : Axel, Binôme, Pair
- `Estimate` (number, en heures)

## Daily standup async

**Issue épinglée "📅 Daily Standup"** — chacun y poste un commentaire/jour :

```
**[Date] — [Nom]**
- Hier : #X, #Y mergés
- Aujourd'hui : #Z en cours, vise #W
- Blockers : aucun / besoin d'un avis sur la gestion des heredocs
```

2 min à écrire. Évite les "tu travailles sur quoi ?" en boucle.

## Setup initial (à faire 1 fois, ensemble)

```bash
# 1. Créer le repo sur GitHub (privé)
gh repo create minishell --private --clone

# 2. Ajouter les fichiers d'orga
cp -r ~/Documents/42_Cursus/Milestone_3/docs minishell/
cp -r ~/Documents/42_Cursus/Milestone_3/.github minishell/
cp ~/Documents/42_Cursus/Milestone_3/README.md minishell/

# 3. Premier commit
cd minishell
git add .
git commit -m "chore: initial project organization"
git push

# 4. Créer la branche dev
git checkout -b dev
git push -u origin dev

# 5. Protéger main (via gh ou UI)
gh api -X PUT "repos/{owner}/minishell/branches/main/protection" \
  -f required_status_checks='{"strict":true,"contexts":[]}' \
  -F enforce_admins=false \
  -f required_pull_request_reviews='{"required_approving_review_count":1}' \
  -F restrictions=null

# 6. Créer le board "Minishell"
gh project create --title "Minishell" --owner @me

# 7. Créer les milestones
gh api repos/:owner/minishell/milestones -f title="J1 - Fondations"
gh api repos/:owner/minishell/milestones -f title="J2 - Exécution"
gh api repos/:owner/minishell/milestones -f title="J3 - Pipelines"
gh api repos/:owner/minishell/milestones -f title="J4 - Polish + Rendu"
```

## Conflits de merge — protocole

1. **Ne pas paniquer.** Les conflits sont normaux.
2. `git pull origin dev` sur ta branche
3. Ouvrir le fichier en conflit dans VS Code (markers `<<<<<<<`)
4. **Si tu ne comprends pas le code de l'autre** → PING ton binôme, résolution en pair (5 min)
5. `git add .` puis `git commit` (le message du merge est généré)
6. `git push`

**Règle d'or** : pull souvent, push souvent. Plus tu attends, pire c'est.
