# Checklist de rendu — Minishell

> À faire **le jour avant** de cliquer "rendu" sur intra. À deux, dans le calme.
> Si UN seul item est rouge, on ne rend pas. Mieux vaut décaler de 24h que rendre cassé.

## 1. Compilation

- [ ] `make` compile sans warning (`-Wall -Wextra -Werror`)
- [ ] `make` ne relink pas si rien n'a changé (test : `make` deux fois de suite, le second doit dire "rien à faire")
- [ ] `make clean` supprime les `.o` (et seulement les `.o`)
- [ ] `make fclean` supprime `.o` + binaire + libft
- [ ] `make re` = `fclean` + `all` fonctionne
- [ ] `make bonus` fonctionne (si on a fait des bonus) ; sinon retirer la règle
- [ ] Le Makefile **liste explicitement** tous les `.c` (pas de `wildcard` qui inclurait des fichiers parasites)
- [ ] Le Makefile **link readline** correctement sur macOS (`-lreadline -L $(brew --prefix readline)/lib -I $(brew --prefix readline)/include`)
- [ ] Le Makefile fonctionne sur les Mac de l'école (vérifier !)
- [ ] Pas de `-g`, `-fsanitize`, `-O0` ou autres flags de debug en prod (laisser propre)

## 2. Norminette

- [ ] `norminette src/` → zéro erreur
- [ ] `norminette includes/` → zéro erreur
- [ ] `norminette libft/` → zéro erreur (la libft DOIT aussi être norme)
- [ ] Aucune fonction > 25 lignes
- [ ] Aucun fichier > 4 fonctions
- [ ] Aucun fichier > 25 colonnes d'indentation par tab
- [ ] Headers 42 obligatoires en haut de chaque fichier
- [ ] Aucune ligne > 80 colonnes
- [ ] Indentation tabs (vérifier avec `cat -A`)

## 3. Fonctions externes

