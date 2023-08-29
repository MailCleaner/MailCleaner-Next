# Configure Prompt
CLIENTID=$(grep 'CLIENTID' /etc/mailcleaner.conf | cut -d ' ' -f3)
export HOSTID=$(grep 'HOSTID' /etc/mailcleaner.conf | cut -d ' ' -f3)
export VARDIR=$(grep 'VARDIR' /etc/mailcleaner.conf | cut -d ' ' -f3)
if [[ -n $CLIENTID ]]; then
	export $CLIENTID="${CLIENTID}-"
fi
export PROMPT_COMMAND='echo -ne "\033]0;root@$(hostname) - ${CLIENTID}${HOSTID} \007"'
#export PS1='\h:\w$ '
umask 022

export PYENV_ROOT="${VARDIR}/.pyenv"
export PATH=${PYENV_ROOT}/shims:${PYENV_ROOT}/bin:${SRCDIR}/bin:${PATH}/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
if command -v pyenv 1>/dev/null 2>&1; then
	eval "$(pyenv init -)"
fi
