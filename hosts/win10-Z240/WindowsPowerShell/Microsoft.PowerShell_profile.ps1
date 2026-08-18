Invoke-Expression (&starship init powershell)

Import-Module posh-git

# 1. Autocompletado con menú desplegable al presionar TAB
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -PredictionSource History   # Muestra predicciones basadas en tu historial
Set-PSReadLineOption -PredictionViewStyle ListView # O usa 'InlineView' para estilo pez/fish
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

#Import-Module psfzf
#Set-PsFzfOption -PSReadlineChordProvider
#Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'

Import-Module psfzf
#Set-PsFzfKeyBindings

# --- ALIAS PARA CONDA ---
function ca ($envName) { conda activate $envName }
function cdact { conda deactivate }
function clist { conda env list }

# --- ALIAS PARA GIT ---
function gs { git status }
function ga { git add . }
function gc ($msg) { git commit -m "$msg" }
function gco ($branch) { git checkout $branch }
function gcn ($branch) { git checkout -b $branch }
function gp { git push }
function gld { git log --oneline --graph --decorate -n 10 }
function gl { git log --oneline --graph --decorate -n 10 }

