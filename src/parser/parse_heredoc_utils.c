/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   parse_heredoc_utils.c                              :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/09/18 14:58:46 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/09/18 14:58:47 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

static char	*next_path(int counter)
{
	char	*num;
	char	*path;

	num = ft_itoa(counter);
	if (!num)
		return (NULL);
	path = ft_strjoin("/tmp/minishell_heredoc_", num);
	free(num);
	return (path);
}

char	*heredoc_tmp_path(void)
{
	static int	counter = 0;
	char		*path;
	int			fd;

	while (1)
	{
		path = next_path(counter++);
		if (!path)
			return (NULL);
		fd = open(path, O_CREAT | O_EXCL | O_WRONLY, 0600);
		if (fd >= 0)
		{
			close(fd);
			return (path);
		}
		if (errno != EEXIST)
		{
			free(path);
			return (NULL);
		}
		free(path);
	}
}

char	*strip_delim(char *raw)
{
	int	len;

	len = ft_strlen(raw);
	if (len >= 2 && ((raw[0] == '"' && raw[len - 1] == '"')
			|| (raw[0] == '\'' && raw[len - 1] == '\'')))
		return (ft_substr(raw, 1, len - 2));
	return (ft_strdup(raw));
}

static char	*read_line_raw(int fd)
{
	static char	buf[4096];
	char		c;
	int			len;
	ssize_t		n;

	len = 0;
	n = read(fd, &c, 1);
	while (n > 0 && len < 4095)
	{
		buf[len++] = c;
		if (c == '\n')
			break ;
		n = read(fd, &c, 1);
	}
	if (len == 0 && n <= 0)
		return (NULL);
	buf[len] = '\0';
	return (ft_strdup(buf));
}

int	read_heredoc_body(char *delim, int fd)
{
	char	*line;
	int		dlen;

	dlen = ft_strlen(delim);
	ft_putstr_fd("> ", 1);
	line = read_line_raw(STDIN_FILENO);
	while (line)
	{
		if (!ft_strncmp(line, delim, dlen)
			&& (line[dlen] == '\0' || line[dlen] == '\n'))
		{
			free(line);
			return (1);
		}
		write(fd, line, ft_strlen(line));
		if (!ft_strchr(line, '\n'))
			write(fd, "\n", 1);
		free(line);
		ft_putstr_fd("> ", 1);
		line = read_line_raw(STDIN_FILENO);
	}
	return (0);
}
