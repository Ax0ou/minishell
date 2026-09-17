#include "../../includes/minishell.h"

static int	resolve_in_path(t_env *env, char *name, char **out)
{
	char	**dirs;
	int		status;
	int		i;

	dirs = ft_split(env_get(env, "PATH"), ':');
	if (!dirs)
		return (RESOLVE_CNF);
	i = 0;
	while (dirs[i])
	{
		status = handle_candidate(dirs[i], name, out);
		if (status != RESOLVE_ENOENT)
		{
			free_split(dirs);
			return (status);
		}
		i++;
	}
	free_split(dirs);
	return (RESOLVE_CNF);
}

t_path_status	resolve_path(t_env *env, char *name, char **out_path)
{
	int	status;

	*out_path = NULL;
	if (!name || !*name)
		return (RESOLVE_CNF);
	if (ft_strchr(name, '/'))
	{
		status = probe_path(name);
		if (status == RESOLVE_OK)
		{
			*out_path = ft_strdup(name);
			if (!*out_path)
				return (RESOLVE_ENOENT);
		}
		return (status);
	}
	return (resolve_in_path(env, name, out_path));
}
