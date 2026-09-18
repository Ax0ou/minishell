/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   exec_pipeline.c                                    :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/09/18 13:10:05 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/09/18 13:10:06 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

static pid_t	spawn_stage(t_shell *shell, t_cmd *cmd, int prev_read,
	int *next_read)
{
	int		p[2];
	pid_t	pid;

	*next_read = -1;
	if (cmd->next)
		pipe(p);
	pid = fork();
	if (pid == 0)
	{
		child_dup_pipes(prev_read, p, cmd->next != NULL);
		pipe_child_run(shell, cmd);
	}
	if (prev_read != -1)
		close(prev_read);
	if (cmd->next)
	{
		close(p[1]);
		*next_read = p[0];
	}
	return (pid);
}

void	exec_pipeline(t_shell *shell)
{
	t_cmd	*cmd;
	pid_t	*pids;
	int		n;
	int		i;
	int		prev_read;

	n = count_cmds(shell->cmds);
	pids = malloc(sizeof(pid_t) * n);
	if (!pids)
	{
		print_error(NULL, NULL, strerror(errno));
		shell->last_exit = 1;
		return ;
	}
	cmd = shell->cmds;
	prev_read = -1;
	i = 0;
	while (cmd)
	{
		pids[i] = spawn_stage(shell, cmd, prev_read, &prev_read);
		cmd = cmd->next;
		i++;
	}
	shell->last_exit = wait_all(pids, n);
	free(pids);
}
