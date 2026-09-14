#!/bin/bash
# tests/run_sprint.sh — Lance les tests pertinents pour un sprint donné.
# Usage : bash tests/run_sprint.sh 1     # → tests S1
#         bash tests/run_sprint.sh 2     # → tests S2
# Cf docs/PLAN.md §Critères de passage.
set -e

cd "$(dirname "$0")/.."

SPRINT="${1:-1}"

run_test() {
    local t="$1"
    if [ -e "$t" ]; then
        echo "→ $t"
        bash "$t"
    else
        echo "⚠ $t — fichier absent (pas encore écrit pour cette feature)"
    fi
}

case "$SPRINT" in
    1)
        echo "═══ Sprint 1 — Lexer + Env + Builtins simples ═══"
        run_test tests/unit/test_lexer.sh
        run_test tests/unit/test_env.sh
        run_test tests/unit/test_utils.sh
        run_test tests/integration/test_builtins.sh
        ;;
    2)
        echo "═══ Sprint 2 — Parser + Executor 1 commande + Redirections ═══"
        run_test tests/unit/test_parser.sh
        run_test tests/unit/test_executor.sh
        run_test tests/unit/test_redirections.sh
        run_test tests/integration/test_single_cmd.sh
        run_test tests/integration/test_redirs.sh
        ;;
    3)
        echo "═══ Sprint 3 — Expander + Pipes + Heredoc ═══"
        run_test tests/unit/test_expander.sh
        run_test tests/integration/test_pipes.sh
        run_test tests/integration/test_heredoc.sh
        ;;
    4)
        echo "═══ Sprint 4 — Polish + tout ═══"
        bash tests/run_all.sh
        ;;
    *)
        echo "Usage : $0 <1|2|3|4>"
        echo "  1 = lexer / env / builtins simples"
        echo "  2 = parser / single cmd / redirections"
        echo "  3 = expander / pipes / heredoc"
        echo "  4 = tout (alias de run_all.sh)"
        exit 1
        ;;
esac

echo ""
echo "✅ Tests du Sprint $SPRINT passés."
