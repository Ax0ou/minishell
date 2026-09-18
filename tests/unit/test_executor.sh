#!/bin/bash
# tests/unit/test_executor.sh
# Issue #23 — Tests unitaires resolve_path (src/executor/exec_path.c)
# Cf docs/PARSING_RULES.md §9 pour l'algorithme, docs/EDGE_CASES.md §8.3
# pour les codes/messages attendus (command not found = 127, is a
# directory / permission denied = 126).

set -e
cd "$(dirname "$0")/../.."
SKIP_BIN_CHECK=1
source tests/lib.sh

echo "═══ Tests unitaires resolve_path — Issue #23 ═══"

FIXTURE_DIR=$(mktemp -d /tmp/minishell_exec_path_fixture.XXXXXX)
PATH_TEST_BIN="/tmp/minishell_exec_path_test"
PATH_VALGRIND_LOG="/tmp/minishell_exec_path_valgrind.log"
trap 'rm -rf "$FIXTURE_DIR"; rm -f "$PATH_TEST_BIN" "$PATH_VALGRIND_LOG"' EXIT

mkdir -p "$FIXTURE_DIR/binA/asdir" "$FIXTURE_DIR/binB"
printf '#!/bin/sh\n' > "$FIXTURE_DIR/binA/runme"
chmod +x "$FIXTURE_DIR/binA/runme"
printf 'no exec bit here\n' > "$FIXTURE_DIR/binB/noperm"
chmod -x "$FIXTURE_DIR/binB/noperm"

make --no-print-directory -C libft >/dev/null
cc -Wall -Wextra -Werror \
	tests/unit/exec_path_runner.c \
	src/executor/exec_path.c \
	src/executor/exec_path_utils.c \
	src/env/env_init.c \
	src/env/env_access.c \
	src/utils/ut_cleanup.c \
	src/parser/cmd_list_free.c \
	src/lexer/lex_token_list_free.c \
	libft/libft.a \
	-o "$PATH_TEST_BIN"

expected="PATH search: found + executable -> status=[OK] path=[$FIXTURE_DIR/binA/runme]
PATH search: found but is a directory -> status=[ISDIR] path=[(null)]
PATH search: found but not executable -> status=[NOPERM] path=[(null)]
PATH search: not found anywhere -> status=[CNF] path=[(null)]
direct path: found + executable -> status=[OK] path=[$FIXTURE_DIR/binA/runme]
direct path: does not exist -> status=[ENOENT] path=[(null)]
direct path: is a directory -> status=[ISDIR] path=[(null)]
direct path: not executable -> status=[NOPERM] path=[(null)]
PATH unset -> status=[CNF] path=[(null)]
PATH empty -> status=[CNF] path=[(null)]"

actual=$("$PATH_TEST_BIN" "$FIXTURE_DIR")

assert_eq "PATH search trouve + executable -> OK" "$(echo "$expected" | sed -n '1p')" "$(echo "$actual" | sed -n '1p')"
assert_eq "PATH search trouve un dossier -> ISDIR (126)" "$(echo "$expected" | sed -n '2p')" "$(echo "$actual" | sed -n '2p')"
assert_eq "PATH search trouve sans +x -> NOPERM (126)" "$(echo "$expected" | sed -n '3p')" "$(echo "$actual" | sed -n '3p')"
assert_eq "PATH search rien trouvé -> CNF (127, command not found)" "$(echo "$expected" | sed -n '4p')" "$(echo "$actual" | sed -n '4p')"
assert_eq "chemin direct existant + executable -> OK" "$(echo "$expected" | sed -n '5p')" "$(echo "$actual" | sed -n '5p')"
assert_eq "chemin direct inexistant -> ENOENT (127, No such file or directory)" "$(echo "$expected" | sed -n '6p')" "$(echo "$actual" | sed -n '6p')"
assert_eq "chemin direct est un dossier -> ISDIR (126)" "$(echo "$expected" | sed -n '7p')" "$(echo "$actual" | sed -n '7p')"
assert_eq "chemin direct sans +x -> NOPERM (126)" "$(echo "$expected" | sed -n '8p')" "$(echo "$actual" | sed -n '8p')"
assert_eq "PATH non défini -> CNF pour un nom sans /" "$(echo "$expected" | sed -n '9p')" "$(echo "$actual" | sed -n '9p')"
assert_eq "PATH=\"\" -> CNF pour un nom sans /" "$(echo "$expected" | sed -n '10p')" "$(echo "$actual" | sed -n '10p')"
assert_eq "resolve_path — sortie complète" "$expected" "$actual"

