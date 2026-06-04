/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_calloc.c                                        :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/10/15 15:56:19 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/05/22 18:58:05 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../inc/libft.h"

void	*ft_calloc(size_t nmemb, size_t size)
{
	void			*ptr;
	size_t			total;
	size_t			i;
	unsigned char	*p;
	void			*null;

	null = (void *)0;
	if (size != 0 && nmemb > (size_t)-1 / size)
		return (null);
	total = nmemb * size;
	if (nmemb == 0 || size == 0)
		ptr = malloc(0);
	else
		ptr = malloc(total);
	if (!ptr)
		return (null);
	p = (unsigned char *)ptr;
	i = 0;
	while (i < total)
	{
		p[i] = 0;
		i ++;
	}
	return (ptr);
}
