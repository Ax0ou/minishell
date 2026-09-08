/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   minishell.h                                        :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aalvard <aalvarad@student.42lausanne.ch    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/01 10:10:00 by aalvard           #+#    #+#             */
/*   Updated: 2026/08/01 15:16:29 by aalvard          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#ifndef MINISHELL_H
# define MINISHELL_H

# include <stdlib.h>
# include <unistd.h>
# include <fcntl.h>
# include <sys/types.h>
# include <sys/wait.h>
# include <sys/stat.h>
# include <signal.h>
# include <errno.h>
# include <string.h>
# include <stdio.h>
# include <dirent.h>
# include <termios.h>
# include <sys/ioctl.h>
# include <readline/readline.h>
# include <readline/history.h>

# include "../libft/inc/libft.h"
# include "../libft/inc/ft_printf.h"
# include "../libft/inc/get_next_line.h"

typedef enum e_token_type
{
	T_WORD,
	T_PIPE,
	T_REDIR_IN,
	T_REDIR_OUT,
	T_HEREDOC,
	T_APPEND
}	t_token_type;

typedef enum e_lex_state
{
	STATE_NORMAL,
	STATE_SQUOTE,
	STATE_DQUOTE
}	t_lex_state;

typedef struct s_lex
{
	t_lex_state	state;
	int			token_active;
	int			has_quotes;
	char		buffer[4096];
	int			i;
}	t_lex;

typedef struct s_token
{
	t_token_type	type;
	char			*value;
	int				has_quotes;
	struct s_token	*next;
}	t_token;

typedef struct s_redir
{
	int				type;		// IN, OUT, APPEND, HEREDOC
	char			*target;	// fichier ou délimiteur
	struct s_redir	*next;
}	t_redir;

typedef struct s_cmd
{
	char			**argv;		// ["ls", "-la", NULL]
	t_redir			*redirs;	// liste des redirections
	struct s_cmd	*next;		// prochaine commande du pipeline
}	t_cmd;

typedef struct s_pipeline
{
	t_cmd	*cmds;				// premier maillon
}	t_pipeline;

typedef struct s_env
{
	char			*key;
	char			*value;
	int				exported;	// 1 si visible par env, 0 sinon
	struct s_env	*next;
}	t_env;

typedef struct s_shell
{
	t_env		*env;
	int			last_exit;
	char		*line;			// ligne courante (sortie readline)
	t_token		*tokens;
	t_pipeline	*ast;
}	t_shell;

t_env			*env_init(char **envp);
void			env_free(t_env *env);
char			*env_get(t_env *env, char *key);
int				env_set(t_env **env, char *key, char *value, int exported);
void			env_unset(t_env **env, char *key);
char			**env_to_array(t_env *env);

/*builtins*/
int				bi_env(t_env *env);

/*utils*/
int				print_error(char *cmd, char *arg, char *msg);
void			shell_free(t_shell *shell);

/*lexer stuff*/
void			token_add_back(t_token **head, t_token *new);
t_token			*new_token(t_token_type type, char *value);
t_token			*lex_tokenize(char *line);
void			token_list_free(t_token *head);
t_token_type	detect_operator(char *line, int i, int *len);
void			append_char(char *buffer, char c);
void			flush_buffer(t_lex *lex, t_token **head);
void			lex_init(t_lex *lex);
int				lex_in_quote(t_lex *lex);
int				lex_is_quote_char(char c);
int				lex_is_operator_char(char c);
void			lex_handle_quote_char(t_lex *lex, char c);

#endif
