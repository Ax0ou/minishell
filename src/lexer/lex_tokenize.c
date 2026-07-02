/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   lex_tokenize.c                                     :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aalvard <aalvarad@student.42lausanne.ch    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/01 12:46:52 by aalvard           #+#    #+#             */
/*   Updated: 2026/07/02 13:20:46 by aalvard          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

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
	{
		if (line[i] == ' ')
		{
			if (buffer[0] != '\0')
				flush_buffer(&tokens, buffer);
		}
		else
			append_char(buffer, line[i]);
		i++;
	}
	if (buffer[0] != '\0')
		flush_buffer(&tokens, buffer);
	return (tokens);
}
