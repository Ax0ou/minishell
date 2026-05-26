# Edge cases — Minishell

> Catalogue des pièges qui font perdre 10-20% à l'éval. À lire **avant** S2 et **relire** avant S4.
> Tous les cas listés ici ont été observés en éval réelle ou viennent de retours de pairs.

## 1. Exit codes — le piège n°1

### 1.1 La règle générale
`$?` reflète l'exit code de la **dernière commande exécutée** (ou pipeline). Voir la table de référence dans [ARCHITECTURE.md §D6](ARCHITECTURE.md).

### 1.2 Pipelines
Pour `cmd1 | cmd2 | cmd3` → `$?` = exit code de **cmd3** (le dernier).
Même si cmd1 plante, on garde le dernier.

```
$ false | true
$ echo $?
0
$ true | false
$ echo $?
1
```

### 1.3 Commandes tuées par signal
| Signal       | Exit code |
|--------------|-----------|
| SIGINT (2)   | 130       |
| SIGQUIT (3)  | 131       |
| SIGTERM (15) | 143       |
| SIGKILL (9)  | 137       |

Récupération via `WIFSIGNALED(status) && 128 + WTERMSIG(status)`.

### 1.4 Erreur de syntaxe
`$?` = `2` (PAS 1, PAS 258).

### 1.5 Builtin `exit`
- `exit` sans arg → exit avec `$?` courant.
- `exit 42` → exit avec 42.
- `exit 256` → exit avec 0 (modulo 256, comme bash).
- `exit -1` → exit avec 255.
- `exit abc` → stderr `minishell: exit: abc: numeric argument required`, **quitte** avec 2.
- `exit 1 2` → stderr `minishell: exit: too many arguments`, **ne quitte PAS**, `$?` = 1.
- `exit 42 abc` → **quitte** avec 2 (le check numérique a priorité sur "trop d'args").
  - ⚠️ vérifier ce dernier comportement avec bash — variable selon les versions.

### 1.6 `command not found` vs `no such file`
- Exécutable introuvable via PATH → `command not found`, code 127.
- Path absolu/relatif qui n'existe pas → `No such file or directory`, code 127.
- Path qui existe mais sans `+x` → `Permission denied`, code 126.
- Path qui est un dossier → `is a directory`, code 126.

## 2. Quotes — pièges

### 2.1 Quote au milieu d'un opérateur
`echo "|" wc` → `|` est dans une quote → `T_WORD`, pas `T_PIPE`. Sortie : `| wc`.

### 2.2 Quote vide
- `echo ""` → ligne vide.
- `cd ""` → erreur `chdir() failed: No such file or directory`, code 1.
- `export ""` → erreur `not a valid identifier`, code 1.
- `unset ""` → erreur `not a valid identifier`, code 1.

### 2.3 Quotes non fermées
`echo "hello` → erreur de syntaxe, code 2, prompt revient. **PAS de readline multi-ligne** (sauf si tu veux te lancer dans une horreur).

### 2.4 Quote autour d'un nom de commande
`"ls"` → cherche `ls` (les quotes sont retirées avant résolution PATH).
`""ls""` → idem.

### 2.5 Quote au milieu d'un nom de var
`echo "$U"SER` → si USER=alex, sortie : `alexSER` (concat).
`echo "$"USER` → sortie : `$USER` (le `$` est isolé donc littéral).

## 3. Heredoc — pièges

### 3.1 Heredoc + pipe
`cat << EOF | wc -l` → le heredoc est lu, son contenu va dans stdin de cat, cat pipe vers wc. Le pipeline démarre **après** que le heredoc soit complètement lu.

### 3.2 Plusieurs heredocs sur la même commande
`cat << A << B` → on lit A, on lit B, seul B est utilisé comme stdin de cat. Les lignes lues pour A sont jetées.

### 3.3 Heredoc dans un pipeline avec plusieurs heredocs
`cat << A | cat << B` → on lit A, puis B, dans cet ordre. CHAQUE commande a son propre heredoc.

### 3.4 Délimiteur quoté
`<< "EOF"` ou `<< 'EOF'` ou `<< E"O"F` → délimiteur = `EOF` (quotes retirées pour la comparaison), et **pas d'expansion** dans le contenu.

### 3.5 Ctrl-D pendant heredoc
Affiche un warning sur stderr (`warning: here-document at line N delimited by end-of-file (wanted 'EOF')`), puis exécute la commande avec ce qu'on a lu.

