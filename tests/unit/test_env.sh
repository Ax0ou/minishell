#!/bin/bash
# tests/unit/test_env.sh
# Issue #18 — Tests unitaires env
#
# Le module env/ (env_init, env_access, env_to_array) et le builtin env
# (bi_env) sont couverts ici via des runners C compilés à la volée, car le
# pipeline complet lexer -> parser -> executor n'existe pas encore : les cas
# "au clavier" de TESTS.md §4.2 (run_shell 'export FOO=bar; echo $FOO', etc.)
# dépendent de builtins pas encore écrits (echo #8, export #38, unset #39)
# et de l'executor (#19-#30). À réintégrer tels quels une fois ces briques
# posées — voir docs/TESTS.md §4.2 pour la liste complète.

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
	src/parser/cmd_list_free.c \
	src/lexer/lex_token_list_free.c \
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
	src/parser/cmd_list_free.c \
	src/lexer/lex_token_list_free.c \
	libft/libft.a \
	-o "$ACCESS_TEST_BIN"

expected='get USER -> [bomfim]
get MISSING -> [(null)]
get USER after update -> [davi]
get NEW_VAR after create -> [hello]
get PATH after unset -> [(null)]
unset missing key ok
key=[NEW_VAR] value=[hello] exported=[1]
key=[USER] value=[davi] exported=[1]
get US (pas de faux positif prefix) -> [(null)]
get NEW_VAR after unset (head) -> [(null)]
key=[USER] value=[davi] exported=[1]'

actual=$("$ACCESS_TEST_BIN")
assert_eq "env_get lookup existant" "get USER -> [bomfim]" "$(echo "$actual" | sed -n '1p')"
assert_eq "env_get lookup absent -> NULL" "get MISSING -> [(null)]" "$(echo "$actual" | sed -n '2p')"
assert_eq "env_set met à jour une clé existante" "get USER after update -> [davi]" "$(echo "$actual" | sed -n '3p')"
assert_eq "env_set crée une nouvelle clé" "get NEW_VAR after create -> [hello]" "$(echo "$actual" | sed -n '4p')"
assert_eq "env_unset retire une clé existante" "get PATH after unset -> [(null)]" "$(echo "$actual" | sed -n '5p')"
assert_eq "env_unset sur clé absente ne crash pas" "unset missing key ok" "$(echo "$actual" | sed -n '6p')"
assert_eq "env_set préserve exported=1 même avec exported=0 en update" "key=[USER] value=[davi] exported=[1]" "$(echo "$actual" | sed -n '8p')"
assert_eq "env_get ne fait pas de faux positif sur un préfixe de clé" "get US (pas de faux positif prefix) -> [(null)]" "$(echo "$actual" | sed -n '9p')"
assert_eq "env_unset retire correctement la tête de la liste" "get NEW_VAR after unset (head) -> [(null)]" "$(echo "$actual" | sed -n '10p')"
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
	src/parser/cmd_list_free.c \
	src/lexer/lex_token_list_free.c \
	libft/libft.a \
	-o "$ARRAY_TEST_BIN"

expected='USER=bomfim
PATH=/usr/bin:/bin
count=[2]
USER=bomfim
PATH=/usr/bin:/bin
count=[2]
count=[0]'

actual=$("$ARRAY_TEST_BIN")
assert_eq "env_to_array ignore une variable exportee sans valeur (pas de crash)" \
	"$(echo "$expected" | sed -n '4,6p')" "$(echo "$actual" | sed -n '4,6p')"
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

echo "═══ Tests unitaires bi_env — Issue #15 ═══"

BI_ENV_TEST_BIN="/tmp/minishell_bi_env_test"
BI_ENV_VALGRIND_LOG="/tmp/minishell_bi_env_valgrind.log"
trap 'rm -f "$ENV_TEST_BIN" "$VALGRIND_LOG" "$ACCESS_TEST_BIN" "$ACCESS_VALGRIND_LOG" "$ARRAY_TEST_BIN" "$ARRAY_VALGRIND_LOG" "$BI_ENV_TEST_BIN" "$BI_ENV_VALGRIND_LOG"' EXIT

