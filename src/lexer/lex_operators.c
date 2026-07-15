/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   lex_operators.c                                    :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aalvard <aalvarad@student.42lausanne.ch    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/14 10:15:35 by aalvard           #+#    #+#             */
/*   Updated: 2026/07/15 13:28:03 by aalvard          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

static t_token_type	check_double(char *line, int i, int *len)
{
	if (line[i + 1] == line[i])
	{
		*len = 2;
		if (line[i] == '<')
			return (T_HEREDOC);
		return (T_APPEND);
	}
	*len = 1;
	if (line[i] == '<')
		return (T_REDIR_IN);
	return (T_REDIR_OUT);
}

t_token_type	detect_operator(char *line, int i, int *len)
{
	if (line[i] == '|')
	{
		*len = 1;
		return (T_PIPE);
	}
	if (line[i] == '<' || line[i] == '>')
		return (check_double(line, i, len));
	*len = 0;
	return (T_WORD);
}
