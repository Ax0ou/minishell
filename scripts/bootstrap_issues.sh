#!/bin/bash
# Bootstrap des issues GitHub pour le projet Minishell
# Prérequis : gh CLI authentifié, dans le dossier du repo
# Usage : ./scripts/bootstrap_issues.sh

set -e

# Création des labels
echo "→ Création des labels..."
gh label create "module:lexer"     --color "0E8A16" --force
gh label create "module:parser"    --color "0E8A16" --force
gh label create "module:expander"  --color "0E8A16" --force
gh label create "module:executor"  --color "C5DEF5" --force
gh label create "module:builtins"  --color "C5DEF5" --force
gh label create "module:signals"   --color "D93F0B" --force
gh label create "module:env"       --color "C5DEF5" --force
gh label create "module:utils"     --color "BFD4F2" --force
gh label create "module:tests"     --color "FBCA04" --force
gh label create "module:docs"      --color "FEF2C0" --force
gh label create "sprint:S1"        --color "5319E7" --force
gh label create "sprint:S2"        --color "5319E7" --force
gh label create "sprint:S3"        --color "5319E7" --force
gh label create "sprint:S4"        --color "5319E7" --force
gh label create "sprint:bonus"     --color "B60205" --force
gh label create "owner:axel"       --color "0052CC" --force
gh label create "owner:binome"     --color "FF9F1C" --force
gh label create "owner:pair"       --color "8B5CF6" --force

# Création des milestones
echo "→ Création des milestones..."
gh api repos/:owner/:repo/milestones -f title="J1 — Fondations" 2>/dev/null || true
gh api repos/:owner/:repo/milestones -f title="J2 — Exécution" 2>/dev/null || true
gh api repos/:owner/:repo/milestones -f title="J3 — Pipelines" 2>/dev/null || true
gh api repos/:owner/:repo/milestones -f title="J4 — Polish + Rendu" 2>/dev/null || true

# Helper pour créer une issue
issue() {
    local title="$1"
    local labels="$2"
    local milestone="$3"
    local body="$4"
    gh issue create \
        --title "$title" \
        --label "$labels" \
        --milestone "$milestone" \
        --body "$body"
}

# ─── SEMAINE 1 — Fondations (J1) ───────────────────────────────────────
echo "→ Sprint 1..."

issue "Setup repo (Makefile, libft, structure)" \
    "module:utils,sprint:S1,owner:pair" \
    "J1 — Fondations" \
    "Initialiser le squelette : Makefile, libft copiée, includes/, src/, tests/, .gitignore. cf. README.md pour la structure cible."

issue "Définir les structures de données (t_token, t_cmd, t_pipeline, t_redir, t_env)" \
    "module:utils,sprint:S1,owner:pair" \
    "J1 — Fondations" \
    "Geler les structures dans includes/minishell.h. cf. docs/ARCHITECTURE.md."

issue "Squelette main.c avec boucle readline + free" \
    "module:utils,sprint:S1,owner:pair" \
    "J1 — Fondations" \
    "Boucle REPL minimale qui readline, affiche la ligne, free, recommence."

issue "Configurer GitHub Projects board + automations" \
    "module:docs,sprint:S1,owner:axel" \
    "J1 — Fondations" \
    "Créer le board, ajouter les colonnes Backlog/Sprint/In Progress/In Review/Done, activer les automations."

issue "lexer: tokenisation basique (whitespace, mots)" \
    "module:lexer,sprint:S1,owner:axel" \
    "J1 — Fondations" \
    "src/lexer/tokenize.c — découpage par whitespace, création de tokens WORD."

issue "lexer: gestion des quotes ('...' et \"...\")" \
    "module:lexer,sprint:S1,owner:axel" \
    "J1 — Fondations" \
    "src/lexer/quotes.c — détection, marquage du type, gestion non fermées."

issue "lexer: détection des opérateurs (|, <, >, <<, >>)" \
    "module:lexer,sprint:S1,owner:axel" \
    "J1 — Fondations" \
    "src/lexer/operators.c — création des tokens PIPE, REDIR_*, HEREDOC, APPEND."

issue "builtin: echo (avec option -n)" \
    "module:builtins,sprint:S1,owner:axel" \
    "J1 — Fondations" \
    "src/builtins/echo.c — gère -n et plusieurs -n."

issue "builtin: pwd" \
    "module:builtins,sprint:S1,owner:axel" \
    "J1 — Fondations" \
    "src/builtins/pwd.c — getcwd + ft_putendl."

issue "builtin: exit (gestion argc + valeur de retour)" \
    "module:builtins,sprint:S1,owner:axel" \
    "J1 — Fondations" \
    "src/builtins/exit.c — exit, exit N, exit abc (erreur), exit a b (too many args)."

issue "Tests unitaires lexer" \
    "module:tests,sprint:S1,owner:axel" \
    "J1 — Fondations" \
    "tests/unit/test_lexer.sh — couvre les cas de docs/TESTS.md."

