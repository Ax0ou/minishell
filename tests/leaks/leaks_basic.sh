#!/bin/bash
# tests/leaks/leaks_basic.sh — Issue #48 (chasse aux leaks)
# Lance minishell sous valgrind sur un scénario représentatif.
# Cf docs/TESTS.md §9.
set -e
cd "$(dirname "$0")/../.."

if ! command -v valgrind > /dev/null; then
    echo "⚠ valgrind non installé (normal sur Mac)."
    echo "  Tester sur Linux ou via Docker avant le rendu final."
    exit 0
fi

if [ ! -x ./minishell ]; then
    echo "⚠ Pas de binaire ./minishell — skip."
    exit 0
fi

valgrind --leak-check=full \
         --show-leak-kinds=definite,indirect \
         --errors-for-leak-kinds=definite,indirect \
         --suppressions=tests/readline.supp \
         --error-exitcode=42 \
         --quiet \
         ./minishell <<'SHELL_CMDS'
echo hello
pwd
cd /tmp
pwd
export X=42
echo $X
unset X
exit 0
SHELL_CMDS

if [ $? -eq 42 ]; then
    echo "❌ LEAKS DÉTECTÉS"
    exit 1
fi
echo "✅ Pas de leaks (hors readline)"
