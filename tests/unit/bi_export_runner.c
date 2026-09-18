#include "../../includes/minishell.h"

static void	run_export(t_env **env, char **argv, char *label)
{
	int	ret;

	fflush(stdout);
	ret = bi_export(env, argv);
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
	char	*envp[2];
	t_env	*env;

	envp[0] = "USER=bomfim";
	envp[1] = NULL;
	env = env_init(envp);
	run_export(&env, (char *[]){"export", "FOO=bar", NULL}, "export FOO=bar");
	print_val(env, "FOO", "  FOO");
	run_export(&env, (char *[]){"export", "BAZ", NULL}, "export BAZ (no value)");
	print_val(env, "BAZ", "  BAZ (should be null)");
	run_export(&env, (char *[]){"export", "BAZ=now", NULL}, "export BAZ=now");
	print_val(env, "BAZ", "  BAZ");
	run_export(&env, (char *[]){"export", "FOO", NULL},
		"export FOO (re-export, no clobber)");
	print_val(env, "FOO", "  FOO (should still be bar)");
	run_export(&env, (char *[]){"export", "1BAD=x", NULL},
		"export 1BAD=x (invalid)");
	run_export(&env, (char *[]){"export", "A=1", "2BAD", "B=2", NULL},
		"export A=1 2BAD B=2 (partial failure)");
	print_val(env, "A", "  A");
	print_val(env, "B", "  B");
	printf("=== export (listing) ===\n");
	run_export(&env, (char *[]){"export", NULL}, "export (no args)");
	env_free(env);
	return (0);
}
