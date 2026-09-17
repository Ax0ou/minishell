/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ut_str.c                                           :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aalvard <aalvarad@student.42lausanne.ch    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/01 10:10:00 by aalvard           #+#    #+#             */
/*   Updated: 2026/09/17 13:48:45 by aalvard          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

static int	skip_spaces(char *s, int i)
{
	while (s[i] == ' ' || (s[i] >= '\t' && s[i] <= '\r'))
		i++;
	return (i);
}

static int	read_sign(char *s, int *i)
{
	int	sign;

	sign = 1;
	if (s[*i] == '-')
		sign = -1;
	if (s[*i] == '-' || s[*i] == '+')
		(*i)++;
	return (sign);
}

static int	accumulate(char *s, int *i, unsigned long long *acc)
{
	int	digits;

	*acc = 0;
	digits = 0;
	while (s[*i] >= '0' && s[*i] <= '9')
	{
		if (*acc > (ULLONG_MAX - (unsigned long long)(s[*i] - '0')) / 10)
			return (0);
		*acc = *acc * 10 + (unsigned long long)(s[*i] - '0');
		digits++;
		(*i)++;
	}
	return (digits > 0);
}

int	parse_ll(char *s, long long *out)
{
	int					i;
	int					sign;
	unsigned long long	acc;

	i = skip_spaces(s, 0);
	sign = read_sign(s, &i);
	if (!accumulate(s, &i, &acc))
		return (0);
	i = skip_spaces(s, i);
	if (s[i])
		return (0);
	if (acc > (unsigned long long)LLONG_MAX + (sign < 0))
		return (0);
	if (sign < 0)
		*out = -(long long)(acc - 1) - 1;
	else
		*out = (long long)acc;
	return (1);
}
