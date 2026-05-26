<div align="center">

```
███╗   ███╗██╗███╗   ██╗██╗███████╗██╗  ██╗███████╗██╗     ██╗
████╗ ████║██║████╗  ██║██║██╔════╝██║  ██║██╔════╝██║     ██║
██╔████╔██║██║██╔██╗ ██║██║███████╗███████║█████╗  ██║     ██║
██║╚██╔╝██║██║██║╚██╗██║██║╚════██║██╔══██║██╔══╝  ██║     ██║
██║ ╚═╝ ██║██║██║ ╚████║██║███████║██║  ██║███████╗███████╗███████╗
╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝
```

### *A tiny bash, written in C, by two students who refuse to debug for 3 weeks.*

![C](https://img.shields.io/badge/Language-C-00599C?style=flat-square&logo=c&logoColor=white)
![42](https://img.shields.io/badge/School-42_Lausanne-000000?style=flat-square&logo=42&logoColor=white)
![Status](https://img.shields.io/badge/Status-Pre--kickoff-yellow?style=flat-square)
![Sprint](https://img.shields.io/badge/Sprint-Awaiting_Davi-blueviolet?style=flat-square)
![Norm](https://img.shields.io/badge/Norminette-pending-lightgrey?style=flat-square)
![License](https://img.shields.io/badge/License-MIT_(maybe)-blue?style=flat-square)

[![Issues](https://img.shields.io/github/issues/Ax0ou/minishell?style=flat-square&color=success)](https://github.com/Ax0ou/minishell/issues)
[![Closed Issues](https://img.shields.io/github/issues-closed/Ax0ou/minishell?style=flat-square&color=blueviolet)](https://github.com/Ax0ou/minishell/issues?q=is%3Aissue+is%3Aclosed)
[![Last commit](https://img.shields.io/github/last-commit/Ax0ou/minishell?style=flat-square)](https://github.com/Ax0ou/minishell/commits)

</div>

---

## ✦ What is this

A **POSIX-ish shell**, written from scratch in C, that reproduces the core behavior of `bash` :
parsing, redirections, pipes, environment variables, signal handling, built-in commands, the whole circus.

Built as the **Milestone 3** project of [42 Lausanne](https://42lausanne.ch/), in pair, over 4 weeks.

**Reference behavior** = bash (`echo cmd | bash --posix`). When in doubt, we follow bash.

---

## ✦ The pipeline

```
                           ┌──────────────┐
   user types a line  ──▶  │  readline()  │  ◀── arrow keys / history / Ctrl-C
                           └──────┬───────┘
                                  │  "ls -la | grep .c > out.txt"
                                  ▼
                ┌──────────────────────────────────┐
                │              LEXER               │
                │  splits into tokens, keeps quote │
                │  info, detects | < > << >>       │
                └──────────────┬───────────────────┘
                               │  [WORD:ls] [WORD:-la] [PIPE] [WORD:grep] ...
                               ▼
                ┌──────────────────────────────────┐
                │             PARSER               │
                │  builds a linked list of t_cmd,  │
                │  attaches redirections,          │
                │  pre-reads heredocs              │
                └──────────────┬───────────────────┘
                               │  pipeline → cmd1(ls -la) → cmd2(grep .c, >out)
                               ▼
                ┌──────────────────────────────────┐
                │            EXPANDER              │
                │  resolves $VAR and $?,           │
                │  strips quotes,                  │
                │  respects single vs double       │
                └──────────────┬───────────────────┘
                               │
                               ▼
                ┌──────────────────────────────────┐
                │            EXECUTOR              │
                │  fork, pipe, dup2, execve, wait  │
                │  builtins run in parent if alone │
                └──────────────┬───────────────────┘
                               │
                               ▼
                          $? updated
                               │
                               ▼
                       back to readline()
```

---

## ✦ Sprint progress

| Sprint | Goal | Status | Tests |
|:------:|------|:------:|:-----:|
| **S1** | Lexer + Env + builtins simples (`echo`, `pwd`, `env`, `exit`) | ⬜ Pending | 0 / ~41 |
| **S2** | Parser + Executor 1 cmd + Redirections + `cd` | ⬜ Pending | 0 / ~35 |
| **S3** | Expander + Pipes + Heredoc + `export`/`unset` | ⬜ Pending | 0 / ~40 |
| **S4** | Signals + Polish + Leak chase + 50 edge cases | ⬜ Pending | 0 / ~50 |
| **Bonus** | `&&`, `||`, `()`, wildcards | ⬜ Optional | — |

> [!NOTE]
> Trackeur mis à jour à chaque clôture de sprint. Voir [docs/PLAN.md](docs/PLAN.md) pour les critères go/no-go.

---

## ✦ Features (toggle as we ship)

### Mandatory
- ⬜ Prompt with readline + history
- ⬜ Single command : `ls`, `cat`, `/bin/echo`, etc.
- ⬜ Quotes (`'...'` literal, `"..."` with expansion)
- ⬜ Redirections : `<`, `>`, `>>`
- ⬜ Heredoc : `<<` (with/without quoted delimiter)
- ⬜ Pipes : `cmd1 | cmd2 | cmd3 ...`
- ⬜ Environment variables : `$VAR`, `$?`
- ⬜ Built-ins : `echo -n`, `cd`, `pwd`, `export`, `unset`, `env`, `exit`
- ⬜ Signals : `Ctrl-C`, `Ctrl-D`, `Ctrl-\`
- ⬜ Exit codes : 0, 1, 2, 126, 127, 128+N

### Constraints (non-negotiable)
- 🛡️ Norminette compliant
- 🛡️ Zero memory leaks (excluding readline)
- 🛡️ Zero segfault / bus error / double free
- 🛡️ Exactly **one** global variable (an `int`, for the signal number)
- 🛡️ Only [authorized functions](docs/PARSING_RULES.md#11-liste-de-fonctions-externes-autoris%C3%A9es)

### Bonus (if mandatory is perfect)
- ⬜ `&&` and `||` with parentheses
- ⬜ Wildcards `*` in cwd

---

## ✦ Quick start

> [!WARNING]
> Pas encore de code. Cette section sera à jour dès le S1.

```bash
git clone git@github.com:Ax0ou/minishell.git
cd minishell

make            # build
./minishell     # launch

# Inside:
$ echo "hello $USER" | cat
hello axalva
$ exit
```

### Running tests

```bash
bash tests/run_all.sh         # tout : build + norm + unit + integ + leaks
bash tests/run_sprint.sh 1    # juste le sprint courant
```

---

## ✦ Repo structure

```
minishell/
├── README.md          ← you are here
├── TEAM_GUIDE.md      ← daily workflow for the duo (READ FIRST)
├── docs/              ← 9 planning & reference docs (~3000 lines)
├── tests/             ← 4-tier test suite (unit / integration / system / leaks)
├── .github/           ← PR + issue templates
├── Makefile           ← (to be created in S1)
├── includes/          ← (to be created in S1)
├── libft/             ← (to be created in S1)
└── src/               ← (to be created in S1)
    ├── lexer/        parser/       expander/
    ├── executor/     redirections/ builtins/
    ├── signals/      env/          utils/
```

Target : **~60 .c files** following the 4-functions-per-file norm 42 rule.

---

## ✦ The two humans behind this

| | | |
|:-:|:-:|---|
| <img src="https://github.com/Ax0ou.png" width="80" /> | **Axel** ([`@Ax0ou`](https://github.com/Ax0ou)) | Frontend : lexer / parser / expander / signals<br>Built the org. Yells at himself when forgetting `Closes #N`. |
| <img src="https://github.com/DaVy0903.png" width="80" /> | **Davi** ([`@DaVy0903`](https://github.com/DaVy0903)) | Backend : executor / env / utils / signals<br>Brings the fork() wisdom. |

---

## ✦ Documentation

> [!TIP]
> Tout est dans `docs/`. Lis dans l'ordre selon ta phase.

### Before you code
| # | File | Purpose |
|---|------|---------|
| 1 | [TEAM_GUIDE.md](TEAM_GUIDE.md) | **READ FIRST.** Daily workflow : branches, PR, board, conventions |
| 2 | [docs/ROLES.md](docs/ROLES.md) | Who codes what |
| 3 | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Module breakdown + 8 frozen technical decisions |
| 4 | [docs/PLAN.md](docs/PLAN.md) | 4-week roadmap + go/no-go criteria |
| 5 | [docs/WORKFLOW.md](docs/WORKFLOW.md) | Git conventions detail |
| 6 | [docs/TESTS.md](docs/TESTS.md) | Test strategy, 250+ cases, runners |

### While you code
| # | File | When |
|---|------|------|
| 7 | [docs/PARSING_RULES.md](docs/PARSING_RULES.md) | Coding lexer/parser/expander |
| 8 | [docs/EDGE_CASES.md](docs/EDGE_CASES.md) | Any "weird" bug. The 42 traps catalog |

### Before you submit
| # | File | When |
|---|------|------|
| 9 | [docs/CHECKLIST.md](docs/CHECKLIST.md) | 24h before submit — 147 items |
| 10 | [docs/DEFENSE.md](docs/DEFENSE.md) | Before evaluation — 16 classic Q&A |

---

## ✦ Anti-patterns we will NOT commit

> [!CAUTION]
> Toute PR qui viole une de ces règles est refusée à la review. Cf [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

- ❌ Expansion inside the lexer (we'd lose the quote info)
- ❌ `wait()` before forking ALL children of a pipeline (deadlock on SIGPIPE)
- ❌ Forgetting `close()` on pipe fds in the parent (children stuck on `read`)
- ❌ Calling `exit()` from a builtin (except `exit` itself) — we `return` codes
- ❌ Using `printf` for errors — `write` on fd 2 only
- ❌ More than one global variable (the sole `int g_signal` is sacred)

---

## ✦ Acknowledgements

- **mcombeau/minishell** — for inspiration on the file granularity (got 99% at eval). Studied the structure, wrote everything from scratch.
- **The 42 community** — for the testers (francinette, 42_minishell_tester, mshell_tester) and the absurd amount of edge cases discovered the hard way.
- **bash man page** — our north star.

---

<div align="center">

*Cette README sera remplacée par la version officielle 42 (login italique, sections du chapitre V) lors du rendu final.*
*En attendant : on a un truc qu'on lit avec plaisir.*

**Made with `fork(2)`, `execve(2)`, and an unreasonable amount of `valgrind` runs.**

</div>
