/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   syntax_check.c                                     :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aalvard <aalvarad@student.42lausanne.ch    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/09/17 09:00:00 by aalvard           #+#    #+#             */
/*   Updated: 2026/09/17 09:00:00 by aalvard          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

static int	is_redir(t_token_type type)
{
	return (type == T_REDIR_IN || type == T_REDIR_OUT
		|| type == T_HEREDOC || type == T_APPEND);
}

static char	*op_label(t_token *tok)
{
	if (!tok)
		return ("newline");
	if (tok->type == T_PIPE)
		return ("|");
	if (tok->type == T_REDIR_IN)
		return ("<");
	if (tok->type == T_REDIR_OUT)
		return (">");
	if (tok->type == T_HEREDOC)
		return ("<<");
	return (">>");
}

static int	report(char *label)
{
	ft_putstr_fd("minishell: syntax error near unexpected token `", 2);
	ft_putstr_fd(label, 2);
	ft_putstr_fd("'\n", 2);
	return (2);
}

int	syntax_check_tokens(t_token *tokens)
{
	t_token	*cur;

	if (!tokens)
		return (0);
	if (tokens->type == T_PIPE)
		return (report("|"));
	cur = tokens;
	while (cur)
	{
		if (is_redir(cur->type) && (!cur->next || cur->next->type != T_WORD))
			return (report(op_label(cur->next)));
		if (cur->type == T_PIPE && !cur->next)
			return (report("|"));
		if (cur->type == T_PIPE && cur->next->type == T_PIPE)
			return (report("|"));
		cur = cur->next;
	}
	return (0);
}

int	syntax_check_line(char *line)
{
	int		i;
	char	quote;

	if (!line)
		return (0);
	i = 0;
	quote = 0;
	while (line[i])
	{
		if (!quote && (line[i] == '\'' || line[i] == '"'))
			quote = line[i];
		else if (quote && line[i] == quote)
			quote = 0;
		i++;
	}
	if (!quote)
		return (0);
	ft_putstr_fd("minishell: unexpected EOF while looking for matching `", 2);
	ft_putchar_fd(quote, 2);
	ft_putstr_fd("'\n", 2);
	return (2);
}
