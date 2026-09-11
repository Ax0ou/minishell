#include "../../includes/minishell.h"

static char	*status_name(t_resolve_status status)
{
	if (status == RESOLVE_OK)
		return ("OK");
	if (status == RESOLVE_CNF)
		return ("CNF");
	if (status == RESOLVE_ENOENT)
		return ("ENOENT");
	if (status == RESOLVE_ISDIR)
		return ("ISDIR");
	return ("NOPERM");
}

static void	run_case(char *label, t_env *env, char *name)
{
	t_resolve_status	status;
	char				*path;

	status = resolve_path(env, name, &path);
	printf("%s -> status=[%s] path=[%s]\n",
		label, status_name(status), path ? path : "(null)");
	free(path);
}

static void	run_direct_case(char *label, t_env *env, char *base, char *suffix)
{
	char	*name;

	name = ft_strjoin(base, suffix);
	run_case(label, env, name);
	free(name);
}

static t_env	*build_env_with_path(char *base)
{
	char	*dir_a;
	char	*dir_b;
	char	*path_val;
	char	*entry;
	char	*envp[3];
	t_env	*env;

	dir_a = ft_strjoin(base, "/binA:");
	dir_b = ft_strjoin(base, "/binB");
	path_val = ft_strjoin(dir_a, dir_b);
	entry = ft_strjoin("PATH=", path_val);
	envp[0] = entry;
	envp[1] = "USER=bomfim";
	envp[2] = NULL;
	env = env_init(envp);
	free(dir_a);
	free(dir_b);
	free(path_val);
	free(entry);
	return (env);
}

int	main(int argc, char **argv)
{
	char	*base;
	char	*envp[3];
	t_env	*env;
	t_env	*env_no_path;
	t_env	*env_empty_path;

	if (argc < 2)
		return (1);
	base = argv[1];
	env = build_env_with_path(base);
	run_case("PATH search: found + executable", env, "runme");
	run_case("PATH search: found but is a directory", env, "asdir");
	run_case("PATH search: found but not executable", env, "noperm");
	run_case("PATH search: not found anywhere", env, "ghost");
	run_direct_case("direct path: found + executable", env, base, "/binA/runme");
	run_direct_case("direct path: does not exist", env, base, "/nope_at_all");
	run_direct_case("direct path: is a directory", env, base, "/binA");
	run_direct_case("direct path: not executable", env, base, "/binB/noperm");
	envp[0] = "USER=bomfim";
	envp[1] = NULL;
	env_no_path = env_init(envp);
	run_case("PATH unset", env_no_path, "runme");
	envp[0] = "PATH=";
	envp[1] = "USER=bomfim";
	envp[2] = NULL;
	env_empty_path = env_init(envp);
	run_case("PATH empty", env_empty_path, "runme");
	env_free(env);
	env_free(env_no_path);
	env_free(env_empty_path);
	return (0);
}
