#include "../../includes/minishell.h"

void	env_free(t_env *env)
{
	t_env	*next;

	while (env)
	{
		next = env->next;
		free(env->key);
		free(env->value);
		free(env);
		env = next;
	}
}

void	shell_free(t_shell *shell)
{
	if (shell->line)
		free(shell->line);
	token_list_free(shell->tokens);
	cmd_list_free(shell->cmds);
	env_free(shell->env);
}