- [ ] On utilise **uniquement** les fonctions de la liste autorisée (voir [PARSING_RULES.md §11](PARSING_RULES.md))
- [ ] Aucun `printf` avec specifiers exotiques (sticky avec ce qui est dans notre ft_printf si on l'utilise — sinon `printf` standard OK pour les prompts mais pas pour les erreurs)
- [ ] Pas de `system()`, `popen()`, `gets()`, `bzero` (dépréciée), `getline`
- [ ] Pas de `pthread_*`, `clock_gettime`, etc.
- [ ] Faire `nm minishell | grep " U "` (ou équivalent macOS : `nm -u minishell`) — toutes les fonctions externes doivent être dans la liste

## 4. Memory

- [ ] `valgrind --leak-check=full --suppressions=tests/readline.supp ./minishell` sur un scénario complet → 0 leak (hors readline)
- [ ] Pas de "still reachable" ou "definitely lost" autres que readline
- [ ] Tous les `malloc` ont leur `free` correspondant
- [ ] Vérification du retour de `malloc` (pas de segfault si NULL)
- [ ] Vérification du retour de `fork`, `pipe`, `execve` (les 3 retours d'erreur courants)

## 5. File descriptors

- [ ] Pas de fd qui traîne après une commande (vérifier avec `lsof -p $(pidof minishell)` si possible)
- [ ] Tous les pipes sont fermés dans le parent ET dans les fils non concernés
- [ ] Les heredocs ferment leur fd après usage
- [ ] Les fichiers de redirection sont fermés après exec
- [ ] `STDIN_FILENO`, `STDOUT_FILENO`, `STDERR_FILENO` ne sont JAMAIS fermés

## 6. Comportements obligatoires (sujet)

- [ ] Prompt affiché (n'importe quel format ; classiquement `minishell$ `)
- [ ] Historique navigable avec flèches haut / bas (readline le fait gratos)
- [ ] Exécute commande externe avec PATH OU avec chemin
- [ ] Quotes simples : tout littéral sauf elles-mêmes
- [ ] Quotes doubles : tout littéral sauf `$` et `"`
- [ ] Redirections : `<`, `>`, `>>`, `<<`
- [ ] Pipes : `|`
- [ ] Expansion `$VAR` et `$?`
- [ ] Ctrl-C, Ctrl-D, Ctrl-\\ gérés selon spec
- [ ] Builtins : `echo` (avec `-n`), `cd` (chemin relatif/absolu), `pwd`, `export`, `unset`, `env`, `exit`
- [ ] **UNE seule** variable globale `int` (uniquement le signal)

## 7. Comportements bash-compatibles (testés)

- [ ] `echo $?` reflète l'exit code (130 après Ctrl-C, 131 après Ctrl-\\, 127 commande introuvable, 126 permission, 2 syntaxe, 0/1 cas normaux)
- [ ] `exit abc` → stderr + exit code 2
- [ ] `exit 1 2` → erreur, ne quitte pas
- [ ] `export 1FOO=bar` → erreur "not a valid identifier"
- [ ] `unset PATH` puis `ls` → command not found
- [ ] `cd /nope` → erreur, `$?` = 1, cwd inchangé
- [ ] `pwd` après `cd /tmp` → `/tmp`
- [ ] `env` n'affiche que les variables avec valeur exportée
- [ ] `export` (sans arg) affiche en format `declare -x KEY="VAL"`, trié
- [ ] `echo -nnn hello` → `hello` (sans newline)
- [ ] `echo "$USER"x` → concaténation
- [ ] `cat << EOF` lit jusqu'à EOF, expansion par défaut, pas d'expansion si délimiteur quoté

## 8. Erreurs

- [ ] Messages d'erreur préfixés par `minishell:`
- [ ] Erreurs écrites sur **stderr** (fd 2)
- [ ] Format proche de bash (cf [EDGE_CASES.md §8.1](EDGE_CASES.md))
- [ ] Aucun message debug oublié (`printf("ICI\n")`, `printf("val=%d\n", x)`, etc.)
- [ ] Aucun appel `perror("debug")` ou similaire

## 9. Robustesse

- [ ] `./minishell` sans arg fonctionne
- [ ] `./minishell --help` ou avec args : on ignore (ou message simple), pas de crash
- [ ] `env -i ./minishell` (env vide) → tourne (pwd, builtins marchent, externes échouent)
- [ ] Lignes très longues (> 1000 chars) → pas de crash
- [ ] Pipeline très long (> 20 maillons) → pas de crash
- [ ] Heredoc avec 1000+ lignes → pas de crash
- [ ] Ctrl-C en boucle (10 fois rapidement) → pas de crash, pas de prompt bizarre
- [ ] `cd /tmp && rm -rf /tmp` (le cwd disparaît) → ne plante pas (bash affiche un warning sur le pwd, OK pour nous)

## 10. Tests

- [ ] `bash tests/run_all.sh` → tout passe en vert
- [ ] `tests/manual/SIGNALS.md` : toutes les cases cochées
- [ ] **Tester contre 2 testers externes** (francinette + 42_minishell_tester)
  - [ ] francinette : ≥ 95% pass
  - [ ] 42_minishell_tester : ≥ 95% pass
- [ ] Lancer le shell manuellement et taper 10 commandes au pif → tout marche

## 11. Repo

- [ ] Le repo contient **uniquement** ce qui est nécessaire :
  - `Makefile`
  - `README.md`
  - `includes/`
  - `src/`
  - `libft/` (sous-dossier, pas de submodule)
  - éventuellement `tests/` (ne sera pas regardé en éval, mais c'est OK)
- [ ] **PAS de `.DS_Store`**, `.vscode/`, `*.o`, `minishell` binaire dans le commit final
- [ ] `.gitignore` propre
- [ ] Branche `main` à jour
- [ ] Tag `v1.0` posé sur le commit final
- [ ] Le push final est fait, vérifier sur l'UI GitHub

## 12. README final (livrable 42)

- [ ] Login italique dans la première ligne (`*<login>*` ou `_<login>_`)
- [ ] Section : Description du projet
- [ ] Section : Installation / compilation
- [ ] Section : Utilisation (exemples)
- [ ] Section : Builtins supportés
- [ ] Section : Limitations connues (be honest)
- [ ] (Optionnel mais joli) GIF / capture d'écran

## 13. Soutenance

- [ ] Lire [DEFENSE.md](DEFENSE.md) **deux fois**
- [ ] Chacun sait expliquer **TOUS** les modules (pas seulement les siens)
- [ ] Faire une démo croisée 1h avant l'éval : chacun explique l'autre moitié
- [ ] Préparer un fichier de scénarios à montrer (`demo.sh` ?)
- [ ] Avoir bash ouvert dans un terminal pour comparer en live
- [ ] Avoir `man bash` accessible
- [ ] Apporter le sujet PDF (`docs/subject.pdf`)

## 14. Le dernier check — 10 min avant rendu

```bash
# Le rituel final
git status                          # → clean
git log --oneline | head -5         # → vérifier le dernier commit
make re                             # → silence + binaire
norminette src/ includes/ libft/    # → silence
./minishell                         # → prompt s'affiche
echo 'echo hello' | ./minishell     # → "hello"
echo 'exit 42' | ./minishell ; echo $?  # → "42"
git push                            # → up to date
```

Si toutes ces commandes sont OK : **clique "rendre" sur intra**.

---

## En cas de coup dur (jour J)

- **Norm fail soudain** : `norminette -R CheckForbiddenSourceHeader` pour ignorer les headers si broken
- **Leak qui n'existait pas** : vérifier que tu utilises la bonne `.supp`, sinon `valgrind --gen-suppressions=all` et ajouter
- **Tester externe qui plante chez toi mais pas chez le binôme** : check la version de bash (`bash --version`), parfois divergence
- **Heredoc qui marche en local mais pas en éval Mac** : le bug classique = lecture stdin pendant que readline est actif → utiliser une lecture manuelle (`get_next_line` sur fd 0)
