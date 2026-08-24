#include "../../includes/minishell.h"

static t_token	*build_tokens(void)
{
	t_token	*tokens;

	tokens = NULL;
	token_add_back(&tokens, new_token(T_WORD, "ls"));
	token_add_back(&tokens, new_token(T_PIPE, "|"));
	token_add_back(&tokens, new_token(T_WORD, "wc"));
	return (tokens);
}

int	main(void)
{
	char	*envp[] = {
		"USER=bomfim",
		NULL
	};
	t_shell	shell;

	shell.env = env_init(envp);
	shell.tokens = build_tokens();
	shell.line = ft_strdup("ls | wc");
	shell.last_exit = 0;
	shell.ast = NULL;
	shell_free(&shell);
	printf("ok\n");
	return (0);
}
