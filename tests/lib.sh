#!/bin/bash
# tests/lib.sh — Helpers communs, sourcés par tous les scripts de test.
# Cf docs/TESTS.md §3 pour la documentation complète.

# ─── Configuration ───────────────────────────────────────────────────────
SHELL_BIN="${SHELL_BIN:-./minishell}"
BASH_BIN="${BASH_BIN:-bash}"

# Chemins readline : indispensables sur macOS (libedit n'a pas
# rl_replace_line), sans effet sous Linux ou RL_CFLAGS reste vide.
RL_CFLAGS=""
RL_LDFLAGS=""
if [ "$(uname)" = "Darwin" ]; then
	RL_PREFIX="$(brew --prefix readline 2>/dev/null)"
	if [ -n "$RL_PREFIX" ]; then
		RL_CFLAGS="-I$RL_PREFIX/include"
		RL_LDFLAGS="-L$RL_PREFIX/lib"
	fi
fi
export RL_CFLAGS RL_LDFLAGS

# Compteurs (réinitialisés à chaque source)
PASS=0
FAIL=0
FAILED_TESTS=()

# Couleurs (désactivables avec NO_COLOR=1)
if [ -z "$NO_COLOR" ]; then
    C_GREEN='\033[0;32m'
    C_RED='\033[0;31m'
    C_YELLOW='\033[0;33m'
    C_RESET='\033[0m'
else
    C_GREEN=''
    C_RED=''
    C_YELLOW=''
    C_RESET=''
fi

# ─── Exécution ───────────────────────────────────────────────────────────

# readline() imprime le prompt (et, en pipe, l'echo la ligne lue) meme
# quand stdin n'est pas un tty. On filtre ce bruit ("minishell$ ...") pour
# ne garder que la vraie sortie de la commande, sinon toute comparaison
# avec bash (qui n'imprime pas de prompt en non-interactif) echoue a tort.
_strip_prompt() {
    # grep -v sort en erreur (1) s'il ne reste aucune ligne (ex: une
    # commande dont toute la sortie est redirigee vers un fichier). Sous
    # 'set -e' cote appelant, ca tuerait le script a tort : on avale.
    grep -v '^minishell\$ ' || true
}

# Pipe une commande dans minishell, retourne stdout
run_shell() {
    echo "$1" | $SHELL_BIN 2>/dev/null | _strip_prompt
}

# Idem mais capture aussi stderr + retourne l'exit code
run_shell_full() {
    local out
    out=$(echo "$1" | $SHELL_BIN 2>&1)
    local code=$?
    out=$(echo "$out" | _strip_prompt)
    echo "$out"
    return $code
}

# Pipe dans bash --posix pour comparer
run_bash() {
    echo "$1" | $BASH_BIN --posix 2>/dev/null
}

# ─── Assertions ──────────────────────────────────────────────────────────

# assert_eq "nom du test" "valeur_attendue" "valeur_obtenue"
assert_eq() {
    local name="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        printf "  ${C_GREEN}✓${C_RESET} %s\n" "$name"
        PASS=$((PASS+1))
    else
        printf "  ${C_RED}✗${C_RESET} %s\n" "$name"
        printf "    expected: %q\n" "$expected"
        printf "    actual:   %q\n" "$actual"
        FAIL=$((FAIL+1))
        FAILED_TESTS+=("$name")
    fi
}

# assert_exit "nom" code_attendu "commande"
# Lance la commande dans minishell puis fait echo $? pour récupérer le code
assert_exit() {
    local name="$1" expected_code="$2" cmd="$3"
    local out
    out=$(printf '%s\necho $?\n' "$cmd" | $SHELL_BIN 2>/dev/null | _strip_prompt)
    local actual_code
    actual_code=$(echo "$out" | tail -1)
    if [ "$expected_code" = "$actual_code" ]; then
        printf "  ${C_GREEN}✓${C_RESET} %s (exit %s)\n" "$name" "$expected_code"
        PASS=$((PASS+1))
    else
        printf "  ${C_RED}✗${C_RESET} %s — exit code\n" "$name"
        printf "    expected: %s\n" "$expected_code"
        printf "    actual:   %s\n" "$actual_code"
        FAIL=$((FAIL+1))
        FAILED_TESTS+=("$name")
    fi
}

# assert_same_as_bash "nom" "commande" — compare outputs minishell vs bash
assert_same_as_bash() {
    local name="$1" cmd="$2"
    local mini bash_out
    mini=$(run_shell "$cmd")
    bash_out=$(run_bash "$cmd")
    assert_eq "$name" "$bash_out" "$mini"
}

# assert_contains "nom" "needle" "haystack" — vérifie qu'une string est présente
assert_contains() {
    local name="$1" needle="$2" haystack="$3"
    if echo "$haystack" | grep -qF "$needle"; then
        printf "  ${C_GREEN}✓${C_RESET} %s\n" "$name"
        PASS=$((PASS+1))
    else
        printf "  ${C_RED}✗${C_RESET} %s — '%s' not in output\n" "$name" "$needle"
        FAIL=$((FAIL+1))
        FAILED_TESTS+=("$name")
    fi
}

# ─── Récapitulatif ───────────────────────────────────────────────────────

summary() {
    echo ""
    printf "─────────────────────────────\n"
    printf "Total: %d — Pass: ${C_GREEN}%d${C_RESET} — Fail: ${C_RED}%d${C_RESET}\n" \
        $((PASS+FAIL)) $PASS $FAIL
    if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
        printf "${C_RED}Failed tests:${C_RESET}\n"
        for t in "${FAILED_TESTS[@]}"; do
            printf "  - %s\n" "$t"
        done
        exit 1
    fi
    exit 0
}

# ─── Vérification du binaire ─────────────────────────────────────────────
# Si appelé directement (pas sourcé), on affiche un message d'aide.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    echo "tests/lib.sh — ce fichier doit être sourcé, pas exécuté."
    echo "Usage : source tests/lib.sh"
    exit 1
fi

# Avertissement si pas de binaire (sauf si SKIP_BIN_CHECK=1, utile en dev)
if [ -z "$SKIP_BIN_CHECK" ] && [ ! -x "$SHELL_BIN" ]; then
    printf "${C_YELLOW}⚠ Pas de binaire $SHELL_BIN — les tests vont échouer.${C_RESET}\n"
    printf "  Lance 'make' à la racine du projet, ou exporte SHELL_BIN=/chemin/minishell\n"
fi
