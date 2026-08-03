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

static t_lex_state	g_state;
static int		g_token_active;
static int		g_has_quotes;

void	lex_reset_state(void)
{
	g_state = STATE_NORMAL;
	g_token_active = 0;
	g_has_quotes = 0;
}

int	lex_in_quote(void)
{
	return (g_state != STATE_NORMAL);
}

int	lex_is_quote_char(char c)
{
	return (c == '\'' || c == '"');
}

void	lex_handle_quote_char(char c, char *buffer)
{
	if (!lex_in_quote())
	{
		if (c == '"')
			g_state = STATE_DQUOTE;
		else
			g_state = STATE_SQUOTE;
		g_token_active = 1;
		g_has_quotes = 1;
		return ;
	}
	if ((g_state == STATE_SQUOTE && c == '\'')
		|| (g_state == STATE_DQUOTE && c == '"'))
	{
		g_state = STATE_NORMAL;
		return ;
	}
	g_token_active = 1;
	append_char(buffer, c);
}

void	flush_buffer(t_token **head, char *buffer)
{
	t_token	*new;

	if (!g_token_active && buffer[0] == '\0')
		return ;
	new = new_token(T_WORD, buffer);
	if (!new)
		return ;
	new->has_quotes = g_has_quotes;
	token_add_back(head, new);
	buffer[0] = '\0';
	g_token_active = 0;
	g_has_quotes = 0;
}
