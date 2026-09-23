/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   exp_var_identify.c                                 :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aalvard <aalvarad@student.42lausanne.ch    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/09/21 12:00:00 by aalvard           #+#    #+#             */
/*   Updated: 2026/09/21 12:00:00 by aalvard          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

int	exp_var_len(char *s)
{
	int	len;

	if (!s || !*s)
		return (0);
	if (*s == '?' || ft_isdigit(*s))
		return (1);
	if (!ft_isalpha(*s) && *s != '_')
		return (0);
	len = 1;
	while (ft_isalnum(s[len]) || s[len] == '_')
		len++;
	return (len);
}
