/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   exec_pipeline_utils.c                              :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/09/18 13:10:00 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/09/18 13:10:01 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

int	count_cmds(t_cmd *cmds)
{
	int	n;

	n = 0;
	while (cmds)
	{
		n++;
		cmds = cmds->next;
	}
	return (n);
}

void	child_dup_pipes(int prev_read, int p[2], int has_next)
{
	if (prev_read != -1)
	{
		dup2(prev_read, STDIN_FILENO);
		close(prev_read);
	}
	if (has_next)
	{
		dup2(p[1], STDOUT_FILENO);
		close(p[0]);
		close(p[1]);
	}
}

void	pipe_child_run(t_shell *shell, t_cmd *cmd)
{
	t_path_status	status;
	char			*path;
	char			**envp;

	if (!cmd->argv || !cmd->argv[0] || is_builtin(cmd->argv[0]))
	{
		if (apply_redirs(cmd->redirs))
			exit(1);
		if (!cmd->argv || !cmd->argv[0])
			exit(0);
		exit(call_builtin(shell, cmd->argv));
	}
	status = resolve_path(shell->env, cmd->argv[0], &path);
	if (status != RESOLVE_OK)
		exit(report_resolve_error(cmd->argv[0], status));
	envp = env_to_array(shell->env);
	exec_child(path, cmd, envp);
}

int	wait_all(pid_t *pids, int n)
{
	int	i;
	int	code;

	i = 0;
	code = 0;
	while (i < n)
	{
		code = exec_wait(pids[i]);
		i++;
	}
	return (code);
}
