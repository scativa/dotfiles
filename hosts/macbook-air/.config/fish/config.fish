# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:/Users/scatuiva/.docker/bin"
# End of Docker Desktop section.

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /opt/miniconda3/bin/conda
    eval /opt/miniconda3/bin/conda "shell.fish" "hook" $argv | source
else
    if test -f "/opt/miniconda3/etc/fish/conf.d/conda.fish"
        . "/opt/miniconda3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/opt/miniconda3/bin" $PATH
    end
end
# <<< conda initialize <<<



# Added by Antigravity CLI installer
set -gx PATH "/Users/scatuiva/.local/bin" $PATH
zoxide init fish | source

fzf --fish | source

# --- PROMPT ---
starship init fish | source

# --- ALIAS DE CONDA Y GIT ---
alias ca='conda activate'
alias cdact='conda deactivate'
alias clist='conda env list'

alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gw='git checkout'
alias gn='git checkout -b'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -n 10'
alias gld='git log --oneline --graph --decorate -n'
