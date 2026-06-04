/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_bzero.c                                         :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/10/08 12:22:11 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/05/22 18:58:00 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../inc/libft.h"

void	ft_bzero(void *ptr, size_t num)
{
	unsigned char	*p;

	p = (unsigned char *)ptr;
	while (num > 0)
	{
		*p = 0;
		p ++;
		num --;
	}
}
