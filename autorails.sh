#!/bin/bash
source $HOME/.rvm/scripts/rvm
alias instEnvGems="$HOME/$ADIR/envGems.sh"

DEFAULTRUBY=2.2.2
DEFAULTRAILS=4.2.1

# Repeatable Logic
ansi() {
  case $1 in
    grey) echo $2 "\x1B[01;90m$3\x1B[0m";;
    green) echo $2 "\x1B[0;32m$3\x1B[0m";;
    none) echo $2 "\x1B[0m$3\x1B[0m";;
  esac
}

rvmexec() {
  MSG="Enter a valid Ruby version to $1 "
  case $1 in
    [use]* )
      ansi green -en "$MSG" && read -p "(Press [ENTER] to $1 default v$DEFAULTRUBY): " RUBYVER
      if [ -z $RUBYVER ]; then RUBYVER=$DEFAULTRUBY; else RUBYVER=$RUBYVER; fi
      rvm use $RUBYVER
      ;;
    [install]* )
      ansi green -en "$MSG" && read -p "(Press [ENTER] to $1 default v$DEFAULTRUBY): " RUBYVER
      if [ -z $RUBYVER ]; then RUBYVER=$DEFAULTRUBY; else RUBYVER=$RUBYVER; fi
      ansi green -e "\nThis may take some time, please be patient...\n"
      rvm install $RUBYVER
      ;;
  esac
  unset MSG
  export RUBYVER
}

gemrails() {
  MSG="Enter a valid Rails version to $1 "
  case $1 in
    [install]* )
      ansi green -en "$MSG" && read -p "(Press [ENTER] to $1 default v$DEFAULTRAILS): " RAILSVER
      if [ -z $RAILSVER ]; then RAILSVER=$DEFAULTRAILS; else RAILSVER=$RAILSVER; fi
      ansi grey -e "\nInstalling Rails version $RAILSVER"
      ansi green -e "This may take some time, please be patient..."
      gem install rails --version=$RAILSVER
  esac
  unset MSG
}

injectcode() {
  LINE=$1
  TMP="./sed.$$"
  trap "rm -f $TMP; exit 1" 0 1 2 3 13 15
  sed -e "${LINE}r $HOME/$ADIR/src/$2" $HOME/$WDIR/$PDIR/$PROJ/$3 > $TMP
  cp $TMP $HOME/$WDIR/$PDIR/$PROJ/$3
  rm -f $TMP
  trap 0
  unset TMP
  unset LINE
}

bitbucket() {
  if grep -q "[auth]" $HOME/.bitbucket ; then
    bb create --$1 $2
  else
    touch $HOME/.bitbucket
    ansi green -e "\nGenerating $HOME/.bitbucket configuration file"
    read -p "Please enter Bitbucket Username (ex: email@domain.tld): " BBUSERNAME
    read -s -p "Please enter Bitbucket Password: " BBPASSWORD && echo ""
    read -p "Please enter Bitbucket SCM (options: git | hg): " BBSCM
    read -p "Please enter Bitbucket Protocol (options: https | ssh): " BBPROTOCOL
    echo -e "[auth]\nusername = $BBUSERNAME\npassword = $BBPASSWORD\n\n[options]\nscm = $BBSCM\nprotocol = $BBPROTOCOL" >> $HOME/.bitbucket
    chmod 0600 $HOME/.bitbucket
    bb create --$1 $2
    unset BBUSERNAME && unset BBPASSWORD && unset BBSCM && unset BBPROTOCOL
  fi
}

gitignore() {
  echo "$1" >> .gitignore && echo -e "\x1B[0;32mAdding:\x1B[0;0m $1 \x1B[0;31m>>\x1B[0;0m .gitignore"
}

checkruby() {
  rvm list
  while true; do
    read -p "Is the version of Ruby you wish to use listed above? (Y/N) " RUBYVEREXIST
      case $RUBYVEREXIST in
        [Yy]* ) rvmexec use; break;;
        [Nn]* ) rvmexec install; break;;
        * ) ansi green -e "\nERROR: Please enter a valid response\n";;
      esac
  done
  unset RUBYVEREXIST
}

