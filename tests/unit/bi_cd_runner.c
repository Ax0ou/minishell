#include "../../includes/minishell.h"

static void	run_cd(t_env **env, char *arg0, char *arg1)
{
	char	*argv[3];
	char	*cwd;
	int		ret;

	argv[0] = arg0;
	argv[1] = arg1;
	argv[2] = NULL;
	fflush(stdout);
	ret = bi_cd(env, argv);
	cwd = getcwd(NULL, 0);
	printf("cd %s -> ret=[%d] cwd=[%s] PWD=[%s] OLDPWD=[%s]\n",
		arg1 ? arg1 : "(none)", ret, cwd ? cwd : "(null)",
		env_get(*env, "PWD"), env_get(*env, "OLDPWD"));
	free(cwd);
}

int	main(int argc, char **argv)
{
	char	*envp[4];
	char	*fixture;
	char	*home;
	char	*work;
	t_env	*env;

	if (argc < 2)
		return (1);
	fixture = argv[1];
	home = ft_strjoin(fixture, "/home");
	work = ft_strjoin(fixture, "/work");
	chdir(work);
	envp[0] = ft_strjoin("HOME=", home);
	envp[1] = ft_strjoin("PWD=", work);
	envp[2] = ft_strjoin("OLDPWD=", fixture);
	envp[3] = NULL;
	env = env_init(envp);
	free(envp[0]);
	free(envp[1]);
	free(envp[2]);
	run_cd(&env, "cd", "sub");
	run_cd(&env, "cd", NULL);
	run_cd(&env, "cd", "-");
	run_cd(&env, "cd", "/definitely/not/a/real/path/xyz123");
	env_unset(&env, "HOME");
	run_cd(&env, "cd", NULL);
	free(home);
	free(work);
	env_free(env);
	return (0);
}
