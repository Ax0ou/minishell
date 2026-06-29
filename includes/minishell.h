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

t_env	*env_init(char **envp);
void	env_free(t_env *env);

#endif
