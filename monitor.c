/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   monitor.c                                          :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: moel-yag <moel-yag@student.1337.ma>        +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/07/08 12:08:44 by moel-yag          #+#    #+#             */
/*   Updated: 2025/07/08 12:09:03 by moel-yag         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "philo.h"

void	*monitor(void *arg)
{
	t_sim	*sim;
	int		i;
	int		all_full;

	sim = (t_sim *)arg;
	while (1)
	{
		i = -1;
		all_full = 1;
		while (++i < sim->num_philo)
		{
			check_death(sim, i);
			pthread_mutex_lock(sim->stop_mutex);
			if (*(sim->stop))
			{
				pthread_mutex_unlock(sim->stop_mutex);
				return (NULL);
			}
			pthread_mutex_unlock(sim->stop_mutex);
			if (sim->meal_target > 0)
			{
				pthread_mutex_lock(&sim->philos[i].meal_mutex);
				if (sim->philos[i].meals_eaten < sim->meal_target)
					all_full = 0;
				pthread_mutex_unlock(&sim->philos[i].meal_mutex);
			}
		}
		if (sim->meal_target > 0 && all_full)
		{
			pthread_mutex_lock(sim->stop_mutex);
			*(sim->stop) = 1;
			pthread_mutex_unlock(sim->stop_mutex);
			return (NULL);
		}
		usleep(1000);
	}
}
