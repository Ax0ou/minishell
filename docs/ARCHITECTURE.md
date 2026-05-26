# Architecture — Minishell

> Découpage en modules. L'interface entre modules est l'**AST** (Abstract Syntax Tree).
> Connaître les frontières = clé pour bosser à deux sans se marcher dessus.

## Vue d'ensemble — pipeline d'exécution

```
   readline()
       │
       ▼
  ┌─────────┐  string "ls -la | grep .c > out"
  │  Lexer  │
  └────┬────┘
       │ tokens : [WORD:ls] [WORD:-la] [PIPE] [WORD:grep] [WORD:.c] [REDIR_OUT] [WORD:out]
       ▼
  ┌─────────┐
  │ Parser  │
  └────┬────┘
       │ AST : pipeline → [cmd1: ls -la] → [cmd2: grep .c, >out]
       ▼
  ┌──────────┐
  │ Expander │   $VAR, $?, expansion dans les quotes
  └────┬─────┘
       │ AST expansé
       ▼
  ┌──────────┐
  │ Executor │   fork, exec, pipe, dup2, wait
  └────┬─────┘
       │
       ▼
   exit status → stocké pour $?
```

## Modules détaillés

### 1. `lexer/` — Tokenisation
**Rôle** : transformer une string en liste de tokens.
**Input** : `char *line` (sortie de readline)
**Output** : `t_token *tokens` (linked list)

**Types de tokens** :
- `T_WORD` — mot quelconque (commande, argument, fichier)
- `T_PIPE` — `|`
- `T_REDIR_IN` — `<`
- `T_REDIR_OUT` — `>`
- `T_HEREDOC` — `<<`
- `T_APPEND` — `>>`
- `T_SQUOTE` — single quote group
- `T_DQUOTE` — double quote group

**Gère** :
- Découpage par whitespace
- Quotes simples et doubles (mémorise quel type pour expander)
- Quotes non fermées → erreur de syntaxe

