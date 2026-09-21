/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   bi_unset.c                                         :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/09/21 13:59:38 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/09/21 13:59:39 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

int	bi_unset(t_env **env, char **argv)
{
	int	i;
	int	ret;

	ret = 0;
	i = 1;
	while (argv[i])
	{
		if (!valid_identifier(argv[i], 0))
			ret = print_error("unset", argv[i], "not a valid identifier");
		else
			env_unset(env, argv[i]);
		i++;
	}
	return (ret);
}
