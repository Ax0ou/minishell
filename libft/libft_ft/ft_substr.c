/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_substr.c                                        :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/10/16 19:34:21 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/05/22 19:00:18 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../inc/libft.h"

char	*ft_substr(char const *s, unsigned int start, size_t len)
{
	char	*sub;
	char	*src;
	size_t	sub_len;

	if (!s || len <= 0)
		return (NULL);
	if (ft_strlen(s) < (size_t)start)
		return (ft_strdup(""));
	src = (char *)s + start;
	if (ft_strlen(src) < len)
		sub_len = ft_strlen(src) + 1;
	else
		sub_len = len + 1;
	sub = malloc(sub_len);
	if (!sub)
		return (NULL);
	ft_strlcpy(sub, src, sub_len);
	return (sub);
}
