# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Ensure homebrew is in PATH for non-login shells
eval "$(/opt/homebrew/bin/brew shellenv)"

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
ZSH_AUTOSUGGEST_STRATEGY=(history)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242,underline'

plugins=(git golang terraform kubectl helm aws colored-man-pages history macos sudo zsh-autosuggestions zsh-syntax-highlighting)

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

ZSH_AUTOSUGGEST_STRATEGY=(history)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242,underline'
bindkey '^ ' autosuggest-accept
bindkey '^[[1;5C' autosuggest-accept
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border=rounded'
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

bindkey '^I' expand-or-complete   # restore Tab to normal (fzf hijacks it otherwise)

source /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

export AWS_VAULT_BACKEND=file
export HELM_DRIVER=configmap
export PATH="/opt/homebrew/share/google-cloud-sdk/bin:$PATH"
export PATH="$PATH:$HOME/dd/devtools/bin/:/opt/dogbrew/bin"

export DATADOG_ROOT="/Users/maxim.briskin/dd"

gw() {
  local selection
  local worktree
  local -r gw_list=~/.zsh_functions/gw-list
  local -r gw_preview=~/.zsh_functions/gw-preview
  local -r gw_delete=~/.zsh_functions/gw-delete
  local -r gw_create=~/.zsh_functions/gw-create

  selection=$("$gw_list" | \
    fzf \
      --height=50% \
      --margin=1 \
      --padding=1 \
      --layout=reverse \
      --border=rounded \
      --border-label=" Worktrees " \
      --border-label-pos=3 \
      --prompt="  " \
      --pointer="❯" \
      --marker=" " \
      --no-multi \
      --delimiter=$'\t' \
      --with-nth=1,2 \
      --header-lines=1 \
      --header="ctrl-t: new worktree · ctrl-x: delete worktree" \
      --preview-window=right:45%,border-left \
      --preview="$gw_preview {1} {2} {3}" \
      --bind="ctrl-x:execute($gw_delete {1} {2} {3})+reload($gw_list)" \
      --bind="ctrl-t:execute($gw_create)+reload($gw_list)" \
      --color="fg:#908caa,fg+:#e0def4,bg+:#26233a,hl:#3e8fb0,hl+:#9ccfd8,pointer:#9ccfd8,marker:#f6c177,border:#403d52,label:#e0def4,prompt:#c4a7e7,header:#6e6a86,preview-border:#403d52,preview-fg:#e0def4"
  )

  if [[ -n "$selection" ]]; then
    worktree=$(echo "$selection" | cut -f3)
    cd "$worktree"
  fi
}

# Load private credentials safely from an untracked local file
if [ -f "$HOME/.zshrc_local" ]; then
    source "$HOME/.zshrc_local"
fi


alias dotfiles='/usr/bin/git --git-dir=/Users/maxim.briskin/.dotfiles --work-tree=/Users/maxim.briskin'
