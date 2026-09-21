#!/bin/bash
# tests/integration/test_syntax.sh
# Issue #21 - Validation syntaxique
#
# Deux passes sont testees :
#   syntax_check_line   : quotes non fermees, sur la chaine brute
#   syntax_check_tokens : operateurs mal places, sur la liste de tokens
# Reference : bash 5.x sous Linux. Code de sortie attendu : 2.

set -e
cd "$(dirname "$0")/../.."
SKIP_BIN_CHECK=1
source tests/lib.sh

MSH="/tmp/minishell_syntax"
TMP_P="$(cd /tmp && pwd -P)"
SANDBOX="$TMP_P/minishell_syntax_box"
trap 'rm -rf "$MSH" "$SANDBOX"' EXIT

make --no-print-directory -C libft >/dev/null
cc -Wall -Wextra -Werror \
	tests/integration/shell_runner.c \
	$(find src -name '*.c' -size +0 ! -name 'main.c') \
	libft/libft.a -lreadline \
	-o "$MSH"

rm -rf "$SANDBOX" && mkdir -p "$SANDBOX"
printf 'contenu\n' > "$SANDBOX/f"

sh_err() { (cd "$SANDBOX" && "$MSH" "$@" 2>&1 >/dev/null) | head -1; }
sh_out() { (cd "$SANDBOX" && "$MSH" "$@" 2>/dev/null); }
sh_code() { local c; (cd "$SANDBOX" && "$MSH" "$@" >/dev/null 2>&1) && c=0 || c=$?; echo "$c"; }

SYN="minishell: syntax error near unexpected token"

echo "═══ A. Pipe mal place ═══"

assert_eq "pipe en fin de ligne"   "$SYN \`|'"  "$(sh_err 'ls |')"
assert_eq "pipe seul"              "$SYN \`|'"  "$(sh_err '|')"
assert_eq "pipe en debut"          "$SYN \`|'"  "$(sh_err '| ls')"
assert_eq "deux pipes colles"      "$SYN \`|'"  "$(sh_err 'ls | | wc')"
assert_eq "pipe apres redirection" "$SYN \`|'"  "$(sh_err 'ls > f |')"

echo ""
echo "═══ B. Redirection sans cible ═══"

assert_eq "sortante sans cible"    "$SYN \`newline'" "$(sh_err 'ls >')"
assert_eq "entrante sans cible"    "$SYN \`newline'" "$(sh_err 'cat <')"
assert_eq "append sans cible"      "$SYN \`newline'" "$(sh_err 'ls >>')"
assert_eq "heredoc sans limiteur"  "$SYN \`newline'" "$(sh_err 'cat <<')"
assert_eq "redirection seule"      "$SYN \`newline'" "$(sh_err '>')"

echo ""
echo "═══ C. Deux operateurs colles ═══"

assert_eq "> suivi de >"           "$SYN \`>'"  "$(sh_err 'ls > >')"
assert_eq "> suivi de <"           "$SYN \`<'"  "$(sh_err 'ls > <')"
assert_eq "> suivi de >>"          "$SYN \`>>'" "$(sh_err 'ls > >> f')"
assert_eq "> suivi de |"           "$SYN \`|'"  "$(sh_err 'ls > | wc')"
assert_eq "<< suivi de <"          "$SYN \`<'"  "$(sh_err 'cat << <')"

echo ""
echo "═══ D. Quotes non fermees ═══"

EOFQ="minishell: unexpected EOF while looking for matching"

assert_eq "double quote ouverte"   "$EOFQ \`\"'" "$(sh_err 'echo "abc')"
assert_eq "simple quote ouverte"   "$EOFQ \`''"  "$(sh_err "echo 'abc")"
assert_eq "simple dans double"     "$EOFQ \`\"'" "$(sh_err 'echo "abc'"'"'def')"
assert_eq "quote ouverte seule"    "$EOFQ \`\"'" "$(sh_err '"')"

echo ""
echo "═══ E. Code de sortie 2 ═══"

assert_eq "code : ls |"            "2" "$(sh_code 'ls |')"
assert_eq "code : ls >"            "2" "$(sh_code 'ls >')"
assert_eq "code : | ls"            "2" "$(sh_code '| ls')"
assert_eq "code : ls > >"          "2" "$(sh_code 'ls > >')"
assert_eq "code : echo \"abc"      "2" "$(sh_code 'echo "abc')"

echo ""
echo "═══ F. Non regression : le valide reste valide ═══"

assert_eq "commande simple"        "contenu" "$(sh_out 'cat f')"
assert_eq "redirection sortante"   "contenu" "$(sh_out 'cat f > g' 'cat g')"
assert_eq "redirection entrante"   "contenu" "$(sh_out 'cat < f')"
assert_eq "append"                 "contenu
contenu"                                     "$(sh_out 'cat f > h' 'cat f >> h' 'cat h')"
assert_eq "ligne vide"             "0" "$(sh_code '')"
assert_eq "ligne d espaces"        "0" "$(sh_code '   ')"

echo ""
echo "═══ G. Les operateurs entre quotes ne sont PAS des operateurs ═══"
# On teste ici une seule propriete : un operateur entre quotes est inerte.
# Il ne doit produire NI erreur de syntaxe, NI decoupage.
# Le retrait des quotes elles-memes appartient a l expander (issue #41),
# donc on verifie la presence du contenu, pas l egalite stricte.

assert_eq       "pipe entre quotes : pas d erreur"    "" "$(sh_err 'echo "a|b"')"
assert_eq       "pipe entre quotes : code 0"         "0" "$(sh_code 'echo "a|b"')"
assert_contains "pipe entre quotes : non decoupe" "a|b"  "$(sh_out 'echo "a|b"')"
assert_contains "chevron entre quotes"            "a>b"  "$(sh_out 'echo "a>b"')"
assert_contains "pipe final entre quotes"        "fin |" "$(sh_out 'echo "fin |"')"
assert_contains "apostrophe dans double"         "don't" "$(sh_out 'echo "don'"'"'t"')"
assert_eq       "quotes fermees ok"                  "0" "$(sh_code 'echo "abc def"')"

echo ""
echo "═══ H. Codes compares a bash ═══"

cmp_code() { assert_eq "vs bash : $1" "$( (cd "$SANDBOX" && bash -c "$1" >/dev/null 2>&1) && echo 0 || echo $?)" "$(sh_code "$1")"; }

cmp_code 'ls |'
cmp_code '| ls'
cmp_code 'ls >'
cmp_code 'ls > >'
cmp_code 'echo "abc'
cmp_code 'cat f'

summary
