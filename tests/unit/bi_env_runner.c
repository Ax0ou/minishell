#include "../../includes/minishell.h"

int	main(void)
{
	char	*envp[] = {
		"USER=bomfim",
		"PATH=/usr/bin:/bin",
		NULL
	};
	t_env	*env;
	int		ret;

	env = env_init(envp);
	if (!env)
		return (1);
	env_set(&env, "HIDDEN", "secret", 0);
	ret = bi_env(env);
	printf("ret=[%d]\n", ret);
	env_free(env);
	return (0);
}
