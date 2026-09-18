NAME = minishell

CC = cc
CFLAGS = -Wall -Wextra -Werror

LIBFT_DIR = libft
LIBFT = $(LIBFT_DIR)/libft.a

LDFLAGS = -lreadline

SRC = 	src/builtins/bi_cd.c \
		src/builtins/bi_echo.c \
		src/builtins/bi_env.c \
		src/builtins/bi_exit.c \
		src/builtins/bi_export.c \
		src/builtins/bi_pwd.c \
		src/builtins/bi_unset.c \
		src/env/env_access.c \
		src/env/env_init.c \
		src/env/env_to_array.c \
		src/executor/exec_child.c \
		src/executor/exec_path.c \
		src/executor/exec_path_utils.c \
		src/executor/exec_pipeline.c \
		src/executor/exec_pipeline_utils.c \
		src/executor/exec_run.c \
		src/executor/exec_single.c \
		src/executor/exec_wait.c \
		src/expander/exp_quotes_handle.c \
		src/expander/exp_quotes_strip.c \
		src/expander/exp_run.c \
		src/expander/exp_var_identify.c \
		src/expander/exp_var_replace.c \
		src/expander/exp_var_value.c \
		src/lexer/lex_grammar.c \
		src/lexer/lex_input.c \
		src/lexer/lex_quotes.c \
		src/lexer/lex_token_list.c \
		src/lexer/lex_token_list_free.c \
		src/lexer/lex_tokenize_utils.c \
		src/lexer/lex_tokenize.c \
		src/lexer/lex_operators.c \
		src/parser/cmd_list_free.c \
		src/parser/cmd_list_utils.c \
		src/parser/parse_args_default.c \
		src/parser/parse_args_echo.c \
		src/parser/parse_args_echo_utils.c \
		src/parser/parse_input.c \
		src/parser/parse_pipe.c \
		src/parser/parse_redirs.c \
		src/parser/parse_word.c \
		src/parser/syntax_check.c \
		src/redirections/redir_files.c \
		src/redirections/redir_pipes.c \
		src/signals/signals.c \
		src/signals/signals_heredoc.c \
		src/utils/ut_cleanup.c \
		src/utils/ut_error.c \
		src/utils/ut_exit.c \
		src/utils/ut_init_data.c \
		src/utils/ut_str.c \
		src/main.c

OBJ = $(SRC:.c=.o)

RM = rm -f

all: $(NAME)

$(NAME): $(LIBFT) $(OBJ)
	@$(CC) $(CFLAGS) $(OBJ) $(LIBFT) $(LDFLAGS) -o $(NAME)
	@echo "$(NAME) compiled"

$(LIBFT):
	@$(MAKE) --no-print-directory -C $(LIBFT_DIR)

%.o: %.c
	@$(CC) $(CFLAGS) -c $< -o $@

clean:
	@$(RM) $(OBJ)
	@$(MAKE) --no-print-directory -C $(LIBFT_DIR) clean
	@echo "Object files cleaned"

fclean: clean
	@$(RM) $(NAME)
	@$(MAKE) --no-print-directory -C $(LIBFT_DIR) fclean
	@echo "$(NAME) removed"

re: fclean all

.PHONY: all clean fclean re
