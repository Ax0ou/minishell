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

/*
** s pointe sur le caractere qui suit un '$'.
** Renvoie la longueur du nom de variable qui commence la,
** ou 0 si ce '$' n'introduit pas de variable (il reste un '$' litteral).
**
**   "USER-test" -> 4    le '-' arrete le nom
**   "USER_test" -> 9    le '_' fait partie du nom
**   "?abc"      -> 1    $? : nom d'un seul caractere
**   "1abc"      -> 1    $1 : un chiffre, un seul caractere
**   "-test"     -> 0    pas une variable
*/
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
