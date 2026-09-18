/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   parse_heredoc.c                                    :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/09/18 14:58:54 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/09/18 14:58:55 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

static int	fail_heredoc(char *delim, char *path)
{
	free(delim);
	free(path);
	return (0);
}

static void	warn_eof(char *delim)
{
	char	*tmp;
	char	*msg;

	tmp = ft_strjoin(
			"warning: here-document delimited by end-of-file (wanted '",
			delim);
	if (!tmp)
		return ;
	msg = ft_strjoin(tmp, "')");
	free(tmp);
	if (!msg)
		return ;
	print_error(NULL, NULL, msg);
	free(msg);
}

static int	collect_one_heredoc(t_redir *redir)
{
	char	*delim;
	char	*path;
	int		fd;

	delim = strip_delim(redir->target);
	path = heredoc_tmp_path();
	if (!delim || !path)
		return (fail_heredoc(delim, path));
	fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0600);
	if (fd < 0)
		return (fail_heredoc(delim, path));
	if (!read_heredoc_body(delim, fd))
		warn_eof(delim);
	close(fd);
	free(redir->target);
	redir->target = path;
	free(delim);
	return (1);
}

int	collect_heredocs(t_shell *shell)
{
	t_cmd	*cmd;
	t_redir	*redir;

	cmd = shell->cmds;
	while (cmd)
	{
		redir = cmd->redirs;
		while (redir)
		{
			if (redir->type == T_HEREDOC && !collect_one_heredoc(redir))
				return (0);
			redir = redir->next;
		}
		cmd = cmd->next;
	}
	return (1);
}

void	cleanup_heredocs(t_cmd *cmds)
{
	t_redir	*redir;

	while (cmds)
	{
		redir = cmds->redirs;
		while (redir)
		{
			if (redir->type == T_HEREDOC)
				unlink(redir->target);
			redir = redir->next;
		}
		cmds = cmds->next;
	}
}
