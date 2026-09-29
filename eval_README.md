*This project has been created as part of the 42 curriculum by aalvard, dbomfim-.*

## Description

**minishell** is a simplified reimplementation of a Unix shell, written from scratch in C as part of the 42 curriculum. It reproduces the core interactive behavior of `bash`: reading a command line, expanding variables, resolving executables, connecting pipelines, applying redirections, and running built-in commands — all while managing processes, file descriptors, and signals correctly.

The project is deliberately scoped to what the subject requires rather than to full `bash` compatibility. Where a behavior isn't explicitly asked for (backslash escaping, `${VAR}` brace expansion, `~` tilde expansion, positional/special parameters beyond `$?`, `<<-`, `&&`/`||` outside the bonus, background jobs), it is intentionally left out. Where a requirement is ambiguous, `bash` itself was used as the reference, as the subject instructs.

The shell is built as a strict pipeline: a **lexer** turns the raw input line into tokens (aware of quoting, unaware of meaning), an **expander** resolves `$VAR`/`$?` and strips delimiting quotes (in that order — quotes carry the information that decides whether a `$` should expand), a **parser** turns tokens into a linked list of commands and their redirections, and an **executor** forks, pipes, and `execve`s accordingly. Signal handling is centered on the single global variable the subject mandates (`g_signal`, a plain `int` holding only the last received signal number), with different `sigaction` configurations swapped in depending on whether the shell is at the prompt, running a foreground command, or reading a heredoc.

## Instructions

### Compilation

```sh
make
```

Compiles the bundled `libft` first (via its own Makefile), then the shell itself, with `-Wall -Wextra -Werror`. Other standard rules are available: `make clean`, `make fclean`, `make re`.

### Requirements

- A C compiler (`cc`)
- GNU `readline` development headers (on Debian/Ubuntu: `libreadline-dev`; on macOS via Homebrew: `brew install readline` — the Makefile adds the Homebrew include/lib paths automatically on Darwin, since macOS ships `libedit` instead, which doesn't declare `rl_replace_line`)

### Running

```sh
./minishell
```

Launches an interactive prompt (`minishell$ `). Standard readline editing and history (arrow keys) work as expected. Exit with `exit`, `exit <code>`, or Ctrl-D at an empty prompt.

## Resources

- [GNU Readline Library manual](https://tiszka.gitbooks.io/gnu-readline-library/content/) — `readline`, `add_history`, and the signal-related entry points (`rl_on_new_line`, `rl_replace_line`, `rl_redisplay`) used at the prompt.
- [POSIX.1-2017, Shell & Utilities volume](https://pubs.opengroup.org/onlinepubs/9699919799/) — the reference grammar for quoting, redirections, and parameter expansion the subject's requirements are drawn from.
- `man 2` pages for `fork`, `execve`, `pipe`, `dup2`, `waitpid`, `sigaction`, `stat` — the syscalls the executor and signal handling are built on.
- The `bash(1)` manual and `bash` itself, used throughout as the behavioral reference whenever the subject left a case ambiguous, per its own instruction to do so.

AI was used as a tool to deepen the understanding of code written by a teammate, ask about how some external functions work and answer general questions.
