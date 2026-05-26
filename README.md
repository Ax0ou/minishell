# Minishell — Organisation

> Hub central de l'organisation du projet **Minishell** (42 / Milestone 3).

## Lis ces docs dans l'ordre

### Tronc — à lire avant de coder
| # | Doc | Pourquoi |
|---|-----|----------|
| 1 | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Découpage en modules, structures, 8 décisions techniques figées |
| 2 | [docs/ROLES.md](docs/ROLES.md) | Qui fait quoi — répartition binôme |
| 3 | [docs/PLAN.md](docs/PLAN.md) | Planning 4 semaines + critères go/no-go par sprint |
| 4 | [docs/WORKFLOW.md](docs/WORKFLOW.md) | Git, branches, PR, board GitHub Projects |
| 5 | [docs/TESTS.md](docs/TESTS.md) | Stratégie 4 niveaux, 250+ cas, scripts par sprint |

### Référence — à garder ouvert pendant le code
| # | Doc | Quand l'ouvrir |
|---|-----|----------------|
| 6 | [docs/PARSING_RULES.md](docs/PARSING_RULES.md) | Quand tu codes lexer / parser / expander |
| 7 | [docs/EDGE_CASES.md](docs/EDGE_CASES.md) | À chaque bug "bizarre". Catalogue des pièges 42 |

### Rendu — à faire la dernière semaine
| # | Doc | Quand |
|---|-----|-------|
| 8 | [docs/CHECKLIST.md](docs/CHECKLIST.md) | 24h avant de rendre — 147 items à cocher |
| 9 | [docs/DEFENSE.md](docs/DEFENSE.md) | Avant l'éval — 16 questions classiques + réponses |

## État du projet

- **Échéance** : 4 semaines à partir de la création du repo
- **Outil de suivi** : GitHub Projects (board lié au repo)
- **Binôme** : 2 développeurs équivalents, ~20-25h/sem chacun

## Liens rapides

- [Board GitHub Projects](#) ← à remplir après création
- [Repo GitHub](#) ← à remplir après création
- [Sujet PDF](#) ← stocker dans `docs/subject.pdf`

## Structure (cible) — ~60 fichiers .c, voir détail dans ARCHITECTURE.md

```
minishell/
├── Makefile
├── README.md             # README final (livrable 42)
├── includes/minishell.h
├── libft/                # ta libft, copiée
├── src/
│   ├── main.c
│   ├── lexer/            # tokenisation (~7 fichiers)
│   ├── parser/           # AST (~13 fichiers, 1 par opérateur)
│   ├── expander/         # $VAR, $?, quotes (~7 fichiers)
│   ├── executor/         # fork/exec/wait (~6 fichiers)
│   ├── redirections/     # < > >> + plomberie pipes (~3 fichiers)
│   ├── builtins/         # echo cd pwd export unset env exit (7 fichiers)
│   ├── signals/          # SIGINT, SIGQUIT, modes (~2 fichiers)
│   ├── env/              # linked list env (~3 fichiers)
│   └── utils/            # errors, cleanup, init (~5 fichiers)
└── tests/                # cf docs/TESTS.md — 4 niveaux
    ├── lib.sh
    ├── run_all.sh
    ├── run_sprint.sh
    ├── unit/
    ├── integration/
    ├── system/
    ├── leaks/
    └── manual/
```

## Anti-patterns bannis (cf ARCHITECTURE.md)

- Pas d'expansion dans le lexer (on perd l'info de quote)
- Pas de `wait()` avant d'avoir fork tous les enfants du pipeline
- Pas de `close()` oublié sur les fds de pipe dans le parent
- Pas d'`exit()` dans les builtins (sauf `exit` lui-même)
- Pas de `printf` pour les erreurs (utiliser `write` sur fd 2)
