### MINIMAL BASH SETUP FOR LEGACY VERSIONS ###

PS_COLOR="${PS_COLOR:-32}" . ~/.bashrc.d/prompts.bash

echo "
GNU Bash $BASH_VERSION

Upgrade:

    git clone git://gitorious.org/bash/bash.git
    curl -Ls https://gitorious.org/bash/bash/archive-tarball/maintenance/4.2 | tar zxv
"
