/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_memchr.c                                        :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/10/12 15:40:01 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/05/22 18:58:40 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../inc/libft.h"

void	*ft_memchr(const void *ptr, int value, size_t num)
{
	const unsigned char	*p;

	p = (unsigned char *)ptr;
	while (num > 0)
	{
		if (*p == (unsigned char)value)
		{
			return ((void *)p);
		}
		p ++;
		num --;
	}
	return ((void *)0);
}
