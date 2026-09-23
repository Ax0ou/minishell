*minishell, by aalvard and dbomfim-, 42 Lausanne.*

<div align="center">

```
███╗   ███╗██╗███╗   ██╗██╗███████╗██╗  ██╗███████╗██╗     ██╗
████╗ ████║██║████╗  ██║██║██╔════╝██║  ██║██╔════╝██║     ██║
██╔████╔██║██║██╔██╗ ██║██║███████╗███████║█████╗  ██║     ██║
██║╚██╔╝██║██║██║╚██╗██║██║╚════██║██╔══██║██╔══╝  ██║     ██║
██║ ╚═╝ ██║██║██║ ╚████║██║███████║██║  ██║███████╗███████╗███████╗
╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝
```

### *A tiny bash, written in C, by two students who read the man page so you don't have to.*

![C](https://img.shields.io/badge/Language-C-00599C?style=flat-square&logo=c&logoColor=white)
![42](https://img.shields.io/badge/School-42_Lausanne-000000?style=flat-square&logo=42&logoColor=white)
![Norm](https://img.shields.io/badge/Norminette-0_errors-success?style=flat-square)
![Tests](https://img.shields.io/badge/Tests-399_assertions-success?style=flat-square)
![Leaks](https://img.shields.io/badge/Leaks-0_definitely_lost-success?style=flat-square)

[![CI](https://github.com/Ax0ou/minishell/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Ax0ou/minishell/actions/workflows/ci.yml)

</div>

---

## Description

`minishell` is a POSIX-like command interpreter written from scratch in C, as the
Milestone 3 project of the 42 curriculum. It reads a line, tokenizes it, parses it
into a command pipeline, expands its variables, and executes it, the way `bash` does.

Reference behavior is `bash`. Whenever the subject leaves something unspecified, we
compared our output against `bash --posix` and followed it.

**What it does**

| | |
|---|---|
| Prompt | interactive prompt with line editing and history, via `readline` |
| Quoting | `'single'` literal, `"double"` with expansion, concatenation, nesting |
| Redirections | `<`, `>`, `>>`, and heredoc `<<` with quoted or unquoted delimiter |
| Pipes | arbitrary length pipelines, `cmd1 \| cmd2 \| cmd3` |
| Expansion | `$VAR`, `$?`, empty and undefined variables, quote-aware |
| Built-ins | `echo` (with `-n`), `cd`, `pwd`, `export`, `unset`, `env`, `exit` |
| Signals | `Ctrl-C`, `Ctrl-D`, `Ctrl-\`, including `Ctrl-C` during a heredoc |
| Exit codes | `0`, `1`, `2`, `126`, `127`, and `128 + N` on signal termination |

**Constraints respected**

- 42 Norm: 25 lines per function, 5 functions per file, no `for`, no ternary
- Compiled with `-Wall -Wextra -Werror`
- Exactly one global variable, an `int` holding the received signal number
- No memory leaks in our own code. The subject explicitly exempts `readline`
  (page 9), and the remaining `still reachable` blocks under valgrind all
  originate from `libreadline` and `libtinfo` keymaps allocated once at startup.

---

## Instructions

### Requirements

- `cc`, `make`
- GNU `readline` development headers

On Linux:

```bash
sudo apt install libreadline-dev
```

On macOS, Apple ships `libedit` rather than GNU readline, and its header does not
declare `rl_replace_line`. Install the real one, the Makefile detects it:

```bash
brew install readline
```

### Build and run

```bash
git clone git@github.com:Ax0ou/minishell.git
cd minishell
make
./minishell
```

```
minishell$ echo "hello $USER" | cat
hello alvrd
minishell$ cat << EOF > out.txt
> one
> two
> EOF
minishell$ wc -l < out.txt
2
minishell$ exit
```

Other targets: `make clean`, `make fclean`, `make re`.

### Tests

The suite compares our output against the system `bash` case by case.

```bash
make
for t in tests/unit/test_*.sh tests/integration/test_*.sh; do bash "$t"; done
```

15 suites, 399 assertions. Memory is checked separately with valgrind:

```bash
bash tests/leaks/leaks_basic.sh
```

12 scenarios, failing the run on any `definitely lost` or `indirectly lost` block.
On macOS valgrind is unavailable and the script says so; use `leaks --atExit -- ./minishell`
instead.

> On macOS, `bash` is version 3.2 and diverges from modern bash on a few exit-code
> edge cases. `tests/lib.sh` looks for a `bash >= 4` first, and skips those specific
> comparisons with a message if it cannot find one. `brew install bash` resolves it.

Every push and pull request runs the same suites plus norminette and valgrind on
Ubuntu, through GitHub Actions.

---

## How it works

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
                │          SYNTAX CHECK            │
                │  rejects | at the edges, missing │
                │  redirection targets, unclosed   │
                │  quotes, before anything runs    │
                └──────────────┬───────────────────┘
                               │
                               ▼
                ┌──────────────────────────────────┐
                │            EXPANDER              │
                │  resolves $VAR and $?, then      │
                │  strips quotes. The order is     │
                │  mandatory: stripping first      │
                │  would lose the quoting context  │
                └──────────────┬───────────────────┘
                               │
                               ▼
                ┌──────────────────────────────────┐
                │             PARSER               │
                │  builds a linked list of t_cmd,  │
                │  attaches redirections,          │
                │  pre-reads heredocs              │
                └──────────────┬───────────────────┘
                               │  cmd1(ls -la) → cmd2(grep .c, > out.txt)
                               ▼
                ┌──────────────────────────────────┐
                │            EXECUTOR              │
                │  fork, pipe, dup2, execve, wait  │
                │  a lone builtin runs in the      │
                │  parent so cd and export persist │
                └──────────────┬───────────────────┘
                               │
                               ▼
                          $? updated
                               │
                               ▼
                       back to readline()
```

---

## Repository layout

```
minishell/
├── Makefile
├── includes/minishell.h
├── libft/                   our own C library
├── src/                     47 .c files
│   ├── lexer/        6      tokenizer, quote state machine, operators
│   ├── parser/       9      command list, redirections, heredocs, syntax check
│   ├── expander/     5      $VAR and $? resolution, quote stripping
│   ├── executor/     8      fork, pipes, path resolution, wait
│   ├── redirections/ 1      opening and duplicating file descriptors
│   ├── builtins/     8      echo, cd, pwd, export, unset, env, exit
│   ├── env/          3      environment as a linked list
│   ├── signals/      2      prompt, execution and heredoc handlers
│   └── utils/        4      init, cleanup, errors, string helpers
├── tests/
│   ├── unit/                11 suites, per-module runners
│   ├── integration/         4 suites, full shell against bash
│   └── leaks/               valgrind scenarios
├── docs/                    architecture, parsing rules, edge cases, defense notes
└── .github/workflows/ci.yml build, norminette, tests, valgrind
```

---

## Resources

**Documentation**

- The `bash` manual page, and `bash --posix` itself as the reference implementation
- `man readline`, `man 2 execve`, `man 2 fork`, `man 2 dup2`, `man 2 sigaction`
- [GNU Bash Reference Manual](https://www.gnu.org/software/bash/manual/bash.html)
- [Valgrind FAQ](https://valgrind.org/docs/manual/faq.html), on the meaning of
  `still reachable` versus a real leak

**Community**

- `mcombeau/minishell`, read for its file granularity. Structure studied, code
  written from scratch.
- The 42 community testers (`francinette`, `42_minishell_tester`, `mshell_tester`),
  used to find edge cases, alongside our own suite.

**Use of AI**

We used Claude as an assistant during this project, and we want to be explicit
about how. It was used for code review, for debugging sessions, for hunting memory
and file descriptor leaks, and for building the test and continuous integration
infrastructure. It was also used to explain concepts we had not yet met, such as
process groups and signal delivery.

The architecture, the technical decisions recorded in `docs/ARCHITECTURE.md`, and
the implementation are ours. Every function in this repository was written or
reviewed line by line by one of us, and both of us can explain any file on request.
Where an AI suggestion was adopted, we understood it before committing it. Where we
disagreed with it, we did not.

---

## Authors

| | | |
|:-:|:-:|---|
| <img src="https://github.com/Ax0ou.png" width="80" /> | **Axel Alvarade** <br> `aalvard` ([`@Ax0ou`](https://github.com/Ax0ou)) | Lexer, parser, expander, quoting, test and CI infrastructure |
| <img src="https://github.com/DaVy0903.png" width="80" /> | **Davi Bomfim** <br> `dbomfim-` ([`@DaVy0903`](https://github.com/DaVy0903)) | Executor, pipes, redirections, heredocs, signals, environment |

---

<div align="center">

**Made with `fork(2)`, `execve(2)`, and an unreasonable number of `valgrind` runs.**

</div>