issue "env: init depuis envp" \
    "module:env,sprint:S1,owner:binome" \
    "J1 — Fondations" \
    "src/env/env_init.c — copie envp dans linked list t_env."

issue "env: get/set/unset API" \
    "module:env,sprint:S1,owner:binome" \
    "J1 — Fondations" \
    "src/env/env_get_set.c — lookup, update, ajout, suppression."

issue "env: conversion en array pour execve" \
    "module:env,sprint:S1,owner:binome" \
    "J1 — Fondations" \
    "src/env/env_to_array.c — t_env → char **."

issue "builtin: env (sans options)" \
    "module:builtins,sprint:S1,owner:binome" \
    "J1 — Fondations" \
    "src/builtins/env.c — affiche les variables exportées."

issue "utils: error.c (style bash)" \
    "module:utils,sprint:S1,owner:binome" \
    "J1 — Fondations" \
    "src/utils/error.c — print_error(cmd, arg, msg) sur stderr."

issue "utils: cleanup.c (free de toutes les structures)" \
    "module:utils,sprint:S1,owner:binome" \
    "J1 — Fondations" \
    "src/utils/cleanup.c — free_tokens, free_ast, free_env."

issue "Tests unitaires env" \
    "module:tests,sprint:S1,owner:binome" \
    "J1 — Fondations" \
    "tests/unit/test_env.sh — get/set/unset, conversion en array."

# ─── SEMAINE 2 — Exécution (J2) ────────────────────────────────────────
echo "→ Sprint 2..."

issue "parser: token list → t_cmd list" \
    "module:parser,sprint:S2,owner:axel" \
    "J2 — Exécution" \
    "src/parser/parse_tokens.c — construction du pipeline."

issue "parser: attachement des redirections aux commandes" \
    "module:parser,sprint:S2,owner:axel" \
    "J2 — Exécution" \
    "src/parser/parse_redirs.c."

issue "parser: validation syntaxique (| en début, > sans cible, etc.)" \
    "module:parser,sprint:S2,owner:axel" \
    "J2 — Exécution" \
    "src/parser/syntax_check.c — messages d'erreur style bash."

issue "Tests unitaires parser" \
    "module:tests,sprint:S2,owner:axel" \
    "J2 — Exécution" \
    "tests/unit/test_parser.sh."

issue "executor: résolution PATH" \
    "module:executor,sprint:S2,owner:binome" \
    "J2 — Exécution" \
    "src/executor/resolve_path.c — split PATH, access X_OK."

issue "executor: exec d'une commande externe (fork + execve + wait)" \
    "module:executor,sprint:S2,owner:binome" \
    "J2 — Exécution" \
    "src/executor/exec_single.c."

issue "executor: redirections IO (<, >, >>)" \
    "module:executor,sprint:S2,owner:binome" \
    "J2 — Exécution" \
    "src/executor/redirections.c — open + dup2."

issue "builtin: cd (avec update PWD/OLDPWD)" \
    "module:builtins,sprint:S2,owner:binome" \
    "J2 — Exécution" \
    "src/builtins/cd.c — chdir + mise à jour env."

issue "executor: dispatch builtin vs externe" \
    "module:executor,sprint:S2,owner:binome" \
    "J2 — Exécution" \
    "src/executor/dispatch.c — si single + builtin → parent ; sinon → fork."

issue "Tests intégration mono-commande" \
    "module:tests,sprint:S2,owner:binome" \
    "J2 — Exécution" \
    "tests/integration/test_single.sh."

issue "main.c : chaîner lex → parse → exec" \
    "module:utils,sprint:S2,owner:pair" \
    "J2 — Exécution" \
    "Branchement final dans la boucle REPL."

issue "Premier end-to-end : ls -la > out.txt" \
    "module:tests,sprint:S2,owner:pair" \
    "J2 — Exécution" \
    "Test que tout fonctionne ensemble."

# ─── SEMAINE 3 — Pipelines + Expansion (J3) ────────────────────────────
echo "→ Sprint 3..."

issue "expander: \$VAR lookup dans env" \
    "module:expander,sprint:S3,owner:axel" \
    "J3 — Pipelines" \
    "src/expander/expand_vars.c."

issue "expander: \$? (exit status)" \
    "module:expander,sprint:S3,owner:axel" \
    "J3 — Pipelines" \
    "src/expander/expand_exit.c."

issue "expander: gestion expansion dans \"...\" vs '...'" \
    "module:expander,sprint:S3,owner:axel" \
    "J3 — Pipelines" \
    "src/expander/expand_in_quotes.c — pas d'expansion en single quote."

issue "expander: strip des quotes après expansion" \
    "module:expander,sprint:S3,owner:axel" \
    "J3 — Pipelines" \
    "src/expander/strip_quotes.c."

