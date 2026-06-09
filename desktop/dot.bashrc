# .bashrc - interactive bash settings (A/UX 3.1.1)
# Only for interactive shells:
case $- in *i*) ;; *) return ;; esac

# History
HISTSIZE=1000
HISTFILESIZE=2000
HISTCONTROL=ignoredups

# Prompt: user@host:cwd$
PS1='\u@\h:\w\$ '
export PS1

# Aliases
alias ll='ls -lF'
alias la='ls -alF'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias h='history'
command -v less >/dev/null 2>&1 && alias more='less'

# Pager
LESS='-MR'
export LESS
