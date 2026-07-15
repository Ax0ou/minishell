/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   lex_tokenize.c                                     :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aalvard <aalvarad@student.42lausanne.ch    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/01 12:46:52 by aalvard           #+#    #+#             */
/*   Updated: 2026/07/14 14:10:53 by aalvard          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

static void	process_char(t_token **tokens, char *line, char *buffer, int *i);
static void	handle_operator(t_token **head, char *line, char *buffer, int *i);

static void	append_char(char *buffer, char c)
{
	int	len;

	len = ft_strlen(buffer);
	buffer[len] = c;
	buffer[len + 1] = '\0';
}

static void	flush_buffer(t_token **head, char *buffer)
{
	t_token	*new;

	new = new_token(T_WORD, buffer);
	if (!new)
		return ;
	token_add_back(head, new);
	buffer[0] = '\0';
}

t_token	*lex_tokenize(char *line)
{
	t_token	*tokens;
	char	buffer[4096];
	int		i;

	if (!line)
		return (NULL);
	tokens = NULL;
	buffer[0] = '\0';
	i = 0;
	while (line[i])
		process_char(&tokens, line, buffer, &i);
	if (buffer[0] != '\0')
		flush_buffer(&tokens, buffer);
	return (tokens);
}

static void	process_char(t_token **tokens, char *line, char *buffer, int *i)
{
	if (line[*i] == ' ')
	{
		if (buffer[0] != '\0')
			flush_buffer(tokens, buffer);
		(*i)++;
	}
	else if (line[*i] == '|' || line[*i] == '<' || line[*i] == '>')
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
	if (buffer[0] != '\0')
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