if [ "$RUN_VALGRIND" = "1" ]; then
	if ! command -v valgrind >/dev/null 2>&1; then
		printf "  ${C_RED}✗${C_RESET} valgrind disponible\n"
		printf "    valgrind introuvable dans le PATH\n"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("valgrind disponible")
	elif valgrind --leak-check=full --show-leak-kinds=all \
		--errors-for-leak-kinds=all --error-exitcode=42 \
		"$PATH_TEST_BIN" "$FIXTURE_DIR" >"$PATH_VALGRIND_LOG" 2>&1; then
		printf "  ${C_GREEN}✓${C_RESET} resolve_path sans leak Valgrind\n"
		PASS=$((PASS+1))
	else
		printf "  ${C_RED}✗${C_RESET} resolve_path sans leak Valgrind\n"
		sed 's/^/    /' "$PATH_VALGRIND_LOG"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("resolve_path sans leak Valgrind")
	fi
fi

echo "═══ Tests unitaires exec_single — Issue #24 ═══"

SINGLE_FIXTURE_DIR=$(mktemp -d /tmp/minishell_exec_single_fixture.XXXXXX)
SINGLE_TEST_BIN="/tmp/minishell_exec_single_test"
SINGLE_VALGRIND_LOG="/tmp/minishell_exec_single_valgrind.log"
SINGLE_STDERR_LOG="/tmp/minishell_exec_single_stderr.log"
trap 'rm -rf "$FIXTURE_DIR" "$SINGLE_FIXTURE_DIR"; rm -f "$PATH_TEST_BIN" "$PATH_VALGRIND_LOG" "$SINGLE_TEST_BIN" "$SINGLE_VALGRIND_LOG" "$SINGLE_STDERR_LOG"' EXIT

printf '#!/bin/sh\nexit 7\n' > "$SINGLE_FIXTURE_DIR/exit7"
chmod +x "$SINGLE_FIXTURE_DIR/exit7"
printf '#!/bin/sh\nkill -TERM $$\n' > "$SINGLE_FIXTURE_DIR/killself"
chmod +x "$SINGLE_FIXTURE_DIR/killself"
printf 'no exec bit here\n' > "$SINGLE_FIXTURE_DIR/noperm"
chmod -x "$SINGLE_FIXTURE_DIR/noperm"

cc -Wall -Wextra -Werror \
	tests/unit/exec_single_runner.c \
	src/executor/exec_single.c \
	src/executor/exec_child.c \
	src/redirections/redir_files.c \
	src/executor/exec_wait.c \
	src/executor/exec_path.c \
	src/executor/exec_path_utils.c \
	src/env/env_init.c \
	src/env/env_access.c \
	src/env/env_to_array.c \
	src/parser/cmd_list_utils.c \
	src/parser/cmd_list_free.c \
	src/utils/ut_cleanup.c \
	src/utils/ut_error.c \
	src/lexer/lex_token_list_free.c \
	libft/libft.a \
	-o "$SINGLE_TEST_BIN"

expected="execute + normal exit code -> last_exit=[7]
killed by signal (SIGTERM) -> last_exit=[143]
found but not executable -> last_exit=[126]
not found anywhere -> last_exit=[127]"

actual=$("$SINGLE_TEST_BIN" "$SINGLE_FIXTURE_DIR" 2>"$SINGLE_STDERR_LOG")

assert_eq "execve reussit, exit code recupere via WEXITSTATUS" "$(echo "$expected" | sed -n '1p')" "$(echo "$actual" | sed -n '1p')"
assert_eq "enfant tue par signal -> 128 + WTERMSIG (143)" "$(echo "$expected" | sed -n '2p')" "$(echo "$actual" | sed -n '2p')"
assert_eq "resolve echoue (NOPERM) -> pas de fork, 126" "$(echo "$expected" | sed -n '3p')" "$(echo "$actual" | sed -n '3p')"
assert_eq "resolve echoue (CNF) -> pas de fork, 127" "$(echo "$expected" | sed -n '4p')" "$(echo "$actual" | sed -n '4p')"
assert_eq "exec_single — sortie complète" "$expected" "$actual"
assert_eq "message d'erreur: Permission denied" "minishell: noperm: Permission denied" "$(sed -n '1p' "$SINGLE_STDERR_LOG")"
assert_eq "message d'erreur: command not found" "minishell: ghost_cmd_xyz: command not found" "$(sed -n '2p' "$SINGLE_STDERR_LOG")"

if [ "$RUN_VALGRIND" = "1" ]; then
	if ! command -v valgrind >/dev/null 2>&1; then
		printf "  ${C_RED}✗${C_RESET} valgrind disponible\n"
		printf "    valgrind introuvable dans le PATH\n"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("valgrind disponible")
	elif valgrind --leak-check=full --show-leak-kinds=all \
		--errors-for-leak-kinds=all --error-exitcode=42 \
		"$SINGLE_TEST_BIN" "$SINGLE_FIXTURE_DIR" >"$SINGLE_VALGRIND_LOG" 2>&1; then
		printf "  ${C_GREEN}✓${C_RESET} exec_single sans leak Valgrind\n"
		PASS=$((PASS+1))
	else
		printf "  ${C_RED}✗${C_RESET} exec_single sans leak Valgrind\n"
		sed 's/^/    /' "$SINGLE_VALGRIND_LOG"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("exec_single sans leak Valgrind")
	fi
