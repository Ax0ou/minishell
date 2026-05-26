# Règles de parsing — Minishell

> **Le document à imprimer et coller au mur.** 80% des bugs Minishell viennent d'une mauvaise interprétation des règles de quoting et d'expansion. Ici on les fige.
> Référence absolue : **bash en mode non-interactif** (`echo 'cmd' | bash`).
> Quand un cas n'est pas listé ici, le comportement attendu = celui de bash.

## 1. Whitespace

Caractères considérés comme whitespace pour la séparation de tokens :
- espace (` `)
- tabulation (`\t`)

Tout autre caractère (newline interne, vertical tab, etc.) → on ne s'en soucie pas (readline les filtre).

**Règles** :
- Whitespace HORS quotes ⇒ sépare les mots
- Whitespace DANS quotes ⇒ fait partie du mot
- Plusieurs whitespaces consécutifs hors quotes ⇒ équivalent à un seul

| Input                  | Tokens                                  |
|------------------------|-----------------------------------------|
| `ls   -la`             | `[ls] [-la]`                            |
| `echo "a   b"`         | `[echo] [a   b]`                        |
| `echo a"   "b`         | `[echo] [a   b]` (concaténation)        |
| `   ls   `             | `[ls]`                                  |

## 2. Quotes — la table de vérité

| Contexte    | `'`     | `"`     | `$VAR`        | `\` (backslash)   |
|-------------|---------|---------|---------------|-------------------|
| Hors quotes | ouvre `'…'` | ouvre `"…"` | expandé    | non géré (laisser tel quel) |
| Dans `'…'`  | ferme   | littéral | littéral      | littéral          |
| Dans `"…"`  | littéral| ferme   | expandé       | littéral          |

> **Note backslash** : le sujet Minishell **n'exige pas** la gestion de `\` comme échappement (différence avec bash). Il reste littéral partout. C'est documenté dans la FAQ 42.

## 3. Concaténation adjacente (sans whitespace entre tokens)

Deux quotes ou un mot + quote sans whitespace entre eux = UN SEUL mot après concaténation.

| Input              | Output                              |
|--------------------|-------------------------------------|
| `echo a"b"c`       | `abc`                               |
| `echo "$USER"x`    | `<login>x`                          |
| `echo '$USER'"$USER"` | `$USER<login>` (premier littéral, second expansé) |
| `echo ""hello""`   | `hello`                             |
| `echo ""`          | (ligne vide)                        |
| `echo "''"`        | `''`                                |
| `echo '""'`        | `""`                                |

**Règle de concaténation** : tant qu'il n'y a pas de whitespace ou d'opérateur, on accumule dans le même mot. Le lexer doit produire un `T_WORD` qui couvre toute la séquence.

## 4. Expansion des variables — `$NAME`

### 4.1 Forme du nom
Un nom de variable valide après `$` =
- commence par lettre ou `_`
- suivi de lettres, chiffres, `_`

| Input        | Détection                         | Résultat                       |
|--------------|-----------------------------------|--------------------------------|
| `$USER`      | nom = `USER`                      | valeur de USER                 |
| `$_PRIVATE`  | nom = `_PRIVATE`                  | valeur (ou vide)               |
| `$2HOME`     | nom = vide (commence par chiffre) | `$2HOME` littéral... OU `HOME` selon bash. Voir §4.5. |
| `$`          | rien après                        | `$` littéral                   |
| `$ HOME`     | rien valide après `$`             | `$ ` + `HOME`                  |
| `$$`         | spécial bash (PID)                | **non implémenté en Minishell** → `$$` littéral |
| `$1` à `$9`  | paramètres positionnels bash      | **non implémenté** → string vide |
| `$0`         | nom du shell                      | **non implémenté** → string vide |

### 4.2 Cas spéciaux 42

- `$?` → exit code de la dernière commande (toujours géré)
- `$NAME_INEXISTANTE` → string vide (PAS un message d'erreur)
- `$NAME` quand NAME = `""` → string vide

### 4.3 Expansion vs quotes — récap

| Input                | Output           |
|----------------------|------------------|
| `echo $USER`         | `<login>`        |
| `echo "$USER"`       | `<login>`        |
| `echo '$USER'`       | `$USER`          |
| `echo "I am $USER"`  | `I am <login>`   |
| `echo $?`            | exit code        |
| `echo "$?"`          | exit code        |
| `echo '$?'`          | `$?`             |

### 4.4 Expansion qui change le nombre de mots ? **NON**

En bash, `echo $X` avec `X="a b c"` produit 3 mots. **En Minishell on N'EXIGE PAS** ce field splitting (ce serait une horreur à implémenter dans une nuit). Le sujet ne le mentionne pas. Confirmé : on garde `"a b c"` en un seul mot.

### 4.5 Cas tordu — `$` immédiatement suivi de quelque chose qui n'est pas un nom

| Input            | Output                              |
|------------------|-------------------------------------|
| `echo $`         | `$`                                 |
| `echo $.`        | `$.`                                |
| `echo $-`        | `$-` (on ne gère pas le mode shell) |
| `echo $#`        | `$#`                                |
| `echo $!`        | `$!`                                |
| `echo "$"`       | `$`                                 |
| `echo "$$"`      | `$$` (PID non géré → littéral)      |

