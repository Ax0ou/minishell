/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_memmove.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/10/11 14:55:57 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/05/22 18:58:53 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../inc/libft.h"

void	*ft_memmove(void *dest, const void *src, size_t n)
{
	unsigned char		*d;
	const unsigned char	*s;

	d = (unsigned char *)dest;
	s = (const unsigned char *)src;
	if (src == dest)
		return (dest);
	if (s < d && d < s + n)
	{
		while (n --)
		{
			*(d + n) = *(s + n);
		}
	}
	else
	{
		while (n --)
		{
			*d = *s;
			d ++;
			s ++;
		}
	}
	return (dest);
}
