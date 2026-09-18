#include "../../includes/minishell.h"

static t_redir	*build_heredoc_redir(char *raw_delim)
{
	t_redir	*r;

	r = malloc(sizeof(t_redir));
	r->type = T_HEREDOC;
	r->target = ft_strdup(raw_delim);
	r->next = NULL;
	return (r);
}

static t_cmd	*build_one_heredoc_cmd(char *raw_delim)
{
	t_cmd	*cmd;

	cmd = cmd_new();
	cmd->argv = malloc(sizeof(char *) * 2);
	cmd->argv[0] = ft_strdup("cat");
	cmd->argv[1] = NULL;
	cmd->redirs = build_heredoc_redir(raw_delim);
	return (cmd);
}

static void	print_file(char *path)
{
	int		fd;
	char	buf[512];
	ssize_t	n;

	fd = open(path, O_RDONLY);
	if (fd < 0)
	{
		printf("  content -> (missing)\n");
		return ;
	}
	n = read(fd, buf, sizeof(buf) - 1);
	close(fd);
	if (n < 0)
		n = 0;
	buf[n] = '\0';
	printf("  content -> [%s]\n", buf);
}

static void	run_case(char *label, t_shell *shell, char *raw_delim)
{
	int		ret;
	char	*path;

	fflush(stdout);
	shell->cmds = build_one_heredoc_cmd(raw_delim);
	ret = collect_heredocs(shell);
	printf("%s -> ret=[%d]\n", label, ret);
	if (ret)
	{
		path = ft_strdup(shell->cmds->redirs->target);
		print_file(path);
		cleanup_heredocs(shell->cmds);
		printf("  after cleanup, file exists -> [%d]\n",
			open(path, O_RDONLY) >= 0);
		free(path);
	}
	cmd_list_free(shell->cmds);
	shell->cmds = NULL;
}

int	main(void)
{
	char	*envp[2];
	t_shell	shell;

	envp[0] = "USER=x";
	envp[1] = NULL;
	shell.env = env_init(envp);
	run_case("simple heredoc (delim=EOF)", &shell, "EOF");
	run_case("quoted delimiter (raw = \"EOF\")", &shell, "\"EOF\"");
	run_case("empty delimiter (stops at blank line)", &shell, "");
	run_case("unterminated (EOF hit before delimiter)", &shell, "NEVER");
	env_free(shell.env);
	return (0);
}
