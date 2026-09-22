/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   bi_exit.c                                          :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aalvard <aalvarad@student.42lausanne.ch    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/01 10:10:00 by aalvard           #+#    #+#             */
/*   Updated: 2026/08/01 15:16:29 by aalvard          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

int	bi_exit(t_shell *shell, char **argv)
{
	long long	value;
	int			code;

	code = shell->last_exit;
	if (argv[1])
	{
		if (!parse_ll(argv[1], &value))
		{
			print_error("exit", argv[1], "numeric argument required");
			code = 2;
		}
		else if (argv[2])
			return (print_error("exit", NULL, "too many arguments"));
		else
			code = (int)(value & 255);
	}
	shell->want_exit = 1;
	return (code);
}
