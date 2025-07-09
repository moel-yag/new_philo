/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   routine.c                                          :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: moel-yag <moel-yag@student.1337.ma>        +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/27 11:39:48 by moel-yag          #+#    #+#             */
/*   Updated: 2025/07/09 18:42:00 by moel-yag         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "philo.h"

// void	print_status2(t_philo *philo, const char *status, int fork_id)
// {
// 	long long	timestamp;

// 	pthread_mutex_lock(philo->stop_mutex);
// 	if (!*(philo->stop))
// 	{
// 		pthread_mutex_lock(philo->print_mutex);
// 		timestamp = get_time() - philo->start_time;
// 		printf("%lld %d %s %d\n", timestamp, philo->id, status, fork_id);
// 		pthread_mutex_unlock(philo->print_mutex);
// 	}
// 	pthread_mutex_unlock(philo->stop_mutex);
// }

void	take_forks(t_philo *philo)
{
	if (philo->id % 2 != 0)
	{
		pthread_mutex_lock(philo->right_fork);
		print_status(philo, "has taken a fork");
		// print_status2(philo, "has taken a fork (right)", philo->rightfork_id);
		pthread_mutex_lock(philo->left_fork);
		// print_status2(philo, "has taken a fork (right)", philo->leftfork_id);
		print_status(philo, "has taken a fork");
	}
	else
	{
		pthread_mutex_lock(philo->left_fork);
		// print_status2(philo, "has taken a fork (right)", philo->leftfork_id);
		print_status(philo, "has taken a fork");
		pthread_mutex_lock(philo->right_fork);
		// print_status2(philo, "has taken a fork (right)", philo->rightfork_id);
		print_status(philo, "has taken a fork");
	}
}

/*
void take_forks(t_philo *philo)
{
    pthread_mutex_t *first = (philo->id % 2) ? 
        philo->left_fork : philo->right_fork;
    pthread_mutex_t *second = (philo->id % 2) ? 
        philo->right_fork : philo->left_fork;
    
    pthread_mutex_lock(first);
    if (is_stopped(philo)) {
        pthread_mutex_unlock(first);
        return;
    }
    print_status(philo, "has taken a fork");
    pthread_mutex_lock(second);
    if (is_stopped(philo)) {
        pthread_mutex_unlock(second);
        pthread_mutex_unlock(first);
        return;
    }
    print_status(philo, "has taken a fork");
}

// Add helper function (static to respect 5-function limit)
static int is_stopped(t_philo *philo)
{
    int stop_status;
    pthread_mutex_lock(philo->stop_mutex);
    stop_status = *(philo->stop);
    pthread_mutex_unlock(philo->stop_mutex);
    return (stop_status);
}
*/

void	eat(t_philo *philo)
{
	print_status(philo, "is eating");
	pthread_mutex_lock(&philo->meal_mutex);
	philo->last_meal = get_time();
	philo->meals_eaten++;
	pthread_mutex_unlock(&philo->meal_mutex);
	precise_usleep(philo->time_to_eat, philo);
}

void	*routine(void *arg)
{
	t_philo	*philo;

	philo = (t_philo *)arg;
	if (philo->left_fork == philo->right_fork)
	{
		print_status(philo, "has taken a fork");
		precise_usleep(philo->time_to_die, philo);
		return (NULL);
	}
	while (1)
	{
		pthread_mutex_lock(philo->stop_mutex);
		if (*(philo->stop))
		{
			pthread_mutex_unlock(philo->stop_mutex);
			break ;
		}
		pthread_mutex_unlock(philo->stop_mutex);
		take_forks(philo);
		eat(philo);
		pthread_mutex_unlock(philo->right_fork);
		pthread_mutex_unlock(philo->left_fork);
		print_status(philo, "is sleeping");
		precise_usleep(philo->time_to_sleep, philo);
		print_status(philo, "is thinking");
	}
	return (NULL);
}
