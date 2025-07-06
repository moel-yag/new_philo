/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   parse_args.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: moel-yag <moel-yag@student.1337.ma>        +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/27 11:39:54 by moel-yag          #+#    #+#             */
/*   Updated: 2025/07/01 20:56:03 by moel-yag         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "philo.h"

int	ft_strlen(const char *str)
{
	int	i;

	i = 0;
	while (str[i])
		i++;
	return (i);
}

long long	ft_atoi(const char *str)
{
	long long	result;
	int			i;

	result = 0;
	i = 0;
	while (str[i] >= '0' && str[i] <= '9')
	{
		result = result * 10 + (str[i] - '0');
		if (result > INT_MAX)
			return (-1);
		i++;
	}
	if (str[i] != '\0')
		return (-1);
	return (result);
}

bool	ft_isdigit(char c)
{
	return (c >= '0' && c <= '9');
}

bool	large_number(const char *arg, int i)
{
	long long	num;

	num = ft_atoi(arg);
	if (num < 0 || (i == 1 && num == 0) || (i == 0 && num > 200))
		return (true);
	return (false);
}

bool	is_valid_arg(int ac, char *args[])
{
	int	j;
	int	i;

	i = 1;
	while (i < ac)
	{
		if (!args[i] || !*args[i])
			return (false);
		if (large_number(args[i], i - 1))
			return (false);
		j = 0;
		while (j < (int)ft_strlen(args[i]))
		{
			if (!ft_isdigit(args[i][j]))
				return (false);
			j++;
		}
		i++;
	}
	return (true);
}
