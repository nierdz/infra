shopt -s histappend
HISTSIZE=10000
HISTTIMEFORMAT="%F - %T : "
HISTCONTROL=ignoredups
PROMPT_COMMAND="history -a;history -c;history -r;$PROMPT_COMMAND"
