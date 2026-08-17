#include "../../includes/minishell.h"

int	main(void)
{
	int	ret;

	ret = print_error("cd", "/nonexistent", "No such file or directory");
	printf("ret=[%d]\n", ret);
	ret = print_error("nope_cmd", NULL, "command not found");
	printf("ret=[%d]\n", ret);
	ret = print_error(NULL, NULL, "syntax error near unexpected token `|'");
	printf("ret=[%d]\n", ret);
	return (0);
}
