#!/bin/bash
# tests/unit/test_heredoc.sh
# Issue #37 — Tests unitaires heredoc (collect_heredocs / parse_heredoc*.c)
# Cf docs/PARSING_RULES.md §7 et docs/EDGE_CASES.md §3 pour les regles
# attendues (delimiteur exact, quotes retirees pour la comparaison,
# warning bash-like sur EOF sans delimiteur, plusieurs heredocs = seul
# le dernier compte, unlink du tmpfile apres usage).

set -e
cd "$(dirname "$0")/../.."
SKIP_BIN_CHECK=1
source tests/lib.sh

echo "═══ Tests unitaires heredoc — Issue #37 ═══"

HD_TEST_BIN="/tmp/minishell_heredoc_test"
HD_STDERR_LOG="/tmp/minishell_heredoc_test_stderr.log"
HD_VALGRIND_LOG="/tmp/minishell_heredoc_test_valgrind.log"
trap 'rm -f "$HD_TEST_BIN" "$HD_STDERR_LOG" "$HD_VALGRIND_LOG"' EXIT

cc -Wall -Wextra -Werror \
	tests/unit/heredoc_runner.c \
	src/parser/parse_heredoc.c \
	src/parser/parse_heredoc_utils.c \
	src/parser/cmd_list_utils.c \
	src/parser/cmd_list_free.c \
	src/env/env_init.c \
	src/utils/ut_cleanup.c \
	src/utils/ut_error.c \
	src/lexer/lex_token_list_free.c \
	libft/libft.a \
	-o "$HD_TEST_BIN"

HD_STDIN='hello
world
EOF
quoted content
EOF
abc

partial'

expected='> > > simple heredoc (delim=EOF) -> ret=[1]
  content -> [hello
world
]
  after cleanup, file exists -> [0]
> > quoted delimiter (raw = "EOF") -> ret=[1]
  content -> [quoted content
]
  after cleanup, file exists -> [0]
> > empty delimiter (stops at blank line) -> ret=[1]
  content -> [abc
]
  after cleanup, file exists -> [0]
> > unterminated (EOF hit before delimiter) -> ret=[1]
  content -> [partial
]
  after cleanup, file exists -> [0]'

actual=$(printf '%s' "$HD_STDIN" | "$HD_TEST_BIN" 2>"$HD_STDERR_LOG")

assert_eq "heredoc simple : lit jusqu'au delimiteur exact" \
	"$(echo "$expected" | sed -n '1,5p')" "$(echo "$actual" | sed -n '1,5p')"
assert_eq "delimiteur quote : quotes retirees pour la comparaison" \
	"$(echo "$expected" | sed -n '6,9p')" "$(echo "$actual" | sed -n '6,9p')"
assert_eq "delimiteur vide : s'arrete a la premiere ligne vide" \
	"$(echo "$expected" | sed -n '10,13p')" "$(echo "$actual" | sed -n '10,13p')"
assert_eq "EOF sans delimiteur : execute quand meme avec le contenu lu" \
	"$(echo "$expected" | sed -n '14,17p')" "$(echo "$actual" | sed -n '14,17p')"
assert_eq "heredoc — sortie complète" "$expected" "$actual"
assert_eq "tmpfile toujours unlink apres usage (4 cas)" \
	"0
0
0
0" "$(echo "$actual" | sed -n 's/.*file exists -> \[\(.\)\]/\1/p')"
assert_eq "warning bash-like sur EOF sans delimiteur" \
	"minishell: warning: here-document delimited by end-of-file (wanted 'NEVER')" \
	"$(cat "$HD_STDERR_LOG")"

if [ "$RUN_VALGRIND" = "1" ]; then
	if ! command -v valgrind >/dev/null 2>&1; then
		printf "  ${C_RED}✗${C_RESET} valgrind disponible\n"
		printf "    valgrind introuvable dans le PATH\n"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("valgrind disponible")
	elif printf '%s' "$HD_STDIN" | valgrind --leak-check=full --show-leak-kinds=all \
		--errors-for-leak-kinds=all --error-exitcode=42 \
		"$HD_TEST_BIN" >"$HD_VALGRIND_LOG" 2>&1; then
		printf "  ${C_GREEN}✓${C_RESET} heredoc sans leak Valgrind\n"
		PASS=$((PASS+1))
	else
		printf "  ${C_RED}✗${C_RESET} heredoc sans leak Valgrind\n"
		sed 's/^/    /' "$HD_VALGRIND_LOG"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("heredoc sans leak Valgrind")
	fi
fi

summary
