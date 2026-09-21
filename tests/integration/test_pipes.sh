#!/bin/bash
# tests/integration/test_pipes.sh
# Epic #80 — Tests pipelines (integration, contre le binaire reel)
# Base sur docs/TESTS.md §6.2, adapte a ce qui est reellement supporte :
# ';' n'est pas gere par ce minishell (cf docs/PARSING_RULES.md §5.1),
# donc les cas "cmd1; cmd2" du template deviennent des inputs multi-lignes
# (une commande par ligne, meme session shell). On utilise des chaines
# entre quotes simples avec un vrai saut de ligne dedans : a l'interieur
# de quotes simples $ est toujours litteral, aucune ambiguite d'echappement.

set -e
cd "$(dirname "$0")/../.."
source tests/lib.sh

echo "═══ Tests pipelines ═══"

echo "=== Pipes ==="
assert_same_as_bash "ls | wc -l"        'ls /tmp | wc -l'
assert_same_as_bash "3 pipes"           'ls /tmp | head -3 | wc -l'
assert_same_as_bash "echo | cat x4"     'echo hi | cat | cat | cat | cat'
assert_same_as_bash "5-stage chain"     'echo hi | cat | cat | cat | cat | cat'
assert_same_as_bash "grep in pipe"      'ls /tmp | grep -c a'
assert_same_as_bash "pipe + input redir" 'cat < Makefile | wc -l'
assert_eq "pipe with var" "hi" "$(run_shell 'export X=hi
echo $X | cat')"

echo "=== Pipes — exit codes ==="
assert_exit "true | true"   0 'true | true'
assert_exit "true | false"  1 'true | false'
assert_exit "false | true"  0 'false | true'
assert_exit "nope | true"   0 'nonexistent_cmd | true'
assert_exit "true | nope"   127 'true | nonexistent_cmd'
assert_exit "middle stage fails, last determines code" 0 \
	'true | nonexistent_cmd_xyz | true'
assert_exit "builtin piped through externals" 0 'pwd | wc -l | cat'

echo "=== Pipes — builtin dans pipe ==="
# cd dans un pipe ne change pas le cwd du shell (fork force par le pipe)
assert_eq "cd in pipe" "$(pwd)" "$(run_shell 'cd /tmp | true
pwd')"
assert_eq "export visible to piped cmd's env" "X=hi" "$(run_shell 'export X=hi
env | grep ^X= | cat')"
assert_eq "unset var expands empty in pipe" "" "$(run_shell 'unset NOPE_VAR
echo $NOPE_VAR | cat')"

summary