## 5. Opérateurs

### 5.1 Détection
| Char        | Token         | Notes                                    |
|-------------|---------------|------------------------------------------|
| `|`         | `T_PIPE`      | n'apparaît PAS au début / à la fin       |
| `<`         | `T_REDIR_IN`  | doit être suivi (après ws) d'un mot      |
| `>`         | `T_REDIR_OUT` | idem                                     |
| `<<`        | `T_HEREDOC`   | suivi d'un mot (le délimiteur)           |
| `>>`        | `T_APPEND`    | idem out                                 |
| `&&` `\|\|` `(` `)` `;` | non gérés (sauf bonus) → erreur de syntaxe |

### 5.2 Concaténation des opérateurs
- `>>` est UN seul token, pas deux `>`. Pareil pour `<<`.
- `<<<` (here-string bash) → on traite comme `<<` + `<` ? **NON** → erreur de syntaxe en Minishell (non requis).
- `>|` (force overwrite bash) → non requis, erreur syntaxe.

### 5.3 Cas tordus
| Input              | Tokens / résultat                    |
|--------------------|--------------------------------------|
| `ls\|wc`           | `[ls] [|] [wc]` (collé OK)           |
| `echo a>file`      | `[echo] [a] [>] [file]`              |
| `>file`            | `[>] [file]` — crée le fichier vide  |
| `>`                | syntax error                         |
| `\|`               | syntax error                         |
| `cat <<EOF<file`   | heredoc EOF puis redir input file ; bash exécute, on doit gérer |

## 6. Redirections multiples

Une commande peut avoir N redirections. Règles :
- Toutes sont **traitées dans l'ordre** d'apparition.
- Pour `>` et `>>` : on OUVRE chaque fichier (create / truncate / append) → tous existent au final, mais seul le DERNIER est connecté à stdout.
- Pour `<` : on OUVRE chaque fichier (check existence + perm) → seul le DERNIER reste connecté à stdin. Si un fichier intermédiaire n'existe pas → erreur, `$?` = 1, et la commande n'est PAS exécutée.

| Input                  | Effet                                                |
|------------------------|------------------------------------------------------|
| `echo hi > a > b > c`  | a, b, c existent ; "hi" est dans c uniquement        |
| `cat < a < b < c`      | si a, b, c existent → cat lit c. Si b manque → erreur sans rien exécuter |
| `> a > b`              | crée a et b vides, pas de commande lancée            |

## 7. Heredoc — règles

```
cat << DELIM
ligne 1
ligne 2
DELIM
```

- Le délimiteur (`DELIM`) est le **mot exact** après `<<` (whitespace trim).
- Le shell lit ligne par ligne **JUSQU'AU** prompt qui contient uniquement `DELIM` + newline.
- Si EOF (Ctrl-D) arrive avant le délimiteur → bash affiche un warning :
  `warning: here-document at line N delimited by end-of-file (wanted 'DELIM')`
  → puis exécute la commande quand même avec ce qu'on a lu.
