:
: .profile
:
# sample of .profile commands
# .profile runs once when you log in using /bin/sh or /bin/ksh

#### Settings for use with both sh and ksh
uid=`expr "\`id\`" : 'uid=\([0-9]*\)'`		# get the user ID number

	# set terminal type non-interactively (xterm sets TERM=xterm itself;
	# otherwise default to vt100 - no interactive "TERM = (vt100)" prompt)
TERM=${TERM:-vt100}; export TERM

	# Set the prompt, search path, and permissions for the login session
if [ "$uid" = 0 ]; then
  umask 022		# rwxr-xr-x
  if [ -d /tcb ]; then          # On secure systems add /tcb/bin to path
    PATH="/tcb/bin:/bin:/usr/bin:/usr/ucb:/mac/bin:/etc:/usr/etc:."
  else
    PATH="/bin:/usr/bin:/usr/ucb:/mac/bin:/etc:/usr/etc:."
  fi
  export PATH
  prmp='# '
else
  umask 027		# rwxr-x---
  PATH=":/bin:/usr/bin:/usr/ucb:/mac/bin:/etc:/usr/etc:/usr/local/bin"
  export PATH
  prmp='$ '
fi

if [ -d /usr/bin/X11 ]; then
    PATH="$PATH:/usr/bin/X11"
fi

PS1="`hostname`.$LOGNAME $prmp"
export PS1

#### special settings just for use with Korn shell

case "$0" in
*ksh) 

	# set special variables and terminal settings
      stty susp '^Z' dsusp '^Y'  	 # set suspend characters
      export PS1="$(hostname).$LOGNAME \! $prmp "  # include line number in prompt
      export ENV=$HOME/.kshrc		 # special commands in .kshrc file
      export EDITOR=/usr/bin/vi	 	 # set editor for history
      # HISTSIZE, HISTFILE set in .kshrc
      ;;
esac

unset prmp
# login banner (date/news/pwd/ls) removed - terminals open clean


