/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_strjoin.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/10/16 20:32:33 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/05/22 18:59:30 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../inc/libft.h"

char	*ft_strjoin(char const *s1, char const *s2)
{
	char	*joined;
	size_t	len;
	size_t	i;

	if (!s1 && !s2)
		return (NULL);
	len = ft_strlen(s1) + ft_strlen (s2);
	joined = ft_calloc(len + 1, sizeof(char));
	if (!joined)
		return (NULL);
	len = 0;
	while (s1[len])
	{
		joined[len] = s1[len];
		len ++;
	}
	i = 0;
	while (s2[i])
	{
		joined[len + i] = s2[i];
		i ++;
	}
	return (joined);
}
