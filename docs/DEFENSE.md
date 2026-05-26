# Préparation soutenance — Minishell

> 100% des évals comportent **les mêmes questions de fond**. Les anticiper = note plus haute, défense plus courte.
> À RELIRE en pair ~24h avant l'éval. Chacun doit pouvoir répondre à chaque question (pas juste ses modules).

## Le format type

1. L'évaluateur vérifie la compilation, la norm, les builtins basiques (~15 min)
2. L'évaluateur teste des cas (de basique à tordu) (~30 min)
3. Questions sur le code, l'architecture, les choix (~15 min)
4. Discussion + notation

Total : ~60-90 min.

## Questions classiques + réponses préparées

### Q1 — "Explique-moi l'architecture générale"

**Réponse** :
> Le shell suit un pipeline classique en 4 étapes : **lexer** qui tokenise la ligne, **parser** qui construit un AST sous forme de liste chaînée de commandes, **expander** qui résout les variables et retire les quotes, **executor** qui fork et exec.
>
> Les modules sont en plus :
> - **builtins** (echo, cd, pwd, export, unset, env, exit)
> - **env** : linked list qui maintient l'environnement modifiable
> - **signals** : 3 modes (prompt, exécution, heredoc), une seule globale int
> - **redirections** : extraite de l'executor pour respecter la norme
> - **utils** : error, cleanup, init.
>
> Le binôme s'est réparti : un sur l'analyse syntaxique (lexer/parser/expander), l'autre sur l'exécution (executor/builtins qui modifient l'env). Les signaux on les a fait en pair.

### Q2 — "Pourquoi une linked list pour env et pas un tableau ?"

**Réponse** :
> Les opérations dominantes sont `set` (qui peut allouer une nouvelle entrée) et `unset` (qui retire un maillon). Avec un tableau on doit `realloc` à chaque modif, gérer la taille, déplacer les éléments. Avec une linked list :
> - Set / unset en O(1) une fois la clé trouvée
> - Pas de realloc, pas de gestion de capacité
> - Plus simple pour la norme (peu de fonctions)
>
> Le seul moment où on en convertit en tableau, c'est pour passer `envp` à `execve`, mais on free le tableau juste après.

### Q3 — "Pourquoi UNE seule variable globale ?"

**Réponse** :
> Le sujet l'impose. Mais derrière la contrainte il y a une raison : les signaux sont **asynchrones**. Le handler tourne dans un contexte limité (signal-safety). On ne peut pas y faire grand-chose sans risque (pas de malloc, pas de free, pas de printf, pas de `getenv`...). On peut juste assigner une variable globale `volatile sig_atomic_t` ou ici simplement `int`.
>
> Avoir UN INT permet de :
> - Faire l'assignation atomiquement
> - Vérifier la valeur depuis n'importe où dans le code (notamment après chaque retour de `readline`)
> - Pas d'allocation, pas de cleanup
>
> Si on avait une struct, il faudrait gérer son init, son cleanup, et l'assigner depuis le handler n'est pas atomique → race condition.

### Q4 — "Comment tu gères les pipes ?"

**Réponse** :
> Pour un pipeline `cmd1 | cmd2 | cmd3` :
> 1. Je parse en une liste de 3 `t_cmd`.
> 2. Pour chaque cmd, j'appelle `pipe()` (sauf pour la dernière qui n'a pas besoin de pipe sortant) et `fork()`.
> 3. Dans **chaque fils** : `dup2(read_prev, 0)` pour récupérer l'entrée du pipe précédent, `dup2(p[1], 1)` pour écrire dans le pipe suivant. Puis `execve`.
> 4. Dans le **parent** : je close immédiatement les fds que je n'utilise plus (sinon le `read` du fils suivant ne reçoit jamais EOF).
> 5. Je `waitpid` sur tous les fils, garde l'exit du DERNIER.
>
> Le piège classique : oublier de close dans le parent → deadlock. Je teste explicitement avec `cmd | cat | cat | cat`.

### Q5 — "Comment tu gères le heredoc ?"

