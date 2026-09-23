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
X_BIN="/tmp/minishell_exit_test"
P_BIN="/tmp/minishell_pwd_test"
trap 'rm -f "$E_BIN" "$P_BIN" "$X_BIN"' EXIT

make --no-print-directory -C libft >/dev/null
cc -Wall -Wextra -Werror \
	tests/unit/echo_runner.c \
	src/builtins/bi_echo.c \
	libft/libft.a \
	-o "$E_BIN"

# sortie brute de notre echo, sentinel compris
mine() { "$E_BIN" "$@"; printf '|END'; }

# sortie brute du echo builtin de bash, sentinel compris
theirs() { $BASH_BIN -c 'echo "$@"' _ "$@"; printf '|END'; }

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

echo ""
echo "═══ D. exit (issue #10) ═══"

cc -Wall -Wextra -Werror \
	tests/unit/exit_runner.c \
	src/builtins/bi_exit.c \
	src/utils/ut_str.c \
	src/utils/ut_cleanup.c \
	src/utils/ut_error.c \
	src/lexer/lex_token_list_free.c \
	src/parser/cmd_list_free.c \
	libft/libft.a \
	-o "$X_BIN"

# code de sortie de notre exit
ex() { local c; "$X_BIN" "$@" >/dev/null 2>&1 && c=0 || c=$?; echo "$c"; }

# message sur stderr de notre exit
ex_err() { "$X_BIN" "$@" 2>&1 >/dev/null || true; }

# code de sortie du exit builtin de bash
bx() { local c; $BASH_BIN -c 'exit "$@"' _ "$@" 2>/dev/null && c=0 || c=$?; echo "$c"; }

echo "  -- codes de sortie, valeurs attendues --"

assert_eq "sans argument, reprend last_exit (7)"  "7"   "$(ex)"
assert_eq "exit 42"                               "42"  "$(ex 42)"
assert_eq "exit 0"                                "0"   "$(ex 0)"
assert_eq "exit 255"                              "255" "$(ex 255)"
assert_eq "exit 256 -> 0"                         "0"   "$(ex 256)"
assert_eq "exit 300 -> 44"                        "44"  "$(ex 300)"
assert_eq "exit -1 -> 255"                        "255" "$(ex -1)"
assert_eq "exit -300 -> 212"                      "212" "$(ex -300)"
assert_eq "exit +42 -> 42"                        "42"  "$(ex +42)"
assert_eq "espaces autour du nombre"              "42"  "$(ex "  42  ")"
assert_eq "exit abc -> code 2"                    "2"   "$(ex abc)"
assert_eq "exit 42abc -> code 2"                  "2"   "$(ex 42abc)"
assert_eq "exit vide -> code 2"                   "2"   "$(ex "")"
assert_eq "exit tiret seul -> code 2"             "2"   "$(ex -)"
assert_eq "depassement -> code 2"                 "2"   "$(ex 99999999999999999999)"
assert_eq "exit 1 2 -> ne sort pas, retourne 1"   "1"   "$(ex 1 2)"

echo "  -- messages sur stderr --"

assert_eq "message argument non numerique" \
"minishell: exit: abc: numeric argument required" "$(ex_err abc)"

assert_eq "message trop d'arguments" \
"minishell: exit: too many arguments" "$(ex_err 1 2)"

assert_eq "aucun message quand tout va bien" "" "$(ex_err 42)"

echo "  -- comparaison des codes avec bash --"

cmp_exit() {
	local name="$1"
	shift
	assert_eq "$name" "$(bx "$@")" "$(ex "$@")"
}

if [ "${BASH_MAJOR:-0}" -lt 4 ]; then
	printf "  ${C_YELLOW}⚠${C_RESET} comparaison ignoree : bash %s est trop ancien\n" "$BASH_MAJOR"
	printf "    Le bash 3.2 d'Apple diverge sur \"exit abc def\". La reference\n"
	printf "    est bash 5, comme sur les machines de l'ecole et dans la CI.\n"
	printf "    Pour tester en local : brew install bash\n"
else
cmp_exit "vs bash : 42"          42
cmp_exit "vs bash : 0"           0
cmp_exit "vs bash : 255"         255
cmp_exit "vs bash : 256"         256
cmp_exit "vs bash : 300"         300
cmp_exit "vs bash : abc"         abc
cmp_exit "vs bash : 42abc"       42abc
cmp_exit "vs bash : chaine vide" ""
cmp_exit "vs bash : depassement" 99999999999999999999
cmp_exit "vs bash : 1 2"         1 2
cmp_exit "vs bash : abc def"     abc def
cmp_exit "vs bash : 1 abc"       1 abc
cmp_exit "vs bash : abc 1"       abc 1
cmp_exit "vs bash : -1"          -1
cmp_exit "vs bash : -300"        -300
fi

summary
