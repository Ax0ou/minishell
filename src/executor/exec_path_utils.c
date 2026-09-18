/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   exec_path_utils.c                                  :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/09/18 13:09:45 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/09/18 13:09:46 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

int	probe_path(char *path)
{
	struct stat	st;

	if (stat(path, &st) != 0)
		return (RESOLVE_ENOENT);
	if (S_ISDIR(st.st_mode))
		return (RESOLVE_ISDIR);
	if (access(path, X_OK) != 0)
		return (RESOLVE_NOPERM);
	return (RESOLVE_OK);
}

void	free_split(char **arr)
{
	int	i;

	i = 0;
	while (arr[i])
		free(arr[i++]);
	free(arr);
}

int	handle_candidate(char *dir, char *name, char **out)
{
	char	*candidate;
	char	*tmp;
	int		status;

	tmp = ft_strjoin(dir, "/");
	candidate = NULL;
	if (tmp)
		candidate = ft_strjoin(tmp, name);
	free(tmp);
	status = RESOLVE_ENOENT;
	if (candidate)
		status = probe_path(candidate);
	if (status == RESOLVE_OK)
		*out = candidate;
	else
		free(candidate);
	return (status);
}
