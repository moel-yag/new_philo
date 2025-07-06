/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   philo.c                                            :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: moel-yag <moel-yag@student.1337.ma>        +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/27 11:39:44 by moel-yag          #+#    #+#             */
/*   Updated: 2025/07/06 19:41:56 by moel-yag         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "philo.h"

int	init_mutexes(pthread_mutex_t *forks, pthread_mutex_t *stop_mutex,
	pthread_mutex_t *print_mutex, int num_philo)
{
	int	i;

	if (pthread_mutex_init(stop_mutex, NULL))
		return (1);
	if (pthread_mutex_init(print_mutex, NULL))
		return (1);
	i = -1;
	while (++i < num_philo)
		if (pthread_mutex_init(&forks[i], NULL))
			return (1);
	return (0);
}

void	init_philos(t_philo *philos, pthread_mutex_t *forks,
	t_sim *sim, char **av)
{
	int			i;
	long long	start;
	int			num_philo;

	num_philo = ft_atoi(av[1]);
	start = get_time();
	i = -1;
	while (++i < num_philo)
	{
		philos[i].id = i + 1;
		philos[i].meals_eaten = 0;
		philos[i].last_meal = start;
		philos[i].left_fork = &forks[i];
		philos[i].right_fork = &forks[(i + 1) % num_philo];
		philos[i].stop = sim->stop;
		philos[i].stop_mutex = sim->stop_mutex;
		philos[i].print_mutex = sim->print_mutex;
		philos[i].start_time = start;
		philos[i].time_to_eat = ft_atoi(av[3]);
		philos[i].time_to_sleep = ft_atoi(av[4]);
		philos[i].time_to_die = ft_atoi(av[2]);
		pthread_mutex_init(&philos[i].meal_mutex, NULL);
	}
}

int	start_threads(t_philo *philos, pthread_t *monitor_thread,
	t_sim *sim, int num_philo)
{
	int	i;

	i = -1;
	while (++i < num_philo)
		if (pthread_create(&philos[i].threads, NULL, routine, &philos[i]))
			return (1);
	if (pthread_create(monitor_thread, NULL, monitor, sim))
		return (1);
	return (0);
}

void	cleanup(t_philo *philos, pthread_mutex_t *forks,
	pthread_mutex_t *stop_mutex, pthread_mutex_t *print_mutex, int num_philo)
{
	int	i;

	i = -1;
	while (++i < num_philo)
	{
		pthread_mutex_destroy(&forks[i]);
		pthread_mutex_destroy(&philos[i].meal_mutex);
	}
	pthread_mutex_destroy(stop_mutex);
	pthread_mutex_destroy(print_mutex);
}

int	main(int ac, char **av)
{
	t_philo			philos[200];
	pthread_mutex_t	forks[200];
	pthread_mutex_t	stop_mutex;
	pthread_mutex_t	print_mutex;
	t_sim			sim;
	pthread_t		monitor_thread;
	int				stop;
	int				num_philo;

	stop = 0;
	if (ac < 5 || ac > 6)
		return (printf("Usage: %s number t_die t_eat t_sleep [meals]\n"
				, av[0]), 1);
	if (!is_valid_arg(ac, av))
		return (printf("Error: Invalid arguments\n"), 2);
	num_philo = ft_atoi(av[1]);
	if (num_philo <= 0 || num_philo > 200)
		return (printf("Error: Philosophers 1-200\n"), 2);
	if (init_mutexes(forks, &stop_mutex, &print_mutex, num_philo))
		return (printf("Error: Mutex init failed\n"), 3);
	sim = (t_sim){philos, num_philo, ft_atoi(av[2]), -1, &stop,
		&stop_mutex, &print_mutex};
	if (ac == 6)
		sim.meal_target = ft_atoi(av[5]);
	init_philos(philos, forks, &sim, av);
	if (start_threads(philos, &monitor_thread, &sim, num_philo))
		return (printf("Error: Thread creation failed\n"), 4);
	pthread_join(monitor_thread, NULL);
	cleanup(philos, forks, &stop_mutex, &print_mutex, num_philo);
	return (0);
}
