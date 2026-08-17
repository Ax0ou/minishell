#!/bin/bash
# tests/unit/test_utils.sh
# Issue #16 — Tests unitaires utils (print_error)
# Cf docs/EDGE_CASES.md §8.1 pour le format attendu.

set -e
cd "$(dirname "$0")/../.."
SKIP_BIN_CHECK=1
source tests/lib.sh

echo "═══ Tests unitaires print_error — Issue #16 ═══"

ERROR_TEST_BIN="/tmp/minishell_ut_error_test"
ERROR_STDERR_LOG="/tmp/minishell_ut_error_stderr.log"
ERROR_VALGRIND_LOG="/tmp/minishell_ut_error_valgrind.log"
trap 'rm -f "$ERROR_TEST_BIN" "$ERROR_STDERR_LOG" "$ERROR_VALGRIND_LOG"' EXIT

make --no-print-directory -C libft >/dev/null
cc -Wall -Wextra -Werror \
	tests/unit/ut_error_runner.c \
	src/utils/ut_error.c \
	libft/libft.a \
	-o "$ERROR_TEST_BIN"

expected_out='ret=[1]
ret=[1]
ret=[1]'

expected_err="minishell: cd: /nonexistent: No such file or directory
minishell: nope_cmd: command not found
minishell: syntax error near unexpected token \`|'"

actual_out=$("$ERROR_TEST_BIN" 2>"$ERROR_STDERR_LOG")
actual_err=$(cat "$ERROR_STDERR_LOG")

assert_eq "print_error retourne 1 dans tous les cas" "$expected_out" "$actual_out"
assert_eq "print_error: cmd + arg + msg" "minishell: cd: /nonexistent: No such file or directory" "$(sed -n '1p' "$ERROR_STDERR_LOG")"
assert_eq "print_error: cmd + msg (arg absent)" "minishell: nope_cmd: command not found" "$(sed -n '2p' "$ERROR_STDERR_LOG")"
assert_eq "print_error: msg seul (cmd + arg absents)" "minishell: syntax error near unexpected token \`|'" "$(sed -n '3p' "$ERROR_STDERR_LOG")"
assert_eq "print_error — stderr complet" "$expected_err" "$actual_err"

if [ "$RUN_VALGRIND" = "1" ]; then
	if ! command -v valgrind >/dev/null 2>&1; then
		printf "  ${C_RED}✗${C_RESET} valgrind disponible\n"
		printf "    valgrind introuvable dans le PATH\n"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("valgrind disponible")
	elif valgrind --leak-check=full --show-leak-kinds=all \
		--errors-for-leak-kinds=all --error-exitcode=42 \
		"$ERROR_TEST_BIN" >"$ERROR_VALGRIND_LOG" 2>&1; then
		printf "  ${C_GREEN}✓${C_RESET} print_error sans leak Valgrind\n"
		PASS=$((PASS+1))
	else
		printf "  ${C_RED}✗${C_RESET} print_error sans leak Valgrind\n"
		sed 's/^/    /' "$ERROR_VALGRIND_LOG"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("print_error sans leak Valgrind")
	fi
fi

summary