cc -Wall -Wextra -Werror \
	tests/unit/bi_env_runner.c \
	src/env/env_init.c \
	src/env/env_access.c \
	src/builtins/bi_env.c \
	src/utils/ut_cleanup.c \
	src/parser/cmd_list_free.c \
	src/lexer/lex_token_list_free.c \
	libft/libft.a \
	-o "$BI_ENV_TEST_BIN"

expected='USER=bomfim
PATH=/usr/bin:/bin
ret=[0]'

actual=$("$BI_ENV_TEST_BIN")
assert_eq "bi_env n'affiche que les variables exportées" "$expected" "$actual"

if [ "$RUN_VALGRIND" = "1" ]; then
	if ! command -v valgrind >/dev/null 2>&1; then
		printf "  ${C_RED}✗${C_RESET} valgrind disponible\n"
		printf "    valgrind introuvable dans le PATH\n"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("valgrind disponible")
	elif valgrind --leak-check=full --show-leak-kinds=all \
		--errors-for-leak-kinds=all --error-exitcode=42 \
		"$BI_ENV_TEST_BIN" >"$BI_ENV_VALGRIND_LOG" 2>&1; then
		printf "  ${C_GREEN}✓${C_RESET} bi_env sans leak Valgrind\n"
		PASS=$((PASS+1))
	else
		printf "  ${C_RED}✗${C_RESET} bi_env sans leak Valgrind\n"
		sed 's/^/    /' "$BI_ENV_VALGRIND_LOG"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("bi_env sans leak Valgrind")
	fi
fi

echo "═══ Tests unitaires bi_cd — Issue #26 ═══"

CD_FIXTURE_DIR=$(mktemp -d /tmp/minishell_bi_cd_fixture.XXXXXX)
CD_FIXTURE_DIR=$(cd "$CD_FIXTURE_DIR" && pwd)
CD_TEST_BIN="/tmp/minishell_bi_cd_test"
CD_VALGRIND_LOG="/tmp/minishell_bi_cd_valgrind.log"
CD_STDERR_LOG="/tmp/minishell_bi_cd_stderr.log"
trap 'rm -rf "$CD_FIXTURE_DIR"; rm -f "$CD_TEST_BIN" "$CD_VALGRIND_LOG" "$CD_STDERR_LOG"' EXIT

mkdir -p "$CD_FIXTURE_DIR/home" "$CD_FIXTURE_DIR/work/sub"

cc -Wall -Wextra -Werror \
	tests/unit/bi_cd_runner.c \
	src/builtins/bi_cd.c \
	src/env/env_init.c \
	src/env/env_access.c \
	src/utils/ut_cleanup.c \
	src/parser/cmd_list_free.c \
	src/utils/ut_error.c \
	src/lexer/lex_token_list_free.c \
	libft/libft.a \
	-o "$CD_TEST_BIN"

expected="cd sub -> ret=[0] cwd=[$CD_FIXTURE_DIR/work/sub] PWD=[$CD_FIXTURE_DIR/work/sub] OLDPWD=[$CD_FIXTURE_DIR/work]
cd (none) -> ret=[0] cwd=[$CD_FIXTURE_DIR/home] PWD=[$CD_FIXTURE_DIR/home] OLDPWD=[$CD_FIXTURE_DIR/work/sub]
$CD_FIXTURE_DIR/work/sub
cd - -> ret=[0] cwd=[$CD_FIXTURE_DIR/work/sub] PWD=[$CD_FIXTURE_DIR/work/sub] OLDPWD=[$CD_FIXTURE_DIR/home]
cd /definitely/not/a/real/path/xyz123 -> ret=[1] cwd=[$CD_FIXTURE_DIR/work/sub] PWD=[$CD_FIXTURE_DIR/work/sub] OLDPWD=[$CD_FIXTURE_DIR/home]
cd (none) -> ret=[1] cwd=[$CD_FIXTURE_DIR/work/sub] PWD=[$CD_FIXTURE_DIR/work/sub] OLDPWD=[$CD_FIXTURE_DIR/home]"

