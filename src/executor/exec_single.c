/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   exec_single.c                                      :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/09/18 13:10:14 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/09/18 13:10:15 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

int	report_resolve_error(char *name, t_path_status status)
{
	if (status == RESOLVE_CNF)
	{
		print_error(name, NULL, "command not found");
		return (127);
	}
	if (status == RESOLVE_ENOENT)
	{
		print_error(name, NULL, "No such file or directory");
		return (127);
	}
	if (status == RESOLVE_ISDIR)
	{
		print_error(name, NULL, "Is a directory");
		return (126);
	}
	print_error(name, NULL, "Permission denied");
	return (126);
}

static void	cleanup(char *path, char **envp)
{
	free(path);
	free_split(envp);
}

void	exec_single(t_shell *shell, t_cmd *cmd)
{
	t_path_status		status;
	char				*path;
	char				**envp;
	pid_t				pid;

	status = resolve_path(shell->env, cmd->argv[0], &path);
	if (status != RESOLVE_OK)
	{
		shell->last_exit = report_resolve_error(cmd->argv[0], status);
		return ;
	}
	envp = env_to_array(shell->env);
	pid = fork();
	if (pid < 0)
	{
		print_error("fork", NULL, strerror(errno));
		shell->last_exit = 1;
		cleanup(path, envp);
		return ;
	}
	if (pid == 0)
		exec_child(path, cmd, envp);
	shell->last_exit = exec_wait(pid);
	cleanup(path, envp);
}
