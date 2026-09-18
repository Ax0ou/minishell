/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   redir_files.c                                      :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/09/18 13:11:15 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/09/18 13:11:13 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

static int	open_redir(t_redir *redir)
{
	int	fd;

	if (redir->type == T_REDIR_IN)
		return (open(redir->target, O_RDONLY));
	if (redir->type == T_HEREDOC)
	{
		fd = open(redir->target, O_RDONLY);
		if (fd >= 0)
			unlink(redir->target);
		return (fd);
	}
	if (redir->type == T_REDIR_OUT)
		return (open(redir->target, O_WRONLY | O_CREAT | O_TRUNC, 0644));
	if (redir->type == T_APPEND)
		return (open(redir->target, O_WRONLY | O_CREAT | O_APPEND, 0644));
	return (-2);
}

int	apply_redirs(t_redir *redirs)
{
	int	fd;
	int	target_fd;

	while (redirs)
	{
		fd = open_redir(redirs);
		if (fd < 0)
		{
			print_error(redirs->target, NULL, strerror(errno));
			return (1);
		}
		target_fd = STDOUT_FILENO;
		if (redirs->type == T_REDIR_IN || redirs->type == T_HEREDOC)
			target_fd = STDIN_FILENO;
		dup2(fd, target_fd);
		close(fd);
		redirs = redirs->next;
	}
	return (0);
}
