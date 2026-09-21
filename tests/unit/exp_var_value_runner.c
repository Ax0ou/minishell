#include "../../includes/minishell.h"

/* usage : exp_var_value_runner <texte apres le $> <last_exit> */
int	main(int argc, char **argv)
{
	t_shell	shell;
	char	*envp[4];
	char	*out;

	if (argc != 3)
		return (1);
	envp[0] = "USER=alvrd";
	envp[1] = "EMPTY=";
	envp[2] = "HOME=/Users/alvrd";
	envp[3] = NULL;
	shell.env = env_init(envp);
	shell.last_exit = ft_atoi(argv[2]);
	out = exp_var_value(&shell, argv[1], exp_var_len(argv[1]));
	if (!out)
		printf("NULL\n");
	else
		printf("[%s]\n", out);
	free(out);
	env_free(shell.env);
	return (0);
}
