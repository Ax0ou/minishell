#include "../../includes/minishell.h"

static const char	*redir_name(t_token_type type)
{
	if (type == T_REDIR_IN)
		return ("IN");
	if (type == T_REDIR_OUT)
		return ("OUT");
	if (type == T_APPEND)
		return ("APPEND");
	return ("HEREDOC");
}

static void	print_argv(char **argv)
{
	int	i;

	printf("CMD");
	i = 0;
	while (argv && argv[i])
	{
		printf("|%s", argv[i]);
		i++;
	}
	printf("\n");
}

static void	print_cmd(t_cmd *cmd)
{
	t_redir	*r;

	print_argv(cmd->argv);
	r = cmd->redirs;
	while (r)
	{
		printf("REDIR|%s|%s\n", redir_name(r->type), r->target);
		r = r->next;
	}
}

int	main(int argc, char **argv)
{
	t_token	*tokens;
	t_cmd	*cmds;
	t_cmd	*cur;

	if (argc != 2)
		return (1);
	tokens = lex_tokenize(argv[1]);
	cmds = parse_tokens(tokens);
	token_list_free(tokens);
	if (!cmds)
	{
		printf("NULL\n");
		return (0);
	}
	cur = cmds;
	while (cur)
	{
		print_cmd(cur);
		cur = cur->next;
	}
	cmd_list_free(cmds);
	return (0);
}
