#!/bin/bash
# tests/unit/test_lexer.sh
# Issue #11 - Tests unitaires lexer
#
# Deux blocs :
#   A. INVARIANTS  - doivent passer AVANT et APRES la passe 2 (quotes conservees)
#   B. PASSE 2     - rouges tant que lex_handle_quote_char ne garde pas les quotes
#
# Usage : bash tests/unit/test_lexer.sh

set -e
cd "$(dirname "$0")/../.."
SKIP_BIN_CHECK=1
source tests/lib.sh

LEX_BIN="/tmp/minishell_lexer_test"
trap 'rm -f "$LEX_BIN"' EXIT

make --no-print-directory -C libft >/dev/null
cc -Wall -Wextra -Werror \
	tests/unit/lexer_runner.c \
	src/lexer/lex_tokenize.c \
	src/lexer/lex_quotes.c \
	src/lexer/lex_operators.c \
	src/lexer/lex_token_list.c \
	src/lexer/lex_token_list_free.c \
	src/lexer/lex_tokenize_utils.c \
	libft/libft.a \
	-o "$LEX_BIN"

lex() { "$LEX_BIN" "$1"; }

echo "═══ A. Invariants (doivent rester verts apres la passe 2) ═══"

assert_eq "mot simple" \
"WORD|echo" \
"$(lex 'echo')"

assert_eq "deux mots" \
"WORD|echo
WORD|hello" \
"$(lex 'echo hello')"

assert_eq "espaces multiples ignores" \
"WORD|ls
WORD|-la" \
"$(lex 'ls    -la')"

assert_eq "espaces en debut et fin" \
"WORD|ls" \
"$(lex '  ls  ')"

assert_eq "pipe avec espaces" \
"WORD|ls
PIPE||
WORD|grep" \
"$(lex 'ls | grep')"

assert_eq "pipe colle aux mots" \
"WORD|ls
PIPE||
WORD|grep" \
"$(lex 'ls|grep')"

assert_eq "redirection entrante" \
"WORD|cat
REDIR_IN|<
WORD|in" \
"$(lex 'cat < in')"

assert_eq "redirection sortante" \
"WORD|ls
REDIR_OUT|>
WORD|out" \
"$(lex 'ls > out')"

assert_eq "append" \
"WORD|ls
APPEND|>>
WORD|out" \
"$(lex 'ls >> out')"

assert_eq "heredoc" \
"WORD|cat
HEREDOC|<<
WORD|EOF" \
"$(lex 'cat << EOF')"

assert_eq "redirections collees" \
"WORD|cat
REDIR_IN|<
WORD|in
REDIR_OUT|>
WORD|out" \
"$(lex 'cat <in >out')"

assert_eq "pipeline a trois" \
"WORD|ls
PIPE||
WORD|grep
PIPE||
WORD|wc" \
"$(lex 'ls | grep | wc')"

assert_eq "quote simple non fermee -> NULL" \
"NULL" \
"$(lex "echo 'abc")"

assert_eq "quote double non fermee -> NULL" \
"NULL" \
"$(lex 'echo "abc')"

assert_eq "ligne vide -> NULL" \
"NULL" \
"$(lex '')"

assert_eq "quotes fermees : un seul token pour le contenu" \
"2" \
"$(lex 'echo "a b"' | wc -l | tr -d ' ')"

echo ""
echo "═══ B. Passe 2 : les quotes doivent rester dans la valeur du token ═══"
echo "   (rouges tant que lex_handle_quote_char ne les ajoute pas au buffer)"

assert_eq "guillemets doubles conserves" \
'WORD|echo
WORD|"a b"' \
"$(lex 'echo "a b"')"

assert_eq "quote simple dans guillemets doubles" \
"WORD|echo
WORD|\"a'b\"" \
"$(lex $'echo "a\'b"')"

assert_eq "quotes adjacentes de types differents" \
"WORD|echo
WORD|abc\"def\"'ghi'" \
"$(lex $'echo abc"def"\'ghi\'')"

assert_eq "quotes simples conservees" \
"WORD|echo
WORD|'\$HOME'" \
"$(lex $'echo \'$HOME\'')"

assert_eq "token vide quote" \
"WORD|echo
WORD|''" \
"$(lex "echo ''")"

summary
