#include "../../includes/minishell.h"

static void	print_array(char **array)
{
	int	i;

	if (!array)
	{
		printf("(null)\n");
		return ;
	}
	i = 0;
	while (array[i])
	{
		printf("%s\n", array[i]);
		i++;
	}
	printf("count=[%d]\n", i);
}

static void	free_array(char **array)
{
	int	i;

	if (!array)
		return ;
	i = 0;
	while (array[i])
		free(array[i++]);
	free(array);
}

int	main(void)
{
	char	*envp[] = {
		"USER=bomfim",
		"PATH=/usr/bin:/bin",
		NULL
	};
	t_env	*env;
	char	**array;

	env = env_init(envp);
	if (!env)
		return (1);
	env_set(&env, "HIDDEN", "secret", 0);
	array = env_to_array(env);
	print_array(array);
	free_array(array);
	env_free(env);
	env = NULL;
	array = env_to_array(env);
	print_array(array);
	free_array(array);
	return (0);
}
