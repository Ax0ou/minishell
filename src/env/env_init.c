#include "../../includes/minishell.h"

static t_env	*env_new(char *key, char *value, int exported)
{
	t_env	*new;

	new = malloc(sizeof(t_env));
	if (!new)
		return (NULL);
	new->key = key;
	new->value = value;
	new->exported = exported;
	new->next = NULL;
	return (new);
}

static void	env_add_back(t_env **env, t_env *new)
{
	t_env	*current;

	if (!*env)
	{
		*env = new;
		return ;
	}
	current = *env;
	while (current->next)
		current = current->next;
	current->next = new;
}

static t_env	*env_from_string(char *str)
{
	char	*equal;
	char	*key;
	char	*value;
	t_env	*new;

	equal = ft_strchr(str, '=');
	if (!equal)
		return (NULL);
	key = ft_substr(str, 0, equal - str);
	if (!key)
		return (NULL);
	value = ft_strdup(equal + 1);
	if (!value)
	{
		free(key);
		return (NULL);
	}
	new = env_new(key, value, 1);
	if (!new)
	{
		free(key);
		free(value);
	}
	return (new);
}

t_env	*env_init(char **envp)
{
	t_env	*env;
	t_env	*new;
	int		i;

	env = NULL;
	i = 0;
	while (envp && envp[i])
	{
		if (ft_strchr(envp[i], '='))
		{
			new = env_from_string(envp[i]);
			if (!new)
			{
				env_free(env);
				return (NULL);
			}
			env_add_back(&env, new);
		}
		i++;
	}
	return (env);
}
