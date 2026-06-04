/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_print_nbr.c                                     :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/11/25 15:03:37 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/05/22 18:55:34 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../inc/ft_printf.h"

int	ft_print_nbr(int n)
{
	long	nb;
	int		count;
	char	c;

	nb = n;
	count = 0;
	if (nb < 0)
	{
		count += write(1, "-", 1);
		nb = -nb;
	}
	if (nb >= 10)
		count += ft_print_nbr(nb / 10);
	c = '0' + (nb % 10);
	count += write(1, &c, 1);
	return (count);
}
