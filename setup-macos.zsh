#!/usr/bin/env zsh

set -eux

if ! [[ -f ~/.sec.key ]]; then
  echo "need: ~/.sec.key"
  exit 1
fi

if ! [[ -f ~/Brewfile ]]; then
  echo "need: ~/Brewfile"
  exit 1
fi

cd ~
mkdir -p .config
mkdir -p .gnupg
mkdir -p prog
mkdir -p _setup
pushd _setup

sudo spctl --master-disable

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew bundle

# import key
gpg --list-keys | grep -q 8117 || {
  export GPG_TTY="$(tty)"
  echo "pinentry-program $(which pinentry-mac)" > ~/.gnupg/gpg-agent.conf
  chmod 600 ~/.gnupg/*
  chmod 700 ~/.gnupg
  gpgconf --kill gpg-agent
  sleep 3s
  cat ~/.sec.key | gpg --allow-secret-key --import
}

[[ -f ~/.gitconfig ]] || {
  echo -n "github token?> "
  # Copy generated fine-grained PAT and paste.
  # Required permission: Gist, Contents
  # https://github.com/settings/tokens
  read -s -r token
  cat << A >> ~/.netrc
machine github.com
login eggplants
password ${token}
machine gist.github.com
login eggplants
password ${token}
A
  git_email="$(
    gpg --list-keys | grep -Em1 '^uid' |
    rev | cut -f1 -d ' ' | tr -d '<>' | rev
  )"
  gpg -e -r "$git_email" ~/.netrc
  rm ~/.netrc
  sudo chmod +x \
    /usr/local/Cellar/git/*/share/git-core/contrib/credential/netrc/git-credential-netrc.perl
  git config --global credential.helper \
    /usr/local/Cellar/git/*/share/git-core/contrib/credential/netrc/git-credential-netrc.perl
  git config --global user.name eggplants
  git config --global user.email "$git_email"
  git config --global user.signingkey "$(
    gpg --list-secret-keys | tac | grep -m1 -B1 '^sec' | head -1 | awk '$0=$1'
  )"
  git config --global gpg.program "$(which gpg)"
  git config --global commit.gpgsign true
  git config --global help.autocorrect 1
  git config --global pull.rebase false
}

[[ -d ~/.nano ]] || {
  git clone --depth 1 --single-branch 'https://github.com/serialhex/nano-highlight' ~/.nano
}
cat <<'A'>~/.nanorc
include "~/.nano/*.nanorc"

set autoindent
set constantshow
set linenumbers
set tabsize 4
set softwrap

# Color
set titlecolor white,red
set numbercolor white,blue
set selectedcolor white,green
set statuscolor white,green
A

# mise
echo 'eval "$(/usr/local/bin/mise activate bash)"' >> ~/.bashrc
echo 'eval "$(/usr/local/bin/mise activate zsh)"' >> ~/.zshrc
eval "$(/usr/local/bin/mise activate zsh)"

# python
command -v python 2>/dev/null || {
  mise use --global python@latest 
  pip install pipx
  pipx ensurepath
  export PATH="$HOME/.local/bin:$PATH"
  pipx install getjump poetry yt-dlp
  poetry self add poetry-version-plugin
}

# ruby
command -v ruby 2>/dev/null || {
  mise use --global ruby@latest
}

# rust
command -v rust 2>/dev/null || {
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
}

# node
command -v node 2>/dev/null || {
  mise use --global node@latest
}

# go
command -v go 2>/dev/null || {
  mise use --global go@latest
}


# lisp
command -v sbcl 2>/dev/null || ros install sbcl-bin

# alacritty-theme
[[ -f ~/.config/alacritty/alacritty.toml ]] || {
  mkdir -p ~/.config/alacritty
  curl -o- 'https://codeload.github.com/alacritty/alacritty-theme/tar.gz/refs/heads/master' |
    tar xzf - alacritty-theme-master/themes
  mv alacritty-theme-master ~/.config/alacritty
  echo 'import = [' >> ~/.config/alacritty/alacritty.toml
  find ~/.config/alacritty/alacritty-theme-master/themes -type f -name '*toml' |
    sed 's/^.*/  # "&",/' >> ~/.config/alacritty/alacritty.toml
  echo ']' >> ~/.config/alacritty/alacritty.toml

  cat <<'A'>>~/.config/alacritty/alacritty.toml
[font]
size = 10.0

[font.bold]
family = "HackGen35 Console"
style = "Bold"

[font.bold_italic]
family = "HackGen35 Console"
style = "Bold Italic"

[font.italic]
family = "HackGen35 Console"
style = "Italic"

[font.normal]
family = "HackGen35 Console"
style = "Regular"
A
}

