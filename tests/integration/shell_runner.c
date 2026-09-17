#include "../../includes/minishell.h"

int	main(int argc, char **argv, char **envp)
{
	t_shell	shell;
	int		i;

	init_shell(&shell, envp);
	i = 1;
	while (i < argc)
	{
		shell.line = ft_strdup(argv[i]);
		run_line(&shell);
		free(shell.line);
		shell.line = NULL;
		i++;
	}
	i = shell.last_exit;
	shell_free(&shell);
	return (i);
}
