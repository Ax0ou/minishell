# Répartition binôme — Minishell

> Découpage **frontend / backend** autour de l'AST.
> Niveau équivalent → charge équilibrée (~50/50).
> À ajuster en pair-programming pour les zones grises (signals, env).

## Principe de découpe

```
┌────────────────────────────┐         ┌────────────────────────────┐
│   PERSONNE A (frontend)    │         │   PERSONNE B (backend)     │
│   "Comprendre la ligne"    │         │   "Exécuter l'AST"         │
└────────────┬───────────────┘         └────────────┬───────────────┘
             │                                       │
             │            interface = AST            │
             └──────────────────┬────────────────────┘
                                ▼
                  structures t_token, t_cmd, t_pipeline
                       (figées fin semaine 1)
```

## Personne A — Axel (frontend)

**Modules principaux :**
- `lexer/` — tokenisation
- `parser/` — construction de l'AST
- `expander/` — `$VAR`, `$?`, gestion des quotes
- `signals/` — handlers (en pair avec B)

**Builtins :**
- `echo` (avec `-n`)
- `pwd`
- `env`
- `exit`

**Pourquoi cette répartition** : l'analyse syntaxique forme un bloc cohérent (tokenisation → AST → expansion). Les builtins choisis sont simples et n'impactent pas l'env (sauf exit). `signals` traverse les couches → travail à deux.

**Heures estimées :** ~80h

---

## Personne B — Binôme (backend)

**Modules principaux :**
- `executor/` — fork, exec, pipes, redirections, heredoc
- `env/` — structure linked list, init/get/set/unset
- `utils/` — error.c, cleanup.c
- `signals/` — handlers (en pair avec A)

**Builtins :**
- `cd` (gestion `PWD`/`OLDPWD`)
- `export` (avec/sans args, tri alphabétique)
- `unset`

**Pourquoi cette répartition** : l'exécution forme l'autre bloc cohérent (fork/exec/wait + IO). Les builtins choisis modifient l'env → cohérent avec le module env. `cleanup` est dans le backend parce que c'est lui qui orchestre la fin de chaque cycle REPL.

**Heures estimées :** ~80h

---

## Travail en commun (pair-programming)

| Sujet | Pourquoi en commun |
|-------|--------------------|
| Définition des structures (fin semaine 1) | Contrat partagé |
| `signals/` | Touche prompt + heredoc + exec — frontière floue |
| `main.c` (boucle REPL) | Orchestre tous les modules |
| `Makefile` | Doit lister TOUS les `.c` |
| Tests d'intégration | Vérifient l'interaction entre les deux blocs |
| Debug fin de projet | Le plus dur = les bugs cross-module |

## Anti-conflits

- **Une feature = une branche** (`feat/lexer`, `feat/executor/pipes`, ...)
- **Une seule personne par fichier à la fois** — pour éviter les merge conflicts
- **Push quotidien** — visibilité de l'avancement sur le board
- **Daily standup async** : chacun écrit 3 lignes dans une issue épinglée (hier / aujourd'hui / blockers) — 2 min/jour
