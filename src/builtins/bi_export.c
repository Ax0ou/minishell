/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   bi_export.c                                        :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/09/18 14:02:57 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/09/18 14:02:58 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

int	count_env(t_env *env)
{
	int	n;

	n = 0;
	while (env)
	{
		n++;
		env = env->next;
	}
	return (n);
}

int	key_lt(char *a, char *b)
{
	while (*a && *a == *b)
	{
		a++;
		b++;
	}
	return ((unsigned char)*a < (unsigned char)*b);
}

int	valid_identifier(char *s, int stop_at_eq)
{
	int	i;

	if (!s || !s[0])
		return (0);
	if (!ft_isalpha(s[0]) && s[0] != '_')
		return (0);
	i = 1;
	while (s[i] && (!stop_at_eq || s[i] != '='))
	{
		if (!ft_isalnum(s[i]) && s[i] != '_')
			return (0);
		i++;
	}
	return (1);
}

static int	assign_one(t_env **env, char *arg)
{
	char	*eq;
	char	*key;

	if (!valid_identifier(arg, 1))
		return (print_error("export", arg, "not a valid identifier"));
	eq = ft_strchr(arg, '=');
	if (!eq)
		return (env_set(env, arg, NULL, 1));
	key = ft_substr(arg, 0, eq - arg);
	env_set(env, key, eq + 1, 1);
	free(key);
	return (0);
}

int	bi_export(t_env **env, char **argv)
{
	int	i;
	int	ret;

	if (!argv[1])
		return (export_list(*env));
	ret = 0;
	i = 1;
	while (argv[i])
	{
		if (assign_one(env, argv[i]))
			ret = 1;
		i++;
	}
	return (ret);
}