### 3.6 Ctrl-C pendant heredoc
- Annule le heredoc
- `$?` = 130
- Retour au prompt
- La commande N'est PAS exécutée

### 3.7 Heredoc avec délimiteur vide
`cat << ""` → bash accepte, le délimiteur est la ligne vide. Comportement bash, à reproduire si on veut être pédant. **Acceptable** en éval de simplifier en erreur.

## 4. Signals — pièges

### 4.1 Comportement spécifique par mode

| Mode             | Ctrl-C (SIGINT)                          | Ctrl-\ (SIGQUIT)        | Ctrl-D (EOF) |
|------------------|------------------------------------------|-------------------------|--------------|
| Prompt vide      | newline + nouveau prompt, `$?` = 130    | ignoré                  | `exit` du shell |
| Prompt avec texte| efface la ligne, nouveau prompt, `$?`=130| ignoré                  | rien         |
| Commande externe | tue + newline, `$?` = 130                | tue + `Quit (core dumped)`, `$?`=131 | rien (EOF passe à la commande) |
| Heredoc          | annule heredoc, `$?` = 130               | ignoré                  | warning + exécute la cmd |
| Pipeline         | tue tous les forks                       | tue tous les forks      | rien         |

### 4.2 Les fonctions readline et SIGINT
- `rl_on_new_line()` → indique à readline qu'on a changé de ligne.
- `rl_replace_line("")` → efface le buffer courant.
- `rl_redisplay()` → réaffiche le prompt.
- Ces 3 appels dans le handler SIGINT du mode prompt = nouveau prompt propre.

⚠️ `rl_on_new_line` peut faire planter readline si appelé hors contexte → toujours dans le handler.

### 4.3 Le prompt et le signal status
Quand SIGINT au prompt vide :
- `$?` passe à 130 ? Oui en bash si une ligne a été pressée ; non si on a juste appuyé Ctrl-C sans entrée.
- Pour rester simple : on met `$?` à 130 dans tous les cas. Acceptable.

### 4.4 Signal handler simple = signal()  ou sigaction() ?
**`sigaction` recommandé** : plus portable, comportement défini, peut bloquer d'autres signaux pendant l'exécution du handler. Le sujet autorise les deux.

### 4.5 Le signal global = INT pur
- Type : `int g_signal;` (unique variable globale du projet).
- Ne JAMAIS y mettre un pointeur, struct, ou autre.
- Le handler fait `g_signal = signum;` et rien d'autre.
- Le main loop check `g_signal` après chaque cycle.

## 5. Pipes — pièges

### 5.1 Fermeture des fds
**Le bug n°1 de tous les Minishells** : oublier de close un fd de pipe dans le parent.

Règle absolue : après avoir fork un enfant qui utilise un pipe, le **parent doit close** son extrémité non utilisée. Sinon le `read` du fils suivant ne reçoit jamais EOF, le pipeline se bloque à l'infini.

Pattern :
```
prev_read = -1
pour chaque cmd :
    pipe(p)             # p[0] read, p[1] write
    fork()
    si fils :
        si prev_read != -1 : dup2(prev_read, 0); close(prev_read)
        si pas dernier : dup2(p[1], 1)
        close(p[0]); close(p[1])
        execve(...)
    parent :
        si prev_read != -1 : close(prev_read)
        close(p[1])
        prev_read = p[0]
parent: si prev_read != -1 : close(prev_read)
parent: waitpid pour tous les fils
```

### 5.2 SIGPIPE
Si cmd2 termine avant cmd1 dans `cmd1 | cmd2`, cmd1 reçoit SIGPIPE quand il essaie d'écrire. Comportement par défaut = mort silencieuse. C'est OK, on ne fait rien de spécial.

### 5.3 Ordre des wait
Wait sur **tous** les enfants AVANT de récupérer l'exit code. Sinon zombies. Garder l'exit code du DERNIER (celui qui détermine `$?`).