issue "Tests unitaires expander" \
    "module:tests,sprint:S3,owner:axel" \
    "J3 — Pipelines" \
    "tests/unit/test_expander.sh."

issue "executor: pipelines multi-commandes" \
    "module:executor,sprint:S3,owner:binome" \
    "J3 — Pipelines" \
    "src/executor/exec_pipeline.c — boucle fork + pipe, close des fds."

issue "executor: heredoc (<<)" \
    "module:executor,sprint:S3,owner:binome" \
    "J3 — Pipelines" \
    "src/executor/heredoc.c — read jusqu'au délimiteur, expansion sauf si délim quoté."

issue "builtin: export (avec/sans args, tri)" \
    "module:builtins,sprint:S3,owner:binome" \
    "J3 — Pipelines" \
    "src/builtins/export.c — sans arg : tri ASCII ; avec : KEY=VAL."

issue "builtin: unset" \
    "module:builtins,sprint:S3,owner:binome" \
    "J3 — Pipelines" \
    "src/builtins/unset.c."

issue "Tests intégration pipes + redirs" \
    "module:tests,sprint:S3,owner:binome" \
    "J3 — Pipelines" \
    "tests/integration/test_pipes.sh, test_redirs.sh, test_heredoc.sh."

issue "Intégration expander dans la pipeline" \
    "module:expander,sprint:S3,owner:pair" \
    "J3 — Pipelines" \
    "Connecter expander entre parser et executor."

issue "Edge cases : export+expansion, heredoc+pipe" \
    "module:tests,sprint:S3,owner:pair" \
    "J3 — Pipelines" \
    "Validation des combinaisons critiques."

# ─── SEMAINE 4 — Polish + Rendu (J4) ───────────────────────────────────
echo "→ Sprint 4..."

issue "signals: handlers SIGINT / SIGQUIT" \
    "module:signals,sprint:S4,owner:pair" \
    "J4 — Polish + Rendu" \
    "src/signals/handlers.c — handlers pour chaque mode (prompt/exec/heredoc)."

issue "signals: setup avec sigaction" \
    "module:signals,sprint:S4,owner:pair" \
    "J4 — Polish + Rendu" \
    "src/signals/setup.c."

issue "signals: variable globale g_signal (unique, int)" \
    "module:signals,sprint:S4,owner:pair" \
    "J4 — Polish + Rendu" \
    "Une SEULE variable globale, stocke uniquement le numéro de signal."

issue "Tests manuels signals" \
    "module:tests,sprint:S4,owner:pair" \
    "J4 — Polish + Rendu" \
    "tests/manual/SIGNALS.md — checklist à passer en mode interactif."

issue "Chasse aux leaks (valgrind sur tous les scénarios)" \
    "module:tests,sprint:S4,owner:pair" \
    "J4 — Polish + Rendu" \
    "valgrind avec suppressions readline. Tolérance : 0 leak côté nous."

issue "Norminette : 0 erreur sur src/ et includes/" \
    "module:utils,sprint:S4,owner:pair" \
    "J4 — Polish + Rendu" \
    "norminette src/ includes/."

issue "Test vs bash : script comparatif" \
    "module:tests,sprint:S4,owner:pair" \
    "J4 — Polish + Rendu" \
    "tests/system/test_vs_bash.sh — compare outputs sur ~30 scénarios."

issue "50 cas d'edge cases (cf. TESTS.md)" \
    "module:tests,sprint:S4,owner:pair" \
    "J4 — Polish + Rendu" \
    "Couvrir toute la liste des cas de docs/TESTS.md."

issue "README final (conforme au chapitre V du sujet)" \
    "module:docs,sprint:S4,owner:axel" \
    "J4 — Polish + Rendu" \
    "Login italique + Description + Instructions + Resources + section IA."

issue "Démo croisée binôme (chacun explique l'autre moitié)" \
    "module:docs,sprint:S4,owner:pair" \
    "J4 — Polish + Rendu" \
    "Préparation défense : chacun doit pouvoir justifier le code de l'autre."

# ─── BONUS (si temps) ──────────────────────────────────────────────────
echo "→ Bonus..."

issue "Bonus: && et || avec parenthèses" \
    "module:parser,sprint:bonus,owner:pair" \
    "J4 — Polish + Rendu" \
    "À traiter dans le parser + executor. Voir Chapitre VI du sujet."

issue "Bonus: wildcards * dans le cwd" \
    "module:expander,sprint:bonus,owner:pair" \
    "J4 — Polish + Rendu" \
    "Expansion glob, opendir/readdir."

issue "Bonus: tests dédiés" \
    "module:tests,sprint:bonus,owner:pair" \
    "J4 — Polish + Rendu" \
    "tests/integration/test_bonus.sh."

echo ""
echo "✅ Bootstrap terminé. Va sur le board GitHub Projects pour assigner les issues."
echo "   Tu peux maintenant filtrer par : sprint:S1, owner:axel, module:lexer, etc."
