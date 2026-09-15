/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   parse_redirs.c                                     :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aalvard <aalvarad@student.42lausanne.ch    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/01 10:10:00 by aalvard           #+#    #+#             */
/*   Updated: 2026/08/01 15:16:29 by aalvard          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

t_redir	*redir_new(t_token_type type, char *target)
{
	t_redir	*redir;

	redir = malloc(sizeof(t_redir));
	if (!redir)
		return (NULL);
	redir->type = type;
	redir->target = ft_strdup(target);
	if (!redir->target)
	{
		free(redir);
		return (NULL);
	}
	redir->next = NULL;
	return (redir);
}

void	redir_add_back(t_redir **head, t_redir *new)
{
	t_redir	*last;

	if (!head || !new)
		return ;
	if (!*head)
	{
		*head = new;
		return ;
	}
	last = *head;
	while (last->next)
		last = last->next;
	last->next = new;
}

int	attach_redirs(t_cmd *cmd, t_token *token)
{
	t_redir	*redir;

	while (token && token->type != T_PIPE)
	{
		if (token->type != T_WORD)
		{
			if (!token->next)
				return (0);
			redir = redir_new(token->type, token->next->value);
			if (!redir)
				return (0);
			redir_add_back(&cmd->redirs, redir);
		}
		token = token_advance(token);
	}
	return (1);
}
