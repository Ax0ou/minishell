#!/bin/bash
# tests/leaks/leaks_basic.sh — chasse aux leaks (issue #48)
# Lance minishell sous valgrind sur plusieurs scenarios representatifs.
# Un leak "definitely lost" ou "indirectly lost" = echec.
# Les leaks de readline sont filtres par tests/readline.supp (le sujet 42
# autorise explicitement les leaks de cette lib externe).
# Cf docs/TESTS.md §9.

cd "$(dirname "$0")/../.."

SHELL_BIN="${SHELL_BIN:-./minishell}"
SUPP="tests/readline.supp"
LOGDIR="${LOGDIR:-/tmp/minishell_leaks}"

if ! command -v valgrind > /dev/null; then
	echo "⚠ valgrind non installe (normal sur Mac)."
	echo "  Sur Mac : make && leaks --atExit -- ./minishell"
	echo "  Sur Linux / dans la CI : ce script tourne pour de vrai."
	exit 0
fi

if [ ! -x "$SHELL_BIN" ]; then
	echo "⚠ Pas de binaire $SHELL_BIN — lance 'make' d'abord."
	exit 1
fi

mkdir -p "$LOGDIR"
rm -f "$LOGDIR"/*.log
PASS=0
FAIL=0
FAILED=()

# run_case "nom" "lignes envoyees a minishell"
run_case() {
	local name="$1" input="$2"
	local log="$LOGDIR/${name// /_}.log"
	local code

	printf '%b' "$input" | valgrind \
		--leak-check=full \
		--show-leak-kinds=definite,indirect \
		--errors-for-leak-kinds=definite,indirect \
		--suppressions="$SUPP" \
		--error-exitcode=42 \
		--log-file="$log" \
		"$SHELL_BIN" > /dev/null 2>&1
	code=$?

	if [ "$code" -eq 42 ]; then
		printf '  \033[0;31m✗\033[0m %s — LEAK\n' "$name"
		grep -E "definitely lost|indirectly lost" "$log" | sed 's/^/      /'
		echo "      log complet : $log"
		FAIL=$((FAIL + 1))
		FAILED+=("$name")
	else
		printf '  \033[0;32m✓\033[0m %s\n' "$name"
		PASS=$((PASS + 1))
	fi
}

echo "=== Leaks (valgrind) ==="

run_case "builtins"        'echo hello\npwd\ncd /tmp\npwd\nexport X=42\necho $X\nenv\nunset X\nexit 0\n'
run_case "commandes ext"   '/bin/ls\n/bin/echo hi\nexit 0\n'
run_case "cmd introuvable" 'nawak_pas_une_commande\nexit 0\n'
run_case "pipes"           'echo a | cat | cat\nls | wc -l\nexit 0\n'
run_case "redirections"    'echo hi > /tmp/msh_leak.txt\ncat < /tmp/msh_leak.txt\necho bis >> /tmp/msh_leak.txt\nexit 0\n'
run_case "heredoc"         'cat << EOF\nligne1\nligne2\nEOF\nexit 0\n'
run_case "quotes"          "echo 'simple'\necho \"double \$USER\"\necho \"\"\necho ''\nexit 0\n"
run_case "expansions"      'export A=1\necho $A$A\necho $?\necho $PAS_DEFINI\necho "$A"\nexit 0\n'
run_case "erreurs syntaxe" 'echo |\n| echo\necho >\necho "pas ferme\nexit 0\n'
run_case "melange"         'export V=x\necho $V | cat > /tmp/msh_leak2.txt\ncat < /tmp/msh_leak2.txt | wc -c\nunset V\nexit 0\n'
run_case "exit sans arg"   'echo avant\nexit\n'
run_case "ctrl-d (EOF)"    'echo avant\n'

rm -f /tmp/msh_leak.txt /tmp/msh_leak2.txt

echo ""
echo "─────────────────────────────"
printf "Total: %d — Pass: \033[0;32m%d\033[0m — Fail: \033[0;31m%d\033[0m\n" \
	$((PASS + FAIL)) $PASS $FAIL
if [ ${#FAILED[@]} -gt 0 ]; then
	printf "\033[0;31mScenarios qui leakent :\033[0m\n"
	for t in "${FAILED[@]}"; do
		printf "  - %s\n" "$t"
	done
	exit 1
fi
echo "✅ Aucun leak (hors readline)"
exit 0
