# Tests — Minishell

> **Philosophie** : pas de feature mergée sans test qui prouve qu'elle marche.
> **Stratégie** : 4 niveaux (unit / module / integration / system) + script global.
> **Référence** : bash en mode non-interactif. En cas de doute, on compare avec bash.
> **Objectif** : ≥ 250 cas de test, exécutables en < 30s pour le run complet.

## Sommaire

1. [Pourquoi tester EN PERMANENCE](#1-pourquoi-tester-en-permanence)
2. [Arborescence](#2-arborescence)
3. [Helpers communs (lib.sh)](#3-helpers-communs-libsh)
4. [Sprint 1 — tests à passer pour clôturer S1](#4-sprint-1)
5. [Sprint 2 — tests à passer pour clôturer S2](#5-sprint-2)
6. [Sprint 3 — tests à passer pour clôturer S3](#6-sprint-3)
7. [Sprint 4 — tests à passer pour clôturer S4](#7-sprint-4)
8. [Tests de régression vs bash](#8-tests-de-régression-vs-bash)
9. [Tests de leaks](#9-tests-de-leaks)
10. [Tests manuels (signaux)](#10-tests-manuels-signaux)
11. [Stress tests](#11-stress-tests)
12. [Testers externes](#12-testers-externes)
13. [Script global run_all.sh](#13-script-global)

---

## 1. Pourquoi tester EN PERMANENCE

> **Règle d'or** : pour chaque issue mergée, AU MOINS UN test exécutable doit être ajouté.
> Pas de test = pas de merge. Cette règle est dans la définition de "Done".

**Coût d'un bug attrapé tôt vs tard** :
- Trouvé en unit test : 5 min de fix
- Trouvé en integration : 30 min (déjà oublié pourquoi tu l'as écrit comme ça)
- Trouvé en éval : la note baisse, le binôme déprime, on refait des nuits blanches

Cette doc liste les tests **par sprint** pour qu'à la fin de chaque semaine, on sache exactement ce qu'on doit vérifier avant de passer à la suite. **On ne passe pas au sprint N+1 si les tests du sprint N ne passent pas.**

---

## 2. Arborescence

```
tests/
├── lib.sh                    # helpers communs (sourcés partout)
├── run_all.sh                # lance tout : compile + unit + integ + sys + leaks + norm
├── run_sprint.sh             # lance les tests d'un sprint donné : ./run_sprint.sh 2
├── readline.supp             # suppressions valgrind pour readline
│
├── unit/                     # tests par module, en isolation
│   ├── test_lexer.sh
│   ├── test_parser.sh
│   ├── test_expander.sh
│   ├── test_env.sh
│   └── test_quotes.sh
│
├── integration/              # tests cross-module
│   ├── test_builtins.sh
│   ├── test_single_cmd.sh
│   ├── test_redirs.sh
│   ├── test_pipes.sh
│   ├── test_heredoc.sh
│   ├── test_exit_codes.sh
│   ├── test_concat.sh
│   └── test_errors.sh
│
├── system/                   # comparaison avec bash
│   ├── test_vs_bash.sh
│   └── bash_oracle.sh        # outil qui génère l'output attendu via bash
│
├── leaks/
│   ├── leaks_basic.sh
│   ├── leaks_pipes.sh
│   └── leaks_heredoc.sh
│
├── manual/
│   ├── SIGNALS.md            # checklist signaux
│   └── INTERACTIVE.md        # cas qui nécessitent un humain
│
└── fixtures/                 # fichiers texte / scripts de test
    ├── small.txt
    ├── empty.txt
    └── permission_denied.txt
```

---

## 3. Helpers communs (lib.sh)

```bash
#!/bin/bash
# tests/lib.sh — sourced par tous les scripts de test

SHELL_BIN="${SHELL_BIN:-./minishell}"
BASH_BIN="${BASH_BIN:-bash}"

PASS=0
FAIL=0
FAILED_TESTS=()

# Couleurs (désactivables avec NO_COLOR=1)
if [ -z "$NO_COLOR" ]; then
    C_GREEN='\033[0;32m' ; C_RED='\033[0;31m' ; C_RESET='\033[0m'
else
    C_GREEN='' ; C_RED='' ; C_RESET=''
fi

run_shell() {
    # Pipe la commande passée en arg dans minishell, stdout = output
    echo "$1" | $SHELL_BIN 2>/dev/null
}

run_shell_full() {
    # Comme run_shell mais capture stdout + stderr + exit code
    local out
    out=$(echo "$1" | $SHELL_BIN 2>&1)
    local code=$?
    echo "$out"
    return $code
}

run_bash() {
    echo "$1" | $BASH_BIN --posix 2>/dev/null
}

assert_eq() {
    local name="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        printf "  ${C_GREEN}✓${C_RESET} %s\n" "$name"
        PASS=$((PASS+1))
    else
        printf "  ${C_RED}✗${C_RESET} %s\n" "$name"
        printf "    expected: %q\n" "$expected"
        printf "    actual:   %q\n" "$actual"
        FAIL=$((FAIL+1))
        FAILED_TESTS+=("$name")
    fi
}

assert_exit() {
    # assert_exit "name" expected_code "cmd"
    local name="$1" expected_code="$2" cmd="$3"
    local out
    out=$(echo -e "$cmd\necho \$?" | $SHELL_BIN 2>/dev/null)
    local actual_code=$(echo "$out" | tail -1)
    if [ "$expected_code" = "$actual_code" ]; then
        printf "  ${C_GREEN}✓${C_RESET} %s\n" "$name"
        PASS=$((PASS+1))
    else
        printf "  ${C_RED}✗${C_RESET} %s — exit code\n" "$name"
        printf "    expected: %s\n" "$expected_code"
        printf "    actual:   %s\n" "$actual_code"
        FAIL=$((FAIL+1))
        FAILED_TESTS+=("$name")
    fi
}

assert_same_as_bash() {
    # assert_same_as_bash "name" "cmd"
    local name="$1" cmd="$2"
    local mini bash_out
    mini=$(run_shell "$cmd")
    bash_out=$(run_bash "$cmd")
    assert_eq "$name" "$bash_out" "$mini"
}

assert_contains() {
    # assert_contains "name" "needle" "haystack"
    local name="$1" needle="$2" haystack="$3"
    if echo "$haystack" | grep -qF "$needle"; then
        printf "  ${C_GREEN}✓${C_RESET} %s\n" "$name"
        PASS=$((PASS+1))
    else
        printf "  ${C_RED}✗${C_RESET} %s — '%s' not in output\n" "$name" "$needle"
        FAIL=$((FAIL+1))
        FAILED_TESTS+=("$name")
    fi
}

summary() {
    echo ""
    printf "─────────────────────────────\n"
    printf "Total: %d — Pass: ${C_GREEN}%d${C_RESET} — Fail: ${C_RED}%d${C_RESET}\n" \
        $((PASS+FAIL)) $PASS $FAIL
    if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
        printf "${C_RED}Failed tests:${C_RESET}\n"
        for t in "${FAILED_TESTS[@]}"; do
            printf "  - %s\n" "$t"
        done
        exit 1
    fi
    exit 0
}
```

---

## 4. Sprint 1

### Critères go/no-go pour clôturer S1

Tous ces tests **doivent passer** avant d'attaquer S2.

#### 4.1 `tests/unit/test_lexer.sh`

> Test le lexer seul, sans parser. On utilise un mode debug du binaire (`./minishell --print-tokens "cmd"`) qui imprime les tokens et quitte. À implémenter dès S1.

```bash
#!/bin/bash
source tests/lib.sh

echo "=== Lexer — basics ==="

# Format expected output (un token par ligne, type:value)
expect_tokens() {
    local name="$1" input="$2" expected="$3"
    local actual=$($SHELL_BIN --print-tokens "$input" 2>/dev/null)
    assert_eq "$name" "$expected" "$actual"
}

expect_tokens "single word"        "ls"                  "WORD:ls"
expect_tokens "two words"          "ls -la"              $'WORD:ls\nWORD:-la'
expect_tokens "many spaces"        "ls    -la"           $'WORD:ls\nWORD:-la'
expect_tokens "leading spaces"     "   ls"               "WORD:ls"
expect_tokens "pipe"               "ls | wc"             $'WORD:ls\nPIPE\nWORD:wc'
expect_tokens "pipe no spaces"     "ls|wc"               $'WORD:ls\nPIPE\nWORD:wc'
expect_tokens "redir out"          "ls > out"            $'WORD:ls\nREDIR_OUT\nWORD:out'
expect_tokens "redir in"           "cat < f"             $'WORD:cat\nREDIR_IN\nWORD:f'
expect_tokens "append"             "ls >> out"           $'WORD:ls\nAPPEND\nWORD:out'
expect_tokens "heredoc"            "cat << EOF"          $'WORD:cat\nHEREDOC\nWORD:EOF'

echo "=== Lexer — quotes ==="

expect_tokens "single quoted"      "echo 'hi'"           $'WORD:echo\nWORD:hi'
expect_tokens "double quoted"      'echo "hi"'           $'WORD:echo\nWORD:hi'
expect_tokens "quotes preserved"   "echo 'a b'"          $'WORD:echo\nWORD:a b'
expect_tokens "concat word+quote"  'echo a"b"c'          $'WORD:echo\nWORD:abc'
expect_tokens "quote contains pipe" 'echo "|"'           $'WORD:echo\nWORD:|'
expect_tokens "empty quotes"       'echo ""'             $'WORD:echo\nWORD:'

echo "=== Lexer — erreurs ==="

expect_tokens "unclosed dquote"    'echo "hi'            "ERROR:unclosed_quote"
expect_tokens "unclosed squote"    "echo 'hi"            "ERROR:unclosed_quote"

summary
```

#### 4.2 `tests/unit/test_env.sh`

```bash
#!/bin/bash
source tests/lib.sh

echo "=== Env basics ==="

assert_eq "env affiche" "$(printenv USER)" "$(run_shell 'env | grep ^USER= | head -1' | cut -d= -f2-)"
assert_eq "echo \$USER" "$USER" "$(run_shell 'echo $USER')"
assert_eq "echo \$INEXISTANT" "" "$(run_shell 'echo $INEXISTANT')"
assert_eq "export FOO=bar" "bar" "$(run_shell 'export FOO=bar; echo $FOO')"
assert_eq "unset FOO" "" "$(run_shell 'export FOO=bar; unset FOO; echo $FOO')"
assert_eq "multiple export" "1 2 3" "$(run_shell 'export A=1 B=2 C=3; echo $A $B $C')"
assert_eq "export empty value" "[]" "$(run_shell 'export X=; echo [$X]')"

echo "=== Env — exit codes ==="
assert_exit "export valid"    0 'export FOO=bar'
assert_exit "export invalid"  1 'export 1FOO=bar'
assert_exit "unset valid"     0 'unset FOO'
assert_exit "unset invalid"   1 'unset 1FOO'

summary
```

#### 4.3 `tests/integration/test_builtins.sh` (simples, sans exec)

```bash
#!/bin/bash
source tests/lib.sh

echo "=== echo ==="
assert_eq "echo"            ""              "$(run_shell 'echo')"
assert_eq "echo hello"      "hello"         "$(run_shell 'echo hello')"
assert_eq "echo -n"         ""              "$(run_shell 'echo -n')"
assert_eq "echo -n hello"   "hello"         "$(run_shell 'echo -n hello')"
assert_eq "echo -nnn"       ""              "$(run_shell 'echo -nnn')"
assert_eq "echo -n -n hi"   "hi"            "$(run_shell 'echo -n -n hi')"
assert_eq "echo hello -n"   "hello -n"      "$(run_shell 'echo hello -n')"

echo "=== pwd ==="
assert_eq "pwd" "$(pwd)" "$(run_shell 'pwd')"

echo "=== exit ==="
assert_exit "exit"          0 'exit'
assert_exit "exit 42"       42 'exit 42'
assert_exit "exit 256"      0 'exit 256'
assert_exit "exit -1"       255 'exit -1'
assert_exit "exit abc"      2 'exit abc'

summary
```

#### Sprint 1 — checklist de clôture
- [ ] `bash tests/unit/test_lexer.sh` passe (≥ 16 cas)
- [ ] `bash tests/unit/test_env.sh` passe (≥ 10 cas)
- [ ] `bash tests/integration/test_builtins.sh` passe pour echo/pwd/exit/env (≥ 15 cas)
- [ ] `make re` sans warning
- [ ] `norminette src/ includes/` zéro erreur
- [ ] `valgrind ./minishell <<< "echo hi"` aucun leak

---

## 5. Sprint 2

### Critères go/no-go pour clôturer S2

#### 5.1 `tests/unit/test_parser.sh`

```bash
#!/bin/bash
source tests/lib.sh

# Mode debug : --print-ast affiche l'AST
echo "=== Parser — simple ==="

expect_ast() {
    local name="$1" input="$2" expected="$3"
    local actual=$($SHELL_BIN --print-ast "$input" 2>/dev/null)
    assert_eq "$name" "$expected" "$actual"
}

expect_ast "one cmd"     "ls"           "CMD: ls"
expect_ast "one cmd arg" "ls -la"       "CMD: ls -la"
expect_ast "pipe 2"      "ls | wc"      $'CMD: ls\nCMD: wc'
expect_ast "pipe 3"      "a | b | c"    $'CMD: a\nCMD: b\nCMD: c'
expect_ast "redir out"   "ls > out"     $'CMD: ls\n  REDIR_OUT: out'
expect_ast "redir all"   "ls < in > out >> ap << END"   \
    $'CMD: ls\n  REDIR_IN: in\n  REDIR_OUT: out\n  APPEND: ap\n  HEREDOC: END'

echo "=== Parser — erreurs ==="
assert_exit "pipe seul"        2 '|'
assert_exit "pipe au début"    2 '| ls'
assert_exit "pipe à la fin"    2 'ls |'
assert_exit "double pipe"      2 'ls || wc'
assert_exit "redir vide"       2 '>'
assert_exit "redir double op"  2 '> >'
assert_exit "unclosed quote"   2 'echo "hi'

summary
```

#### 5.2 `tests/integration/test_single_cmd.sh`

```bash
#!/bin/bash
source tests/lib.sh

echo "=== Single command — externe ==="
assert_same_as_bash "ls /tmp"        "ls /tmp"
assert_same_as_bash "/bin/ls /tmp"   "/bin/ls /tmp"
assert_same_as_bash "cat Makefile"   "cat Makefile | head -1"

echo "=== Single command — not found ==="
assert_exit "command not found"  127 "definitely_not_a_command"
assert_exit "path no such"       127 "/nope/nope/nope"
assert_exit "path is dir"        126 "/tmp"

echo "=== Builtin cd ==="
assert_eq "cd /tmp + pwd" "/tmp" "$(run_shell 'cd /tmp; pwd')"
assert_eq "cd .. cohérent" "/" "$(run_shell 'cd /tmp; cd ..; pwd')"
assert_exit "cd nonexistent" 1 'cd /nonexistent'

summary
```

#### 5.3 `tests/integration/test_redirs.sh`

```bash
#!/bin/bash
source tests/lib.sh

OUT=/tmp/minishell_test_$$

cleanup() { rm -f $OUT $OUT.1 $OUT.2; }
trap cleanup EXIT

echo "=== Redirections — out ==="
run_shell "echo hi > $OUT"
assert_eq "echo > out" "hi" "$(cat $OUT)"

run_shell "echo a > $OUT; echo b >> $OUT"
assert_eq "echo >> out" $'a\nb' "$(cat $OUT)"

echo "=== Redirections — in ==="
echo "input content" > $OUT
assert_eq "cat < in" "input content" "$(run_shell "cat < $OUT")"

echo "=== Redirections — multiples ==="
run_shell "echo X > $OUT.1 > $OUT.2"
assert_eq "multi out — file 1 existe vide" "" "$(cat $OUT.1)"
assert_eq "multi out — file 2 contient" "X" "$(cat $OUT.2)"

echo "=== Redirections — erreurs ==="
assert_exit "read nonexistent"  1 "cat < /nope_$$"
assert_exit "no perm to read"   1 "cat < /etc/shadow"

summary
```

#### Sprint 2 — checklist
- [ ] `tests/unit/test_parser.sh` ≥ 15 cas
- [ ] `tests/integration/test_single_cmd.sh` ≥ 10 cas
- [ ] `tests/integration/test_redirs.sh` ≥ 10 cas
- [ ] `echo $?` cohérent partout
- [ ] `cd` change le cwd et met à jour PWD/OLDPWD
- [ ] aucun leak sur ces tests

---

## 6. Sprint 3

#### 6.1 `tests/unit/test_expander.sh`

```bash
#!/bin/bash
source tests/lib.sh

echo "=== Expander — basics ==="
assert_same_as_bash "$USER simple"     'echo $USER'
assert_same_as_bash "$USER in dquote"  'echo "$USER"'
assert_same_as_bash "$USER in squote"  "echo '\$USER'"
assert_same_as_bash "$INEXISTANT"      'echo $INEXISTANT'
assert_same_as_bash "\$? after true"   'true; echo $?'
assert_same_as_bash "\$? after false"  'false; echo $?'
assert_same_as_bash "concat"           'echo $USER$HOME'
assert_same_as_bash "concat mixed"     'echo "$USER"x"$USER"'

echo "=== Expander — cas tordus ==="
assert_same_as_bash "$ alone"          'echo $'
assert_same_as_bash "$ before space"   'echo $ HOME'
assert_same_as_bash "dollar dot"       'echo $.'
assert_same_as_bash "var then word"    'echo $USERhello'  # USERhello vide
assert_same_as_bash "var underscore"   'export _X=hi; echo $_X'

echo "=== Expander — quotes ==="
assert_same_as_bash "I am dquote"      'echo "I am $USER today"'
assert_same_as_bash "I am squote"      "echo 'I am \$USER today'"
assert_same_as_bash "mixed quotes"     "echo '\$USER'\"\$USER\""

summary
```

#### 6.2 `tests/integration/test_pipes.sh`

```bash
#!/bin/bash
source tests/lib.sh

echo "=== Pipes ==="
assert_same_as_bash "ls | wc -l"        'ls /tmp | wc -l'
assert_same_as_bash "3 pipes"           'ls /tmp | head -3 | wc -l'
assert_same_as_bash "echo | cat | cat"  'echo hi | cat | cat | cat | cat'
assert_same_as_bash "pipe with var"     'export X=hi; echo $X | cat'

echo "=== Pipes — exit codes ==="
assert_exit "true | true"   0 'true | true'
assert_exit "true | false"  1 'true | false'
assert_exit "false | true"  0 'false | true'
assert_exit "nope | true"   0 'nonexistent_cmd | true'
assert_exit "true | nope"   127 'true | nonexistent_cmd'

echo "=== Pipes — builtin dans pipe ==="
# cd dans un pipe ne change pas le cwd du shell
assert_eq "cd in pipe" "$(pwd)" "$(run_shell 'cd /tmp | true; pwd')"

summary
```

#### 6.3 `tests/integration/test_heredoc.sh`

```bash
#!/bin/bash
source tests/lib.sh

echo "=== Heredoc basics ==="
assert_eq "heredoc simple" "hello" "$(run_shell $'cat << EOF\nhello\nEOF')"
assert_eq "heredoc multi"  $'a\nb\nc' "$(run_shell $'cat << END\na\nb\nc\nEND')"

echo "=== Heredoc — expansion ==="
assert_same_as_bash "heredoc expand"   $'cat << EOF\n$USER\nEOF'
assert_same_as_bash "heredoc no expand" $'cat << "EOF"\n$USER\nEOF'

echo "=== Heredoc — pipe ==="
assert_eq "heredoc | wc" "3" "$(run_shell $'cat << EOF | wc -l\na\nb\nc\nEOF')"

echo "=== Heredoc — multiples ==="
# Seul le dernier compte
assert_eq "double heredoc" "second" "$(run_shell $'cat << A << B\njunk\nA\nsecond\nB')"

summary
```

#### Sprint 3 — checklist
- [ ] `tests/unit/test_expander.sh` ≥ 15 cas
- [ ] `tests/integration/test_pipes.sh` ≥ 15 cas
- [ ] `tests/integration/test_heredoc.sh` ≥ 10 cas
- [ ] `echo $?` reflète bien le code du dernier maillon du pipeline
- [ ] `export X=Y` puis `$X` dans la même session ⇒ Y
- [ ] aucun leak

---

## 7. Sprint 4

#### 7.1 `tests/integration/test_exit_codes.sh`

```bash
#!/bin/bash
source tests/lib.sh

echo "=== Exit codes — basics ==="
assert_exit "true"               0   'true'
assert_exit "false"              1   'false'
assert_exit "exit 0"             0   'exit 0'
assert_exit "exit 42"            42  'exit 42'
assert_exit "exit -1"            255 'exit -1'
assert_exit "exit 256"           0   'exit 256'

echo "=== Exit codes — errors ==="
assert_exit "command not found"  127 'nope'
assert_exit "permission denied"  126 '/etc/passwd'
assert_exit "syntax error"       2   '|'
assert_exit "syntax unclosed"    2   'echo "hi'

echo "=== Exit codes — chaining via \$? ==="
assert_eq "false ; echo \$?"   "1"   "$(run_shell 'false; echo $?')"
assert_eq "true ; false ; \$?" "1"   "$(run_shell 'true; false; echo $?')"

summary
```

#### 7.2 `tests/integration/test_concat.sh`

```bash
#!/bin/bash
source tests/lib.sh

echo "=== Concaténation ==="
assert_same_as_bash "abc"       'echo a"b"c'
assert_same_as_bash "var sq"    "echo \"\$USER\"' is here'"
assert_same_as_bash "empty"     'echo ""'
assert_same_as_bash "empty x2"  'echo "" ""'
assert_same_as_bash "weird"     'echo a""""b'
assert_same_as_bash "mid var"   'echo "$U"SER'

summary
```

#### 7.3 `tests/integration/test_errors.sh`

```bash
#!/bin/bash
source tests/lib.sh

echo "=== Error messages format ==="

check_stderr() {
    local name="$1" cmd="$2" needle="$3"
    local err=$(echo "$cmd" | $SHELL_BIN 2>&1 >/dev/null)
    assert_contains "$name" "$needle" "$err"
}

check_stderr "cnf format"      'nope_cmd'                 'command not found'
check_stderr "cd noent format' 'cd /nope_$$'              'No such file or directory'
check_stderr "syntax format"   '|'                        'syntax error'
check_stderr "exit numeric"    'exit abc'                 'numeric argument'
check_stderr "export invalid"  'export 1F=a'              'not a valid identifier'
check_stderr "unset invalid"   'unset 1F'                 'not a valid identifier'

# Le prefixe "minishell:"
check_stderr "prefix"          'nope'                     'minishell:'

summary
```

#### Sprint 4 — checklist (= rendu prêt)
- [ ] tous les tests des sprints précédents passent encore
- [ ] `tests/integration/test_exit_codes.sh` ≥ 15 cas
- [ ] `tests/integration/test_concat.sh` ≥ 10 cas
- [ ] `tests/integration/test_errors.sh` ≥ 10 cas
- [ ] `tests/system/test_vs_bash.sh` ≥ 30 cas (cf §8)
- [ ] `tests/manual/SIGNALS.md` toutes cases cochées (cf §10)
- [ ] `tests/leaks/*` aucun leak
- [ ] norminette zéro erreur
- [ ] 2 testers externes (francinette, 42_minishell_tester) ≥ 95% pass
- [ ] README final écrit (cf [CHECKLIST.md](CHECKLIST.md))

---

## 8. Tests de régression vs bash

> La référence absolue. Tout ce qui diverge de bash sans justification = bug.

`tests/system/test_vs_bash.sh` :

```bash
#!/bin/bash
source tests/lib.sh

CMDS=(
    # Echo
    'echo'
    'echo hello'
    'echo -n hi'
    'echo "$USER"'
    "echo '\$USER'"
    'echo a"b"c'
    'echo "  spaces  "'
    'echo "" ""'

    # Pwd / cd
    'pwd'
    'cd /tmp && pwd'
    'cd / && cd .. && pwd'

    # Env / export
    'export X=42 && echo $X'
    'export A=1 B=2 && echo $A $B'
    'export X=hi && unset X && echo "[$X]"'

    # Pipes
    'ls / | head -3'
    'echo hi | cat | cat | cat'
    'true | false'
    'false | true'

    # Redirections
    'echo hi > /tmp/mtest && cat /tmp/mtest'
    'echo a > /tmp/mtest && echo b >> /tmp/mtest && cat /tmp/mtest'

    # Heredoc
    $'cat << EOF\nhello\nEOF'
    $'cat << "EOF"\n$USER\nEOF'
    $'cat << EOF | wc -l\na\nb\nc\nEOF'

    # Exit codes
    'true; echo $?'
    'false; echo $?'
    'nonexistent_cmd_xyz; echo $?'

    # Quotes
    'echo "I am $USER and home is $HOME"'
    "echo 'literal \$USER'"
    'echo a""""b'

    # Variables tordues
    'echo $'
    'echo $?'
    'echo $INEXISTANT'
    'echo $USER$USER'
)

for cmd in "${CMDS[@]}"; do
    assert_same_as_bash "$cmd" "$cmd"
done

summary
```

---

## 9. Tests de leaks

`tests/leaks/leaks_basic.sh` :

```bash
#!/bin/bash
# Lance minishell avec valgrind sur un set de commandes représentatif.
# Si leaks détectés (hors readline), exit 42.

valgrind --leak-check=full \
         --show-leak-kinds=definite,indirect \
         --errors-for-leak-kinds=definite,indirect \
         --suppressions=tests/readline.supp \
         --error-exitcode=42 \
         --quiet \
         ./minishell <<'EOF'
echo hello
echo "$USER"
echo 'literal $USER'
pwd
cd /tmp
pwd
cd -
export X=42
echo $X
unset X
ls / | head -3
echo hi | cat | cat | cat
echo a > /tmp/mleak_$$
echo b >> /tmp/mleak_$$
cat < /tmp/mleak_$$
rm /tmp/mleak_$$ 2>/dev/null
cat << EOF1
hello $USER
EOF1
true
false
echo $?
exit 0
EOF

if [ $? -eq 42 ]; then
    echo "❌ LEAKS DÉTECTÉS"
    exit 1
else
    echo "✅ Pas de leaks"
fi
```

`tests/readline.supp` :
```
{
   readline_init
   Memcheck:Leak
   ...
   fun:readline
}
{
   add_history_alloc
   Memcheck:Leak
   ...
   fun:add_history
}
{
   rl_* allocations
   Memcheck:Leak
   ...
   fun:rl_*
}
```

---

## 10. Tests manuels (signaux)

`tests/manual/SIGNALS.md` :

```markdown
# Signals — vérification manuelle

> À faire à 2 (un pilote, un coche). Lancer `./minishell`.

## A. Prompt vide
- [ ] Ctrl-C : newline, nouveau prompt, le shell ne quitte PAS
- [ ] Ctrl-C suivi de `echo $?` : affiche `130`
- [ ] Ctrl-\\ : RIEN ne se passe (pas de quit, pas de message)
- [ ] Ctrl-D : le shell quitte proprement (équivalent `exit`)

## B. Prompt avec texte tapé (mais pas validé)
- [ ] Taper `bonjour` (pas d'entrée) puis Ctrl-C : la ligne est effacée, nouveau prompt
- [ ] Le buffer est bien vide après Ctrl-C (Enter ne relance pas `bonjour`)

## C. Pendant qu'une commande tourne (lancer `cat` sans arg)
- [ ] Ctrl-C : tue cat, newline, nouveau prompt
- [ ] `echo $?` après Ctrl-C : `130`
- [ ] Relancer cat, Ctrl-\\ : tue cat, "Quit (core dumped)", `echo $?` = `131`
- [ ] Relancer cat, Ctrl-D : cat lit EOF, finit normalement, `$?` = `0`

## D. Pendant un heredoc (`cat << END`)
- [ ] Taper quelques lignes, Ctrl-C : annule heredoc, prompt revient, `$?` = `130`
- [ ] Taper quelques lignes, Ctrl-D : warning sur stderr + exécute avec ce qui a été lu
- [ ] Pendant un heredoc, Ctrl-\\ : RIEN (ignoré)

## E. Pendant un pipeline (`cat | cat | cat`)
- [ ] Ctrl-C : tous les `cat` sont tués, prompt revient, `$?` = `130`
- [ ] Ctrl-\\ : tous tués, "Quit", `$?` = `131`

## F. Comparaison avec bash
Lancer bash dans un autre terminal, refaire chaque scénario, vérifier que l'output est identique (ou très proche : on tolère des petites différences de wording sur les messages signal).
```

---

## 11. Stress tests

`tests/stress.sh` — à lancer en S4 pour la robustesse :

```bash
#!/bin/bash
# Tests de stress — n'attendez pas qu'ils soient verts à 100%, mais ils ne
# doivent ni segfault ni leaker.

set -e
SHELL_BIN=${SHELL_BIN:-./minishell}

echo "=== 1. Très longues lignes ==="
LONG=$(printf 'a%.0s' {1..10000})
echo "echo $LONG" | $SHELL_BIN > /dev/null

echo "=== 2. Pipeline très long ==="
PIPELINE="echo hi"
for i in $(seq 1 50); do PIPELINE="$PIPELINE | cat"; done
echo "$PIPELINE" | $SHELL_BIN

echo "=== 3. Beaucoup de commandes successives ==="
for i in $(seq 1 1000); do echo "echo $i > /dev/null"; done | $SHELL_BIN

echo "=== 4. Variables avec valeurs énormes ==="
BIGVAR=$(printf 'x%.0s' {1..10000})
echo "export Y=$BIGVAR; echo \${#Y}" | $SHELL_BIN  # #Y bash-only mais on teste juste pas de crash

echo "=== 5. Heredoc géant ==="
{
    echo "cat << END | wc -l"
    seq 1 5000
    echo "END"
} | $SHELL_BIN

echo "✅ Stress tests OK (pas de crash)"
```

---

## 12. Testers externes

À lancer **au moins 1 fois par semaine** une fois qu'on a quelque chose qui tourne :

| Tester | Repo | Notes |
|--------|------|-------|
| **francinette** (paco) | github.com/xicodomingues/francinette | Le plus complet, 4000+ cas, intègre tous les projets 42 |
| **42_minishell_tester** | github.com/zstenger93/42_minishell_tester | Spécifique minishell, granulaire par section |
| **mshell_tester** | github.com/LucasKuhn/mini_hell | Plus léger, bonne sanity check |
| **minihell_tester** | github.com/grademy-fr/minishell_tester | Récent, à jour |

> **Règle** : on lance 2 testers différents avant chaque PR vers `main`. Si l'un échoue sur un cas qu'on pense correct → on compare avec bash et on tranche.

---

## 13. Script global

`tests/run_all.sh` :

```bash
#!/bin/bash
set -e
cd "$(dirname "$0")/.."

step() {
    echo ""
    echo "═══════════════════════════════"
    echo "  $1"
    echo "═══════════════════════════════"
}

step "1. Build"
make re

step "2. Norminette"
norminette src/ includes/ || { echo "❌ Norm"; exit 1; }

step "3. Unit tests"
for t in tests/unit/test_*.sh; do bash "$t"; done

step "4. Integration tests"
for t in tests/integration/test_*.sh; do bash "$t"; done

step "5. System tests (vs bash)"
bash tests/system/test_vs_bash.sh

step "6. Leaks"
bash tests/leaks/leaks_basic.sh

step "7. Stress (best effort)"
bash tests/stress.sh || echo "⚠️  Stress imparfait (acceptable)"

echo ""
echo "✅ Tous les tests automatiques passent."
echo "👉 Reste : tests manuels signaux (tests/manual/SIGNALS.md) + testers externes."
```

`tests/run_sprint.sh` :

```bash
#!/bin/bash
# Usage : ./run_sprint.sh <N>
# Lance les tests du sprint N.
set -e
SPRINT="${1:-1}"

case "$SPRINT" in
    1)
        bash tests/unit/test_lexer.sh
        bash tests/unit/test_env.sh
        bash tests/integration/test_builtins.sh
        ;;
    2)
        bash tests/unit/test_parser.sh
        bash tests/integration/test_single_cmd.sh
        bash tests/integration/test_redirs.sh
        ;;
    3)
        bash tests/unit/test_expander.sh
        bash tests/integration/test_pipes.sh
        bash tests/integration/test_heredoc.sh
        ;;
    4)
        bash tests/run_all.sh
        ;;
    *) echo "Usage: $0 <1|2|3|4>" ; exit 1 ;;
esac
```

---

## Rappel — pourquoi tout ce ramdam

Sans cette discipline :
- Tu écris le lexer, "ça a l'air de marcher", tu passes au parser.
- Une semaine plus tard, le pipeline plante. Tu te demandes : "le bug est-il dans le lexer, le parser ou l'expander ?"
- Tu passes 3 nuits à dichotomiser.

Avec cette discipline :
- À chaque issue, un test ajouté.
- À chaque PR, `./run_sprint.sh <N>` passe.
- Quand le pipeline plante en S4, tu sais que **les modules pris isolément** sont OK → c'est forcément l'intégration. Tu vas direct au bon endroit.

> **Promesse** : si on respecte ce doc, on économise une semaine sur le debug.
