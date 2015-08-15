# GGCOM - Docker - py3nlp v201508150755
# Louis T. Getterman IV (@LTGIV)
# www.GotGetLLC.com | www.opensour.cc/ggcom/docker/py3nlp
#
# Example usage:
#
# Build
# $] docker build --tag=py3nlp .
#
# Run
# $] docker run py3nlp --version
# $] docker run --volume="HOST/PATH/PROJECT:/opt/PROJECT" py3nlp "/opt/PROJECT/run.py"
#
# Thanks:
#
# Setting up pyenv in docker
# https://gist.github.com/jprjr/7667947
#
# To-do:
#
# Possibly include Stanford CoreNLP (http://nlp.stanford.edu/software/corenlp.shtml) in a future update, or in a separate container
#
################################################################################
FROM		ubuntu:latest
MAINTAINER	GotGet, LLC <contact+docker@gotgetllc.com>

# Initial prerequisites for installing pyenv
USER		root
ENV			DEBIAN_FRONTEND	noninteractive
RUN			apt-get -y update && apt-get -y install \
				apt-transport-https \
				curl \
				gcc \
				git-core \
				libbz2-dev \
				libreadline-dev \
				libsqlite3-dev \
				libssl-dev \
				make \
				zlib1g-dev

# Create a user and reciprocal environment variables
RUN			adduser --disabled-password --gecos "" python_user
USER		python_user

# Set environment variables
ENV			HOME			/home/python_user
ENV			PYENV_ROOT		$HOME/.pyenv
ENV			PATH			$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

# Install pyenv
WORKDIR		$HOME
RUN			curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash

# Create source directory to work out of
RUN			mkdir -pv $HOME/src/

# Clone "GGCom - Docker - pyenv" so that we can use the pycompiler
RUN			git clone https://github.com/gotget/ggcom-docker-pyenv.git $HOME/src/ggcom-docker-pyenv

RUN			bash $HOME/src/ggcom-docker-pyenv/pycompiler.bash 2 python2
RUN			bash $HOME/src/ggcom-docker-pyenv/pycompiler.bash 3 python3
################################################################################
USER		root

# Used by entry point
RUN			cp -vaR $HOME/src/ggcom-docker-pyenv/init.bash /root/init.bash

# Install Python module requirements
RUN			apt-get -y install \
				build-essential \
				gfortran \
				liblapack-dev \
				libopenblas-dev \
				libxml2-dev \
				libxslt-dev \
				pkg-config \
				python-dev \
				zlib1g-dev
################################################################################
USER		python_user
WORKDIR		$HOME

# Python 3
RUN			pyenv global python3

# Install Python 3 NLP requirements
RUN			pip install phonenumbers
RUN			pip install NLTK
RUN			pip install textblob
#RUN			python -m textblob.download_corpora # Skip for NLTK downloader below to grab it all
RUN			pip install pyenchant
RUN			pip install lockfile
RUN			pip install numpy
RUN			pip install scipy
RUN			pip install scikit-learn
RUN			pip install execnet
RUN			pip install pymongo
RUN			pip install redis
RUN			pip install lxml
RUN			pip install beautifulsoup4
RUN			pip install python-dateutil
RUN			pip install charade

# Please see https://honnibal.github.io/spaCy/ for more details, including licensing restrictions.
RUN			pip install spacy
RUN			python -m spacy.en.download

# Install MQTT and ZeroMQ client capabilities
RUN			pip install mosquitto
RUN			pip install pyzmq
################################################################################
USER		root

# Install requirements for Megam, needed by NLTK Trainer
RUN			apt-get -y install \
			ocaml

WORKDIR		/usr/lib/ocaml

# Resolve "/usr/bin/ld: cannot find -lstr" error - thank you jrouquie : http://stackoverflow.com/a/13585196
RUN			ln -s libcamlstr.a libstr.a

# Clone and compile megam (http://hal3.name/megam/ | https://www.umiacs.umd.edu/~hal/megam/)
RUN			curl -L https://www.umiacs.umd.edu/~hal/megam/megam_src.tgz | tar xzv -C $HOME/src/
RUN			mv $(ls -d $HOME/src/megam*) $HOME/src/megam/
WORKDIR		$HOME/src/megam/
RUN			make

# Move compiled executable
RUN			find $HOME/src/megam/ -executable -type f -print0 | xargs -0 mv -t /usr/local/bin/

# Remove alias so that we can purge without error of a non-empty directory
RUN			rm -rf /usr/lib/ocaml/libstr.a
################################################################################
USER		python_user

# Clone NLTK Trainer
RUN			git clone https://github.com/japerk/nltk-trainer.git $HOME/nltk-trainer

# Set Python 2 for NLTK Trainer, based upon README (statements seem to conflict with https://nltk-trainer.readthedocs.org/en/latest/)
WORKDIR		$HOME/nltk-trainer/
RUN			pyenv local python2

# Install Python 2 NLTK Trainer requirements
RUN			pip install argparse
RUN			pip install NLTK
RUN			python -m nltk.downloader -d $HOME/nltk_data all
RUN			pip install numpy
RUN			pip install scipy
RUN			pip install scikit-learn
################################################################################
USER		root

# Clean-up after ourselves
RUN			apt-get -y purge \
				build-essential \
				gcc \
				git \
				make \
				pkg-config
RUN			apt-get -y autoremove

# Delete specific targets
RUN			rm -rf $HOME/src/ $HOME/.cache/pip/ /tmp/* /usr/lib/ocaml/

# Delete all Git directories
RUN			find / -type d -name .git -print0 | xargs -0 rm -rf

# Delete all Python byte code
#RUN			find / -type f -name *.pyc -print0 | xargs -0 rm -rf # Holding off on this, for now.

# Return to home
WORKDIR		$HOME
################################################################################
RUN			chmod 750 /root/init.bash
ENTRYPOINT	[ "/bin/bash", "/root/init.bash" ]
################################################################################
