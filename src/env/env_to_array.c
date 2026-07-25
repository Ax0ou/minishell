#include "../../includes/minishell.h"

static int	count_exported(t_env *env)
{
	int	count;

	count = 0;
	while (env)
	{
		if (env->exported)
			count++;
		env = env->next;
	}
	return (count);
}

static char	*env_entry(t_env *env)
{
	char	*tmp;
	char	*entry;

	tmp = ft_strjoin(env->key, "=");
	if (!tmp)
		return (NULL);
	entry = ft_strjoin(tmp, env->value);
	free(tmp);
	return (entry);
}

static void	free_array(char **array, int count)
{
	int	i;

	i = 0;
	while (i < count)
		free(array[i++]);
	free(array);
}

char	**env_to_array(t_env *env)
{
	char	**array;
	int		count;
	int		i;

	count = count_exported(env);
	array = malloc(sizeof(char *) * (count + 1));
	if (!array)
		return (NULL);
	i = 0;
	while (env)
	{
		if (env->exported)
		{
			array[i] = env_entry(env);
			if (!array[i])
				return (free_array(array, i), NULL);
			i++;
		}
		env = env->next;
	}
	array[i] = NULL;
	return (array);
}
