/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   bi_export_utils.c                                  :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/09/18 14:03:01 by dbomfim-          #+#    #+#             */
/*   Updated: 2026/09/18 14:03:02 by dbomfim-         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

static void	sort_entries(t_env **arr, int n)
{
	t_env	*tmp;
	int		i;
	int		j;

	i = 1;
	while (i < n)
	{
		j = i;
		while (j > 0 && key_lt(arr[j]->key, arr[j - 1]->key))
		{
			tmp = arr[j];
			arr[j] = arr[j - 1];
			arr[j - 1] = tmp;
			j--;
		}
		i++;
	}
}

static t_env	**sorted_entries(t_env *env, int n)
{
	t_env	**arr;
	int		i;

	arr = malloc(sizeof(t_env *) * n);
	if (!arr)
		return (NULL);
	i = 0;
	while (env)
	{
		arr[i++] = env;
		env = env->next;
	}
	sort_entries(arr, n);
	return (arr);
}

static void	print_entry(t_env *e)
{
	ft_putstr_fd("declare -x ", 1);
	ft_putstr_fd(e->key, 1);
	if (e->value)
	{
		ft_putstr_fd("=\"", 1);
		ft_putstr_fd(e->value, 1);
		ft_putstr_fd("\"", 1);
	}
	ft_putstr_fd("\n", 1);
}

int	export_list(t_env *env)
{
	t_env	**arr;
	int		n;
	int		i;

	n = count_env(env);
	arr = sorted_entries(env, n);
	if (!arr)
		return (1);
	i = 0;
	while (i < n)
	{
		print_entry(arr[i]);
		i++;
	}
	free(arr);
	return (0);
}