**Réponse** :
> Le heredoc est lu **pendant le parsing**, AVANT toute exécution. Pourquoi ?
> - Les signaux pendant le heredoc se gèrent dans le shell parent, pas un fils
> - Quand on a plusieurs heredocs (`<< A << B`), il faut tous les lire avant d'exécuter
> - L'expansion `$VAR` se fait avec l'env du shell, pas un sous-process
>
> Concrètement : à chaque `<<`, j'appelle `readline("> ")` en boucle jusqu'à lire le délimiteur. J'accumule les lignes (avec expansion sauf si le délimiteur est quoté). Je stocke le résultat dans le `t_redir`.
>
> Au moment de l'exec, je crée un pipe, j'écris le contenu dedans, je dup2 le côté lecture sur stdin du fils.

### Q6 — "Comment tu gères les quotes ?"

**Réponse** :
> Le lexer respecte les quotes pour ne pas découper les mots, mais il **conserve l'information** : chaque token sait s'il contient une `'…'`, une `"…"`, ou des deux. Cette info est cruciale pour l'expander :
> - Hors quote et dans `"…"` : `$VAR` est expansé
> - Dans `'…'` : `$VAR` reste littéral
>
> Le retrait des quotes (`quotes stripping`) se fait dans l'expander, APRÈS l'expansion. Si on retirait avant, on perdrait l'info.

### Q7 — "Et si je tape `cd /tmp | echo hi`, qu'est-ce qui se passe ?"

**Réponse** :
> Comme il y a un pipe, chaque cmd est fork. Donc `cd` tourne dans un fils. Le `chdir()` modifie le cwd du **fils**, pas du parent. Quand le fils meurt, le cwd du shell reste inchangé.
>
> C'est le comportement de bash : `cd` dans un pipe ne change rien. Pour que `cd` change le cwd, il faut qu'il soit **seul** (pas dans un pipeline).
>
> Dans mon dispatcher, je détecte ce cas : si la liste de cmds a 1 seul maillon ET que c'est un builtin "modifiant" (cd, export, unset, exit), je l'exécute dans le parent, sans fork.

### Q8 — "Exit codes — explique-moi `echo $? ; false ; echo $? ; nonexistent ; echo $?`"

**Réponse** :
> - `echo $?` : 0 (rien avant, sauf si init a un exit code de la commande précédente)
> - `false` → exit 1
> - `echo $?` : 1
> - `nonexistent` → command not found, exit 127
> - `echo $?` : 127
>
> Côté implémentation : j'ai un champ `last_exit` dans ma struct shell. Après chaque exec, je l'update :
> - Builtin → retour direct
> - Externe → `WEXITSTATUS(status)` après waitpid
> - Externe tué par signal → `128 + WTERMSIG(status)`
>
> Quand l'expander voit `$?`, il convertit `last_exit` en string.

### Q9 — "Si je `ctrl-C` pendant un heredoc, qu'est-ce qui se passe ?"

**Réponse** :
> Le handler SIGINT en mode heredoc :
> 1. Met `g_signal = SIGINT`
> 2. Ferme le stdin (ou utilise `rl_clear_history` selon implémentation) pour faire sortir readline
> 3. Le code qui lit le heredoc détecte `g_signal != 0`, annule, free les lignes lues
> 4. Retour au prompt
> 5. `$?` = 130

### Q10 — "Pourquoi tu ne fais pas `echo $X` avec field splitting comme bash ?"

**Réponse** :
> Le sujet ne le demande pas. Implémenter le field splitting (qui re-tokenise l'output de l'expansion) demande de refaire passer le résultat dans le lexer après expansion, c'est une complexité majeure pour zéro point. Donc `echo $X` avec `X="a b c"` affiche `"a b c"` chez nous (un seul mot), pas 3 mots.

### Q11 — "Comment tu free tout à la fin ?"

**Réponse** :
> À deux niveaux :
> - **Par cycle REPL** : à la fin de chaque tour, je free la ligne (sortie de readline), la liste de tokens, l'AST avec ses redirections. L'env reste.
> - **À l'exit du shell** : je free l'env, je clear l'history readline (`rl_clear_history`), je free la struct shell.
>
> Tout est testé sous valgrind avec une suppression pour les leaks internes à readline qui sont autorisés par le sujet.

### Q12 — "Si je lance `./minishell` avec `env -i`, ça marche ?"

