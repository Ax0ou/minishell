/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_memset.c                                        :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/10/08 11:34:23 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/05/22 18:58:56 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../inc/libft.h"

void	*ft_memset(void *ptr, int value, size_t num)
{
	unsigned char	*p;

	p = (unsigned char *)ptr;
	while (num > 0)
	{
		*p = (unsigned char)value;
		p ++;
		num --;
	}
	return (ptr);
}
