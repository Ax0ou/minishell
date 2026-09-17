/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ut_init_data.c                                     :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aalvard <aalvarad@student.42lausanne.ch    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/01 10:10:00 by aalvard           #+#    #+#             */
/*   Updated: 2026/08/01 15:16:29 by aalvard          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

void	init_shell(t_shell *shell, char **envp)
{
	shell->env = env_init(envp);
	shell->last_exit = 0;
	shell->line = NULL;
	shell->tokens = NULL;
	shell->cmds = NULL;
}

static void	fail_syntax(t_shell *shell)
{
	shell->last_exit = 2;
	token_list_free(shell->tokens);
	shell->tokens = NULL;
}

void	run_line(t_shell *shell)
{
	if (syntax_check_line(shell->line))
	{
		fail_syntax(shell);
		return ;
	}
	shell->tokens = lex_tokenize(shell->line);
	if (!shell->tokens)
		return ;
	if (syntax_check_tokens(shell->tokens))
	{
		fail_syntax(shell);
		return ;
	}
	shell->cmds = parse_tokens(shell->tokens);
	token_list_free(shell->tokens);
	shell->tokens = NULL;
	if (!shell->cmds)
		return ;
	exec_run(shell);
	cmd_list_free(shell->cmds);
	shell->cmds = NULL;
}