- Si Ctrl-C pendant la lecture → annule le heredoc, `$?` = 130, retour au prompt.

### Expansion dans le heredoc
- Par défaut, `$VAR` est expansé dans le contenu lu.
- Si le délimiteur est QUOTÉ (`<< "EOF"` ou `<< 'EOF'`) → PAS d'expansion. Le contenu est littéral.
  - Les quotes sont retirées pour la comparaison du délimiteur lui-même.
- L'expansion utilise l'env du shell **au moment de la lecture**, pas au moment de l'exec.

### Heredoc multiple
`cat << A << B` → on lit DEUX heredocs successifs, mais seul le DERNIER est utilisé comme stdin (les autres sont lus puis jetés). Bash fait pareil.

## 8. Erreurs de syntaxe — sortie exacte

Format bash standard :
```
minishell: syntax error near unexpected token `TOKEN`
```
Stocker dans `$?` = `2` (comme bash).

| Input         | Token reporté        |
|---------------|----------------------|
| `\|`          | `|`                  |
| `\| ls`       | `|`                  |
| `ls \|`       | `newline`            |
| `>` (seul)    | `newline`            |
| `> >`         | `>`                  |
| `;`           | `;`                  |
| `&&`          | `&&`                 |

Les erreurs `unexpected EOF` (quotes non fermées) :
```
minishell: syntax error: unclosed quote
```
(`$?` = 2 également)

## 9. Résolution PATH

Pour exécuter une commande externe `NAME` :
1. Si `NAME` contient `/` (relatif ou absolu) → on tente `execve(NAME, ...)` directement.
2. Sinon : on splite `PATH` par `:`, on tente `execve("<dir>/NAME", ...)` pour chaque dir.
3. Première qui retourne autre que `ENOENT` → on prend.
4. Si toutes échouent avec ENOENT → erreur "command not found", `$?` = 127.
5. Si trouvé mais pas exécutable (ex: dossier, fichier sans `+x`) → erreur "Permission denied", `$?` = 126.

**Cas spéciaux** :
- `PATH` non défini (`unset PATH`) → seules les commandes avec `/` sont trouvables.
- `PATH=""` → équivalent à "répertoire courant uniquement"... non, en bash `PATH=""` cherche dans le cwd implicitement. **En Minishell on simplifie** : `PATH=""` → command not found pour tout ce qui n'a pas de `/`.
- Path d'une chaîne vide entre deux `:` (`/bin::/usr/bin`) → bash considère `""` comme le cwd. On peut s'aligner ou ignorer (non testé strict en éval).

## 10. Cas que le sujet ne demande PAS (à NE PAS implémenter)

Pour éviter de perdre du temps :
- ❌ Globbing / wildcards (`*.c`, `?`, `[abc]`) — sauf bonus
- ❌ Substitution de commande `$(cmd)` ou backticks
- ❌ Expansion arithmétique `$((1+2))`
- ❌ Tilde `~` → littéral (sauf si on veut faire propre — bonus)
- ❌ `&&`, `||`, `;`, `()` — sauf bonus parenthèses
- ❌ Background jobs `cmd &`
- ❌ Jobs control (`fg`, `bg`, `jobs`, `kill %1`)
- ❌ Alias
- ❌ Functions
- ❌ Arrays
- ❌ Field splitting après expansion (`echo $X` avec `X="a b"` ⇒ on garde `"a b"`)

## 11. Liste de fonctions externes autorisées (sujet v10)

À garder sous les yeux pendant tout le projet :
```
readline, rl_clear_history, rl_on_new_line, rl_replace_line, rl_redisplay,
add_history, printf, malloc, free, write, access, open, read, close,
fork, wait, waitpid, wait3, wait4, signal, sigaction, sigemptyset, sigaddset,
kill, exit, getcwd, chdir, stat, lstat, fstat, unlink, execve, dup, dup2,
pipe, opendir, readdir, closedir, strerror, perror, isatty, ttyname,
ttyslot, ioctl, getenv, tcsetattr, tcgetattr, tgetent, tgetflag, tgetnum,
tgetstr, tgoto, tputs
```

**Toute autre fonction = fail automatique**. À cocher en review de PR.
