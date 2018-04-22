include /etc/firejail/electron.profile

net none

mkdir ${HOME}/.config/FontBase
whitelist ${HOME}/.config/FontBase

mkdir ${HOME}/.local/share/FontBase
whitelist ${HOME}/.local/share/FontBase
