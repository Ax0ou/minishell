/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   exec_run.c                                         :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aalvard <aalvarad@student.42lausanne.ch    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/01 10:10:00 by aalvard           #+#    #+#             */
/*   Updated: 2026/08/01 15:16:29 by aalvard          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

int	is_builtin(char *name)
{
	return (!ft_strncmp(name, "echo", 5) || !ft_strncmp(name, "cd", 3)
		|| !ft_strncmp(name, "pwd", 4) || !ft_strncmp(name, "env", 4)
		|| !ft_strncmp(name, "exit", 5) || !ft_strncmp(name, "export", 7)
		|| !ft_strncmp(name, "unset", 6));
}

int	call_builtin(t_shell *shell, char **argv)
{
	if (!ft_strncmp(argv[0], "echo", 5))
		return (bi_echo(argv));
	if (!ft_strncmp(argv[0], "pwd", 4))
		return (bi_pwd());
	if (!ft_strncmp(argv[0], "env", 4))
		return (bi_env(shell->env));
	if (!ft_strncmp(argv[0], "cd", 3))
		return (bi_cd(&shell->env, argv));
	if (!ft_strncmp(argv[0], "export", 7))
		return (bi_export(&shell->env, argv));
	if (!ft_strncmp(argv[0], "unset", 6))
		return (bi_unset(&shell->env, argv));
	return (bi_exit(shell, argv));
}

static int	run_in_parent(t_shell *shell, t_cmd *cmd)
{
	int	saved_in;
	int	saved_out;
	int	code;

	saved_in = dup(STDIN_FILENO);
	saved_out = dup(STDOUT_FILENO);
	code = 1;
	if (!apply_redirs(cmd->redirs))
	{
		code = 0;
		if (cmd->argv && cmd->argv[0])
			code = call_builtin(shell, cmd->argv);
	}
	dup2(saved_in, STDIN_FILENO);
	dup2(saved_out, STDOUT_FILENO);
	close(saved_in);
	close(saved_out);
	return (code);
}

void	exec_run(t_shell *shell)
{
	t_cmd	*cmd;

	cmd = shell->cmds;
	if (!cmd)
		return ;
	if (cmd->next)
	{
		exec_pipeline(shell);
		return ;
	}
	if (cmd->argv && cmd->argv[0] && !is_builtin(cmd->argv[0]))
		exec_single(shell, cmd);
	else
		shell->last_exit = run_in_parent(shell, cmd);
}
