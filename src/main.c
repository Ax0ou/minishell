/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   main.c                                             :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aalvard <aalvarad@student.42lausanne.ch    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/01 10:10:00 by aalvard           #+#    #+#             */
/*   Updated: 2026/08/01 15:16:29 by aalvard          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../includes/minishell.h"

static void	check_prompt_signal(t_shell *shell)
{
	if (g_signal == SIGINT)
	{
		shell->last_exit = 130;
		g_signal = 0;
	}
}

int	main(int argc, char **argv, char **envp)
{
	t_shell	shell;

	(void)argc;
	(void)argv;
	init_shell(&shell, envp);
	rl_catch_signals = 0;
	while (1)
	{
		setup_prompt_signals();
		shell.line = readline("minishell$ ");
		check_prompt_signal(&shell);
		if (!shell.line)
			break ;
		if (*shell.line)
			add_history(shell.line);
		run_line(&shell);
		free(shell.line);
		shell.line = NULL;
	}
	ft_putendl_fd("exit", STDOUT_FILENO);
	shell_free(&shell);
	return (shell.last_exit);
}
