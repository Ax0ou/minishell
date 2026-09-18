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
# include <limits.h>
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

typedef enum e_resolve_status
{
	RESOLVE_OK,
	RESOLVE_CNF,
	RESOLVE_ENOENT,
	RESOLVE_ISDIR,
	RESOLVE_NOPERM
}	t_path_status;

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
	t_token_type	type;
	char			*target;
	struct s_redir	*next;
}	t_redir;

typedef struct s_cmd
{
	char			**argv;
	t_redir			*redirs;
	struct s_cmd	*next;
}	t_cmd;

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
	char		*line;
	t_token		*tokens;
	t_cmd		*cmds;
}	t_shell;

t_env				*env_init(char **envp);
void				env_free(t_env *env);
char				*env_get(t_env *env, char *key);
int					env_set(t_env **env, char *key, char *value, int exported);
void				env_unset(t_env **env, char *key);
char				**env_to_array(t_env *env);

/*executor*/
t_path_status		resolve_path(t_env *env, char *name, char **out_path);
int					probe_path(char *path);
void				free_split(char **arr);
int					handle_candidate(char *dir, char *name, char **out);
void				exec_single(t_shell *shell, t_cmd *cmd);
void				exec_child(char *path, t_cmd *cmd, char **envp);
int					exec_wait(pid_t pid);
int					report_resolve_error(char *name, t_path_status status);
void				exec_run(t_shell *shell);
int					is_builtin(char *name);
int					call_builtin(t_shell *shell, char **argv);
void				exec_pipeline(t_shell *shell);
int					count_cmds(t_cmd *cmds);
void				child_dup_pipes(int prev_read, int p[2], int has_next);
void				pipe_child_run(t_shell *shell, t_cmd *cmd);
int					wait_all(pid_t *pids, int n);

/*redirections*/
int					apply_redirs(t_redir *redirs);

/*builtins*/
int					bi_env(t_env *env);
int					bi_pwd(void);
int					bi_echo(char **argv);
int					bi_exit(t_shell *shell, char **argv);
int					bi_cd(t_env **env, char **argv);
int					bi_export(t_env **env, char **argv);
int					export_list(t_env *env);
int					count_env(t_env *env);
int					key_lt(char *a, char *b);

/*utils*/
int					print_error(char *cmd, char *arg, char *msg);
int					parse_ll(char *s, long long *out);
void				shell_free(t_shell *shell);
void				init_shell(t_shell *shell, char **envp);
void				run_line(t_shell *shell);

/*parser*/
t_cmd				*parse_tokens(t_token *tokens);
int					syntax_check_tokens(t_token *tokens);
int					syntax_check_line(char *line);
void				cmd_list_free(t_cmd *cmds);
t_cmd				*cmd_new(void);
void				cmd_add_back(t_cmd **head, t_cmd *new);
int					count_args(t_token *token);
char				**fill_argv(t_token *token, int n);
t_token				*skip_to_next_cmd(t_token *token);
t_token				*token_advance(t_token *token);
t_redir				*redir_new(t_token_type type, char *target);
void				redir_add_back(t_redir **head, t_redir *new);
int					attach_redirs(t_cmd *cmd, t_token *token);
int					collect_heredocs(t_shell *shell);
void				cleanup_heredocs(t_cmd *cmds);
char				*heredoc_tmp_path(void);
char				*strip_delim(char *raw);
int					read_heredoc_body(char *delim, int fd);

/*lexer stuff*/
void				token_add_back(t_token **head, t_token *new);
t_token				*new_token(t_token_type type, char *value);
t_token				*lex_tokenize(char *line);
void				token_list_free(t_token *head);
t_token_type		detect_operator(char *line, int i, int *len);
void				append_char(char *buffer, char c);
void				flush_buffer(t_lex *lex, t_token **head);
void				lex_init(t_lex *lex);
int					lex_in_quote(t_lex *lex);
int					lex_is_quote_char(char c);
int					lex_is_operator_char(char c);
void				lex_handle_quote_char(t_lex *lex, char c);

#endif
