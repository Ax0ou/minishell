# Signals — checklist manuelle

> À faire à 2 (un pilote, un coche). Lancer `./minishell` puis dérouler.
> Cf docs/EDGE_CASES.md §4 pour le détail attendu.

## A. Prompt vide
- [ ] **Ctrl-C** : newline, nouveau prompt, le shell ne quitte PAS
- [ ] Après Ctrl-C, `echo $?` affiche `130`
- [ ] **Ctrl-\\** : RIEN ne se passe (pas de quit, pas de message)
- [ ] **Ctrl-D** : le shell quitte proprement (équivalent `exit`)

## B. Prompt avec texte tapé (mais pas validé)
- [ ] Taper `bonjour` (sans Entrée) puis Ctrl-C : la ligne est effacée, nouveau prompt
- [ ] Le buffer est bien vide (Enter ne relance pas `bonjour`)

## C. Pendant qu'une commande tourne (lancer `cat` sans arg)
- [ ] **Ctrl-C** : tue cat, newline, nouveau prompt
- [ ] `echo $?` après Ctrl-C : `130`
- [ ] Relancer cat, **Ctrl-\\** : tue cat, "Quit (core dumped)", `echo $?` = `131`
- [ ] Relancer cat, **Ctrl-D** : cat lit EOF, finit normalement, `$?` = `0`

## D. Pendant un heredoc (`cat << END`)
- [ ] Taper quelques lignes, **Ctrl-C** : annule heredoc, prompt revient, `$?` = `130`
- [ ] Taper quelques lignes, **Ctrl-D** : warning sur stderr + exécute avec ce qui a été lu
- [ ] Pendant un heredoc, **Ctrl-\\** : RIEN (ignoré)

## E. Pendant un pipeline (`cat | cat | cat`)
- [ ] **Ctrl-C** : tous les `cat` sont tués, prompt revient, `$?` = `130`
- [ ] **Ctrl-\\** : tous tués, "Quit", `$?` = `131`

## F. Comparaison avec bash
Lancer `bash` dans un autre terminal, refaire chaque scénario, vérifier que l'output est identique (ou très proche : on tolère des petites différences de wording sur les messages signal).

---

**Quand toutes les cases sont cochées** → l'issue #47 (Tests signals manuels) peut être fermée.
