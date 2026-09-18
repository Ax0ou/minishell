#!/bin/bash
# tests/unit/test_strip.sh
# Issue #34 - expander : strip des quotes apres expansion
#
# Teste exp_strip_quotes() en isolation, sans passer par le shell complet.
# La fonction retire les quotes qui DELIMITENT et garde celles qui sont
# a l'interieur d'une autre paire.
#
# Usage : bash tests/unit/test_strip.sh

set -e
cd "$(dirname "$0")/../.."
SKIP_BIN_CHECK=1
source tests/lib.sh

STRIP_BIN="/tmp/minishell_strip_test"
trap 'rm -f "$STRIP_BIN"' EXIT

make --no-print-directory -C libft >/dev/null
cc -Wall -Wextra -Werror \
	tests/unit/strip_runner.c \
	src/expander/exp_quotes_strip.c \
	libft/libft.a \
	-o "$STRIP_BIN"

strip() { "$STRIP_BIN" "$1"; }

echo "═══ A. Cas de base ═══"

assert_eq "sans quotes, inchange"        "[bonjour]"  "$(strip 'bonjour')"
assert_eq "guillemets doubles"           "[bonjour]"  "$(strip '"bonjour"')"
assert_eq "guillemets simples"           "[bonjour]"  "$(strip "'bonjour'")"
assert_eq "chaine vide entre doubles"    "[]"         "$(strip '""')"
assert_eq "chaine vide entre simples"    "[]"         "$(strip "''")"

echo ""
echo "═══ B. Quotes collees, un seul mot en sortie ═══"

assert_eq "quotes au milieu"             "[abc]"      "$(strip 'a"b"c')"
assert_eq "alternance double simple"     "[abc]"      "$(strip '"a"'"'"'b'"'"'"c"')"
assert_eq "deux paires collees"          "[ab]"       "$(strip '"a""b"')"
assert_eq "quotes a cheval sur un mot"   "[hello world]" "$(strip 'he"llo wor"ld')"
assert_eq "doubles vides autour"         "[bonjour]"  "$(strip '""bonjour""')"

echo ""
echo "═══ C. Une quote a l'interieur de l'autre : elle est CONSERVEE ═══"

assert_eq "apostrophe dans des doubles"  "[l'ami]"    "$(strip "\"l'ami\"")"
assert_eq "doubles dans des simples"     '["bonjour"]' "$(strip "'\"bonjour\"'")"
assert_eq "simple quote seule"           "[']"        "$(strip "\"'\"")"
assert_eq "double quote seule"           '["]'        "$(strip "'\"'")"

echo ""
echo "═══ D. L'espace protege est conserve ═══"

assert_eq "espace entre doubles"         "[a b]"      "$(strip '"a b"')"
assert_eq "espaces multiples"            "[a   b]"    "$(strip '"a   b"')"

echo ""
echo "═══ E. Le dollar n'est PAS interprete ici (c'est le role de #31 a #33) ═══"

assert_eq "dollar entre doubles"         '[$USER]'    "$(strip '"$USER"')"
assert_eq "dollar entre simples"         '[$USER]'    "$(strip "'\$USER'")"
assert_eq "dollar nu"                    '[$USER]'    "$(strip '$USER')"

echo ""
echo "═══ F. Comparaison avec bash sur les memes chaines ═══"

check_vs_bash() {
	local name="$1" raw="$2"
	local mine expected
	mine=$("$STRIP_BIN" "$raw")
	expected="[$(bash -c "printf '%s' $raw")]"
	assert_eq "$name" "$expected" "$mine"
}

check_vs_bash "bash : \"bonjour\""       '"bonjour"'
check_vs_bash "bash : a\"b\"c"           'a"b"c'
check_vs_bash "bash : he\"llo wor\"ld"   'he"llo wor"ld'
check_vs_bash "bash : \"l'ami\""         "\"l'ami\""
check_vs_bash "bash : '\"bonjour\"'"     "'\"bonjour\"'"
check_vs_bash "bash : \"a b\""           '"a b"'

summary
