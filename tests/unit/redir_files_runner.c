#include "../../includes/minishell.h"

static t_redir	*new_redir(t_token_type type, char *target)
{
	t_redir	*r;

	r = malloc(sizeof(t_redir));
	r->type = type;
	r->target = ft_strdup(target);
	r->next = NULL;
	return (r);
}

static void	free_redirs(t_redir *r)
{
	t_redir	*next;

	while (r)
	{
		next = r->next;
		free(r->target);
		free(r);
		r = next;
	}
}

static void	seed_file(char *path, char *content)
{
	int	fd;

	fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
	write(fd, content, ft_strlen(content));
	close(fd);
}

static void	run_write_case(char *label, t_redir *redirs, char *payload)
{
	pid_t	pid;
	int		status;

	fflush(stdout);
	pid = fork();
	if (pid == 0)
	{
		if (apply_redirs(redirs))
			exit(1);
		write(STDOUT_FILENO, payload, ft_strlen(payload));
		exit(0);
	}
	waitpid(pid, &status, 0);
	printf("%s -> exit=[%d]\n", label, WEXITSTATUS(status));
	free_redirs(redirs);
}

static void	run_read_case(char *label, t_redir *redirs)
{
	pid_t	pid;
	int		status;
	char	buf[256];
	ssize_t	n;

	fflush(stdout);
	pid = fork();
	if (pid == 0)
	{
		if (apply_redirs(redirs))
			exit(1);
		n = read(STDIN_FILENO, buf, sizeof(buf) - 1);
		if (n < 0)
			n = 0;
		buf[n] = '\0';
		printf("  read content -> [%s]\n", buf);
		exit(0);
	}
	waitpid(pid, &status, 0);
	printf("%s -> exit=[%d]\n", label, WEXITSTATUS(status));
	free_redirs(redirs);
}

static void	print_file(char *label, char *path)
{
	int		fd;
	char	buf[256];
	ssize_t	n;

	fd = open(path, O_RDONLY);
	if (fd < 0)
	{
		printf("%s -> (missing)\n", label);
		return ;
	}
	n = read(fd, buf, sizeof(buf) - 1);
	close(fd);
	if (n < 0)
		n = 0;
	buf[n] = '\0';
	printf("%s -> [%s]\n", label, buf);
}

int	main(int argc, char **argv)
{
	char	*dir;
	char	*out_a;
	char	*out_append;
	char	*in_ok;
	char	*in_missing;
	t_redir	*r;

	if (argc < 2)
		return (1);
	dir = argv[1];
	out_a = ft_strjoin(dir, "/out_a");
	out_append = ft_strjoin(dir, "/out_append");
	in_ok = ft_strjoin(dir, "/in_ok");
	in_missing = ft_strjoin(dir, "/in_missing");
	seed_file(out_append, "existing-");
	seed_file(in_ok, "input-data");
	run_write_case("simple > (create + write)",
		new_redir(T_REDIR_OUT, out_a), "hello-out");
	print_file("  content of out_a", out_a);
	run_write_case("simple >> (append to existing content)",
		new_redir(T_APPEND, out_append), "appended");
	print_file("  content of out_append", out_append);
	r = new_redir(T_REDIR_OUT, out_a);
	r->next = new_redir(T_REDIR_OUT, out_append);
	run_write_case("multiple > (only the last is connected)", r, "last");
	print_file("  content of out_a (truncated, never written to)", out_a);
	print_file("  content of out_append (holds the write)", out_append);
	run_read_case("simple < (read from file)", new_redir(T_REDIR_IN, in_ok));
	r = new_redir(T_REDIR_IN, in_ok);
	r->next = new_redir(T_REDIR_IN, in_missing);
	run_read_case("< then < on missing file (bail, nothing runs)", r);
	free(out_a);
	free(out_append);
	free(in_ok);
	free(in_missing);
	return (0);
}
