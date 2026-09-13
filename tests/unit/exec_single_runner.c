#include "../../includes/minishell.h"

static t_cmd	*build_cmd(char *name)
{
	t_cmd	*cmd;

	cmd = cmd_new();
	cmd->argv = malloc(sizeof(char *) * 2);
	cmd->argv[0] = ft_strdup(name);
	cmd->argv[1] = NULL;
	return (cmd);
}

static void	run_case(char *label, t_shell *shell, char *name)
{
	t_cmd	*cmd;

	cmd = build_cmd(name);
	exec_single(shell, cmd);
	printf("%s -> last_exit=[%d]\n", label, shell->last_exit);
	cmd_list_free(cmd);
}

int	main(int argc, char **argv)
{
	char	*envp[3];
	char	*path_entry;
	t_shell	shell;

	if (argc < 2)
		return (1);
	path_entry = ft_strjoin("PATH=", argv[1]);
	envp[0] = path_entry;
	envp[1] = "USER=bomfim";
	envp[2] = NULL;
	shell.env = env_init(envp);
	free(path_entry);
	run_case("execute + normal exit code", &shell, "exit7");
	run_case("killed by signal (SIGTERM)", &shell, "killself");
	run_case("found but not executable", &shell, "noperm");
	run_case("not found anywhere", &shell, "ghost_cmd_xyz");
	env_free(shell.env);
	return (0);
}
