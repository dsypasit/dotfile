FROM ubuntu

LABEL MAINTAINER "Pasit Sriin"

ENV DEBIAN_FRONTEND noninteractive

RUN yes | unminimize && \
	apt-get -y --no-install-recommends upgrade && \
	apt-get install -y \
        apt-utils \
        build-essential \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        man-db \
        curl \
        && \
    add-apt-repository ppa:git-core/ppa && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
        neovim tmux dialog perl python3 git gh jq sudo shellcheck \
        figlet sl tree nmap ed bc iputils-ping  htop curl \
        net-tools ssh sshpass sshfs rsync \
        cifs-utils smbclient bash-completion make wget less lolcat \
		golang npm nodejs \
        && \
	apt-get clean

WORKDIR /home/dsypasit

COPY .config/ .config/
COPY script/ ./dotfile/.
COPY alias ./dotfile/.
COPY .bashrc .
COPY .profile .
COPY .zshrc .
COPY user .
COPY .tmux.reset.conf .
COPY .tmux.conf .
COPY starship_install .
COPY nvim/ .config/nvim/

RUN  sh starship_install --yes

CMD ["sh", "user"]

