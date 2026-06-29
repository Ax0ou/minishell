# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: dbomfim- <dbomfim-@student.42lausanne.c    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/10/15 18:45:27 by dbomfim-          #+#    #+#              #
#    Updated: 2026/05/27 17:03:31 by dbomfim-         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

NAME = libft.a

CC = cc
CFLAGS = -Wall -Wextra -Werror

AR = ar rcs
RM = rm -f

SRC =	libft_ft/ft_isalpha.c \
		libft_ft/ft_isdigit.c \
		libft_ft/ft_isalnum.c \
		libft_ft/ft_isascii.c \
		libft_ft/ft_isprint.c \
		libft_ft/ft_strlen.c \
		libft_ft/ft_memset.c \
		libft_ft/ft_bzero.c \
		libft_ft/ft_memcpy.c \
		libft_ft/ft_memmove.c \
		libft_ft/ft_strlcpy.c \
		libft_ft/ft_strlcat.c \
		libft_ft/ft_toupper.c \
		libft_ft/ft_tolower.c \
		libft_ft/ft_strchr.c \
		libft_ft/ft_strrchr.c \
		libft_ft/ft_strncmp.c \
		libft_ft/ft_memchr.c \
		libft_ft/ft_memcmp.c \
		libft_ft/ft_strnstr.c \
		libft_ft/ft_atoi.c \
		libft_ft/ft_calloc.c \
		libft_ft/ft_strdup.c \
		libft_ft/ft_substr.c \
		libft_ft/ft_strjoin.c \
		libft_ft/ft_strtrim.c \
		libft_ft/ft_split.c \
		libft_ft/ft_itoa.c \
		libft_ft/ft_strmapi.c \
		libft_ft/ft_striteri.c \
		libft_ft/ft_putchar_fd.c \
		libft_ft/ft_putstr_fd.c \
		libft_ft/ft_putendl_fd.c \
		libft_ft/ft_putnbr_fd.c \
		ft_printf/ft_printf.c \
		ft_printf/ft_print_char.c \
		ft_printf/ft_print_str.c \
		ft_printf/ft_print_nbr.c \
		ft_printf/ft_print_unsigned.c \
		ft_printf/ft_print_hex.c \
		ft_printf/ft_print_ptr.c \
		get_next_line/get_next_line.c

OBJ = $(SRC:.c=.o)

all: $(NAME)

$(NAME): $(OBJ)
	@$(AR) $(NAME) $(OBJ)
	@echo "$(NAME) compiled"

%.o: %.c
	@$(CC) $(CFLAGS) -c $< -o $@

clean:
	@$(RM) $(OBJ)
	@echo "libft objects cleaned"

fclean: clean
	@$(RM) $(NAME)
	@echo "$(NAME) removed"

re: fclean all

.PHONY: all clean fclean re