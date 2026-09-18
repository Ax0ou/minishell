#include "../../includes/minishell.h"

int	main(int argc, char **argv)
{
	char	*out;

	if (argc != 2)
		return (1);
	out = exp_strip_quotes(argv[1]);
	if (!out)
	{
		printf("NULL\n");
		return (1);
	}
	printf("[%s]\n", out);
	free(out);
	return (0);
}
