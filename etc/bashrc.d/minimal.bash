### MINIMAL BASH SETUP FOR LEGACY VERSIONS ###

PS_COLOR="${PS_COLOR:-32}" . ~/.bashrc.d/prompts.bash

echo "
GNU Bash $BASH_VERSION

Upgrade:

    git clone git://git.sv.gnu.org/bash.git

    curl -Ls http://git.sv.gnu.org/cgit/bash.git/snapshot/master.tar.gz | tar zxv
"