**Ne gère PAS** :
- L'expansion des variables (c'est le boulot de l'expander)
- La structure pipeline (c'est le parser)

---

### 2. `parser/` — Construction de l'AST
**Rôle** : transformer la liste de tokens en arbre exécutable.
**Input** : `t_token *tokens`
**Output** : `t_pipeline *ast`

**Structures clés** :
```c
typedef struct s_redir
{
    int             type;       // IN, OUT, APPEND, HEREDOC
    char           *target;     // fichier ou délimiteur
    struct s_redir *next;
}   t_redir;

typedef struct s_cmd
{
    char         **argv;        // ["ls", "-la", NULL]
    t_redir       *redirs;      // liste des redirections
    struct s_cmd  *next;        // prochaine commande du pipeline
}   t_cmd;

typedef struct s_pipeline
{
    t_cmd *cmds;                // premier maillon
}   t_pipeline;
```

**Gère** :
- Validation syntaxique (`|` en début, `>>` sans cible, etc.)
- Construction de la chaîne de commandes
- Attachement des redirections à la bonne commande

---

### 3. `expander/` — Expansion des variables
**Rôle** : remplacer `$VAR` et `$?` par leur valeur dans les WORDs.
**Input** : `t_pipeline *ast`, `t_env *env`, `int last_exit`
**Output** : `t_pipeline *ast` (modifié in-place)

**Règles** :
- Pas d'expansion dans `'...'`
- Expansion active dans `"..."` et hors quotes
- `$?` → exit status précédent (sous forme de string)
- `$VAR_INEXISTANTE` → string vide
- `$` seul (sans nom valide) → reste `$`

---

### 4. `executor/` — Exécution
**Rôle** : exécuter l'AST.
**Input** : `t_pipeline *ast`, `t_env *env`
**Output** : `int exit_status`

**Responsabilités** :
- Résoudre le chemin de l'exécutable (PATH, relatif, absolu)
- Fork pour chaque commande externe
- Créer les pipes entre commandes
- Dup2 stdin/stdout selon redirections
- Appliquer les heredocs (lecture avant exec)
- Wait sur tous les enfants, récupérer le code de la dernière
- Si **un seul builtin sans pipe** → l'exécuter dans le parent (pour `cd`, `export`, `unset`, `exit` qui modifient le shell)

---

### 5. `builtins/` — Commandes intégrées
| Builtin  | Comportement                                     |
|----------|--------------------------------------------------|
| `echo`   | `-n` supprime le newline final                   |
| `cd`     | relatif ou absolu uniquement, met à jour `PWD`   |
| `pwd`    | affiche `getcwd()`                                |
| `export` | sans arg = liste triée ; avec `KEY=VAL` ajoute   |
| `unset`  | retire une variable de env                       |
| `env`    | affiche les variables exportées avec valeur      |
| `exit`   | quitte avec code optionnel, gère argc/erreurs    |

---

### 6. `signals/` — Gestion des signaux
**Rôle** : interactivité shell.

**Mode interactif (prompt)** :
- `SIGINT` (Ctrl-C) → nouvelle ligne, nouveau prompt
- `SIGQUIT` (Ctrl-\\) → ignoré
- `EOF` (Ctrl-D) → quitte (via retour `NULL` de readline)

**Mode exécution (commande en cours)** :
- `SIGINT` → tue le child, affiche newline
- `SIGQUIT` → tue le child, affiche `Quit (core dumped)`

**Mode heredoc** :
- `SIGINT` → annule le heredoc, retour au prompt

> **Contrainte** : UNE seule variable globale `g_signal` (int) qui stocke uniquement le numéro de signal. Pas de pointeurs, pas de struct.

---

### 7. `env/` — Gestion de l'environnement
**Rôle** : maintenir l'environnement modifiable du shell.

```c
typedef struct s_env
{
    char         *key;
    char         *value;
    int           exported;  // 1 si visible par env, 0 sinon
    struct s_env *next;
}   t_env;
```

**API** :
- `env_init(char **envp)` — copie de l'env reçu
- `env_get(t_env *env, char *key)` — lookup
- `env_set(t_env *env, char *key, char *value, int export)` — set/update
- `env_unset(t_env **env, char *key)` — remove
- `env_to_array(t_env *env)` — pour `execve`

---

### 8. `utils/` — Helpers transverses
- `error.c` — `print_error()`, format style bash
- `cleanup.c` — `free_tokens()`, `free_ast()`, `free_env()`
- `string_utils.c` — extensions de la libft

## Interface entre les deux développeurs

**Le contrat = les structures `t_token`, `t_cmd`, `t_pipeline`, `t_env`.**

Une fois ces structures gelées (fin semaine 1), chaque développeur bosse en parallèle :
- Frontend (Lexer/Parser/Expander) produit l'AST
- Backend (Executor/Builtins/Env) consomme l'AST

Le seul point de friction = les **signals** (touchent un peu partout). On le traite en pair-programming.

---

## Découpage en fichiers (norme 42 : max 4 fonctions / fichier)

> Cible : pas plus de 4 fonctions / fichier ⇒ ~6-13 fichiers par module. Plan inspiré d'un projet qui a tapé 99% à l'éval.

```
src/
├── main.c
├── lexer/                 ~6-8 fichiers
│   ├── lex_input.c           # entrée principale, boucle de scan
│   ├── lex_grammar.c         # détection opérateur vs mot vs whitespace
│   ├── lex_tokenize.c        # création des tokens un par un
│   ├── lex_tokenize_utils.c  # helpers (skip_ws, is_op_char…)
│   ├── lex_quotes.c          # gestion '...' et "..."
│   ├── lex_token_list.c      # init / add / size de la liste
│   └── lex_token_list_free.c # cleanup + free
├── parser/                ~10-13 fichiers
│   ├── parse_input.c         # entrée, dispatch par type de token
│   ├── parse_pipe.c          # | → enchaîne deux t_cmd
│   ├── parse_word.c          # mot → push dans argv
│   ├── parse_redir_in.c      # <
│   ├── parse_redir_out.c     # >
│   ├── parse_append.c        # >>
│   ├── parse_heredoc.c       # << (lit input ici, AVANT exec)
│   ├── parse_heredoc_utils.c
│   ├── parse_args_default.c  # remplissage argv standard
│   ├── parse_args_echo.c     # echo (-n peut être collé)
│   ├── parse_args_echo_utils.c
│   ├── cmd_list_utils.c      # init/add/size t_cmd
│   └── cmd_list_free.c       # cleanup
├── expander/              ~6-8 fichiers
│   ├── exp_run.c             # entrée, parcourt l'AST
│   ├── exp_var_identify.c    # repère "$NAME" / "$?" / "$1"
│   ├── exp_var_value.c       # récupère la valeur dans env (ou "")
│   ├── exp_var_replace.c     # remplace dans la string
│   ├── exp_quotes_handle.c   # respect quotes pendant expansion
│   └── exp_quotes_strip.c    # enlève les quotes au final
├── executor/              ~5-7 fichiers
│   ├── exec_run.c            # entrée, dispatch builtin / externe / pipeline
│   ├── exec_single.c         # une commande, sans pipe
│   ├── exec_pipeline.c       # boucle fork + pipe pour N commandes
│   ├── exec_path.c           # résolution PATH + relatif + absolu
│   ├── exec_child.c          # ce que fait le fils après fork
│   └── exec_wait.c           # waitpid + récupération exit code
├── redirections/          ~2-3 fichiers   (séparé d'executor)
│   ├── redir_files.c         # open/dup2 pour <, >, >>
│   └── redir_pipes.c         # création + plomberie des pipes
├── builtins/              ~7 fichiers (un par builtin)
│   ├── bi_echo.c
│   ├── bi_cd.c
│   ├── bi_pwd.c
│   ├── bi_export.c
│   ├── bi_unset.c
│   ├── bi_env.c
│   └── bi_exit.c
├── signals/               1-2 fichiers
│   ├── signals.c             # handlers + setup
│   └── signals_heredoc.c     # mode heredoc spécifique
├── env/                   ~3 fichiers
│   ├── env_init.c            # copie envp → linked list
│   ├── env_access.c          # get / set / unset
│   └── env_to_array.c        # linked list → char ** pour execve
└── utils/                 ~5 fichiers
    ├── ut_error.c
    ├── ut_cleanup.c
    ├── ut_init_data.c        # init de la struct globale du shell
    ├── ut_exit.c             # exit propre du shell
    └── ut_str.c              # extensions libft locales
```

**Total estimé** : **~55-65 fichiers `.c`**. Ça paraît énorme mais c'est ce qu'impose la norme avec ~250 fonctions.

---

## Décisions techniques critiques (à acter AVANT de coder)

### D1 — Heredoc lu PENDANT le parsing (avant exec)
Quand on parse `<< EOF`, on lit immédiatement les lignes du heredoc dans une string ou un fichier temporaire **avant** de lancer l'exécution. Pourquoi :
- Les signaux pendant le heredoc se gèrent depuis le shell parent (pas un enfant déjà forké).
- L'exécution ne se bloque pas en attente de stdin si plusieurs heredocs dans un pipeline.
- L'expansion `$VAR` dans le heredoc se fait avec l'env du shell, au moment du parsing.

**Stockage** : on stocke le contenu collecté dans le `t_redir` correspondant. Au moment de l'exec, on écrit ce contenu dans un pipe ou un tmpfile, puis on dup2 dessus.

### D2 — Variable globale `g_signal` : INT et rien d'autre
- Type : `int`. Pas de struct, pas de pointeur. La norme 42 du sujet est explicite.
- Usage : le handler stocke le numéro du signal reçu, le main loop le lit après chaque cycle.
- Toute info contextuelle (mode prompt/exec/heredoc) doit être déduite de l'état du shell, pas stockée dans une globale.

### D3 — Une struct "shell" passée partout
On évite les paramètres explosifs en passant un seul `t_shell *sh` à toutes les grosses fonctions :
```c
typedef struct s_shell
{
    t_env       *env;
    int          last_exit;
    char        *line;       // ligne courante (sortie readline)
    t_token     *tokens;
    t_pipeline  *ast;
}   t_shell;
```
Ça reste autorisé par la norme (1 variable, pas globale).

### D4 — Lexer : machine à état mais SIMPLE
Pas besoin d'une vraie state machine académique. 3 états suffisent :
- `NORMAL` — on scanne des mots et opérateurs
- `IN_SQUOTE` — on est entre `'...'`, tout est littéral
- `IN_DQUOTE` — on est entre `"..."`, expansion possible mais opérateurs neutralisés

Voir [PARSING_RULES.md](PARSING_RULES.md) pour la table complète.

### D5 — Parser : descent direct, pas d'arbre binaire
- L'AST n'est pas un vrai arbre : c'est une **liste chaînée de `t_cmd`** (un maillon par commande du pipeline). Les redirections sont une sous-liste attachée à chaque maillon.
- Pourquoi : on n'a pas besoin de gérer `&&`, `||`, `()` (sauf bonus). Une liste suffit.

### D6 — Exit codes : on copie bash bit pour bit
| Cas                                            | Exit code |
|------------------------------------------------|-----------|
| Commande OK                                    | 0         |
| Erreur générique                               | 1         |
| Mauvaise utilisation builtin (ex: `exit abc`)  | 2         |
| Commande non exécutable (permissions)          | 126       |
| Commande introuvable                           | 127       |
| Tué par signal `N`                             | 128 + N   |
| Ctrl-C pendant commande                        | 130       |
| Ctrl-\ pendant commande                        | 131       |

Voir [EDGE_CASES.md](EDGE_CASES.md) §exit-codes pour les cas tordus.

### D7 — Cleanup : un seul point de free par cycle REPL
À la fin de chaque tour de boucle (après exécution), on free :
1. La string `line` (readline)
2. La liste de tokens
3. L'AST (`t_pipeline` + chaque `t_cmd` + chaque `t_redir`)

On NE free PAS l'env (vit toute la session) ni `last_exit`. Cleanup global = uniquement à `exit`.

### D8 — Le bool "norm hack" : pas de variables globales pour `last_exit`
`last_exit` vit dans `t_shell`. Quand un builtin retourne, on assigne. Quand un fork termine, le wait renvoie un status → on convertit en exit code via `WEXITSTATUS` ou `128 + WTERMSIG`.

---

## Anti-patterns à bannir dès maintenant

- ❌ Ne pas mélanger lexer et parser dans la même fonction
- ❌ Ne pas faire d'expansion dans le lexer (on perd l'info de quote)
- ❌ Ne pas free dans une fonction qui retourne un pointeur qu'on utilise après (use-after-free classique sur les tokens)
- ❌ Ne pas `wait()` AVANT d'avoir fork tous les enfants d'un pipeline (deadlock sur SIGPIPE)
- ❌ Ne pas oublier `close()` sur les fds de pipe dans le parent (les fils restent bloqués à `read`)
- ❌ Ne pas appeler `exit()` depuis les builtins (sauf `exit` lui-même) — on `return` un code
- ❌ Ne pas utiliser `printf` pour les erreurs (utiliser `write` sur fd 2)
