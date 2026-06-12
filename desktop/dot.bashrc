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

# AUX-PROMPT-BEGIN  (synthwave prompt; remove through AUX-PROMPT-END)
case $- in
*i*)
	# magenta user @ cyan host, yellow cwd, green chevron on its own line
	PS1='\[\033[1;36m\][\[\033[1;35m\]\u\[\033[0;37m\]@\[\033[1;36m\]\h\[\033[1;36m\]]\[\033[0m\] \[\033[1;33m\]\w\[\033[0m\]\n\[\033[1;32m\]>>\[\033[0m\] '
	;;
esac
# AUX-PROMPT-END

# AUX-TITLE-BEGIN  (dynamic xterm titles: running command, else cwd)
case $- in
*i*)
  case "$TERM" in
  xterm*|rxvt*)
    PROMPT_COMMAND='echo -ne "\033]0;auxvm: ${PWD}\007"'
    trap '[ "$BASH_COMMAND" != "$PROMPT_COMMAND" ] && echo -ne "\033]0;${BASH_COMMAND} - auxvm\007" 2>/dev/null' DEBUG
    ;;
  esac
  ;;
esac
# AUX-TITLE-END

# ncurses 5.7 terminfo database (TUI apps)
TERMINFO=/usr/local/ncurses-5.7/share/terminfo; export TERMINFO
