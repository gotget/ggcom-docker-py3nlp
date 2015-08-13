#!/usr/bin/env bash
: <<'!COMMENT'

GGCOM - Docker - py3nlp v201508132002
Louis T. Getterman IV (@LTGIV)
www.GotGetLLC.com | www.opensour.cc/ggcom/docker/py3nlp

Thanks:

bash - How to keep quotes in args? - Stack Overflow - Thank you Dennis Williamson!
http://stackoverflow.com/a/1669493

!COMMENT

# Attempt to keep quotes in arguments passed to Docker, which is then passed to here.
pyrun=''
whitespace="[[:space:]]"
for i in "$@"
do
	if [[ $i =~ $whitespace ]]
	then
		i=\"$i\"
	fi
	pyrun="${pyrun}${i} "
done
pyrun="python ${pyrun}"
unset i

# Run as user
sudo -u python_user 'bash' <<EOF
export HOME=/home/python_user
export PYENV_ROOT=$HOME/.pyenv
export PATH=$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH
pyenv rehash
$pyrun
EOF
