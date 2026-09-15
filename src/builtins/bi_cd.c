#include "../../includes/minishell.h"

static char	*get_target(t_env *env, char **argv, int *is_dash)
{
	*is_dash = 0;
	if (!argv[1])
		return (env_get(env, "HOME"));
	if (argv[1][0] == '-' && argv[1][1] == '\0')
	{
		*is_dash = 1;
		return (env_get(env, "OLDPWD"));
	}
	return (argv[1]);
}

static char	*update_pwd(t_env **env)
{
	char	*old_pwd;
	char	*new_pwd;

	old_pwd = env_get(*env, "PWD");
	new_pwd = getcwd(NULL, 0);
	if (!new_pwd)
		return (NULL);
	if (old_pwd)
		env_set(env, "OLDPWD", old_pwd, 1);
	env_set(env, "PWD", new_pwd, 1);
	return (new_pwd);
}

int	bi_cd(t_env **env, char **argv)
{
	char	*target;
	int		is_dash;
	char	*new_pwd;

	target = get_target(*env, argv, &is_dash);
	if (!target)
	{
		if (is_dash)
			return (print_error("cd", NULL, "OLDPWD not set"));
		return (print_error("cd", NULL, "HOME not set"));
	}
	if (chdir(target) != 0)
		return (print_error("cd", target, strerror(errno)));
	new_pwd = update_pwd(env);
	if (is_dash && new_pwd)
		ft_putendl_fd(new_pwd, STDOUT_FILENO);
	free(new_pwd);
	return (0);
}
