/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   philo.c                                            :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: moel-yag <moel-yag@student.1337.ma>        +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/27 11:39:44 by moel-yag          #+#    #+#             */
/*   Updated: 2025/07/02 17:03:06 by moel-yag         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "philo.h"

int main(int ac, char **av)
{
    t_philo         philo[200];
    pthread_mutex_t forks[200];
    pthread_mutex_t stop_mutex;
    pthread_mutex_t print_mutex;
    int             stop;
    int             num_philo;
    int             i;
    long long       simulation_start;
    t_sim           sim;
    pthread_t       monitor_thread;

    stop = 0;
    if (ac != 5 && ac != 6)
    {
        printf("Usage: %s <number_of_philo> <time_to_die> <time_to_eat> \
<time_to_sleep> [number_of_meals]\n", av[0]);
        return (1);
    }
    if (!is_valid_arg(ac, av))
    {
        printf("Error: Invalid arguments\n");
        return (2);
    }
    num_philo = ft_atoi(av[1]);
    if (num_philo <= 0 || num_philo > 200)
    {
        printf("Error: Philosophers must be between 1-200\n");
        return (2);
    }
    
    // Initialize mutexes
    pthread_mutex_init(&stop_mutex, NULL);
    pthread_mutex_init(&print_mutex, NULL);
    for (i = 0; i < num_philo; i++)
        pthread_mutex_init(&forks[i], NULL);

    // Initialize philosophers
    simulation_start = get_time();
    for (i = 0; i < num_philo; i++)
    {
        philo[i].id = i + 1;
        philo[i].meals_eaten = 0;
        philo[i].last_meal = simulation_start;
        philo[i].left_fork = &forks[i];
        philo[i].right_fork = &forks[(i + 1) % num_philo];
        philo[i].stop = &stop;
        philo[i].stop_mutex = &stop_mutex;
        philo[i].print_mutex = &print_mutex;
        philo[i].start_time = simulation_start;
        philo[i].time_to_eat = ft_atoi(av[3]);
        philo[i].time_to_sleep = ft_atoi(av[4]);
        philo[i].time_to_die = ft_atoi(av[2]);
        pthread_mutex_init(&philo[i].meal_mutex, NULL);
    }

    // Start philosopher threads
    for (i = 0; i < num_philo; i++)
        pthread_create(&philo[i].threads, NULL, routine, &philo[i]);

    // Set up and start monitor thread
    sim.philos = philo;
    sim.num_philo = num_philo;
    sim.time_to_die = ft_atoi(av[2]);
    sim.stop = &stop;
    sim.stop_mutex = &stop_mutex;
    sim.print_mutex = &print_mutex;
    sim.meal_target = (ac == 6) ? ft_atoi(av[5]) : -1;
    pthread_create(&monitor_thread, NULL, monitor, &sim);

    // Wait for threads to finish
    for (i = 0; i < num_philo; i++)
        pthread_join(philo[i].threads, NULL);
    pthread_join(monitor_thread, NULL);

    // Cleanup resources
    for (i = 0; i < num_philo; i++)
    {
        pthread_mutex_destroy(&forks[i]);
        pthread_mutex_destroy(&philo[i].meal_mutex);
    }
    pthread_mutex_destroy(&stop_mutex);
    pthread_mutex_destroy(&print_mutex);
    return (0);
}