#!/bin/bash

ansi() {
  case $1 in
    grey) echo $2 "\x1B[01;90m$3\x1B[0m";;
    green) echo $2 "\x1B[0;32m$3\x1B[0m";;
    none) echo $2 "\x1B[0m$3\x1B[0m";;
  esac
}

title() {
  case $1 in
    [single]* ) ansi green -e "\n$2"; ansi grey -e "--------------------------------------------------------------------------------\n";;
    [double]* ) ansi green -e "\n\n$2"; ansi grey -e "--------------------------------------------------------------------------------\n";;
  esac
}

exitmsg() {
  title double "THANK YOU FOR INSTALLING AUTORAILS: THE RAILS/BOOTSTRAP/MYSQL PROJECT AUTOMATION TOOL\nPlease refer to https://github.com/gabrialm/autorails/ for documentation."
}

cat << "HEAD"
    _  _   _ _____ ___  ___    _   ___ _    ___ 
   /_\| | | |_   _/ _ \| _ \  /_\ |_ _| |  / __|
  / _ \ |_| | | || (_) |   / / _ \ | || |__\__ \ 
 /_/ \_\___/  |_| \___/|_|_\/_/ \_\___|____|___/
HEAD

ansi green -e "       RAILS-BOOTSTRAP-MYSQL PROJECT AUTOMATION"

if grep -q "#ARINSTALLED" $HOME/.bash_profile ; then
  title double "Autorails has already been installed.\nPlease run << autorails >> from the prompt to generate a new project"
  return
else
  title double "Installing CURL, PIP, NodeJS and NPM"
  sleep 3
    sudo apt-get -y update && sudo apt-get -y install curl python-pip nodejs npm

  title double "Installing RVM"
  sleep 3
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 && \curl -sSL https://get.rvm.io | bash

  title double "Installing Bitbucket CLI"
  sleep 3
    sudo pip install bitbucket-cli

  title double "Installing Docker"
  sleep 3
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
    sudo bash -c "echo deb https://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
    sudo apt-get update && sudo apt-get install -y lxc-docker
    sudo gpasswd -a ${USER} docker
    sudo service docker restart

  title double "Building MySQL 5.5 Docker Image"
  sleep 3
    mkdir -vp $HOME/workspace/docker/images
    git clone https://github.com/tutumcloud/tutum-docker-mysql.git $HOME/workspace/docker/images/tutum-docker-mysql
    sudo docker build -t tutum/mysql $HOME/workspace/docker/images/tutum-docker-mysql/5.5

  title double "Runnig MySQL 5.5 Docker Image"
  sleep 3
    docker run -d -p 3306:3306 -e MYSQL_PASS="admin" --cidfile="$HOME/$WDIR/autorails-mysql.cid" --name="autorails" --restart="always" tutum/mysql


  title double "Generating environment parameters"
  sleep 3
    if grep -q "GITUSER" $HOME/.bash_profile ; then sleep 0; else read -p "Enter your Git Username for Bitbucket. Example: git@bitbucket.org:<USERNAME>/repo.git " GITUSER; fi
    if grep -q "[user]" $HOME/.gitconfig ; then sleep 0; else
    read -p "Please enter your name: " GITNAME
    read -p "Please enter your email: " GITEMAIL
      git config --global user.name $GITNAME
      git config --global user.email $GITEMAIL
      unset GITNAME && unset GITEMAIL
    fi

    ADIR='"autorails"'
    WDIR='"workspace"'
    PDIR='"projects"'
    EXE='alias autorails="source $HOME/$ADIR/autorails.sh"'
    echo -e "\n\nADIR=$ADIR\nWDIR=$WDIR\nPDIR=$PDIR\nGITUSER=\""$GITUSER\""\n\nexport ADIR\nexport WDIR\nexport PDIR\nexport GITUSER\n\n#ARINSTALLED\n\n $EXE" >> $HOME/.bash_profile

    exitmsg
    sleep 3
    source $HOME/.bash_profile
    newgrp docker
fi