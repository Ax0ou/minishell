/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   exp_run.c                                          :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aalvard <aalvarad@student.42lausanne.ch    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/09/21 11:00:00 by aalvard           #+#    #+#             */
/*   Updated: 2026/09/21 11:00:00 by aalvard          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

static int	expand_word(t_shell *shell, t_token *tok)
{
	char	*expanded;

	expanded = exp_var_replace(shell, tok->value, 1);
	if (!expanded)
		return (1);
	free(tok->value);
	tok->value = expanded;
	return (0);
}

static void	drop_token(t_token **link)
{
	t_token	*tok;

	tok = *link;
	*link = tok->next;
	free(tok->value);
	free(tok);
}

/*
** Etend chaque mot, sauf le delimiteur d'un heredoc (cat << $USER
** cherche litteralement "$USER"). Un mot sans quotes devenu vide
** disparait, comme dans bash : echo $INEXISTANT a -> echo a.
** On le garde s'il sert de cible a une redirection.
*/
static int	expand_tokens(t_shell *shell)
{
	t_token			**link;
	t_token_type	prev;

	link = &shell->tokens;
	prev = T_PIPE;
	while (*link)
	{
		if ((*link)->type == T_WORD && prev != T_HEREDOC)
		{
			if (expand_word(shell, *link))
				return (1);
			if (!(*link)->value[0] && !(*link)->has_quotes
				&& (prev == T_WORD || prev == T_PIPE))
			{
				drop_token(link);
				continue ;
			}
		}
		prev = (*link)->type;
		link = &(*link)->next;
	}
	return (0);
}

/*
** Point d'entree unique de l'expander : d'abord les variables,
** ensuite le retrait des quotes. L'ordre est obligatoire.
*/
int	exp_run(t_shell *shell)
{
	if (expand_tokens(shell))
		return (1);
	return (exp_strip_tokens(shell->tokens));
}
