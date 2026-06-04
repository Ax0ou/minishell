/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_print_ptr.c                                     :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/11/25 14:50:07 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/05/22 18:55:45 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../inc/ft_printf.h"

int	ft_print_ptr(unsigned long ptr)
{
	int				count;

	if (!ptr)
	{
		write(1, "(nil)", 5);
		return (5);
	}
	count = 0;
	count += write(1, "0x", 2);
	if (!ptr || ptr == 0)
		count += write(1, "0", 1);
	else
		count += ft_print_hex(ptr, 0);
	return (count);
}