makegemset() { 
  rvm use $RUBYVER@$PROJ --create && rvm gemset copy $RUBYVER@default $RUBYVER@$PROJ && rvm gemset list
}

title() {
  case $1 in
    [single]* ) ansi green -e "\n$2"; ansi grey -e "--------------------------------------------------------------------------------\n";;
    [double]* ) ansi green -e "\n\n$2"; ansi grey -e "--------------------------------------------------------------------------------\n";;
  esac
}

# Command Sequence
createproject() {
  title single "Creating rails project (( $PROJ ))"
    checkruby

  title double "Creating $HOME/$WDIR/$PDIR/$PROJ"
    mkdir -vp $HOME/$WDIR/$PDIR/$PROJ && cd $HOME/$WDIR/$PDIR/$PROJ

  title double "Creating $PROJ Gemset"
    makegemset

  title single "Installing Environment Utilities"
    if grep -q "gem: --no-document" $HOME/.gemrc ; then sleep 0; else touch $HOME/.gemrc && echo "gem: --no-document" >> $HOME/.gemrc; fi
    sudo apt-get -y install libmysqlclient-dev
    instEnvGems

  title double "Installing Rails to $HOME/$WDIR/$PDIR/$PROJ"
    gemrails install

  title double "Scaffolding $HOME/$WDIR/$PDIR/$PROJ"
    rails new . -d mysql -B

  title double "Configuring $PROJ Runtime Environment"
    injectcode "3" "_Gemfile" "Gemfile"
    sed -i "4iruby '$RUBYVER'" $HOME/$WDIR/$PDIR/$PROJ/Gemfile
    sed -i "5i#ruby-gemset=$PROJ" $HOME/$WDIR/$PDIR/$PROJ/Gemfile
    cp $HOME/$ADIR/src/_database.yml $HOME/$WDIR/$PDIR/$PROJ/config/database.yml
    sed -i "6i\ \ database:\ ${PROJ}_development" $HOME/$WDIR/$PDIR/$PROJ/config/database.yml
    bundle install
    rake db:create

  title double "Adding configuration elements to $PROJ/config/application.rb"
    injectcode "22" "_application.rb" "config/application.rb"

  title double "Initializing local git repository"
    git init

  title double "Adding sensitive files to $PROJ/.gitignore"
    gitignore "config/database.yml"
    gitignore "config/secrets.yml"

  title double "Invoking initial commit"
    git add -A && git commit -am "Initial Commit"

  title double "Creating Bitbucket repository"
    bitbucket private $PROJ

  title double "Creating Git remote"
    git remote add origin git@bitbucket.org:$GITUSER/$PROJ.git

  title double "Pushing initial commit to remote"
    git push origin master

  unset PROJ && unset RUBYVER && unset RAILSVER && unset DEFRUBY && unset DEFRAILS
}

cat << "HEAD"
    _  _   _ _____ ___  ___    _   ___ _    ___ 
   /_\| | | |_   _/ _ \| _ \  /_\ |_ _| |  / __|
  / _ \ |_| | | || (_) |   / / _ \ | || |__\__ \
 /_/ \_\___/  |_| \___/|_|_\/_/ \_\___|____|___/
HEAD

ansi green -e "       RAILS-BOOTSTRAP-MYSQL PROJECT AUTOMATION\n"

if [ $PROJ="" ]; then
  read -p "Enter a project name: " PROJ
  while true; do
    case $PROJ in
      "") read -p "ERROR: Project name cannot be blank, please enter a project name: " PROJ;;
      *)
        while true; do
          if [ -d "$HOME/$WDIR/$PDIR/$PROJ" ]; then PROJPATH=0; else PROJPATH=1; fi
          case $PROJPATH in
            0) read -p "ERROR: $PROJ already exists, choose another name: " PROJ; break;;
            1) createproject; return;;
          esac
        done
    esac
  done
fi
