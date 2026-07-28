#include "../../includes/minishell.h"

static char	*env_line(t_env *env)
{
	char	*tmp;
	char	*line;

	tmp = ft_strjoin(env->key, "=");
	if (!tmp)
		return (NULL);
	line = ft_strjoin(tmp, env->value);
	free(tmp);
	return (line);
}

int	bi_env(t_env *env)
{
	char	*line;

	while (env)
	{
		if (env->exported && env->value)
		{
			line = env_line(env);
			if (!line)
				return (1);
			ft_putendl_fd(line, 1);
			free(line);
		}
		env = env->next;
	}
	return (0);
}
