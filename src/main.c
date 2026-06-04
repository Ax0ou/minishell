int	main(int argc, char *argv[])
{
	char	*line;

	(void)argc;
	(void)argv;
	while (1)
	{
		line = readline("minishell$ ");
		free(line);
	}
	return (0);
}
