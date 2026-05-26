#!/bin/bash
# tests/run_all.sh — Lance la suite complète (build + tests + leaks + norm).
# À utiliser : avant chaque PR vers dev/main.
# Si UN seul check échoue, le script exit 1.
set -e

# Aller à la racine du projet (où vit le Makefile)
cd "$(dirname "$0")/.."

step() {
    echo ""
    echo "═══════════════════════════════"
    echo "  $1"
    echo "═══════════════════════════════"
}

# ─── 1. Build ────────────────────────────────────────────────────────────
step "1. Build (make re)"
if [ ! -f Makefile ]; then
    echo "⚠ Pas de Makefile encore — skip (projet pas démarré)."
    echo "  Reviens lancer ce script quand le squelette code existe."
    exit 0
fi
make re

# ─── 2. Norminette ───────────────────────────────────────────────────────
step "2. Norminette"
if command -v norminette > /dev/null; then
    norminette src/ includes/ libft/ 2>&1 | tee /tmp/norm.log
    if grep -q "Error" /tmp/norm.log; then
        echo "❌ Norminette : des erreurs détectées."
        exit 1
    fi
else
    echo "⚠ norminette non installée — skip."
fi

# ─── 3. Tests unitaires ──────────────────────────────────────────────────
step "3. Unit tests"
for t in tests/unit/test_*.sh; do
    [ -e "$t" ] || continue
    echo "→ $t"
    bash "$t"
done

# ─── 4. Tests d'intégration ──────────────────────────────────────────────
step "4. Integration tests"
for t in tests/integration/test_*.sh; do
    [ -e "$t" ] || continue
    echo "→ $t"
    bash "$t"
done

# ─── 5. Tests system (vs bash) ───────────────────────────────────────────
step "5. System tests (vs bash)"
for t in tests/system/test_*.sh; do
    [ -e "$t" ] || continue
    echo "→ $t"
    bash "$t"
done

# ─── 6. Leaks (valgrind) ─────────────────────────────────────────────────
step "6. Memory leaks (valgrind)"
if command -v valgrind > /dev/null; then
    for t in tests/leaks/leaks_*.sh; do
        [ -e "$t" ] || continue
        echo "→ $t"
        bash "$t"
    done
else
    echo "⚠ valgrind non installé (normal sur Mac) — skip."
    echo "  Tester sur Linux ou via Docker avant le rendu."
fi

echo ""
echo "✅ Tous les tests automatiques passent."
echo "👉 Reste à faire à la main : signaux (tests/manual/SIGNALS.md) + testers externes."
