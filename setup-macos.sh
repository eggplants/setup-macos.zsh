#!/usr/bin/env bash

set -eux

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew update
brew tap fumiyas/echo-sd
brew tap gcenx/wine
brew install --cask \
    docker google-chrome iterm2 \
    keybase obs slack visual-studio-code zoom
brew install \
    act binutils byobu cmake coreutils deno diffutils \
    docker echo-sd emacs feh findutils gawk gh gnu-sed \
    gnu-tar gnupg go grep nodenv ncurses nkf pinentry-mac \
    pyenv rbenv shellcheck sl spectacle tmux tree uniutils wget w3m yarn
brew reinstall git nano

curl https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh | sh

git clone https://github.com/eggplants/dotfiles
cp dotfiles/.{*shrc,nanorc,gitconfig,weather*.sh} ~

git config --global gpg.program "$(which gpg)"
git config --global credential.helper \
    /usr/local/Cellar/git/*/share/git-core/contrib/credential/netrc/git-credential-netrc.perl
keybase login
mkdir ~/.gnupg
echo "pinentry-program $(which pinentry-mac)" > ~/.gnupg/gpg-agent.conf
chmod 600 ~/.gnupg/*
chmod 700 ~/.gnupg

echo -n "gh-token: "
read -sr pass
cat << A > .netrc
echo machine github.com
echo login eggplants
password $pass
machine gist.github.com
login eggplants
password $pass
A

echo -e "5\ny\n" |
    gpg --command-fd 0 \
        --expert --edit-key "$(gpg --list-keys |
            sed -n '4s/^  *//p')" trust
gpg -e -r w10776e8w@yahoo.co.jp ~/.netrc && rm -i "$_"

curl https://kyome.io/resources/runcat_plugins_manager.dmg -o runcat.dmg && open "$_"

cat << 'A' >> .zshenv
##### Mac BEGIN #####

export PERLLIB=/Library/Developer/CommandLineTools/usr/share/git-core/perl:$PERLLIB
export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"
export PATH="/usr/local/opt/findutils/libexec/gnubin:$PATH"
export MANPATH="/usr/local/opt/findutils/libexec/gnuman:$MANPATH"
export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
export MANPATH="/usr/local/opt/gnu-sed/libexec/gnuman:$MANPATH"
export COWPATH=$HOME/usr/share/cows
export PATH="/usr/local/opt/gnu-tar/libexec/gnubin:$PATH"
export MANPATH="/usr/local/opt/gnu-tar/libexec/gnuman:$MANPATH"
PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
MANPATH="/usr/local/opt/grep/libexec/gnuman:$MANPATH"
export PATH="/usr/local/sbin:$PATH"
eval "$(nodenv init -)"

##### mac END #####
A

pyenv install 3.10.0
pyenv install 3.7.12
pyrnv global "$_"
rbenv install 3.0.0
rbenv install 2.7.4
pyenv global "$_"
nodenv install 17.0.1
nodenv global "$_"
