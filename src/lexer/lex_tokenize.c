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

static void	process_char(t_token **tokens, char *line, char *buffer, int *i);
static void	handle_operator(t_token **head, char *line, char *buffer, int *i);

t_token	*lex_tokenize(char *line)
{
	t_token	*tokens;
	char	buffer[4096];
	int		i;

	if (!line)
		return (NULL);
	lex_reset_state();
	tokens = NULL;
	buffer[0] = '\0';
	i = 0;
	while (line[i])
		process_char(&tokens, line, buffer, &i);
	if (lex_in_quote())
	{
		token_list_free(tokens);
		return (NULL);
	}
	flush_buffer(&tokens, buffer);
	return (tokens);
}

static void	process_char(t_token **tokens, char *line, char *buffer, int *i)
{
	if (lex_in_quote())
	{
		lex_handle_quote_char(line[*i], buffer);
		(*i)++;
		return ;
	}
	if (lex_is_quote_char(line[*i]))
	{
		lex_handle_quote_char(line[*i], buffer);
		(*i)++;
		return ;
	}
	if (line[*i] == ' ')
	{
		flush_buffer(tokens, buffer);
		(*i)++;
		return ;
	}
	if (lex_is_operator_char(line[*i]))
		handle_operator(tokens, line, buffer, i);
	else
	{
		append_char(buffer, line[*i]);
		(*i)++;
	}
}

static void	handle_operator(t_token **head, char *line, char *buffer, int *i)
{
	t_token_type	type;
	int				len;
	t_token			*new;
	char			op[3];

	type = detect_operator(line, *i, &len);
	flush_buffer(head, buffer);
	op[0] = line[*i];
	op[1] = '\0';
	if (len == 2)
	{
		op[1] = line[*i + 1];
		op[2] = '\0';
	}
	new = new_token(type, op);
	if (!new)
		return ;
	token_add_back(head, new);
	*i += len;
}
