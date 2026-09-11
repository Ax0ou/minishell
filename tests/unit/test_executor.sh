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

summary
