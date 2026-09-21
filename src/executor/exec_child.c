/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   exec_child.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/09/18 13:09:37 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/09/18 13:09:38 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

void	exec_child(char *path, t_cmd *cmd, char **envp)
{
	reset_child_signals();
	if (apply_redirs(cmd->redirs))
		exit(1);
	execve(path, cmd->argv, envp);
	print_error(cmd->argv[0], NULL, strerror(errno));
	exit(126);
}
