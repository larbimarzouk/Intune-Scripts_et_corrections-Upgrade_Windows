# SYNOPSIS
# Script de correction pour appliquer les mises à jour détectées via Winget.
# DESCRIPTION : Si le marqueur existe, applique les mises à jour Winget.

# Version: 1.0
# Author: Marzouk Larbi

$LogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\WingetCorrection.log"
$markerPath = "$env:ProgramData\WingetUpdatesMarker.txt"

# Fonction de journalisation
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$Level] $Message" | Out-File $LogPath -Append -Encoding UTF8
    Write-Host "$timestamp [$Level] $Message"
}

try {
    Write-Log "Début du script de correction"

    if (-not (Test-Path $markerPath)) {
        Write-Log "Aucun marqueur trouvé. Aucune mise à jour à appliquer." -Level "INFO"
        exit 0
    }

    # Vérifier que Winget est présent
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Log "Winget n'est pas disponible sur cette machine" -Level "ERROR"
        exit 1
    }

    # Appliquer les mises à jour
    Write-Log "Lancement de la commande : winget upgrade --all --accept-package-agreements --accept-source-agreements"
    winget upgrade --all --accept-package-agreements --silent --accept-source-agreements 2>&1 | Tee-Object -FilePath $LogPath -Append

    # Supprimer le marqueur après exécution
    Remove-Item $markerPath -Force
    Write-Log "Mises à jour terminées. Marqueur supprimé."

    exit 0
}
catch {
    Write-Log "ERREUR pendant la correction : $_" -Level "ERROR"
    exit 1
}
