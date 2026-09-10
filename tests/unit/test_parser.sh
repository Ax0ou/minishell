#!/bin/bash
# tests/unit/test_parser.sh
# Issues #19 / #20 / #22 - Tests unitaires parser
#
# Deux blocs :
#   A. #19 - token list vers t_cmd list (argv + pipes)
#   B. #20 - attachement des redirections
#
# Format de sortie du runner :
#   CMD|arg0|arg1|...      une ligne par commande
#   REDIR|TYPE|cible       les redirections suivent leur commande
#   NULL                   parse_tokens a retourne NULL

set -e
cd "$(dirname "$0")/../.."
SKIP_BIN_CHECK=1
source tests/lib.sh

P_BIN="/tmp/minishell_parser_test"
trap 'rm -f "$P_BIN"' EXIT

make --no-print-directory -C libft >/dev/null
cc -Wall -Wextra -Werror \
	tests/unit/parser_runner.c \
	src/lexer/lex_tokenize.c \
	src/lexer/lex_quotes.c \
	src/lexer/lex_operators.c \
	src/lexer/lex_token_list.c \
	src/lexer/lex_token_list_free.c \
	src/lexer/lex_tokenize_utils.c \
	src/parser/parse_input.c \
	src/parser/cmd_list_free.c \
	src/parser/cmd_list_utils.c \
	src/parser/parse_word.c \
	src/parser/parse_pipe.c \
	src/parser/parse_redir_in.c \
	src/parser/parse_redir_out.c \
	src/parser/parse_append.c \
	src/parser/parse_heredoc.c \
	libft/libft.a \
	-o "$P_BIN"

p() { "$P_BIN" "$1"; }

echo "═══ A. Issue #19 : argv et pipes ═══"

assert_eq "commande seule" \
"CMD|ls" \
"$(p 'ls')"

assert_eq "commande avec arguments" \
"CMD|ls|-la|/tmp" \
"$(p 'ls -la /tmp')"

assert_eq "deux commandes" \
"CMD|ls
CMD|grep|c" \
"$(p 'ls | grep c')"

assert_eq "pipe colle" \
"CMD|ls
CMD|grep" \
"$(p 'ls|grep')"

assert_eq "trois commandes" \
"CMD|ls
CMD|grep|c
CMD|wc|-l" \
"$(p 'ls | grep c | wc -l')"

assert_eq "ligne vide -> NULL" \
"NULL" \
"$(p '')"

assert_eq "quotes conservees jusqu'au parser" \
'CMD|echo|"a b"' \
"$(p 'echo "a b"')"

echo ""
echo "═══ B. Issue #20 : redirections ═══"

assert_eq "redirection sortante" \
"CMD|ls
REDIR|OUT|out.txt" \
"$(p 'ls > out.txt')"

assert_eq "redirection entrante" \
"CMD|cat
REDIR|IN|in.txt" \
"$(p 'cat < in.txt')"

assert_eq "append" \
"CMD|ls
REDIR|APPEND|log" \
"$(p 'ls >> log')"

assert_eq "heredoc" \
"CMD|cat
REDIR|HEREDOC|EOF" \
"$(p 'cat << EOF')"

assert_eq "deux redirections sur la meme commande" \
"CMD|ls
REDIR|OUT|a
REDIR|OUT|b" \
"$(p 'ls > a > b')"

assert_eq "redirection avant la commande" \
"CMD|ls
REDIR|OUT|out" \
"$(p '> out ls')"

assert_eq "redirection au milieu des arguments" \
"CMD|ls|-la
REDIR|OUT|out" \
"$(p 'ls > out -la')"

assert_eq "pipe et redirections combines" \
"CMD|cat
REDIR|IN|in
CMD|grep|x
REDIR|OUT|out" \
"$(p 'cat < in | grep x > out')"

summary
