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

echo "═══ Tests unitaires env_access (get/set/unset) — Issue #13 ═══"

ACCESS_TEST_BIN="/tmp/minishell_env_access_test"
ACCESS_VALGRIND_LOG="/tmp/minishell_env_access_valgrind.log"
trap 'rm -f "$ENV_TEST_BIN" "$VALGRIND_LOG" "$ACCESS_TEST_BIN" "$ACCESS_VALGRIND_LOG"' EXIT

cc -Wall -Wextra -Werror \
	tests/unit/env_access_runner.c \
	src/env/env_init.c \
	src/env/env_access.c \
	src/utils/ut_cleanup.c \
	libft/libft.a \
	-o "$ACCESS_TEST_BIN"

expected='get USER -> [bomfim]
get MISSING -> [(null)]
get USER after update -> [davi]
get NEW_VAR after create -> [hello]
get PATH after unset -> [(null)]
unset missing key ok
key=[NEW_VAR] value=[hello] exported=[1]
key=[USER] value=[davi] exported=[1]'

actual=$("$ACCESS_TEST_BIN")
assert_eq "env_get lookup existant" "get USER -> [bomfim]" "$(echo "$actual" | sed -n '1p')"
assert_eq "env_get lookup absent -> NULL" "get MISSING -> [(null)]" "$(echo "$actual" | sed -n '2p')"
assert_eq "env_set met à jour une clé existante" "get USER after update -> [davi]" "$(echo "$actual" | sed -n '3p')"
assert_eq "env_set crée une nouvelle clé" "get NEW_VAR after create -> [hello]" "$(echo "$actual" | sed -n '4p')"
assert_eq "env_unset retire une clé existante" "get PATH after unset -> [(null)]" "$(echo "$actual" | sed -n '5p')"
assert_eq "env_unset sur clé absente ne crash pas" "unset missing key ok" "$(echo "$actual" | sed -n '6p')"
assert_eq "env_set préserve exported=1 même avec exported=0 en update" "key=[USER] value=[davi] exported=[1]" "$(echo "$actual" | sed -n '8p')"
assert_eq "env_access — sortie complète" "$expected" "$actual"

if [ "$RUN_VALGRIND" = "1" ]; then
	if ! command -v valgrind >/dev/null 2>&1; then
		printf "  ${C_RED}✗${C_RESET} valgrind disponible\n"
		printf "    valgrind introuvable dans le PATH\n"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("valgrind disponible")
	elif valgrind --leak-check=full --show-leak-kinds=all \
		--errors-for-leak-kinds=all --error-exitcode=42 \
		"$ACCESS_TEST_BIN" >"$ACCESS_VALGRIND_LOG" 2>&1; then
		printf "  ${C_GREEN}✓${C_RESET} env_get/env_set/env_unset sans leak Valgrind\n"
		PASS=$((PASS+1))
	else
		printf "  ${C_RED}✗${C_RESET} env_get/env_set/env_unset sans leak Valgrind\n"
		sed 's/^/    /' "$ACCESS_VALGRIND_LOG"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("env_get/env_set/env_unset sans leak Valgrind")
	fi
fi

echo "═══ Tests unitaires env_to_array — Issue #14 ═══"

ARRAY_TEST_BIN="/tmp/minishell_env_to_array_test"
ARRAY_VALGRIND_LOG="/tmp/minishell_env_to_array_valgrind.log"
trap 'rm -f "$ENV_TEST_BIN" "$VALGRIND_LOG" "$ACCESS_TEST_BIN" "$ACCESS_VALGRIND_LOG" "$ARRAY_TEST_BIN" "$ARRAY_VALGRIND_LOG"' EXIT

cc -Wall -Wextra -Werror \
	tests/unit/env_to_array_runner.c \
	src/env/env_init.c \
	src/env/env_access.c \
	src/env/env_to_array.c \
	src/utils/ut_cleanup.c \
	libft/libft.a \
	-o "$ARRAY_TEST_BIN"

expected='USER=bomfim
PATH=/usr/bin:/bin
count=[2]
count=[0]'

actual=$("$ARRAY_TEST_BIN")
assert_eq "env_to_array — sortie complète" "$expected" "$actual"

if [ "$RUN_VALGRIND" = "1" ]; then
	if ! command -v valgrind >/dev/null 2>&1; then
		printf "  ${C_RED}✗${C_RESET} valgrind disponible\n"
		printf "    valgrind introuvable dans le PATH\n"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("valgrind disponible")
	elif valgrind --leak-check=full --show-leak-kinds=all \
		--errors-for-leak-kinds=all --error-exitcode=42 \
		"$ARRAY_TEST_BIN" >"$ARRAY_VALGRIND_LOG" 2>&1; then
		printf "  ${C_GREEN}✓${C_RESET} env_to_array sans leak Valgrind\n"
		PASS=$((PASS+1))
	else
		printf "  ${C_RED}✗${C_RESET} env_to_array sans leak Valgrind\n"
		sed 's/^/    /' "$ARRAY_VALGRIND_LOG"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("env_to_array sans leak Valgrind")
	fi
fi

summary
