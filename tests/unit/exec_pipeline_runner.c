#include "../../includes/minishell.h"

static t_cmd	*build_cmd(char **argv_lits, int argc)
{
	t_cmd	*cmd;
	int		i;

	cmd = cmd_new();
	cmd->argv = malloc(sizeof(char *) * (argc + 1));
	i = 0;
	while (i < argc)
	{
		cmd->argv[i] = ft_strdup(argv_lits[i]);
		i++;
	}
	cmd->argv[i] = NULL;
	return (cmd);
}

static void	run_case(char *label, t_shell *shell, t_cmd *cmds)
{
	shell->cmds = cmds;
	fflush(stdout);
	exec_pipeline(shell);
	printf("%s -> last_exit=[%d]\n", label, shell->last_exit);
	cmd_list_free(shell->cmds);
	shell->cmds = NULL;
}

int	main(void)
{
	char	*envp[2];
	t_shell	shell;
	t_cmd	*chain;
	char	*cwd_before;
	char	*cwd_after;

	envp[0] = "PATH=/bin:/usr/bin";
	envp[1] = NULL;
	shell.env = env_init(envp);

	chain = build_cmd((char *[]){"/bin/echo", "hello"}, 2);
	chain->next = build_cmd((char *[]){"/bin/cat"}, 1);
	run_case("2-stage passthrough", &shell, chain);

	chain = build_cmd((char *[]){"/bin/echo", "hello world"}, 2);
	chain->next = build_cmd((char *[]){"/bin/cat"}, 1);
	chain->next->next = build_cmd((char *[]){"/bin/cat"}, 1);
	run_case("3-stage passthrough", &shell, chain);

	chain = build_cmd((char *[]){"/bin/sh", "-c", "exit 5"}, 3);
	chain->next = build_cmd((char *[]){"/bin/cat"}, 1);
	run_case("exit code = LAST stage (cat=0), not first (5)", &shell, chain);

	chain = build_cmd((char *[]){"/bin/echo", "x"}, 2);
	chain->next = build_cmd((char *[]){"/bin/sh", "-c", "exit 7"}, 3);
	run_case("exit code = LAST stage (7)", &shell, chain);

	chain = build_cmd((char *[]){"nonexistent_cmd_xyz"}, 1);
	chain->next = build_cmd((char *[]){"/bin/cat"}, 1);
	run_case("broken middle stage: pipeline still completes", &shell, chain);

	cwd_before = getcwd(NULL, 0);
	chain = build_cmd((char *[]){"cd", "/tmp"}, 2);
	chain->next = build_cmd((char *[]){"/bin/echo", "done"}, 2);
	run_case("cd inside a pipe: forked, no real effect", &shell, chain);
	cwd_after = getcwd(NULL, 0);
	printf("cwd unchanged -> [%d]\n", !ft_strncmp(cwd_before, cwd_after,
			ft_strlen(cwd_before) + 1));
	free(cwd_before);
	free(cwd_after);

	env_free(shell.env);
	return (0);
}
