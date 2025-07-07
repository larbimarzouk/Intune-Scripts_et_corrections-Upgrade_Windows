# SYNOPSIS 
# Script de détection pour les mises à jour Winget (Intune).
# DESCRIPTION: Détecte les applications avec mises à jour disponibles et prépare le déclenchement du script de correction.
# Version: 4.1
# Author: Marzouk Larbi

$LogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\WingetUpdates.log"

# Fonction de journalisation 
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$Level] $Message" | Out-File $LogPath -Append -Encoding UTF8
    Write-Host "$timestamp [$Level] $Message"
}

try {
    Write-Log "Début de la détection des mises à jour"

    # Vérifier si Winget est installé
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Log "Winget n'est pas installé" -Level "ERROR"
        exit 0
    }

    # Exécuter winget upgrade
    $updates = winget upgrade --accept-source-agreements 2>&1

    if ($updates -match "\s+\S+\s+\S+\s+\S+\s+\S+") {
        Write-Log "Mises à jour disponibles détectées"

        # Créer un marqueur pour le script de correction
        $markerPath = "$env:ProgramData\WingetUpdatesMarker.txt"
        "UpdatesAvailable $(Get-Date)" | Out-File $markerPath -Encoding UTF8

        exit 1
    }
    else {
        Write-Log "Aucune mise à jour disponible"
        exit 0
    }
}
catch {
    Write-Log "ERREUR: $_" -Level "ERROR"
    exit 0
}
