        _  _   _ _____ ___  ___    _   ___ _    ___ 
       /_\| | | |_   _/ _ \| _ \  /_\ |_ _| |  / __|
      / _ \ |_| | | || (_) |   / / _ \ | || |__\__ \
     /_/ \_\___/  |_| \___/|_|_\/_/ \_\___|____|___/
           RAILS-BOOTSTRAP-MYSQL PROJECT AUTOMATION

# table of contents

1. [description](#description)
2. [release history](#release-history)
3. [todo](#todo)
4. [installation](#installation)
5. [script components](#script-components)  
    `(1)` [`envGems.sh`](#envgemssh)  
    `(2)` [`src/_Gemfile`](#src_gemfile)  
    `(3)` [`src/_application.rb`](#src_applicationrb)  
    `(4)` [`src/_database.yml`](#src_databaseyml)
    `(5)` [`injectcode()`](#injectcode)  
6. [helper functions](#helper-functions)  
    `(1)` [`ansi()`](#ansi)  
    `(2)` [`title()`](#title)  
    `(3)` [`gitignore()`](#gitignore)  
7. [script workflow](#script-workflows)  
    `(1)` [`arinstall.sh`](#arinstall.sh)  
    `(2)` [`autorails.sh`](#autorails.sh)

# description
Shell Script to automate your local development environment for a new Rails-Bootstrap-MySQL project

This simple script was created to help manage the automation of the basic steps needed to prep for new project development. It's intended to follow a general core set of common Gems and Configuration tweaks common accross all projects. Included is a minimal list of Gems and Configuration elements suggested by Spark Master Flex as detailed in his blog post found here: http://goo.gl/atjMWE, along with some of my own tweaks.

There are two target audiences for this script, but the core focus for both is the same: saving time. For beginner to intermediate Ruby/Rails developers, it allows one to set up a functional project without spending time reading documentation and instead focus more on developing code and learning syntax. When I started learning Ruby and Rails, I found everything involved with getting a project from nothing to something overwhelming, and actually fairly arbitrary and unnecessary when all I wanted to do was learn the syntax hands on in a sandbox like environment. For me reading through and following a manual is needlessly tedious, and prefer to start with an idea and consult resources when I become stuck on an issue.

For the advanced/veteran Ruby/Rails developers, this script provides an easy way to automate their own familiar workflows without having to add additional layers of complexity using Chef or Puppet or anything else which are entirely unnecessary in a singular development environment. The core components of the script are abstracted away from the script itself, allowing for simple adding and subtracting of Gems and other component configurations, and is easily extendable by utilizing reusable functions.

There are some interactions in this script which allow you to change/install new versions of Ruby via RVM, install any valid versions of Rails via Gem Install, and define the project names encapsulated by some minor error handling to ensure no duplication of unique project names occurs.

# release history
May 11, 2015 - 1.0.0 - Initial production release - [Release Notes](RELEASE.md#100)

# todo

1. Create error handling and version verification for Ruby and Rails (presently, if an invalid version of Ruby or Rails is provided, RVM/Gem Install fails, and so will additional steps during the process.
2. Create interactions to delete projects and their associated Gemsets.
3. Enhance deletion interactions to include remote repository deletion (BB seems a bit buggy)
4. Expand functionality to choose many different combinations of Ruby-Rails-CSS Framework-DBConnector setups
5. Rewrite some interactions from type based input to menu selection based input
6. Create compatibility with Github
7. Create logging of all script activity for future troubleshooting purposes

# installation
This script is tested extensively against Ubuntu 12.04 (`Vagrant > ubuntu/trusty64`). Initial testing performed under LinuxMint 17.1 x64 revealed Ruby source and Gem dependency conflicts after several iterations of testing, which did not exist under `ubuntu/trusty64`

Unless you want to install this to your native filesystem (Ubuntu), alternate ways you can utilize this script is via Vagrant, or Docker, and Boot2Docker for Windows and OS X.

Install your machine SSH Pubkey to Bitbucket `cat ~/.ssh/id_rsa.pub`, copy output and paste it into your Bitbucket account. If you do not have a `~/.ssh/id_rsa.pub` file type `ssh-keygen` at the command line and follow the prompts to generate a public key for your machine, then re-run the `cat` command.

If you are running terminal via GUI, then you have to set an option for the script to function correctly: `Edit > Preferences > Enable "Run command as login shell"`

1. Ensure you have `sudo` access on the machine you are running this script on
2. Ensure Git is installed `sudo apt-get -y update && sudo apt-get -y install git`
3. Clone repository `cd ~ && git clone https://github.com/gabrialm/autorails.git`
4. Run installer script `cd autorails && ./arinstall.sh`
5. Run autorails, from terminal type `autorails [ENTER]` and follow the steps

# script components
There are a few external files used as data sources that can be used to modify the automation sequence to suit your needs:

envGems.sh
--------------
Contains `gem install` commands to install three required Gems: `bundler`, `nokogiri` and `mysql2` as well as an optional Gem: `html2slim` for converting any pre-generated .html.erb files from HTML to Slim. You can add additional environment gems here and they will be installed at runtime. **Note:** `slim` and `slim-rails` are added by default in the _Gemfile partial, so be sure to remove those entries if you do not wish to utilize Slim.

You do not run this script independently, it will be called automatically by the parent `autorails.sh`

src/_Gemfile
-----------
Partial which contains a list of Gems that are meant to be common across all projects. Included are:

1. `bootstrap-sass`
2. `slim`
3. `slim-rails`
4. `devise`
5. `cancan`
6. `will_paginate`
7. `attr_encrypted`
8. `momentjs-rails`
9. `quiet_assets`

src/_application.rb
--------------
Partial which details common configuration changes accross all projects to be injected into `config/application.rb`. Configuration adjustments include:

1. `lib/assets/javascripts` and `lib/assets/stylesheets` made available to the Rails pipeline.
2. Prevent the creation of supporting assets when new controllers are generated. This forces the application to rely on a single unified location for CSS/SCSS and JavaScript

`src/_Gemfile` and `src/_application.rb` are dependencies of the `injectcode()` function.

src/_database.yml
---------------
Partial which details standard structure for database.yml. The partial is copied to the `config/database.yml` location in the project directory, and then further modified by the `autorails.sh` script.

Included are the necessary connection details to connect to the Docker container running the MySQL server. You will have to enter your own relevant settings for test and production.

injectcode()
------------
Re-usable function configured to make use of three (3) parameters: Line Number, Source File and Output File. The function can be easily used to extend the usability of this script in the future. Simply create a new source file, identify an Output File to modify and identify the line number in the Output File where you want the code injected.

    injectcode() {
        LINE=$1
        TMP="./sed.$$"
        trap "rm -f $TMP; exit 1" 0 1 2 3 13 15
        sed -e "${LINE}r $HOME/autorails/src/$2" $HOME/$WDIR/$PDIR/$PROJ/$3 > $TMP
        cp $TMP $HOME/$WDIR/$PDIR/$PROJ/$3
        rm -f $TMP
        trap 0
        unset TMP
        unset LINE
    }

Usage: `injectcode "3" "_Gemfile" "Gemfile"`  
Where:

1. `injectcode` calls the function
2. `"3"` declares the line number in the output file to begin placement of injected source
3. `"_Gemfile"` declares the source file to read from
4. `"Gemfile"` declares the output file to write to

# helper functions
ansi()
------
`ansi()` is a re-useable and extendable function created to cleanly colorize text output for echo statements. The function accepts the following parameters (in order) color/identifier, echo options, string.

Usage: `ansi green -en "\nMessage to make green\n"`  
Where:

1. `ansi` calls the function
2. `green` declares the color or other identifier for case statement
3. `-en` (concatenated -e and -n switch options for `echo`), you can include either/or both.
4. `"\nMessage to make green\n"` Self explanatory

The function itself makes use of official ANSI color codes.

title()
------
Function for formatting titles, accepts two parameters: single|double and "string"

Usage: `title single|double "Message to be displayed"`  
Where:

1. `title` calls the function
2. `single|double` declares the number of line breaks to be inserted prior to the title
3. `"Message to be displayed"` Self explanatory

gitignore()
----------
Function to simplify adding files to .gitignore, and provide an echoed output of each file added, accepts a single parameter: the relative file path of the file to add.

Usage: `gitignore "path/to/file"`  
Where:

1. `gitignore` calls the function
2. `"path/to/file"` is relative to the root of the project folder. Ex: `$HOME/Workspace/Projects/Foo/config/database.yml` would be declared as: `gitignore "config/database.yml"`

# script workflows

## arinstall.sh
1. Checks for the existence of the token declaring `autorails` has been installed. If found, script exits, otherwise it continues
2. Installs environment requirements: `Curl`, `PIP`, `NodeJS` and `NPM`
3. Installs RVM
4. Installs Bitbucket CLI via `PIP`
5. Adds third party `docker` PPG, installs `docker`, adds current user to `docker` group and restarts the `docker` service
6. Clones `tutum/mysql` Git repo and builds `docker` image for `MySQL v5.5`
7. Boots `docker` image, setting password, generating a Container ID file (for future use), names the container to autorails and sets the restart policy to `always` which will indefinitely tell `docker` to restart the container if it exits (for any reason)
8. Generates environment parameters, such as checking for existence of Bitbucket Git Username or the existence of a `.gitconfig` file and generates those where needed. It will also insert these and other parameters needed for the script to function into your `~/.bash_profile`
9. Sources the `~/.bash_profile` and reloads the `docker` group so actions can be performed by `autorails.sh` without needing to use sudo, or close and open a new terminal session.

## autorails.sh
Quick list of the different stages that the script goes through

1. Prompts for project name
2. Checks for current Ruby versions, confirms necessary versions installed. Y proceeds to select version, N proceeds to allow installation of needed version
3. Creates unique project gemset, copies default gemlist over to new gemset
4. Looks for `~/.gemrc` file, and if not found, creates it and inserts a statement to prevent Gem documentation from being generated during Gem install, installs system level Gems and the mysql gem dependency `libmysqlclient-dev`
5. Prompt for requested Rails version for project and installs
6. Scaffold new project with `mysql` and `no bundle` options, copies `_database.yml` partial and inserts the database name based off the previously set `$PROJ` variable. Also performs `rake db:create` to create the project database
7. Injects `_Gemfile` and `_application.rb` partials to their respective configuration targets, adds the previously set `$RUBYVER` to the Gemfile and a comment to auto switch the Gemset being used when switching into the project directory (this is to automatically switch between Gemsets when developing multiple projects concurrently)     
8. Bundle Installs new Gemfile
9. Initiate local Git repository
10. Add sensitive files to `.gitignore`
11. Performs initial local commit
12. Creates Bitbucket remote repository. If first run, it will prompt the user to build the `~/.bitbucket` configuration file
13. Creates `Origin` remote to newly created Bitbucket repository
14. Pushes initial local commit to `Origin/Master`
15. Unsets variables and exits to newly created project folder
