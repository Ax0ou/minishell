/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_print_hex.c                                     :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/11/25 15:28:28 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/05/22 18:55:29 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../inc/ft_printf.h"

static int	print_hex_recursive(unsigned long n, char *base)
{
	int	count;

	count = 0;
	if (n >= 16)
		count += print_hex_recursive(n / 16, base);
	count += write(1, &base[n % 16], 1);
	return (count);
}

int	ft_print_hex(unsigned long n, int uppercase)
{
	char	*base;
	int		count;

	count = 0;
	if (uppercase)
		base = "0123456789ABCDEF";
	else
		base = "0123456789abcdef";
	count = print_hex_recursive(n, base);
	return (count);
}
