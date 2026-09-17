#!/bin/bash
# tests/integration/test_single_cmd.sh
# Issues #29 / #27 / #30 - Premier bout en bout
#
# Le runner enchaine lex -> parse -> exec sur chaque argument, en
# reutilisant run_line(), la fonction exacte qu'utilise main.c.
# Pas de readline, donc testable en CI et sans terminal.

set -e
cd "$(dirname "$0")/../.."
SKIP_BIN_CHECK=1
source tests/lib.sh

MSH="/tmp/minishell_e2e"

# pwd -P : sur macOS /tmp est un lien symbolique vers /private/tmp, et
# getcwd() renvoie toujours le chemin PHYSIQUE. On aligne les attentes
# du test sur ce que le noyau renvoie, pas sur ce qu on a tape.
TMP_P="$(cd /tmp && pwd -P)"
SANDBOX="$TMP_P/minishell_e2e_box"

# /bin/false et /bin/true n existent pas sur macOS (ils sont dans
# /usr/bin). On les resout au lieu de coder le chemin en dur.
FALSE_BIN="$(command -v false)"
TRUE_BIN="$(command -v true)"
trap 'rm -rf "$MSH" "$SANDBOX"' EXIT

make --no-print-directory -C libft >/dev/null
cc -Wall -Wextra -Werror \
	tests/integration/shell_runner.c \
	$(find src -name '*.c' -size +0 ! -name 'main.c') \
	libft/libft.a \
	-o "$MSH"

rm -rf "$SANDBOX" && mkdir -p "$SANDBOX"
touch "$SANDBOX/a.c" "$SANDBOX/b.c"

# sortie standard de notre shell
sh_out() { (cd "$SANDBOX" && "$MSH" "$@" 2>/dev/null); }
# code de sortie
sh_code() { local c; (cd "$SANDBOX" && "$MSH" "$@" >/dev/null 2>&1) && c=0 || c=$?; echo "$c"; }
# premiere ligne de stderr
sh_err() { (cd "$SANDBOX" && "$MSH" "$@" 2>&1 >/dev/null) | head -1; }
# code de sortie de bash sur la meme ligne
bash_code() { local c; (cd "$SANDBOX" && bash -c "$1" >/dev/null 2>&1) && c=0 || c=$?; echo "$c"; }

echo "═══ A. Commandes externes ═══"

assert_eq "ls liste le dossier"          "a.c
b.c"                                     "$(sh_out 'ls')"
assert_eq "ls avec argument"             "a.c
b.c"                                     "$(sh_out 'ls .')"
assert_eq "chemin absolu"                "via_absolu"  "$(sh_out '/bin/echo via_absolu')"
assert_eq "commande avec plusieurs args" "un deux"     "$(sh_out '/bin/echo un deux')"

echo ""
echo "═══ B. Builtins routes par le dispatch ═══"

assert_eq "echo"        "hello world"      "$(sh_out 'echo hello world')"
assert_eq "echo -n"     "sansnewline|END"  "$(sh_out 'echo -n sansnewline'; printf '|END')"
assert_eq "pwd"         "$SANDBOX"         "$(sh_out 'pwd')"
assert_eq "cd persiste" "$TMP_P"           "$(sh_out 'cd /tmp' 'pwd')"
assert_eq "cd - revient et affiche le chemin" "$SANDBOX" \
                                           "$(sh_out 'cd /tmp' 'cd -')"
assert_eq "cd - vs bash" \
"$(cd "$SANDBOX" && bash -c 'cd /tmp >/dev/null; cd -' 2>/dev/null | tail -1)" \
                                           "$(sh_out 'cd /tmp' 'cd -')"
assert_eq "env contient PATH" "1"          "$(sh_out 'env' | grep -c '^PATH=')"

echo ""
echo "═══ C. Redirections ═══"

assert_eq "redirection sortante" "a.c
b.c
out1"                                      "$(sh_out 'ls > out1' 'cat out1')"
assert_eq "append ajoute"        "un
deux"                                      "$(sh_out 'echo un > log1' 'echo deux >> log1' 'cat log1')"
assert_eq "redirection entrante" "un
deux"                                      "$(sh_out 'cat < log1')"
assert_eq "builtin redirige, fd restaure" "$SANDBOX"  "$(sh_out 'pwd > ou' 'cat ou')"
assert_eq "le prompt suivant n'ecrit plus dans le fichier" "apres" \
                                           "$(sh_out 'pwd > ou' 'echo apres')"

echo ""
echo "═══ D. Codes de sortie ═══"

assert_eq "commande ok"            "0"   "$(sh_code 'echo ok')"
assert_eq "commande introuvable"   "127" "$(sh_code 'nawak')"
assert_eq "repertoire executable"  "126" "$(sh_code '/tmp')"
assert_eq "false renvoie 1"        "1"   "$(sh_code "$FALSE_BIN")"
assert_eq "exit 42"                "42"  "$(sh_code 'exit 42')"
assert_eq "exit abc"               "2"   "$(sh_code 'exit abc')"
assert_eq "cd vers l'inexistant"   "1"   "$(sh_code 'cd /nexistepas')"
assert_eq "ligne vide"             "0"   "$(sh_code '')"
assert_eq "quote non fermee"       "2"   "$(sh_code 'echo "abc')"

echo ""
echo "═══ E. Messages d'erreur, format bash ═══"

assert_eq "command not found" \
"minishell: nawak: command not found"                      "$(sh_err 'nawak')"
assert_eq "cd sur un chemin absent" \
"minishell: cd: /nexistepas: No such file or directory"    "$(sh_err 'cd /nexistepas')"
assert_eq "repertoire" \
"minishell: /tmp: Is a directory"                          "$(sh_err '/tmp')"

echo ""
echo "═══ F. Codes de sortie compares a bash ═══"

cmp_code() { assert_eq "vs bash : $1" "$(bash_code "$1")" "$(sh_code "$1")"; }

cmp_code 'echo ok'
cmp_code 'nawak'
cmp_code "$FALSE_BIN"
cmp_code "$TRUE_BIN"
cmp_code 'exit 42'

# bash 3.2 (celui de macOS) sort avec 255 sur "exit abc".
# bash 5.x (Linux, machines de correction 42) sort avec 2.
# La reference est bash 5.x, donc la comparaison locale ne vaut que la.
if [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
	cmp_code 'exit abc'
else
	echo "  ~ ignore : vs bash exit abc (bash local ${BASH_VERSION%%(*} renvoie 255, bash 5.x renvoie 2)"
fi
cmp_code 'cd /nexistepas'
cmp_code 'ls'

summary
