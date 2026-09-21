#include "../../includes/minishell.h"

int	main(int argc, char **argv)
{
	if (argc != 2)
		return (1);
	printf("%d\n", exp_var_len(argv[1]));
	return (0);
}
