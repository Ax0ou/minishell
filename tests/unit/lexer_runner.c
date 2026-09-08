#include "../../includes/minishell.h"

static const char	*type_name(t_token_type type)
{
	if (type == T_PIPE)
		return ("PIPE");
	if (type == T_REDIR_IN)
		return ("REDIR_IN");
	if (type == T_REDIR_OUT)
		return ("REDIR_OUT");
	if (type == T_HEREDOC)
		return ("HEREDOC");
	if (type == T_APPEND)
		return ("APPEND");
	return ("WORD");
}

static void	print_tokens(t_token *tokens)
{
	t_token	*cur;

	cur = tokens;
	while (cur)
	{
		printf("%s|%s\n", type_name(cur->type), cur->value);
		cur = cur->next;
	}
}

int	main(int argc, char **argv)
{
	t_token	*tokens;

	if (argc != 2)
		return (1);
	tokens = lex_tokenize(argv[1]);
	if (!tokens)
	{
		printf("NULL\n");
		return (0);
	}
	print_tokens(tokens);
	token_list_free(tokens);
	return (0);
}
