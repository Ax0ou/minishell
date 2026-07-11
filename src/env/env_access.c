#include "../../includes/minishell.h"

static t_env	*env_find(t_env *env, char *key)
{
	while (env)
	{
		if (!ft_strncmp(env->key, key, ft_strlen(key) + 1))
			return (env);
		env = env->next;
	}
	return (NULL);
}

char	*env_get(t_env *env, char *key)
{
	t_env	*node;

	node = env_find(env, key);
	if (!node)
		return (NULL);
	return (node->value);
}

int	env_set(t_env **env, char *key, char *value, int exported)
{
	t_env	*node;

	node = env_find(*env, key);
	if (node)
	{
		free(node->value);
		node->value = ft_strdup(value);
		node->exported = (node->exported || exported);
		return (node->value == NULL);
	}
	node = malloc(sizeof(t_env));
	if (!node)
		return (1);
	node->next = NULL;
	node->key = ft_strdup(key);
	node->value = ft_strdup(value);
	node->exported = exported;
	if (!node->key || !node->value)
	{
		env_free(node);
		return (1);
	}
	node->next = *env;
	*env = node;
	return (0);
}

void	env_unset(t_env **env, char *key)
{
	t_env	*node;
	t_env	*prev;

	prev = NULL;
	node = *env;
	while (node && ft_strncmp(node->key, key, ft_strlen(key) + 1))
	{
		prev = node;
		node = node->next;
	}
	if (!node)
		return ;
	if (prev)
		prev->next = node->next;
	else
		*env = node->next;
	free(node->key);
	free(node->value);
	free(node);
}
