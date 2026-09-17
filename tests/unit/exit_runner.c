#include "../../includes/minishell.h"

int	main(int argc, char **argv)
{
	t_shell	shell;

	(void)argc;
	shell.env = NULL;
	shell.last_exit = 7;
	shell.line = NULL;
	shell.tokens = NULL;
	shell.cmds = NULL;
	return (bi_exit(&shell, argv));
}
