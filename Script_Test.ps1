# SYNOPSIS
# Détection proactive de l’éligibilité à la mise à niveau vers Windows 11 24H2

# DESCRIPTION
# Ce script vérifie si le système est prêt pour la mise à niveau vers Windows 11 24H2
# Affiche des messages à l'écran et écrit dans le fichier de log.

# NOTES
# Version :         V1.2
# Auteur :          Marzouk Larbi / ChatGPT
# Date :            5 Juillet 2025

#======================== Section de configuration ================
$RequiredDiskSpaceGB = 45
$MinOSBuildFor24H2 = 26100
#==================================================================

# Initialisation du journal
$LogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Detection_Upgrade_Win11_24H2.log"
Function Write-Log {
    param([string]$Message)
    $timestamped = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    $timestamped | Out-File -FilePath $LogPath -Append
    Write-Host $timestamped
}

# Nettoyage erreurs
$error.clear()
$ErrorActionPreference = 'SilentlyContinue'

Write-Log "====== Détection de compatibilité pour Windows 11 24H2 - $(Get-Date -Format 'yyyy/MM/dd') ======"

# Nom machine
$ComputerName = $env:COMPUTERNAME
Write-Log "Machine : $ComputerName"

# Vérifier si déjà en 24H2
$OSBuild = ([System.Environment]::OSVersion.Version).Build
Write-Log "Build de l’OS détectée : $OSBuild"

if (-not $OSBuild) {
    Write-Log "Échec de récupération du numéro de build."
    Exit 1
}

if ($OSBuild -ge $MinOSBuildFor24H2) {
    Write-Log "Système déjà en Windows 11 24H2 ou supérieur. Aucune action nécessaire."
    Exit 0
}

# Espace disque
$drive = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
$FreeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
Write-Log "Espace disque libre sur C: $FreeSpaceGB Go"

# TPM
$tpmVersion = $null
try {
    $tpmData = tpmtool getdeviceinformation
    $tpmVersion = ($tpmData | Where-Object { $_ -match "TPM Version" }) -replace ".*TPM Version:\s*", ""
    Write-Log "Version TPM : $tpmVersion"
} catch {
    Write-Log "Impossible de récupérer les infos TPM."
}

# Secure Boot
$SecureBootEnabled = $false
try {
    $SecureBootEnabled = Confirm-SecureBootUEFI
    Write-Log "Secure Boot activé : $SecureBootEnabled"
} catch {
    Write-Log "Secure Boot non disponible ou BIOS non UEFI."
}

# Processeur
$cpu = Get-WmiObject Win32_Processor
$Is64Bit = $cpu.Architecture -eq 9
Write-Log "Architecture processeur : $($cpu.Architecture) (64 bits requis)"

# RAM
$ramOK = (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory -ge 4GB
Write-Log "RAM suffisante (≥ 4 Go) : $ramOK"

# CONDITIONS DE RÉUSSITE
if (
    $tpmVersion -ge "2.0" -and
    $SecureBootEnabled -eq $true -and
    $Is64Bit -and
    $ramOK -and
    $FreeSpaceGB -ge $RequiredDiskSpaceGB
) {
    Write-Log "✅ Machine compatible avec Windows 11 24H2. Lancement de la remédiation..."
    Exit 1  # Triggers remediation
} else {
    Write-Log "❌ Machine non compatible avec Windows 11 24H2. Mise à niveau bloquée."
    Exit 0  # Pas de remédiation
}
