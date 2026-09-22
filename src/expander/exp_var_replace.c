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

/*
** Colle les len premiers caracteres de add au bout de *res.
** len == 0 : rien a coller. Test obligatoire, car ft_substr de la
** libft renvoie NULL pour une longueur 0, ce qu'on prendrait a tort
** pour un echec de malloc.
** Si un malloc echoue, *res est libere et passe a NULL.
*/
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

/*
** Meme automate que le lexer : on sait a tout moment si on est
** dehors, entre '...' ou entre "...".
*/
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

/*
** s pointe sur un '$'. Colle sa valeur au bout de *res et renvoie
** le nombre de caracteres consommes dans la chaine d'origine.
*/
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

/*
** Renvoie une nouvelle chaine ou chaque $NOM et $? est remplace par
** sa valeur, sauf entre quotes simples. Les quotes sont conservees :
** elles seront retirees ensuite par exp_strip_tokens.
** respect_quotes = 0 pour un contenu de heredoc : les quotes y sont
** litterales, pas structurelles, donc un ' ne doit pas couper l'expansion.
** NULL uniquement si un malloc echoue.
*/
char	*exp_var_replace(t_shell *shell, char *str, int respect_quotes)
{
	char		*res;
	t_lex_state	state;
	int			i;

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
			append(&res, str + i, 1);
			i++;
		}
	}
	return (res);
}
