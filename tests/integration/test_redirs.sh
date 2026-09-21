#!/bin/bash
# tests/integration/test_redirs.sh
# Epic #80 — Tests redirections IO (integration, contre le binaire reel)
# Base sur docs/TESTS.md §5.3, adapte a ce qui est reellement supporte :
# ';' n'est pas gere par ce minishell (cf docs/PARSING_RULES.md §5.1),
# donc "cmd1; cmd2" devient un input multi-lignes (une commande par ligne,
# meme session shell — les quotes doubles preservent un vrai saut de
# ligne litteral tout en interpolant $OUT).

set -e
cd "$(dirname "$0")/../.."
source tests/lib.sh

OUT=/tmp/minishell_test_redirs_$$

cleanup() { rm -f "$OUT" "$OUT.1" "$OUT.2"; }
trap cleanup EXIT

echo "=== Redirections — out ==="
run_shell "echo hi > $OUT" >/dev/null
assert_eq "echo > out" "hi" "$(cat "$OUT")"

rm -f "$OUT"
run_shell "echo a > $OUT
echo b >> $OUT" >/dev/null
assert_eq "echo >> out" $'a\nb' "$(cat "$OUT")"

rm -f "$OUT"
run_shell "echo new >> $OUT" >/dev/null
assert_eq ">> cree le fichier s'il n'existe pas" "new" "$(cat "$OUT")"

echo "=== Redirections — in ==="
echo "input content" > "$OUT"
assert_eq "cat < in" "input content" "$(run_shell "cat < $OUT")"

rm -f "$OUT.1" "$OUT.2"
echo "src data" > "$OUT.1"
assert_eq "cat < in > out (combines)" "src data" \
	"$(run_shell "cat < $OUT.1 > $OUT.2" >/dev/null; cat "$OUT.2")"

echo "=== Redirections — multiples ==="
rm -f "$OUT.1" "$OUT.2"
run_shell "echo X > $OUT.1 > $OUT.2" >/dev/null
assert_eq "multi out — file 1 existe vide" "" "$(cat "$OUT.1")"
assert_eq "multi out — file 2 contient" "X" "$(cat "$OUT.2")"

echo "input" > "$OUT"
assert_exit "< multiples, intermediaire manquant : rien ne s'execute" 1 \
	"cat < $OUT < /nope_intermediate_$$"
assert_eq "< intermediaire manquant : aucune sortie" "" \
	"$(run_shell "cat < $OUT < /nope_intermediate_$$")"

echo "=== Redirections — erreurs ==="
assert_exit "read nonexistent"  1 "cat < /nope_$$"
assert_exit "no perm to read"   1 "cat < /etc/shadow"
assert_eq "message d'erreur : fichier inexistant" \
	"minishell: /nope_msg_$$: No such file or directory" \
	"$(run_shell_full "cat < /nope_msg_$$" | tail -1)"

echo "=== Redirections — sur un builtin ==="
rm -f "$OUT"
run_shell "pwd > $OUT" >/dev/null
assert_eq "pwd > out (builtin redirige)" "$(pwd)" "$(cat "$OUT")"

summary
