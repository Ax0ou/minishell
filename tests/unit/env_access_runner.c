#include "../../includes/minishell.h"

static void	print_env(t_env *env)
{
	while (env)
	{
		printf("key=[%s] value=[%s] exported=[%d]\n",
			env->key, env->value, env->exported);
		env = env->next;
	}
}

static void	print_get(t_env *env, char *key, char *label)
{
	char	*value;

	value = env_get(env, key);
	printf("%s -> [%s]\n", label, value ? value : "(null)");
}

int	main(void)
{
	char	*envp[] = {
		"USER=bomfim",
		"PATH=/usr/bin:/bin",
		NULL
	};
	t_env	*env;

	env = env_init(envp);
	if (!env)
		return (1);
	print_get(env, "USER", "get USER");
	print_get(env, "MISSING", "get MISSING");
	env_set(&env, "USER", "davi", 0);
	print_get(env, "USER", "get USER after update");
	env_set(&env, "NEW_VAR", "hello", 1);
	print_get(env, "NEW_VAR", "get NEW_VAR after create");
	env_unset(&env, "PATH");
	print_get(env, "PATH", "get PATH after unset");
	env_unset(&env, "GHOST");
	printf("unset missing key ok\n");
	print_env(env);
	env_free(env);
	return (0);
}
