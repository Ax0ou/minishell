#!/bin/bash
# tests/unit/test_builtins.sh
# Issues #8 / #9 / #10 - Tests unitaires des builtins
#
# Bloc A : echo, valeurs attendues explicites
# Bloc B : echo, comparaison octet par octet avec le echo builtin de bash
#
# Le sentinel |END sert a rendre visible la presence ou l'absence du
# saut de ligne final : $(...) supprime les newlines de fin, donc sans
# lui on ne verrait aucune difference entre echo -n x et echo x.

set -e
cd "$(dirname "$0")/../.."
SKIP_BIN_CHECK=1
source tests/lib.sh

E_BIN="/tmp/minishell_echo_test"
P_BIN="/tmp/minishell_pwd_test"
trap 'rm -f "$E_BIN" "$P_BIN"' EXIT

make --no-print-directory -C libft >/dev/null
cc -Wall -Wextra -Werror \
	tests/unit/echo_runner.c \
	src/builtins/bi_echo.c \
	libft/libft.a \
	-o "$E_BIN"

# sortie brute de notre echo, sentinel compris
mine() { "$E_BIN" "$@"; printf '|END'; }

# sortie brute du echo builtin de bash, sentinel compris
theirs() { bash -c 'echo "$@"' _ "$@"; printf '|END'; }

echo "═══ A. echo, valeurs attendues (issue #8) ═══"

assert_eq "trois arguments" \
"a b c
|END" "$(mine a b c)"

assert_eq "aucun argument, juste un saut de ligne" \
"
|END" "$(mine)"

assert_eq "-n seul, aucun octet ecrit" \
"|END" "$(mine -n)"

assert_eq "-n hello" \
"hello|END" "$(mine -n hello)"

assert_eq "-n repete" \
"hello|END" "$(mine -n -n hello)"

assert_eq "-nnnn est une option valide" \
"hello|END" "$(mine -nnnn hello)"

assert_eq "arret definitif : -n apres un mot est un argument" \
"hello -n
|END" "$(mine hello -n)"

assert_eq "-n- n'est pas une option" \
"-n- hello
|END" "$(mine -n- hello)"

assert_eq "tiret seul n'est pas une option" \
"-
|END" "$(mine -)"

assert_eq "chaine vide" \
"
|END" "$(mine "")"

assert_eq "espaces preserves dans un argument" \
"a  b
|END" "$(mine "a  b")"

echo ""
echo "═══ B. echo, comparaison directe avec bash ═══"

cmp_bash() {
	local name="$1"
	shift
	assert_eq "$name" "$(theirs "$@")" "$(mine "$@")"
}

cmp_bash "vs bash : a b c"            a b c
cmp_bash "vs bash : sans argument"
cmp_bash "vs bash : -n seul"          -n
cmp_bash "vs bash : -n hello"         -n hello
cmp_bash "vs bash : -n -n hello"      -n -n hello
cmp_bash "vs bash : -nnnn hello"      -nnnn hello
cmp_bash "vs bash : hello -n"         hello -n
cmp_bash "vs bash : -n- hello"        -n- hello
cmp_bash "vs bash : tiret seul"       -
cmp_bash "vs bash : chaine vide"      ""
cmp_bash "vs bash : espaces internes" "a  b"
cmp_bash "vs bash : -N majuscule"     -N hello
cmp_bash "vs bash : -xn hello"        -xn hello

echo ""
echo "═══ C. pwd (issue #9) ═══"

cc -Wall -Wextra -Werror \
	tests/unit/pwd_runner.c \
	src/builtins/bi_pwd.c \
	src/utils/ut_error.c \
	libft/libft.a \
	-o "$P_BIN" 2>/dev/null || echo "  (pwd_runner.c absent, bloc ignore)"

if [ -x "$P_BIN" ]; then
	assert_eq "pwd affiche le dossier courant" "$(pwd)" "$(cd "$(pwd)" && "$P_BIN")"
	assert_eq "pwd depuis /tmp" "$(cd /tmp && pwd -P)" "$(cd /tmp && "$P_BIN")"
fi

summary