actual=$("$CD_TEST_BIN" "$CD_FIXTURE_DIR" 2>"$CD_STDERR_LOG")

assert_eq "cd chemin relatif : chdir + PWD/OLDPWD mis a jour" "$(echo "$expected" | sed -n '1p')" "$(echo "$actual" | sed -n '1p')"
assert_eq "cd sans arg : va dans \$HOME" "$(echo "$expected" | sed -n '2p')" "$(echo "$actual" | sed -n '2p')"
assert_eq "cd - : affiche le nouveau cwd" "$(echo "$expected" | sed -n '3p')" "$(echo "$actual" | sed -n '3p')"
assert_eq "cd - : va dans \$OLDPWD, met a jour PWD/OLDPWD" "$(echo "$expected" | sed -n '4p')" "$(echo "$actual" | sed -n '4p')"
assert_eq "cd chemin inexistant : erreur, cwd/env inchanges" "$(echo "$expected" | sed -n '5p')" "$(echo "$actual" | sed -n '5p')"
assert_eq "cd sans arg, HOME absent : erreur, cwd/env inchanges" "$(echo "$expected" | sed -n '6p')" "$(echo "$actual" | sed -n '6p')"
assert_eq "bi_cd — sortie complète" "$expected" "$actual"
assert_eq "message d'erreur : chemin inexistant" \
	"minishell: cd: /definitely/not/a/real/path/xyz123: No such file or directory" \
	"$(sed -n '1p' "$CD_STDERR_LOG")"
assert_eq "message d'erreur : HOME not set" \
	"minishell: cd: HOME not set" \
	"$(sed -n '2p' "$CD_STDERR_LOG")"

if [ "$RUN_VALGRIND" = "1" ]; then
	if ! command -v valgrind >/dev/null 2>&1; then
		printf "  ${C_RED}✗${C_RESET} valgrind disponible\n"
		printf "    valgrind introuvable dans le PATH\n"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("valgrind disponible")
	elif valgrind --leak-check=full --show-leak-kinds=all \
		--errors-for-leak-kinds=all --error-exitcode=42 \
		"$CD_TEST_BIN" "$CD_FIXTURE_DIR" >"$CD_VALGRIND_LOG" 2>&1; then
		printf "  ${C_GREEN}✓${C_RESET} bi_cd sans leak Valgrind\n"
		PASS=$((PASS+1))
	else
		printf "  ${C_RED}✗${C_RESET} bi_cd sans leak Valgrind\n"
		sed 's/^/    /' "$CD_VALGRIND_LOG"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("bi_cd sans leak Valgrind")
	fi
fi

echo "═══ Tests unitaires bi_export — Issue #38 ═══"

EXPORT_TEST_BIN="/tmp/minishell_bi_export_test"
EXPORT_VALGRIND_LOG="/tmp/minishell_bi_export_valgrind.log"
EXPORT_STDERR_LOG="/tmp/minishell_bi_export_stderr.log"
trap 'rm -rf "$CD_FIXTURE_DIR"; rm -f "$ENV_TEST_BIN" "$VALGRIND_LOG" "$ACCESS_TEST_BIN" "$ACCESS_VALGRIND_LOG" "$ARRAY_TEST_BIN" "$ARRAY_VALGRIND_LOG" "$BI_ENV_TEST_BIN" "$BI_ENV_VALGRIND_LOG" "$CD_TEST_BIN" "$CD_VALGRIND_LOG" "$CD_STDERR_LOG" "$EXPORT_TEST_BIN" "$EXPORT_VALGRIND_LOG" "$EXPORT_STDERR_LOG"' EXIT

cc -Wall -Wextra -Werror \
	tests/unit/bi_export_runner.c \
	src/builtins/bi_export.c \
	src/builtins/bi_export_utils.c \
	src/env/env_init.c \
	src/env/env_access.c \
	src/utils/ut_cleanup.c \
	src/utils/ut_error.c \
	src/lexer/lex_token_list_free.c \
	src/parser/cmd_list_free.c \
	libft/libft.a \
	-o "$EXPORT_TEST_BIN"