# starship
[[ -f ~/.config/starship.toml ]] || {
  echo 'eval "$(starship init bash)"' >> ~/.bashrc
  echo 'eval "$(starship init zsh)"' >> ~/.zshrc
  cat <<'A'>>~/.config/starship.toml
"$schema" = 'https://starship.rs/config-schema.json'

add_newline = false

format = '''\[\[\[${username}@${hostname}:\(${time}\):${directory}:${memory_usage}\]\]\] $package
->>> '''

right_format = '$git_status$git_branch$git_commit$git_state'

[character]
success_symbol = "[>](bold green)"
error_symbol = "[✗](bold red)"

[username]
disabled = false
style_user = "red bold"
style_root = "red bold"
format = '[$user]($style)'
show_always = true

[hostname]
disabled = false
ssh_only = false
style = "bold blue"
format = '[$hostname]($style)'

[time]
disabled = false
format = '[$time]($style)'

[directory]
# truncation_length = 10
truncation_symbol = '…/'
format = '[$path]($style)[$read_only]($read_only_style)'
# truncate_to_repo = false

[memory_usage]
disabled = false
threshold = -1
style = "bold dimmed green"
format = "[$ram_pct]($style)"

[package]
disabled = false
format = '[$symbol$version]($style)'
A
}

# zinit
curl -s https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh | bash
cat <<'A' >>~/.zshrc
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zdharma-continuum/history-search-multi-word
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions

# if (which zprof > /dev/null) ;then
#   zprof | less
# fi
A

# zsh
[[ "$SHELL" = "$(which zsh)" ]] || chsh -s "$(which zsh)"
cat <<'A' >.zshrc.tmp
#!/usr/bin/env zsh

# load zprofile
[[ -f ~/.zprofile ]] && source ~/.zprofile

# completion
type brew &>/dev/null && FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
autoload -U compinit
if [ "$(find ~/.zcompdump -mtime 1)" ] ; then
    compinit -u
fi
compinit -uC
zstyle ':completion:*' menu select

# enable opts
setopt correct
setopt autocd
setopt nolistbeep
setopt aliasfuncdef
setopt appendhistory
setopt histignoredups
# setopt sharehistory
setopt extendedglob
setopt incappendhistory
setopt interactivecomments
setopt prompt_subst

# alias
alias ll='ls -lGF --color=auto'
alias ls='ls -GF --color=auto'

# save cmd history up to 100k
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
HISTFILESIZE=2000
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search

# enable less to show bin
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# enable colorized prompt
case "$TERM" in
  xterm-color | *-256color) color_prompt=yes ;;
esac

# enable colorized ls
export LSCOLORS=gxfxcxdxbxegedabagacag
export LS_COLORS='di=36;40:ln=35;40:so=32;40:pi=33;40:ex=31;40:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;46'
zstyle ':completion:*:default' list-colors "${(s.:.)LS_COLORS}"

export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"
export MANPATH="/usr/local/opt/findutils/libexec/gnuman:$MANPATH"
export MANPATH="/usr/local/opt/gnu-sed/libexec/gnuman:$MANPATH"
export MANPATH="/usr/local/opt/gnu-tar/libexec/gnuman:$MANPATH"
export MANPATH="/usr/local/opt/grep/libexec/gnuman:$MANPATH"
export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/findutils/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/gnu-tar/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export PATH="$PATH:$HOME/.local/bin"
export PERLLIB="/Library/Developer/CommandLineTools/usr/share/git-core/perl:$PERLLIB"

export GPG_TTY="$(tty)"
A
cat ~/.zshrc >>.zshrc.tmp
mv .zshrc.tmp ~/.zshrc

cat <<'A' >.zshenv.tmp
#!/usr/bin/env zsh

function brew() {
  /usr/bin/env -S brew "$@"
  if [[ "$1" == "install" || "$1" == "remove" || "$1" == "uninstall" ]]; then
    /usr/bin/env -S brew bundle dump --force --file=~/.Brewfile
  fi
}
A
cat ~/.zshenv >>.zshenv.tmp
mv .zshenv.tmp ~/.zshenv

byobu-enable
echo '_byobu_sourced=1 . /usr/bin/byobu-launch 2>/dev/null || true' > ~/.zprofile

rm ~/.sec.key
popd
rm -rf _setup
