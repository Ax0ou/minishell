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

int	main(void)
{
	char	*envp[] = {
		"USER=bomfim",
		"PATH=/usr/bin:/bin",
		"TOKEN=abc=def",
		"EMPTY=",
		NULL
	};
	t_env	*env;

	env = env_init(envp);
	if (!env)
		return (1);
	print_env(env);
	env_free(env);
	return (0);
}
