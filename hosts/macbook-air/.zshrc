
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


. "$HOME/.local/bin/env"


# Added by Antigravity CLI installer
export PATH="/Users/scatuiva/.local/bin:$PATH"

# Added by Antigravity IDE
export PATH="/Users/scatuiva/.antigravity-ide/antigravity-ide/bin:$PATH"

# --- INTEGRACIONES CLI ---
# https://gemini.google.com/app/515948b6a50fac0a
# Prompt Starship
eval "$(starship init zsh)"

# Zoxide (cd inteligente)
eval "$(zoxide init zsh)"

# Búsqueda interactiva con fzf (CTRL+R)
source <(fzf --zsh)

# Plugins de Zsh (Autocompletado + Coloreado de sintaxis)
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- ALIAS DE CONDA Y GIT ---
alias ca="conda activate"
alias cdact="conda deactivate"
alias clist="conda env list"

alias gs="git status"
alias ga="git add ."
alias gc="git commit -m"
alias gco="git checkout"
alias gp="git push"
alias gl="git log --oneline --graph --decorate"