fi

echo "═══ Tests unitaires exec_pipeline — Issue #36 ═══"

PIPE_TEST_BIN="/tmp/minishell_exec_pipeline_test"
PIPE_VALGRIND_LOG="/tmp/minishell_exec_pipeline_valgrind.log"
PIPE_STDERR_LOG="/tmp/minishell_exec_pipeline_stderr.log"
trap 'rm -rf "$FIXTURE_DIR" "$SINGLE_FIXTURE_DIR"; rm -f "$PATH_TEST_BIN" "$PATH_VALGRIND_LOG" "$SINGLE_TEST_BIN" "$SINGLE_VALGRIND_LOG" "$SINGLE_STDERR_LOG" "$PIPE_TEST_BIN" "$PIPE_VALGRIND_LOG" "$PIPE_STDERR_LOG"' EXIT

cc -Wall -Wextra -Werror \
	tests/unit/exec_pipeline_runner.c \
	src/executor/exec_pipeline.c \
	src/executor/exec_pipeline_utils.c \
	src/executor/exec_run.c \
	src/executor/exec_single.c \
	src/executor/exec_child.c \
	src/executor/exec_wait.c \
	src/executor/exec_path.c \
	src/executor/exec_path_utils.c \
	src/redirections/redir_files.c \
	src/env/env_init.c \
	src/env/env_access.c \
	src/env/env_to_array.c \
	src/builtins/bi_env.c \
	src/builtins/bi_cd.c \
	src/builtins/bi_pwd.c \
	src/builtins/bi_echo.c \
	src/builtins/bi_exit.c \
	src/parser/cmd_list_utils.c \
	src/parser/cmd_list_free.c \
	src/utils/ut_cleanup.c \
	src/utils/ut_error.c \
	src/utils/ut_str.c \
	src/lexer/lex_token_list_free.c \
	libft/libft.a \
	-o "$PIPE_TEST_BIN"

expected="hello
2-stage passthrough -> last_exit=[0]
hello world
3-stage passthrough -> last_exit=[0]
exit code = LAST stage (cat=0), not first (5) -> last_exit=[0]
exit code = LAST stage (7) -> last_exit=[7]
broken middle stage: pipeline still completes -> last_exit=[0]
done
cd inside a pipe: forked, no real effect -> last_exit=[0]
cwd unchanged -> [1]"

actual=$("$PIPE_TEST_BIN" 2>"$PIPE_STDERR_LOG")

assert_eq "pipeline 2 etages : passthrough" "$(echo "$expected" | sed -n '1,2p')" "$(echo "$actual" | sed -n '1,2p')"
assert_eq "pipeline 3 etages : passthrough" "$(echo "$expected" | sed -n '3,4p')" "$(echo "$actual" | sed -n '3,4p')"
assert_eq "code retour = dernier maillon (pas le premier)" "$(echo "$expected" | sed -n '5p')" "$(echo "$actual" | sed -n '5p')"
assert_eq "code retour = dernier maillon (7)" "$(echo "$expected" | sed -n '6p')" "$(echo "$actual" | sed -n '6p')"
assert_eq "un maillon casse n'empeche pas le reste du pipeline" "$(echo "$expected" | sed -n '7p')" "$(echo "$actual" | sed -n '7p')"
assert_eq "cd dans un pipe : tourne dans un fork" "$(echo "$expected" | sed -n '8,9p')" "$(echo "$actual" | sed -n '8,9p')"
assert_eq "cd dans un pipe : cwd du parent inchange" "$(echo "$expected" | sed -n '10p')" "$(echo "$actual" | sed -n '10p')"
assert_eq "exec_pipeline — sortie complète" "$expected" "$actual"
assert_eq "message d'erreur du maillon casse" \
	"minishell: nonexistent_cmd_xyz: command not found" \
	"$(cat "$PIPE_STDERR_LOG")"

if [ "$RUN_VALGRIND" = "1" ]; then
	if ! command -v valgrind >/dev/null 2>&1; then
		printf "  ${C_RED}✗${C_RESET} valgrind disponible\n"
		printf "    valgrind introuvable dans le PATH\n"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("valgrind disponible")
	elif valgrind --leak-check=full --show-leak-kinds=all \
		--errors-for-leak-kinds=all --error-exitcode=42 \
		"$PIPE_TEST_BIN" >"$PIPE_VALGRIND_LOG" 2>&1; then
		printf "  ${C_GREEN}✓${C_RESET} exec_pipeline sans leak Valgrind\n"
		PASS=$((PASS+1))
	else
		printf "  ${C_RED}✗${C_RESET} exec_pipeline sans leak Valgrind\n"
		sed 's/^/    /' "$PIPE_VALGRIND_LOG"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("exec_pipeline sans leak Valgrind")
	fi
fi

summary