expected="export FOO=bar -> ret=[0]
  FOO -> [bar]
export BAZ (no value) -> ret=[0]
  BAZ (should be null) -> [(null)]
export BAZ=now -> ret=[0]
  BAZ -> [now]
export FOO (re-export, no clobber) -> ret=[0]
  FOO (should still be bar) -> [bar]
export 1BAD=x (invalid) -> ret=[1]
export A=1 2BAD B=2 (partial failure) -> ret=[1]
  A -> [1]
  B -> [2]
=== export (listing) ===
declare -x A=\"1\"
declare -x B=\"2\"
declare -x BAZ=\"now\"
declare -x FOO=\"bar\"
declare -x USER=\"bomfim\"
export (no args) -> ret=[0]"

actual=$("$EXPORT_TEST_BIN" 2>"$EXPORT_STDERR_LOG")

assert_eq "export KEY=VAL simple" "$(echo "$expected" | sed -n '1,2p')" "$(echo "$actual" | sed -n '1,2p')"
assert_eq "export NAME sans valeur : invisible dans env_get" "$(echo "$expected" | sed -n '3,4p')" "$(echo "$actual" | sed -n '3,4p')"
assert_eq "export NAME=VAL sur une cle deja value-less" "$(echo "$expected" | sed -n '5,6p')" "$(echo "$actual" | sed -n '5,6p')"
assert_eq "re-export NAME (sans =) n'ecrase pas la valeur existante" "$(echo "$expected" | sed -n '7,8p')" "$(echo "$actual" | sed -n '7,8p')"
assert_eq "identifiant invalide -> ret=1, pas applique" "$(echo "$expected" | sed -n '9p')" "$(echo "$actual" | sed -n '9p')"
assert_eq "echec partiel : les valides sont quand meme appliques" "$(echo "$expected" | sed -n '10,12p')" "$(echo "$actual" | sed -n '10,12p')"
assert_eq "export sans arg : liste triee, format declare -x" "$(echo "$expected" | sed -n '13,19p')" "$(echo "$actual" | sed -n '13,19p')"
assert_eq "bi_export — sortie complète" "$expected" "$actual"
assert_eq "message d'erreur : identifiant invalide (1BAD=x)" \
	"minishell: export: 1BAD=x: not a valid identifier" \
	"$(sed -n '1p' "$EXPORT_STDERR_LOG")"
assert_eq "message d'erreur : identifiant invalide (2BAD)" \
	"minishell: export: 2BAD: not a valid identifier" \
	"$(sed -n '2p' "$EXPORT_STDERR_LOG")"

if [ "$RUN_VALGRIND" = "1" ]; then
	if ! command -v valgrind >/dev/null 2>&1; then
		printf "  ${C_RED}✗${C_RESET} valgrind disponible\n"
		printf "    valgrind introuvable dans le PATH\n"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("valgrind disponible")
	elif valgrind --leak-check=full --show-leak-kinds=all \
		--errors-for-leak-kinds=all --error-exitcode=42 \
		"$EXPORT_TEST_BIN" >"$EXPORT_VALGRIND_LOG" 2>&1; then
		printf "  ${C_GREEN}✓${C_RESET} bi_export sans leak Valgrind\n"
		PASS=$((PASS+1))
	else
		printf "  ${C_RED}✗${C_RESET} bi_export sans leak Valgrind\n"
		sed 's/^/    /' "$EXPORT_VALGRIND_LOG"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("bi_export sans leak Valgrind")
	fi
fi

echo "═══ Tests unitaires bi_unset — Issue #80 ═══"

UNSET_TEST_BIN="/tmp/minishell_bi_unset_test"
UNSET_VALGRIND_LOG="/tmp/minishell_bi_unset_valgrind.log"
UNSET_STDERR_LOG="/tmp/minishell_bi_unset_stderr.log"
trap 'rm -rf "$CD_FIXTURE_DIR"; rm -f "$ENV_TEST_BIN" "$VALGRIND_LOG" "$ACCESS_TEST_BIN" "$ACCESS_VALGRIND_LOG" "$ARRAY_TEST_BIN" "$ARRAY_VALGRIND_LOG" "$BI_ENV_TEST_BIN" "$BI_ENV_VALGRIND_LOG" "$CD_TEST_BIN" "$CD_VALGRIND_LOG" "$CD_STDERR_LOG" "$EXPORT_TEST_BIN" "$EXPORT_VALGRIND_LOG" "$EXPORT_STDERR_LOG" "$UNSET_TEST_BIN" "$UNSET_VALGRIND_LOG" "$UNSET_STDERR_LOG"' EXIT

