#!/bin/bash
# tests/unit/test_quotes.sh
# Epic #78 - quotes et expansion de bout en bout
#
# Chaque cas lance la meme ligne dans NOTRE shell (via shell_runner, sans
# readline) et dans bash, puis compare les sorties. On ne code donc aucun
# resultat en dur : bash est la reference, comme le demande le sujet.
#
# Usage : bash tests/unit/test_quotes.sh

set -e
cd "$(dirname "$0")/../.."
SKIP_BIN_CHECK=1
source tests/lib.sh

MSH="/tmp/minishell_quotes_test"
trap 'rm -f "$MSH"' EXIT

make --no-print-directory -C libft >/dev/null
cc -Wall -Wextra -Werror \
	tests/integration/shell_runner.c \
	$(find src -name '*.c' -size +0 ! -name 'main.c') \
	libft/libft.a -lreadline \
	-o "$MSH"

# Variable connue des deux shells, pour ne pas dependre de $USER.
export MSH_T=bonjour
FALSE_BIN="$(command -v false)"

# mine "ligne1" "ligne2"... : chaque argument est une ligne de NOTRE shell
mine() { "$MSH" "$@" 2>/dev/null || true; }
# ref "ligne1" "ligne2"... : les memes lignes, dans bash
ref() { local IFS=$'\n'; bash -c "$*" 2>/dev/null || true; }
# same "nom" "ligne1" ... : compare les deux sorties
same() { local name="$1"; shift; assert_eq "$name" "$(ref "$@")" "$(mine "$@")"; }

echo "═══ A. Quotes seules ═══"

same "doubles, espace garde"          'echo "a   b"'
same "simples, espace garde"          "echo 'a   b'"
same "trois morceaux colles"          "echo \"a\"'b'c"
same "argument vide entre doubles"    'echo "" fin'
same "argument vide entre simples"    "echo '' fin"
same "apostrophe dans des doubles"    "echo \"l'ami\""
same "doubles dans des simples"       "echo '\"cite\"'"
same "operateurs proteges"            "echo 'a | b > c'"

echo ""
echo "═══ B. Expansion et quotes ═══"

same "variable nue"                   'echo $MSH_T'
same "entre doubles : etendue"        'echo "$MSH_T"'
same "entre simples : pas etendue"    "echo '\$MSH_T'"
same "simples dans doubles : etendue" "echo \"'\$MSH_T'\""
same "doubles dans simples : non"     "echo '\"\$MSH_T\"'"
same "le - arrete le nom"             'echo $MSH_T-suite'
same "deux variables collees"         'echo $MSH_T$MSH_T'
same "melange dans un meme mot"       "echo x'\$MSH_T'y\"\$MSH_T\"z"

echo ""
echo "═══ C. Variables vides ou absentes ═══"

same "absente au milieu d'un mot"     'echo x$NOPE-y'
same "absente seule : mot supprime"   'echo $NOPE fin'
same "absente entre doubles : garde"  'echo "$NOPE" fin'
same "dollar seul"                    'echo $'
same "dollar seul entre doubles"      'echo "$"'
same "dollar suivi d'un chiffre"      'echo $1abc'

echo ""
echo "═══ D. \$? ═══"

same "\$? au demarrage"               'echo $?'
same "\$? apres une commande introuvable" 'nawak' 'echo $?'
same "\$? apres un echec (false)"     "$FALSE_BIN" 'echo $?'
same "\$? ecrase par le echo precedent" 'nawak' 'echo $?' 'echo $?'
same "\$?\$? colles"                  'echo $?$?'

echo ""
echo "═══ E. export et expansion ═══"

same "export puis lecture"            'export A=1' 'echo $A'
same "valeur venant d'une variable"   'export A=1' 'export B="$A"' 'echo $B'
same "valeur protegee par ' '"        'export A=1' "export C='\$A'" 'echo $C'
same "valeur avec espaces, citee"     'export A="x y"' 'echo "$A"'
same "les trois formes d'un coup"     'export A=salut' "echo \"\$A\" '\$A' \$A"
same "valeur vide"                    'export A=' 'echo "[$A]"'

summary
