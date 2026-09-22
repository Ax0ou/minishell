/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   lex_tokenize.c                                     :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aalvard <aalvarad@student.42lausanne.ch    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/01 12:46:52 by aalvard           #+#    #+#             */
/*   Updated: 2026/08/01 15:16:29 by aalvard          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

static void	process_char(t_lex *lex, t_token **tokens, char *line);
static void	handle_operator(t_lex *lex, t_token **head, char *line);

t_token	*lex_tokenize(char *line)
{
	t_lex	lex;
	t_token	*tokens;

	if (!line)
		return (NULL);
	lex_init(&lex);
	tokens = NULL;
	while (line[lex.i])
		process_char(&lex, &tokens, line);
	if (lex_in_quote(&lex))
	{
		token_list_free(tokens);
		return (NULL);
	}
	flush_buffer(&lex, &tokens);
	return (tokens);
}

static void	process_char(t_lex *lex, t_token **tokens, char *line)
{
	if (lex_in_quote(lex))
	{
		lex_handle_quote_char(lex, line[lex->i]);
		lex->i++;
		return ;
	}
	if (lex_is_quote_char(line[lex->i]))
	{
		lex_handle_quote_char(lex, line[lex->i]);
		lex->i++;
		return ;
	}
	if (line[lex->i] == ' ' || line[lex->i] == '\t')
	{
		flush_buffer(lex, tokens);
		lex->i++;
		return ;
	}
	if (lex_is_operator_char(line[lex->i]))
		handle_operator(lex, tokens, line);
	else
	{
		append_char(lex->buffer, line[lex->i]);
		lex->i++;
	}
}

static void	handle_operator(t_lex *lex, t_token **head, char *line)
{
	t_token_type	type;
	int				len;
	t_token			*new;
	char			op[3];

	type = detect_operator(line, lex->i, &len);
	flush_buffer(lex, head);
	op[0] = line[lex->i];
	op[1] = '\0';
	if (len == 2)
	{
		op[1] = line[lex->i + 1];
		op[2] = '\0';
	}
	new = new_token(type, op);
	if (!new)
		return ;
	token_add_back(head, new);
	lex->i += len;
}
