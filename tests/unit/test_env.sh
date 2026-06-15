#!/bin/bash
# tests/unit/test_env.sh
# Issue #18 — Tests unitaires env
# Cf docs/TESTS.md §4.2 pour la liste complète des cas attendus.
#
# À REMPLIR AU FUR ET À MESURE :
# 1. Ouvrir docs/TESTS.md §4.2
# 2. Copier les blocs de tests pertinents ici
# 3. Adapter aux fonctions / mode debug réels du minishell
# 4. Vérifier que le test passe avant de PR

set -e
cd "$(dirname "$0")/../.."
SKIP_BIN_CHECK=1
source tests/lib.sh

echo "═══ Tests unitaires env ═══"

ENV_TEST_BIN="/tmp/minishell_env_init_test"
VALGRIND_LOG="/tmp/minishell_env_init_valgrind.log"
trap 'rm -f "$ENV_TEST_BIN" "$VALGRIND_LOG"' EXIT

make --no-print-directory -C libft >/dev/null
cc -Wall -Wextra -Werror \
	tests/unit/env_init_runner.c \
	src/env/env_init.c \
	src/utils/ut_cleanup.c \
	libft/libft.a \
	-o "$ENV_TEST_BIN"

expected='key=[USER] value=[bomfim] exported=[1]
key=[PATH] value=[/usr/bin:/bin] exported=[1]
key=[TOKEN] value=[abc=def] exported=[1]
key=[EMPTY] value=[] exported=[1]'

actual=$("$ENV_TEST_BIN")
assert_eq "env_init copie envp en liste chaînée" "$expected" "$actual"

if [ "$RUN_VALGRIND" = "1" ]; then
	if ! command -v valgrind >/dev/null 2>&1; then
		printf "  ${C_RED}✗${C_RESET} valgrind disponible\n"
		printf "    valgrind introuvable dans le PATH\n"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("valgrind disponible")
	elif valgrind --leak-check=full --show-leak-kinds=all \
		--errors-for-leak-kinds=all --error-exitcode=42 \
		"$ENV_TEST_BIN" >"$VALGRIND_LOG" 2>&1; then
		printf "  ${C_GREEN}✓${C_RESET} env_init/env_free sans leak Valgrind\n"
		PASS=$((PASS+1))
	else
		printf "  ${C_RED}✗${C_RESET} env_init/env_free sans leak Valgrind\n"
		sed 's/^/    /' "$VALGRIND_LOG"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("env_init/env_free sans leak Valgrind")
	fi
fi

summary
