#!/bin/bash
# tests/unit/test_expander.sh
# Epics #77 et #78 - tests unitaires de l'expander
#
# Usage : bash tests/unit/test_expander.sh

set -e
cd "$(dirname "$0")/../.."
SKIP_BIN_CHECK=1
source tests/lib.sh

LEN_BIN="/tmp/minishell_var_len_test"
trap 'rm -f "$LEN_BIN"' EXIT

make --no-print-directory -C libft >/dev/null
cc -Wall -Wextra -Werror \
	tests/unit/exp_var_len_runner.c \
	src/expander/exp_var_identify.c \
	libft/libft.a \
	-o "$LEN_BIN"

vlen() { "$LEN_BIN" "$1"; }

echo "═══ A. exp_var_len : ou s'arrete un nom de variable ═══"
echo "  (l'argument est ce qui suit le \$)"

assert_eq "USER-test : le - arrete le nom"          "4" "$(vlen 'USER-test')"
assert_eq "USER:HOME : le : arrete le nom"          "4" "$(vlen 'USER:HOME')"
assert_eq "HOME/x : le / arrete le nom"             "4" "$(vlen 'HOME/x')"
assert_eq "USER\$HOME : le \$ arrete le nom"        "4" "$(vlen 'USER$HOME')"
assert_eq "USER_test : le _ fait partie du nom"     "9" "$(vlen 'USER_test')"
assert_eq "_ seul est un nom valide"                "1" "$(vlen '_')"
assert_eq "_1a : chiffres acceptes apres le debut"  "3" "$(vlen '_1a')"
assert_eq "a : nom d'une lettre"                    "1" "$(vlen 'a')"

echo ""
echo "═══ B. Les noms d'un seul caractere ═══"

assert_eq "? : \$? fait 1 caractere"                "1" "$(vlen '?abc')"
assert_eq "?? : seul le premier ? compte"           "1" "$(vlen '??')"
assert_eq "1abc : un chiffre fait 1 caractere"      "1" "$(vlen '1abc')"
assert_eq "9 seul"                                  "1" "$(vlen '9')"

echo ""
echo "═══ C. Ce n'est pas une variable : le \$ reste un \$ ═══"

assert_eq "fin de chaine (\$ seul)"                 "0" "$(vlen '')"
assert_eq "espace"                                  "0" "$(vlen ' x')"
assert_eq "tiret"                                   "0" "$(vlen '-test')"
assert_eq "guillemet double"                        "0" "$(vlen '"x')"
assert_eq "guillemet simple"                        "0" "$(vlen "'x")"

summary
