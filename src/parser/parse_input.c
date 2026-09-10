/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   parse_input.c                                      :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aalvard <aalvarad@student.42lausanne.ch    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/01 10:10:00 by aalvard           #+#    #+#             */
/*   Updated: 2026/08/01 15:16:29 by aalvard          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

static t_cmd	*build_cmd(t_token *tokens)
{
	t_cmd	*cmd;
	int		n;

	cmd = cmd_new();
	if (!cmd)
		return (NULL);
	n = count_args(tokens);
	cmd->argv = fill_argv(tokens, n);
	if (!cmd->argv)
	{
		cmd_list_free(cmd);
		return (NULL);
	}
	return (cmd);
}

t_cmd	*parse_tokens(t_token *tokens)
{
	t_cmd	*cmds;
	t_cmd	*cmd;

	cmds = NULL;
	while (tokens)
	{
		cmd = build_cmd(tokens);
		if (!cmd)
		{
			cmd_list_free(cmds);
			return (NULL);
		}
		cmd_add_back(&cmds, cmd);
		tokens = skip_to_next_cmd(tokens);
	}
	return (cmds);
}
