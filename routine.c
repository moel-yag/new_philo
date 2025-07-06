/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   routine.c                                          :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: moel-yag <moel-yag@student.1337.ma>        +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/27 11:39:48 by moel-yag          #+#    #+#             */
/*   Updated: 2025/07/02 21:09:28 by moel-yag         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "philo.h"

long long   get_time(void)
{
    struct timeval  tv;

    gettimeofday(&tv, NULL);
    return (tv.tv_sec * 1000 + tv.tv_usec / 1000);
}

void    print_status(t_philo *philo, const char *status)
{
    long long   timestamp;

    pthread_mutex_lock(philo->print_mutex);
    timestamp = get_time() - philo->start_time;
    printf("%lld %d %s\n", timestamp, philo->id, status);
    pthread_mutex_unlock(philo->print_mutex);
}

void    precise_usleep(long duration, t_philo *philo)
{
    long    start;

    start = get_time();
    while (get_time() - start < duration)
    {
        usleep(100);
        pthread_mutex_lock(philo->stop_mutex);
        if (*(philo->stop))
        {
            pthread_mutex_unlock(philo->stop_mutex);
            break;
        }
        pthread_mutex_unlock(philo->stop_mutex);
    }
}

void    *routine(void *arg)
{
    t_philo *philo;
    // t_philo *philos;

    philo = (t_philo *)arg;
    // philos = (t_philo *)arg;
    
    // Single philosopher edge case
    if (philo->left_fork == philo->right_fork)
    {
        print_status(philo, "has taken a fork");
        precise_usleep(philo->time_to_die, philo);
        print_status(philo, "died");
        return (NULL);
    }

    while (1)
    {
        pthread_mutex_lock(philo->stop_mutex);
        if (*(philo->stop))
        {
            pthread_mutex_unlock(philo->stop_mutex);
            break;
        }
        pthread_mutex_unlock(philo->stop_mutex);

        // Take forks (lock order based on philosopher id)
        if (philo->id % 2 == 0)
        {
            pthread_mutex_lock(philo->right_fork);
            print_status(philo, "has taken a fork");
            pthread_mutex_lock(philo->left_fork);
            print_status(philo, "has taken a fork");
        }
        else
        {
            pthread_mutex_lock(philo->left_fork);
            print_status(philo, "has taken a fork");
            pthread_mutex_lock(philo->right_fork);
            print_status(philo, "has taken a fork");
        }

        // Eating
        print_status(philo, "is eating");
        pthread_mutex_lock(&philo->meal_mutex);
        philo->last_meal = get_time();
        philo->meals_eaten++;
        pthread_mutex_unlock(&philo->meal_mutex);
        
        precise_usleep(philo->time_to_eat, philo);
        
        // Release forks
        pthread_mutex_unlock(philo->right_fork);
        pthread_mutex_unlock(philo->left_fork);

        // Sleeping
        print_status(philo, "is sleeping");
        precise_usleep(philo->time_to_sleep, philo);
        
        // Thinking
        print_status(philo, "is thinking");
    }
    return (NULL);
}

void    *monitor(void *arg)
{
    t_sim   *sim = (t_sim *)arg;
    int     i;
    int     all_full;

    while (1)
    {
        i = -1;
        all_full = 1;
        while (++i < sim->num_philo)
        {
            pthread_mutex_lock(&sim->philos[i].meal_mutex);
            if (get_time() - sim->philos[i].last_meal > sim->time_to_die)
            {
                pthread_mutex_lock(sim->stop_mutex);
                if (!*(sim->stop))
                {
                    *(sim->stop) = 1;
                    pthread_mutex_lock(sim->print_mutex);
                    printf("%lld %d died\n", 
                           get_time() - sim->philos[i].start_time, sim->philos[i].id);
                    pthread_mutex_unlock(sim->print_mutex);
                }
                pthread_mutex_unlock(&sim->philos[i].meal_mutex);
                pthread_mutex_unlock(sim->stop_mutex);
                return (NULL);
            }
            if (sim->meal_target > 0 && 
                sim->philos[i].meals_eaten < sim->meal_target)
            {
                all_full = 0;
            }
            pthread_mutex_unlock(&sim->philos[i].meal_mutex);
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