### 5.4 Pipeline d'un seul builtin
`cd /tmp | echo hi` → le `cd` tourne dans un fork (parce qu'il y a un pipe), donc **le cwd du shell parent ne change pas**. Bash fait pareil. C'est un piège classique : "pourquoi `cd | cat` ne change pas le dir ?".

### 5.5 Builtin SEUL (pas de pipe) → dans le parent
`cd /tmp` → exécuté directement dans le shell parent. Donc cwd change. Idem pour `export`, `unset`, `exit`. Si tu fork pour ces builtins, ils ne servent à rien.

## 6. Builtins — pièges spécifiques

### 6.1 `cd`
- `cd` sans arg → en bash, va dans `$HOME`. Si pas d'HOME → erreur. **Implémenter** ou afficher erreur claire.
- `cd ~` → tilde non géré → erreur ou littéral selon choix. **Le sujet ne demande pas tilde.**
- `cd -` → va dans `$OLDPWD`, affiche le nouveau cwd. Non requis, mais facile à faire.
- `cd ..` puis `pwd` → doit afficher le bon chemin (mise à jour de `PWD`).
- Après `cd /tmp` : `PWD=/tmp` ET `OLDPWD=<ancien>` doivent être à jour dans l'env interne.
- `cd /nonexistent` → erreur stderr, `$?` = 1, cwd inchangé.
- Si on est dans un dossier supprimé pendant la session → `pwd` peut renvoyer un truc bizarre. Bash gère via `PWD` interne ; nous on peut utiliser `getcwd` ET fallback sur `PWD`.

### 6.2 `echo`
- `echo` (sans arg) → newline.
- `echo -n` (juste `-n`) → rien (pas même un newline).
- `echo -n hello` → `hello` (sans newline).
- `echo -nnn hello` → `hello` (chaîne de `n` après `-` = encore l'option).
- `echo -n -n -n hello` → `hello` (plusieurs `-n` accumulés).
- `echo -nE hello` → bash : E non reconnu → traité comme texte → `-nE hello\n`. À reproduire.
- `echo --help` → bash : affiche `--help` (pas d'aide). Pareil chez nous.
- `echo hello -n` → `hello -n\n` (le `-n` n'est option qu'au début).

### 6.3 `export`
- `export` (sans arg) → liste TRIÉE alphabétiquement, format `declare -x KEY="VAL"`.
- `export FOO` → ajoute FOO comme "exported sans valeur" (visible dans `export`, pas dans `env`).
- `export FOO=` → FOO existe avec valeur vide. Visible dans env.
- `export FOO=bar BAZ=qux` → plusieurs assignations en une commande.
- `export 1FOO=bar` → erreur `not a valid identifier`, code 1.
- `export FOO=bar=baz` → assigne `bar=baz` à FOO. OK.
- `export FOO+=bar` → bash : concatène. **Non requis, optionnel**.

### 6.4 `unset`
- `unset FOO BAR BAZ` → unset multiple.
- `unset` (sans arg) → success, code 0, rien à faire.
- `unset 1FOO` → erreur `not a valid identifier`, code 1.
- `unset PATH` → autorisé. Après ça, plus aucune commande non absolue ne fonctionne.

### 6.5 `env`
- `env` sans arg → liste de toutes les variables `exported=1` AVEC une valeur.
- `env FOO=bar cmd` → bash : exécute cmd avec FOO en plus dans l'env. **Non requis Minishell**.
- Variables exportées sans valeur (`export FOO`) → ne s'affichent PAS dans `env`.

### 6.6 `pwd`
- Toujours afficher `getcwd()` (le résultat système), pas la variable `PWD` (qui peut diverger).

### 6.7 `exit` — voir §1.5 ci-dessus

## 7. Env — pièges

### 7.1 Shell lancé avec un env modifié
`env -i ./minishell` → le shell démarre avec un env vide. Doit fonctionner :
- `pwd` doit marcher (utilise `getcwd`)
- Les commandes externes échouent (pas de PATH)
- `env` affiche rien
- `export FOO=bar; env` → affiche `FOO=bar`

### 7.2 Modification de PATH en runtime
- `export PATH=/bin; ls` → doit fonctionner
- `unset PATH; ls` → "command not found"
- `unset PATH; /bin/ls` → fonctionne (path absolu)
- `PATH=/bin ls` → bash autorise. **Non requis Minishell**.

### 7.3 SHLVL
Bash incrémente `SHLVL` à chaque shell imbriqué. **Optionnel** mais facile : à l'init, lire `SHLVL`, incrémenter, ré-exporter. Joli détail si tu veux gagner 1%.

## 8. Erreurs spécifiques

### 8.1 Format des messages d'erreur
Style bash : `minishell: <command>: <arg>: <message>`.

Exemples :
- `minishell: cd: /nonexistent: No such file or directory`
- `minishell: export: 1FOO: not a valid identifier`
- `minishell: exit: abc: numeric argument required`
- `minishell: syntax error near unexpected token \`|\``
- `minishell: <cmd>: command not found`
- `minishell: <cmd>: Permission denied`
- `minishell: <file>: No such file or directory` (pour redirection)

Tous écrits sur **stderr** (fd 2), via `write` ou `ft_putstr_fd`.

### 8.2 Le nom du shell dans les erreurs
Préfixe = `minishell` (cohérent). Pas `bash`. Pas `./minishell`. Pas `42sh`.

### 8.3 Permission denied vs No such file
| Cas                                 | Code | Message                              |
|-------------------------------------|------|--------------------------------------|
| Fichier inexistant pour `<`         | 1    | No such file or directory            |
| Pas de permission de lecture pour `<` | 1  | Permission denied                    |
| Dossier sans permission d'écriture pour `>` | 1 | Permission denied            |
| Path qui est un dossier en commande | 126  | Is a directory                       |
| Path sans `+x` en commande          | 126  | Permission denied                    |

## 9. Memory & fds

### 9.1 Leak vs readline
Readline est connu pour avoir des "leaks" résiduels (history, environnement readline). **Acceptable en éval**. Le sujet exclut explicitement les leaks de readline.

Suppression valgrind : utiliser un fichier `.supp` qui ignore les frames `readline`, `add_history`, `rl_*`.

### 9.2 Free de l'env de execve
`execve(path, argv, envp)` — si le `envp` est alloué à partir d'un linked list, il faut le **free quand execve échoue** (sinon leak dans le shell parent à chaque échec).

Si execve réussit, le `envp` est libéré automatiquement (replace de l'image processus).

### 9.3 Free de l'AST après exec
À la fin de chaque cycle REPL, free tout :
1. `line` (string readline)
2. tokens (linked list)
3. AST (`t_pipeline` + `t_cmd` + `t_redir`)

### 9.4 Fermeture des fds des heredocs
Si on stocke le contenu du heredoc dans un fichier tmp : **toujours unlink** le fichier après usage. Sinon des fichiers `/tmp/minishell_heredoc_XXX` traînent.

Alternative : pipe en mémoire. Le contenu écrit dans `p[1]`, dup2(p[0], 0) dans le fils, close des deux dans le parent.

### 9.5 Le piège du double-close
`close(fd); close(fd);` → le second échoue silencieusement. Mais si entre les deux, on a ouvert un autre fd, le système réattribue ce numéro → on close un fd qui n'est pas à nous. **Toujours remettre fd à -1 après close.**

## 10. Cas tordus à TESTER explicitement

Liste de scénarios qui doivent passer en éval (en plus des classiques) :

```bash
# 1. Heredoc avec expansion
cat << EOF
$USER is in $PWD
EOF

# 2. Heredoc sans expansion
cat << "EOF"
$USER stays literal
EOF

# 3. Pipe + heredoc
cat << EOF | wc -l
a
b
c
EOF

# 4. Redirections multiples
echo a > /tmp/x > /tmp/y > /tmp/z

# 5. Pipe avec builtin (cd ne change pas le cwd)
cd /tmp | echo hi
pwd  # → ancien cwd

# 6. Variables vides
export X=
echo "[$X]"  # → [] 

# 7. Variables non définies
echo $INEXISTANT  # → ligne vide

# 8. Concaténation
echo a"b"c'd'$USER

# 9. Quotes vides
echo "" '' ""

# 10. Chained commands (séparées dans des prompts différents)
ls -la | grep .c | wc -l
echo $?
ls /no_such_dir
echo $?
true
echo $?

# 11. Path absolu
/bin/ls /tmp

# 12. Permission denied
chmod 000 /tmp/x
cat /tmp/x  # → permission denied
echo $?  # → 1
chmod 644 /tmp/x

# 13. Fork bomb protection (juste tester que ça ne crashe pas)
:(){ :|: & };:   # bash fork bomb — on n'a pas de fonctions ni de &, donc safe
                  # mais : tester qu'on rejette proprement

# 14. Variable globale propre
echo $? ; echo $? ; echo $?  # premier = exit du :, suivants = 0
```

## 11. Vérification finale avant rendu

Avant chaque push sur `main` :
```bash
# Le triplet d'or
make re && norminette src/ includes/ && valgrind --leak-check=full ./minishell
```

Si une seule de ces 3 commandes faille → on ne push pas.
