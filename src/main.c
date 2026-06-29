#include "../includes/minishell.h"

int	main(int argc, char **argv, char **envp)
{
	t_shell	shell;

	(void)argc;
	(void)argv;
	shell.env = env_init(envp);
	shell.last_exit = 0;
	shell.tokens = NULL;
	shell.ast = NULL;
	while (1)
	{
		shell.line = readline("minishell$ ");
		if (!shell.line)
			break ;
		free(shell.line);
	}
	env_free(shell.env);
	return (0);
}