cc -Wall -Wextra -Werror \
	tests/unit/bi_unset_runner.c \
	src/builtins/bi_unset.c \
	src/builtins/bi_export.c \
	src/builtins/bi_export_utils.c \
	src/env/env_init.c \
	src/env/env_access.c \
	src/utils/ut_cleanup.c \
	src/utils/ut_error.c \
	src/lexer/lex_token_list_free.c \
	src/parser/cmd_list_free.c \
	libft/libft.a \
	-o "$UNSET_TEST_BIN"

expected='unset FOO -> ret=[0]
  FOO -> [(null)]
unset GHOST (absent) -> ret=[0]
unset (no args) -> ret=[0]
unset 1BAD (invalid) -> ret=[1]
unset A=x (whole token invalid, not partial) -> ret=[1]
  A (should be untouched) -> [1]
unset A 1BAD B (partial failure) -> ret=[1]
  A -> [(null)]
  B -> [(null)]'

actual=$("$UNSET_TEST_BIN" 2>"$UNSET_STDERR_LOG")

assert_eq "unset retire une cle existante" "$(echo "$expected" | sed -n '1,2p')" "$(echo "$actual" | sed -n '1,2p')"
assert_eq "unset sur cle absente ne crash pas, ret=0" "$(echo "$expected" | sed -n '3p')" "$(echo "$actual" | sed -n '3p')"
assert_eq "unset sans arg : succes, rien a faire" "$(echo "$expected" | sed -n '4p')" "$(echo "$actual" | sed -n '4p')"
assert_eq "unset 1BAD : identifiant invalide, ret=1" "$(echo "$expected" | sed -n '5p')" "$(echo "$actual" | sed -n '5p')"
assert_eq "unset A=x : tout le token rejete, pas d'extraction partielle" \
	"$(echo "$expected" | sed -n '6,7p')" "$(echo "$actual" | sed -n '6,7p')"
assert_eq "unset A 1BAD B : les valides sont quand meme retires" \
	"$(echo "$expected" | sed -n '8,10p')" "$(echo "$actual" | sed -n '8,10p')"
assert_eq "bi_unset — sortie complète" "$expected" "$actual"
assert_eq "message d'erreur : identifiant invalide (1BAD)" \
	"minishell: unset: 1BAD: not a valid identifier" \
	"$(sed -n '1p' "$UNSET_STDERR_LOG")"
assert_eq "message d'erreur : A=x rejete en entier (pas 'x' ou '=x')" \
	"minishell: unset: A=x: not a valid identifier" \
	"$(sed -n '2p' "$UNSET_STDERR_LOG")"

if [ "$RUN_VALGRIND" = "1" ]; then
	if ! command -v valgrind >/dev/null 2>&1; then
		printf "  ${C_RED}✗${C_RESET} valgrind disponible\n"
		printf "    valgrind introuvable dans le PATH\n"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("valgrind disponible")
	elif valgrind --leak-check=full --show-leak-kinds=all \
		--errors-for-leak-kinds=all --error-exitcode=42 \
		"$UNSET_TEST_BIN" >"$UNSET_VALGRIND_LOG" 2>&1; then
		printf "  ${C_GREEN}✓${C_RESET} bi_unset sans leak Valgrind\n"
		PASS=$((PASS+1))
	else
		printf "  ${C_RED}✗${C_RESET} bi_unset sans leak Valgrind\n"
		sed 's/^/    /' "$UNSET_VALGRIND_LOG"
		FAIL=$((FAIL+1))
		FAILED_TESTS+=("bi_unset sans leak Valgrind")
	fi
fi

summary
