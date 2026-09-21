#include "../../includes/minishell.h"

static void	run_unset(t_env **env, char **argv, char *label)
{
	int	ret;

	ret = bi_unset(env, argv);
	printf("%s -> ret=[%d]\n", label, ret);
}

static void	print_val(t_env *env, char *key, char *label)
{
	char	*v;

	v = env_get(env, key);
	printf("%s -> [%s]\n", label, v ? v : "(null)");
}

int	main(void)
{
	char	*envp[5];
	t_env	*env;

	envp[0] = "USER=bomfim";
	envp[1] = "FOO=bar";
	envp[2] = "A=1";
	envp[3] = "B=2";
	envp[4] = NULL;
	env = env_init(envp);
	run_unset(&env, (char *[]){"unset", "FOO", NULL}, "unset FOO");
	print_val(env, "FOO", "  FOO");
	run_unset(&env, (char *[]){"unset", "GHOST", NULL}, "unset GHOST (absent)");
	run_unset(&env, (char *[]){"unset", NULL}, "unset (no args)");
	run_unset(&env, (char *[]){"unset", "1BAD", NULL}, "unset 1BAD (invalid)");
	run_unset(&env, (char *[]){"unset", "A=x", NULL},
		"unset A=x (whole token invalid, not partial)");
	print_val(env, "A", "  A (should be untouched)");
	run_unset(&env, (char *[]){"unset", "A", "1BAD", "B", NULL},
		"unset A 1BAD B (partial failure)");
	print_val(env, "A", "  A");
	print_val(env, "B", "  B");
	env_free(env);
	return (0);
}
