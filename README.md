*This project has been created as part of the 42 curriculum by aalvard, dbomfim-.*

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
![Tests](https://img.shields.io/badge/Tests-414_assertions-success?style=flat-square)
![Leaks](https://img.shields.io/badge/Leaks-0_definitely_lost-success?style=flat-square)

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

16 suites, 414 assertions. Memory is checked separately with valgrind:

```bash
bash tests/leaks/leaks_basic.sh
```

12 scenarios, failing the run on any `definitely lost` or `indirectly lost` block.
On macOS valgrind is unavailable and the script says so; use `leaks --atExit -- ./minishell`
instead.

> On macOS, `bash` is version 3.2 and diverges from modern bash on a few exit-code
> edge cases. `tests/lib.sh` looks for a `bash >= 4` first, and skips those specific
> comparisons with a message if it cannot find one. `brew install bash` resolves it.

---

## Architecture

### The path of a single line

```
                           ┌──────────────┐
   user types a line  ──▶  │  readline()  │  ◀── history, arrow keys, Ctrl-C
                           └──────┬───────┘
                                  │  echo "$USER" | wc -c > out
                                  ▼
                ┌──────────────────────────────────┐
                │        syntax_check_line         │
                │  unterminated quote ? $? = 2     │
                └──────────────┬───────────────────┘
                               ▼
                ┌──────────────────────────────────┐
                │              LEXER               │
                │  three-state automaton. Quotes   │
                │  are KEPT inside the token.      │
                └──────────────┬───────────────────┘
                   [WORD echo] [WORD "$USER"] [PIPE] [WORD wc] ...
                               ▼
                ┌──────────────────────────────────┐
                │       syntax_check_tokens        │
                │  pipe at an edge, redirection    │
                │  without a target ? $? = 2       │
                └──────────────┬───────────────────┘
                               ▼
                ┌──────────────────────────────────┐
                │             EXPANDER             │
                │  1. expand $VAR and $?           │
                │  2. THEN strip the quotes        │
                │  the order is mandatory          │
                └──────────────┬───────────────────┘
                               ▼
                ┌──────────────────────────────────┐
                │              PARSER              │
                │  linked list of t_cmd, each with │
                │  its argv and its redirections   │
                └──────────────┬───────────────────┘
                     cmd1(echo alvrd) -> cmd2(wc -c, > out)
                               ▼
                ┌──────────────────────────────────┐
                │         collect_heredocs         │
                │  every << is read BEFORE any     │
                │  command starts                  │
                └──────────────┬───────────────────┘
                               ▼
                ┌──────────────────────────────────┐
                │             EXECUTOR             │
                │  fork, pipe, dup2, execve, wait  │
                │  a lone builtin stays in the     │
                │  parent process                  │
                └──────────────┬───────────────────┘
                               ▼
                        shell->last_exit
                               ▼
              tokens, command list and line are freed
                               ▼
                        back to readline()
```

### Modules

| Directory | Files | Responsibility |
|---|---:|---|
| `src/lexer/` | 6 | Splits the line into tokens. Three-state quote automaton, operator detection, token list. Knows nothing about variables or structure. |
| `src/parser/` | 9 | Turns tokens into a linked list of `t_cmd`, attaches redirections, validates syntax, and reads heredocs into temporary files. |
| `src/expander/` | 5 | Resolves `$VAR` and `$?`, then strips the delimiting quotes. Replays the quote automaton to know where expansion is allowed. |
| `src/executor/` | 8 | Resolves the command path, forks, creates the pipes, duplicates the descriptors, waits, and translates the exit status. |
| `src/redirections/` | 1 | Opens each target with the right flags and duplicates it onto the right descriptor. |
| `src/builtins/` | 8 | `echo`, `cd`, `pwd`, `export`, `unset`, `env`, `exit`. |
| `src/env/` | 3 | The environment as a linked list, and the array rebuilt for `execve`. |
| `src/signals/` | 2 | Three handler sets: at the prompt, during execution, inside a heredoc. |
| `src/utils/` | 4 | REPL chaining, global cleanup, error reporting, string helpers. |

### Technical decisions

**Quotes survive until the expander.** The lexer keeps them inside the token
instead of removing them. They carry the information that decides whether a `$`
must be expanded, and that information is gone once they are stripped.

**Expansion happens before quote removal.** `exp_run` is three lines long so that
this order is visible at a glance. The reverse makes `echo '$USER'` print the value
instead of the literal text.

**The whole pipeline is forked before the first wait.** A pipe holds a finite
amount of data, around 64 KiB. Waiting on the first child before creating the
second one deadlocks as soon as that child writes more than the pipe can hold,
because nothing is reading at the other end yet.

**A lone builtin runs in the parent.** `cd`, `export` and `unset` must outlive the
command. Inside a pipeline they run in a child, which is what bash does too, so
`cd /tmp | echo hi` changes nothing.

**One global variable, and it is an `int`.** A signal handler receives only a
number and returns nothing, so it can only reach the rest of the program through a
global. Everything else lives in `t_shell`, passed by parameter.

**The heredoc handler is installed without `SA_RESTART`.** That is what makes the
blocking `read` return `EINTR` on Ctrl-C, which is what allows the heredoc to be
cancelled at all.

**Exit statuses are read with the macros, never raw.** `waitpid` returns an integer
where the code, the signal and the core flag occupy different bits. `WIFEXITED` and
`WIFSIGNALED` decide, and a signal death becomes `128 + WTERMSIG`.

---

## Repository layout

```
minishell/
├── Makefile
├── README.md
├── includes/minishell.h     structures and prototypes, one @brief per function
├── libft/                   our own C library
├── src/                     47 .c files
│   ├── lexer/        6      tokenizer, quote automaton, operators
│   ├── parser/       9      command list, redirections, heredocs, syntax check
│   ├── expander/     5      $VAR and $? resolution, quote stripping
│   ├── executor/     8      fork, pipes, path resolution, wait
│   ├── redirections/ 1      opening and duplicating file descriptors
│   ├── builtins/     8      echo, cd, pwd, export, unset, env, exit
│   ├── env/          3      environment as a linked list
│   ├── signals/      2      prompt, execution and heredoc handlers
│   └── utils/        4      init, cleanup, errors, string helpers
└── tests/
    ├── unit/                12 suites, per-module runners
    ├── integration/         4 suites, full shell against bash
    └── leaks/               valgrind scenarios
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

We used Claude throughout this project. The subject asks for which tasks and on
which parts, so here it is.

*Understanding and explaining concepts.* This was the main use, and by a wide
margin. Signal delivery and why the heredoc handler must not carry `SA_RESTART`.
Why `waitpid` returns an encoded status rather than an exit code. Why a pipe has a
finite capacity and what that implies for the order of `fork` and `wait`. Why
quoting information has to survive until expansion. Every technical decision listed
above was argued through before being written down.

*Review, debugging and testing.* Code review, debugging sessions, and hunting
memory and file descriptor leaks. An adversarial campaign compared our shell
against `bash 5.2` on roughly 900 cases and surfaced three real defects, which we
then fixed: a stack buffer overflow in the lexer that segfaulted on any word of
4096 characters or more, a quadratic `ft_strjoin` loop in the expander, and a
`PATH` lookup that stopped at the first non-executable candidate instead of
continuing like bash.

*Code produced with AI assistance.* Parts of the test suites under `tests/`, parts
of `src/expander/`, the three fixes above, and the per-function documentation in
`includes/minishell.h`. Nothing was committed before one of us had read it, run it
and understood why it works.

*What is ours.* The architecture and the technical decisions described in this
README, and the implementation of the lexer, the parser, the executor, the
pipeline, the redirections, the heredocs, the signals, the environment and the
builtins. We reviewed each other's halves before submitting, and we can each
explain any file in this repository, including the parts we did not type ourselves.

---

## Authors

| | | |
|:-:|:-:|---|
| <img src="https://github.com/Ax0ou.png" width="80" /> | **Axel Alvarade** <br> `aalvard` ([`@Ax0ou`](https://github.com/Ax0ou)) | Lexer, parser, expander, quoting, test infrastructure |
| <img src="https://github.com/DaVy0903.png" width="80" /> | **Davi Marcelo Bomfim Mota** <br> `dbomfim-` ([`@DaVy0903`](https://github.com/DaVy0903)) | Executor, pipes, redirections, heredocs, signals, environment |

---

<div align="center">

**Made with `fork(2)`, `execve(2)`, and an unreasonable number of `valgrind` runs.**

</div>
