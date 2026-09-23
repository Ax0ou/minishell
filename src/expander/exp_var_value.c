/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   exp_var_value.c                                    :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aalvard <aalvarad@student.42lausanne.ch    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/09/21 12:30:00 by aalvard           #+#    #+#             */
/*   Updated: 2026/09/21 12:30:00 by aalvard          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

char	*exp_var_value(t_shell *shell, char *s, int len)
{
	char	*name;
	char	*value;

	if (*s == '?')
		return (ft_itoa(shell->last_exit));
	if (ft_isdigit(*s))
		return (ft_strdup(""));
	name = ft_substr(s, 0, len);
	if (!name)
		return (NULL);
	value = env_get(shell->env, name);
	free(name);
	if (!value)
		return (ft_strdup(""));
	return (ft_strdup(value));
}
