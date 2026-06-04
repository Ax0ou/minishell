/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_strrchr.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/10/12 15:03:24 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/05/22 19:00:02 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../inc/libft.h"

char	*ft_strrchr(const char *s, int c)
{
	char			*p;
	unsigned char	ch;
	size_t			len;

	ch = c;
	len = ft_strlen(s);
	p = (char *)s + len;
	if (ch == '\0')
		return (p ++);
	while (p >= s)
	{
		if (*p == ch)
			return (p);
		p --;
	}
	return (NULL);
}
