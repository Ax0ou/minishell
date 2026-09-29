/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   lex_quotes.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aalvard <aalvarad@student.42lausanne.ch    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/01 10:10:00 by aalvard           #+#    #+#             */
/*   Updated: 2026/08/01 15:16:29 by aalvard          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

int	lex_init(t_lex *lex)
{
	lex->state = STATE_NORMAL;
	lex->token_active = 0;
	lex->has_quotes = 0;
	lex->len = 0;
	lex->cap = 64;
	lex->buffer = malloc(lex->cap);
	if (!lex->buffer)
		return (0);
	lex->buffer[0] = '\0';
	lex->i = 0;
	return (1);
}

int	lex_in_quote(t_lex *lex)
{
	return (lex->state != STATE_NORMAL);
}

int	lex_is_quote_char(char c)
{
	return (c == '\'' || c == '"');
}

void	lex_handle_quote_char(t_lex *lex, char c)
{
	if (!lex_in_quote(lex))
	{
		if (c == '"')
			lex->state = STATE_DQUOTE;
		else
			lex->state = STATE_SQUOTE;
		lex->token_active = 1;
		lex->has_quotes = 1;
		append_char(lex, c);
		return ;
	}
	if ((lex->state == STATE_SQUOTE && c == '\'')
		|| (lex->state == STATE_DQUOTE && c == '"'))
	{
		lex->state = STATE_NORMAL;
		append_char(lex, c);
		return ;
	}
	lex->token_active = 1;
	append_char(lex, c);
}

void	flush_buffer(t_lex *lex, t_token **head)
{
	t_token	*new;

	if (!lex->buffer)
		return ;
	if (!lex->token_active && lex->buffer[0] == '\0')
		return ;
	new = new_token(T_WORD, lex->buffer);
	if (!new)
		return ;
	new->has_quotes = lex->has_quotes;
	token_add_back(head, new);
	lex->buffer[0] = '\0';
	lex->len = 0;
	lex->token_active = 0;
	lex->has_quotes = 0;
}
