/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   lex_tokenize_utils.c                               :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aalvard <aalvarad@student.42lausanne.ch    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/01 10:10:00 by aalvard           #+#    #+#             */
/*   Updated: 2026/08/01 15:16:29 by aalvard          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

static int	grow_buffer(t_lex *lex)
{
	char	*bigger;

	bigger = malloc(lex->cap * 2);
	if (!bigger)
	{
		free(lex->buffer);
		lex->buffer = NULL;
		return (0);
	}
	ft_memcpy(bigger, lex->buffer, lex->len + 1);
	free(lex->buffer);
	lex->buffer = bigger;
	lex->cap = lex->cap * 2;
	return (1);
}

void	append_char(t_lex *lex, char c)
{
	if (!lex->buffer)
		return ;
	if (lex->len + 2 > lex->cap && !grow_buffer(lex))
		return ;
	lex->buffer[lex->len] = c;
	lex->len++;
	lex->buffer[lex->len] = '\0';
}

int	lex_is_operator_char(char c)
{
	return (c == '|' || c == '<' || c == '>');
}
