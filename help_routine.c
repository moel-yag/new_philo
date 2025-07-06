/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   help_routine.c                                     :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: moel-yag <moel-yag@student.1337.ma>        +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/07/06 19:44:06 by moel-yag          #+#    #+#             */
/*   Updated: 2025/07/06 19:44:20 by moel-yag         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

include "philo.h"

long long	get_time(void)
{
	struct timeval	tv;

	gettimeofday(&tv, NULL);
	return (tv.tv_sec * 1000 + tv.tv_usec / 1000);
}

void	print_status(t_philo *philo, const char *status)
{
	long long	timestamp;

	pthread_mutex_lock(philo->print_mutex);
	timestamp = get_time() - philo->start_time;
	printf("%lld %d %s\n", timestamp, philo->id, status);
	pthread_mutex_unlock(philo->print_mutex);
}

void	precise_usleep(long duration, t_philo *philo)
{
	long	start;

	start = get_time();
	while (get_time() - start < duration)
	{
		usleep(100);
		pthread_mutex_lock(philo->stop_mutex);
		if (*(philo->stop))
		{
			pthread_mutex_unlock(philo->stop_mutex);
			break ;
		}
		pthread_mutex_unlock(philo->stop_mutex);
	}
}
