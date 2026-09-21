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
VAL_BIN="/tmp/minishell_var_value_test"
trap 'rm -f "$LEN_BIN" "$VAL_BIN"' EXIT

make --no-print-directory -C libft >/dev/null
cc -Wall -Wextra -Werror \
	tests/unit/exp_var_len_runner.c \
	src/expander/exp_var_identify.c \
	libft/libft.a \
	-o "$LEN_BIN"

cc -Wall -Wextra -Werror \
	tests/unit/exp_var_value_runner.c \
	src/expander/exp_var_value.c \
	src/expander/exp_var_identify.c \
	src/env/env_init.c \
	src/env/env_access.c \
	src/utils/ut_cleanup.c \
	src/utils/ut_error.c \
	src/parser/cmd_list_free.c \
	src/lexer/lex_token_list_free.c \
	libft/libft.a \
	-o "$VAL_BIN"

vlen() { "$LEN_BIN" "$1"; }
vval() { "$VAL_BIN" "$1" "${2:-0}"; }

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

echo ""
echo "═══ D. exp_var_value : ce que vaut la variable ═══"
echo "  (env du test : USER=alvrd  EMPTY=  HOME=/Users/alvrd)"

assert_eq "USER existe"                            "[alvrd]"        "$(vval 'USER')"
assert_eq "USER-test : seul USER est lu"           "[alvrd]"        "$(vval 'USER-test')"
assert_eq "HOME/x : seul HOME est lu"              "[/Users/alvrd]" "$(vval 'HOME/x')"
assert_eq "variable inexistante -> vide"           "[]"             "$(vval 'INEXISTANT')"
assert_eq "USER_test n'existe pas -> vide"         "[]"             "$(vval 'USER_test')"
assert_eq "variable definie mais vide"             "[]"             "$(vval 'EMPTY')"
assert_eq "\$1 -> vide"                            "[]"             "$(vval '1abc')"

echo ""
echo "═══ E. \$? : le dernier code de sortie ═══"

assert_eq "\$? apres un succes"                    "[0]"            "$(vval '?' 0)"
assert_eq "\$? apres une erreur"                   "[1]"            "$(vval '?' 1)"
assert_eq "\$? apres command not found"            "[127]"          "$(vval '?' 127)"
assert_eq "\$? apres ctrl-C"                       "[130]"          "$(vval '?' 130)"
assert_eq "\$?abc : seul le ? est lu"              "[2]"            "$(vval '?abc' 2)"

summary
