# Planning — Minishell (4 semaines)

> Rythme cible : **20-25h/sem/personne** = ~80-100h/personne au total.
> Toutes les tâches sont à créer comme **issues GitHub** liées au board "Minishell".
> Chaque jalon (J1-J4) = un milestone GitHub.

## Vue d'ensemble

| Semaine | Jalon | Livrable | État final              |
|---------|-------|----------|-------------------------|
| S1      | J1    | Setup + Lexer + Env + Builtins simples | `echo`, `pwd`, `env`, `exit` marchent |
| S2      | J2    | Parser + Executor 1 commande | `ls -la`, `cat file`, redirections simples |
| S3      | J3    | Expander + Pipes + Heredoc | Pipelines complexes, `$VAR`, `<<` |
| S4      | J4    | Signals + Edge cases + README + bonus | Projet rendable, tests OK |

---

## Semaine 1 — Fondations (J1)

**Objectif** : poser l'archi, geler les structures, livrer les briques sans dépendance.

### Tâches communes (pair, lundi-mardi)
- [ ] **#1** Setup repo (Makefile, libft, includes, .gitignore, structure dossiers)
- [ ] **#2** Définir les structures `t_token`, `t_cmd`, `t_pipeline`, `t_redir`, `t_env` dans `includes/minishell.h`
- [ ] **#3** Squelette `main.c` avec boucle readline + free
- [ ] **#4** Configurer le board GitHub Projects + templates issues/PR

### Personne A (mercredi-dimanche)
- [ ] **#5** `lexer/tokenize.c` — découpage par whitespace, tokens basiques
- [ ] **#6** `lexer/quotes.c` — gestion `'...'` et `"..."`, marquage du type
- [ ] **#7** `lexer/operators.c` — détection `|`, `<`, `>`, `<<`, `>>`
- [ ] **#8** `builtins/echo.c` — avec option `-n`
- [ ] **#9** `builtins/pwd.c`
- [ ] **#10** `builtins/exit.c` — argc, valeur de retour, erreurs
- [ ] **#11** Tests unitaires lexer (`tests/unit/test_lexer.sh`)

### Personne B (mercredi-dimanche)
- [ ] **#12** `env/env_init.c` — copie de `envp` dans linked list
- [ ] **#13** `env/env_get_set.c` — API lookup/modification
- [ ] **#14** `env/env_to_array.c` — conversion pour `execve`
- [ ] **#15** `builtins/env.c` — affichage
- [ ] **#16** `utils/error.c` — `print_error(cmd, arg, msg)` style bash
- [ ] **#17** `utils/cleanup.c` — free de toutes les structures
- [ ] **#18** Tests unitaires env (`tests/unit/test_env.sh`)

### Critère de passage J1 (tests obligatoires)
> **On ne passe à S2 qu'une fois TOUS ces tests verts.** Voir [TESTS.md §4](TESTS.md).
- [ ] `make` compile sans warning + sans relink
- [ ] `./minishell` lance un prompt, lit une ligne, free, recommence
- [ ] `bash tests/run_sprint.sh 1` passe (lexer ≥ 16 cas + env ≥ 10 cas + builtins ≥ 15 cas)
- [ ] `echo hello`, `pwd`, `env`, `exit 42` fonctionnent (`$?` cohérent)
- [ ] `norminette src/ includes/` zéro erreur
- [ ] `valgrind ./minishell <<< "echo hi"` zéro leak (hors readline)
- [ ] Structures `t_token`, `t_cmd`, `t_pipeline`, `t_redir`, `t_env`, `t_shell` figées dans `includes/minishell.h`

---

## Semaine 2 — Exécution de base (J2)

**Objectif** : faire tourner UNE commande externe avec redirections IO.

### Personne A
- [ ] **#19** `parser/parse_tokens.c` — token list → t_cmd list
- [ ] **#20** `parser/parse_redirs.c` — attache redirections à la commande
- [ ] **#21** `parser/syntax_check.c` — détection erreurs (`|` en début, `>>` sans cible)
- [ ] **#22** Tests parser (`tests/unit/test_parser.sh`)

### Personne B
- [ ] **#23** `executor/resolve_path.c` — résolution PATH/relatif/absolu
- [ ] **#24** `executor/exec_single.c` — fork + execve + wait pour 1 commande
- [ ] **#25** `executor/redirections.c` — open + dup2 pour `<`, `>`, `>>`
- [ ] **#26** `builtins/cd.c` — chdir + update `PWD`/`OLDPWD`
- [ ] **#27** `executor/dispatch.c` — décide builtin (parent) vs externe (fork)
- [ ] **#28** Tests exec mono-commande (`tests/integration/test_single.sh`)

### Pair-programming (vendredi)
- [ ] **#29** Connecter `main.c` au pipeline complet : `lex → parse → exec`
- [ ] **#30** Premier vrai test end-to-end : `ls -la > out.txt`

### Critère de passage J2 (tests obligatoires)
> Voir [TESTS.md §5](TESTS.md). Aucun passage à S3 sans validation.
- [ ] `bash tests/run_sprint.sh 2` passe (parser ≥ 15 cas + single_cmd ≥ 10 + redirs ≥ 10)
- [ ] `ls`, `cat Makefile`, `/bin/echo hi` tournent
- [ ] `cat < file`, `ls > out`, `cat >> out` fonctionnent
- [ ] `cd ..` puis `pwd` cohérents (avec mise à jour `PWD`/`OLDPWD`)
- [ ] `echo $?` après une cmd refletè le bon code (127 pour cnf, 126 pour permdenied, 1 pour erreur, 0 pour OK)
- [ ] Le dispatcher décide bien builtin-parent vs builtin-fork vs externe-fork
- [ ] Erreurs (cnf, redir échouée) écrites sur stderr avec préfixe `minishell:`
- [ ] Aucun leak ni fd qui traîne

