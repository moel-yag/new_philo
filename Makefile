NAME = philo
CC = gcc
CFLAGS = -Wall -Wextra -Werror -pthread -g3 -fsanitize=address

SRCS = philo.c routine.c parse_args.c
OBJS = $(SRCS:.c=.o)
DEPS = philo.h

all: $(NAME)

$(NAME): $(OBJS)
	$(CC) $(CFLAGS) -o $(NAME) $(OBJS)

%.o: %.c $(DEPS)
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS)

fclean: clean
	rm -f $(NAME)

re: fclean all

.PHONY: all clean fclean re