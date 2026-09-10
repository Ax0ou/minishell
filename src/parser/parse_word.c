/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   parse_word.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aalvard <aalvarad@student.42lausanne.ch    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/01 10:10:00 by aalvard           #+#    #+#             */
/*   Updated: 2026/08/01 15:16:29 by aalvard          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

static t_token	*advance(t_token *token)
{
	if (token->type == T_WORD)
		return (token->next);
	token = token->next;
	if (token)
		return (token->next);
	return (NULL);
}

static char	**free_partial(char **argv, int count)
{
	int	i;

	i = 0;
	while (i < count)
	{
		free(argv[i]);
		i++;
	}
	free(argv);
	return (NULL);
}

int	count_args(t_token *token)
{
	int	n;

	n = 0;
	while (token && token->type != T_PIPE)
	{
		if (token->type == T_WORD)
			n++;
		token = advance(token);
	}
	return (n);
}

char	**fill_argv(t_token *token, int n)
{
	char	**argv;
	int		i;

	argv = malloc(sizeof(char *) * (n + 1));
	if (!argv)
		return (NULL);
	i = 0;
	while (token && token->type != T_PIPE)
	{
		if (token->type == T_WORD)
		{
			argv[i] = ft_strdup(token->value);
			if (!argv[i])
				return (free_partial(argv, i));
			i++;
		}
		token = advance(token);
	}
	argv[i] = NULL;
	return (argv);
}