**Réponse** :
> Oui. À l'init, je copie `envp` (qui peut être NULL ou vide). Mes builtins ne crashent pas :
> - `pwd` utilise `getcwd()`, pas la var PWD
> - `env` affiche rien
> - `cd` peut foirer s'il n'a pas HOME, mais avec un chemin il marche
>
> Les commandes externes échouent car pas de PATH, mais c'est attendu.

### Q13 — "Et `unset PATH ; ls` ?"

**Réponse** :
> `ls` retourne "command not found" car la résolution PATH renvoie ENOENT pour tout. Mais `/bin/ls` marche (chemin absolu).

### Q14 — "Norminette : 25 lignes par fonction — comment tu fais pour le parser ?"

**Réponse** :
> Découpage agressif : un fichier par opérateur parsé (`parse_pipe.c`, `parse_word.c`, `parse_redir_in.c`, ...), une fonction par étape (validate, allocate, attach, advance). On finit avec ~13 fichiers dans le parser et ~7 dans le lexer. C'est plus de fichiers mais chaque fonction est lisible en 1 coup d'œil.

### Q15 — "Cas le plus tordu que tu gères ?"

> Plusieurs candidats. Le plus satisfaisant :
> ```
> cat << "END" | grep $USER >> /tmp/out
> $USER stays literal
> END
> ```
> Ce qui se passe :
> - Heredoc avec délimiteur quoté → pas d'expansion dans le contenu → `$USER` reste littéral dans la stdin de cat
> - cat pipe vers grep
> - grep cherche `$USER` (mais EXPANSÉ ici car hors heredoc) → cherche `axalva` (par ex)
> - Donc grep ne match rien
> - L'output (rien) est appendé à `/tmp/out`
> - `$?` = 1 (grep ne trouve rien)

### Q16 — "C'était quoi le bug le plus chiant ?"

(Préparer une vraie histoire. Style :)
> Pendant 2 jours, mes pipelines de 4+ commandes restaient bloqués. J'avais oublié de close `p[1]` dans le parent après chaque fork. Le fils suivant attendait EOF qui ne venait jamais. Je l'ai trouvé en utilisant `lsof -p PID` qui m'a montré 8 fds ouverts au lieu de 4.

## Tips comportementaux

- **Honnêteté** : si tu ne sais pas, dis "je ne sais pas mais voilà comment je trouverais". Mieux que d'inventer.
- **Le binôme contribue** : si l'évaluateur demande à l'autre, ne réponds pas à sa place. Mais aide si l'autre cale 30s+.
- **Démontre** : pour chaque comportement, tape la commande en live. Comparer avec bash si l'évaluateur doute.
- **Calme** : si une commande plante en démo, "intéressant" + tape la même chose en plus simple + retrouve le bug. Vrai pendant l'éval = -5 ; vrai après ré-éval = -0.

## Cas qui peuvent te coincer

| Demande              | Comportement attendu | Si tu n'as pas implémenté |
|----------------------|----------------------|---------------------------|
| `cd ~`               | va dans HOME         | "non implémenté, tilde non requis par le sujet" |
| `echo $X` avec X="a b" | "a b" (1 mot)      | dire clairement qu'on ne fait pas field splitting |
| `cmd1 && cmd2`       | (mandatory) erreur syntaxe ; (bonus) AND | si pas de bonus : dire que c'est bonus, qu'on ne l'a pas |
| `*.c`                | (mandatory) littéral ; (bonus) globbing | idem |
| `$(cmd)`             | non requis           | "command substitution, non requis Minishell" |
| `$$`                 | PID en bash          | "non requis Minishell, on garde littéral" |

## La phrase magique

Quand on te demande pourquoi un comportement diverge légèrement de bash :
> "Le sujet dit que bash est la référence pour le **comportement obligatoire**. Sur ce point précis, le sujet ne précise pas le comportement attendu, donc on a choisi le plus simple cohérent avec le reste. Si tu veux que je l'aligne sur bash, je vois où corriger."

Ça montre :
1. Tu connais le sujet
2. Tu sais distinguer obligatoire vs choix
3. Tu sais où est le code (=tu maîtrises)
