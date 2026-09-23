/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   exp_var_replace.c                                  :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aalvard <aalvarad@student.42lausanne.ch    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/09/21 13:30:00 by aalvard           #+#    #+#             */
/*   Updated: 2026/09/21 13:30:00 by aalvard          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

static void	append(char **res, char *add, int len)
{
	char	*piece;
	char	*joined;

	if (!*res || len == 0)
		return ;
	piece = ft_substr(add, 0, len);
	joined = NULL;
	if (piece)
		joined = ft_strjoin(*res, piece);
	free(piece);
	free(*res);
	*res = joined;
}

static void	update_state(t_lex_state *state, char c)
{
	if (*state == STATE_NORMAL && c == '\'')
		*state = STATE_SQUOTE;
	else if (*state == STATE_NORMAL && c == '"')
		*state = STATE_DQUOTE;
	else if ((*state == STATE_SQUOTE && c == '\'')
		|| (*state == STATE_DQUOTE && c == '"'))
		*state = STATE_NORMAL;
}

static int	plain_len(char *s, t_lex_state state, int respect_quotes)
{
	int	n;

	n = 1;
	while (s[n])
	{
		if (respect_quotes && (s[n] == '\'' || s[n] == '"'))
			break ;
		if (s[n] == '$' && state != STATE_SQUOTE)
			break ;
		n++;
	}
	return (n);
}

static int	expand_one(t_shell *shell, char *s, char **res)
{
	int		len;
	char	*value;

	len = exp_var_len(s + 1);
	if (len == 0)
	{
		append(res, "$", 1);
		return (1);
	}
	value = exp_var_value(shell, s + 1, len);
	if (!value)
	{
		free(*res);
		*res = NULL;
		return (1);
	}
	append(res, value, ft_strlen(value));
	free(value);
	return (1 + len);
}

char	*exp_var_replace(t_shell *shell, char *str, int respect_quotes)
{
	char		*res;
	t_lex_state	state;
	int			i;
	int			n;

	res = ft_strdup("");
	state = STATE_NORMAL;
	i = 0;
	while (res && str[i])
	{
		if (respect_quotes)
			update_state(&state, str[i]);
		if (str[i] == '$' && state != STATE_SQUOTE)
			i += expand_one(shell, str + i, &res);
		else
		{
			n = plain_len(str + i, state, respect_quotes);
			append(&res, str + i, n);
			i += n;
		}
	}
	return (res);
}
