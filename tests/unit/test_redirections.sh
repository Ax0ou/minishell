#!/bin/bash
# tests/unit/test_redirections.sh
# Issue #25 — Tests unitaires apply_redirs (src/redirections/redir_files.c)
# Cf docs/PARSING_RULES.md §6 pour les regles de redirections multiples,
# docs/EDGE_CASES.md §8.1/§8.3 pour les messages/codes attendus (erreur de
# redirection = code 1, message = strerror direct : "No such file or
# directory", "Permission denied", etc.)

set -e
cd "$(dirname "$0")/../.."
SKIP_BIN_CHECK=1
source tests/lib.sh

echo "═══ Tests unitaires apply_redirs — Issue #25 ═══"

REDIR_FIXTURE_DIR=$(mktemp -d /tmp/minishell_redir_fixture.XXXXXX)
REDIR_TEST_BIN="/tmp/minishell_redir_files_test"
REDIR_VALGRIND_LOG="/tmp/minishell_redir_files_valgrind.log"
REDIR_STDERR_LOG="/tmp/minishell_redir_files_stderr.log"
trap 'rm -rf "$REDIR_FIXTURE_DIR"; rm -f "$REDIR_TEST_BIN" "$REDIR_VALGRIND_LOG" "$REDIR_STDERR_LOG"' EXIT

make --no-print-directory -C libft >/dev/null
cc -Wall -Wextra -Werror \
	tests/unit/redir_files_runner.c \
	src/redirections/redir_files.c \
	src/utils/ut_error.c \
	libft/libft.a \
	-o "$REDIR_TEST_BIN"

expected="simple > (create + write) -> exit=[0]
  content of out_a -> [hello-out]
simple >> (append to existing content) -> exit=[0]
  content of out_append -> [existing-appended]
multiple > (only the last is connected) -> exit=[0]
  content of out_a (truncated, never written to) -> []
  content of out_append (holds the write) -> [last]
  read content -> [input-data]
simple < (read from file) -> exit=[0]
< then < on missing file (bail, nothing runs) -> exit=[1]"

actual=$("$REDIR_TEST_BIN" "$REDIR_FIXTURE_DIR" 2>"$REDIR_STDERR_LOG")

assert_eq "> cree et tronque le fichier" "$(echo "$expected" | sed -n '1,2p')" "$(echo "$actual" | sed -n '1,2p')"
assert_eq ">> preserve le contenu existant" "$(echo "$expected" | sed -n '3,4p')" "$(echo "$actual" | sed -n '3,4p')"
assert_eq "> multiples : tous ouverts, seul le dernier connecte a stdout" "$(echo "$expected" | sed -n '5,7p')" "$(echo "$actual" | sed -n '5,7p')"
assert_eq "< lit bien le contenu du fichier" "$(echo "$expected" | sed -n '8,9p')" "$(echo "$actual" | sed -n '8,9p')"
assert_eq "< sur fichier manquant au milieu de la chaine -> rien ne s'execute" "$(echo "$expected" | sed -n '10p')" "$(echo "$actual" | sed -n '10p')"
assert_eq "apply_redirs — sortie complète" "$expected" "$actual"
assert_eq "message d'erreur bash-fidèle via strerror" \
	"minishell: $REDIR_FIXTURE_DIR/in_missing: No such file or directory" \
	"$(cat "$REDIR_STDERR_LOG")"

if [ "$RUN_VALGRIND" = "1" ]; then
	if ! command -v valgrind >/dev/null 2>&1; then
		printf "  ${C_RED}✗${C_RESET} valgrind disponible\n"
		printf "    valgrind introuvable dans le PATH\n"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("valgrind disponible")
	elif valgrind --leak-check=full --show-leak-kinds=all \
		--errors-for-leak-kinds=all --error-exitcode=42 \
		"$REDIR_TEST_BIN" "$REDIR_FIXTURE_DIR" >"$REDIR_VALGRIND_LOG" 2>&1; then
		printf "  ${C_GREEN}✓${C_RESET} apply_redirs sans leak Valgrind\n"
		PASS=$((PASS+1))
	else
		printf "  ${C_RED}✗${C_RESET} apply_redirs sans leak Valgrind\n"
		sed 's/^/    /' "$REDIR_VALGRIND_LOG"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("apply_redirs sans leak Valgrind")
	fi
fi

summary
