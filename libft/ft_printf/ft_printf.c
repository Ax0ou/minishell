/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_printf.c                                        :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/11/25 13:53:41 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/05/22 18:56:00 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../inc/ft_printf.h"
#include <stdio.h>
#include <limits.h>

static int	ft_dispatch(char specifier, va_list args)
{
	int	count;

	if (specifier == 'c')
		count = ft_print_char(va_arg(args, int));
	else if (specifier == 's')
		count = ft_print_str(va_arg(args, char *));
	else if (specifier == 'p')
		count = ft_print_ptr(va_arg(args, unsigned long));
	else if (specifier == 'd' || specifier == 'i')
		count = ft_print_nbr(va_arg(args, int));
	else if (specifier == 'u')
		count = ft_print_unsigned(va_arg(args, unsigned int));
	else if (specifier == 'x')
		count = ft_print_hex(va_arg(args, unsigned int), 0);
	else if (specifier == 'X')
		count = ft_print_hex(va_arg(args, unsigned int), 1);
	else if (specifier == '%')
		count = write(1, "%", 1);
	else
		count = (write(1, &specifier, 1));
	return (count);
}

int	ft_printf(const char *format, ...)
{
	va_list	args;
	int		printed;
	int		i;

	printed = 0;
	i = 0;
	va_start(args, format);
	while (format[i])
	{
		if (format[i] == '%')
		{
			i ++;
			printed += ft_dispatch(format[i], args);
		}
		else
			printed += write(1, &format[i], 1);
		i ++;
	}
	va_end(args);
	return (printed);
}
