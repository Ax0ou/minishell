/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   exp_quotes_strip.c                                 :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aalvard <aalvarad@student.42lausanne.ch    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/09/18 09:00:00 by aalvard           #+#    #+#             */
/*   Updated: 2026/09/18 09:00:00 by aalvard          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

/*
** Retire les quotes qui DELIMITENT, garde celles qui sont a l'interieur
** d'une autre paire. Appelee apres l'expansion des variables (issue #41),
** jamais avant : sinon "$VAR" et '$VAR' deviendraient indiscernables.
*/

static void	strip_step(char c, t_lex_state *state, int *keep)
{
	*keep = 1;
	if (*state == STATE_NORMAL && (c == '\'' || c == '"'))
	{
		if (c == '"')
			*state = STATE_DQUOTE;
		else
			*state = STATE_SQUOTE;
		*keep = 0;
		return ;
	}
	if ((*state == STATE_SQUOTE && c == '\'')
		|| (*state == STATE_DQUOTE && c == '"'))
	{
		*state = STATE_NORMAL;
		*keep = 0;
	}
}

static void	strip_copy(char *value, char *out)
{
	t_lex_state	state;
	int			keep;
	int			i;
	int			j;

	state = STATE_NORMAL;
	i = 0;
	j = 0;
	while (value[i])
	{
		strip_step(value[i], &state, &keep);
		if (keep)
		{
			out[j] = value[i];
			j++;
		}
		i++;
	}
	out[j] = '\0';
}

char	*exp_strip_quotes(char *value)
{
	char	*out;

	if (!value)
		return (NULL);
	out = malloc(ft_strlen(value) + 1);
	if (!out)
		return (NULL);
	strip_copy(value, out);
	return (out);
}

int	exp_strip_tokens(t_token *tokens)
{
	char			*stripped;
	t_token_type	prev;

	prev = T_PIPE;
	while (tokens)
	{
		if (tokens->type == T_WORD && tokens->has_quotes && prev != T_HEREDOC)
		{
			stripped = exp_strip_quotes(tokens->value);
			if (!stripped)
				return (1);
			free(tokens->value);
			tokens->value = stripped;
		}
		prev = tokens->type;
		tokens = tokens->next;
	}
	return (0);
}
