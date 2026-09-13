#include "../../includes/minishell.h"

void	exec_child(char *path, t_cmd *cmd, char **envp)
{
	execve(path, cmd->argv, envp);
	print_error(cmd->argv[0], NULL, strerror(errno));
	exit(126);
}