---

## Semaine 3 — Pipelines + Expansion (J3)

**Objectif** : pipelines multi-commandes, expansion complète, heredoc.

### Personne A
- [ ] **#31** `expander/expand_vars.c` — `$VAR` lookup dans env
- [ ] **#32** `expander/expand_exit.c` — `$?`
- [ ] **#33** `expander/expand_in_quotes.c` — gestion expansion dans `"..."`, pas dans `'...'`
- [ ] **#34** `expander/strip_quotes.c` — enlever les quotes après expansion
- [ ] **#35** Tests expander (`tests/unit/test_expander.sh`)

### Personne B
- [ ] **#36** `executor/exec_pipeline.c` — boucle fork + pipe pour N commandes
- [ ] **#37** `executor/heredoc.c` — lit jusqu'au délimiteur, écrit dans pipe ou tmpfile
- [ ] **#38** `builtins/export.c` — sans args (tri) + `KEY=VAL`
- [ ] **#39** `builtins/unset.c`
- [ ] **#40** Tests pipelines (`tests/integration/test_pipes.sh`)

### Pair-programming (samedi)
- [ ] **#41** Intégration expander dans la pipeline complète
- [ ] **#42** Edge case : `export FOO=bar` puis `echo $FOO`
- [ ] **#43** Edge case : `cat << EOF | grep x`

### Critère de passage J3 (tests obligatoires)
> Voir [TESTS.md §6](TESTS.md). À ce stade, le shell doit être **utilisable au quotidien**.
- [ ] `bash tests/run_sprint.sh 3` passe (expander ≥ 15 + pipes ≥ 15 + heredoc ≥ 10)
- [ ] `ls -la | grep .c | wc -l` fonctionne
- [ ] `echo "$USER is here" > out.txt` (expansion + redir)
- [ ] `cat << END` lit jusqu'à `END`, expansion gérée selon quoting du délimiteur
- [ ] `export X=42` puis `echo $X` affiche `42` (env partagé dans la session)
- [ ] `cd /tmp | echo hi ; pwd` → ancien cwd (cd dans pipe ne change rien)
- [ ] `echo $?` reflète le code du DERNIER maillon du pipeline
- [ ] Aucun leak après 50 commandes successives

---

## Semaine 4 — Polish + Signals + Rendu (J4)

**Objectif** : projet prêt à rendre, tous les edge cases, README, défense.

### Personne A + B en pair (lundi-mardi)
- [ ] **#44** `signals/handlers.c` — `SIGINT`, `SIGQUIT` selon mode (prompt/exec/heredoc)
- [ ] **#45** `signals/setup.c` — `sigaction` setup
- [ ] **#46** Variable globale `g_signal` (UNIQUE) + intégration
- [ ] **#47** Tests signals manuels (`tests/manual/SIGNALS.md`)

### Tâches partagées (mercredi-jeudi)
- [ ] **#48** Chasse aux leaks (valgrind sur tous les scénarios)
- [ ] **#49** Norminette : `norminette src/ includes/` → 0 erreur
- [ ] **#50** Test contre bash : script qui compare les outputs (`tests/integration/test_vs_bash.sh`)
- [ ] **#51** Edge cases listés dans TESTS.md (au moins 50 cas)
- [ ] **#52** README final selon spec (cf. chapitre V du sujet)

### Tâches bonus si temps (vendredi-dimanche)
- [ ] **#53** `&&` et `||` avec parenthèses
- [ ] **#54** Wildcards `*` dans le cwd
- [ ] **#55** Tests bonus

### Tâches de fermeture
- [ ] **#56** Démo croisée binôme — chacun explique l'autre moitié
- [ ] **#57** Push final + tag `v1.0`
- [ ] **#58** Préparer la défense : anticiper les questions

### Critère de rendu (= [CHECKLIST.md](CHECKLIST.md) en intégralité)
- [ ] **Tous les items** de [CHECKLIST.md](CHECKLIST.md) cochés (147 items)
- [ ] `make re` → zéro warning, zéro relink
- [ ] `norminette` → zéro erreur sur `src/ includes/ libft/`
- [ ] `valgrind --leak-check=full ./minishell` → aucun leak côté nous (readline OK)
- [ ] `bash tests/run_all.sh` → vert intégral
- [ ] `tests/manual/SIGNALS.md` toutes les cases cochées
- [ ] 2 testers externes (francinette + 42_minishell_tester) ≥ 95%
- [ ] README final conforme au sujet (login italique, sections obligatoires)
- [ ] Démo croisée binôme faite, chacun maîtrise les modules de l'autre
- [ ] [DEFENSE.md](DEFENSE.md) relu en pair, réponses préparées

---

## Buffer / gestion du retard

- **Marge intégrée** : ~3 jours sur 28. Si tu glisses sur S1, tu rattrapes en S2.
- **Si on glisse sur S2** : on coupe les bonus immédiatement, focus mandatory.
- **Si on glisse sur S3** : on arrête les tests fancy, on garde un script de smoke test minimal.
- **Si on glisse sur S4** : on rend sans signals propres (sera pénalisé) MAIS on rend.

## Cadence quotidienne

```
Matin  (1h)    : pull, lire le board, choisir 1-2 issues
Coding (3-5h)  : focus sur les issues, commits fréquents
Soir   (30min) : push, update board, écrire le standup du jour
```

## Définition de "Done" pour une issue

1. Code compile sans warning
2. Norminette OK sur le(s) fichier(s) touché(s)
3. Tests associés écrits ET ils passent
4. PR ouverte, review du binôme, merge sur `dev`
5. Issue fermée par le merge (mot-clé `Closes #N` dans la PR)
