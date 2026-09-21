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

/*
** s pointe sur le nom (juste apres le '$'), len vient de exp_var_len.
** Renvoie TOUJOURS une chaine allouee, que l'appelant doit liberer :
**   $?        -> le dernier code de sortie en texte ("0", "127"...)
**   $0 a $9   -> "" (minishell ne recoit pas d'arguments)
**   $NOM      -> sa valeur dans l'env, "" si absente ou sans valeur
** Renvoie NULL uniquement si un malloc echoue.
*/
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
