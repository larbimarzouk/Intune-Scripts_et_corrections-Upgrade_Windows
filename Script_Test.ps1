# SYNOPSIS
# Détection proactive de l’éligibilité à la mise à niveau vers Windows 11 24H2

# DESCRIPTION
# Vérifie la compatibilité matérielle et logicielle avant mise à niveau via Intune ou localement

# NOTES
# Version :         V1.3
# Auteur :          Marzouk Larbi / ChatGPT
# Date :            5 Juillet 2025

#======================== Configuration ===========================
$RequiredDiskSpaceGB = 45
$MinOSBuildFor24H2 = 26100
#==================================================================

# Initialisation du log
$LogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Detection_Upgrade_Win11_24H2.log"
Function Write-Log {
    param([string]$Message)
    $timestamp = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    $timestamp | Out-File -FilePath $LogPath -Append
    Write-Host $timestamp
}

# Nettoyage erreurs
$error.clear()
$ErrorActionPreference = 'SilentlyContinue'

Write-Log "====== Détection de compatibilité pour Windows 11 24H2 - $(Get-Date -Format 'yyyy/MM/dd') ======"

# Nom machine
$ComputerName = $env:COMPUTERNAME
Write-Log "Machine : $ComputerName"

# Vérifier version actuelle
$OSBuild = ([System.Environment]::OSVersion.Version).Build
Write-Log "Build de l’OS détectée : $OSBuild"

if (-not $OSBuild) {
    Write-Log "Échec de récupération du numéro de build."
    Exit 1
}

if ($OSBuild -ge $MinOSBuildFor24H2) {
    Write-Log "✅ Système déjà en Windows 11 24H2 ou supérieur. Aucune action nécessaire."
    Exit 0
}

# Vérification espace disque
$drive = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
$FreeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
Write-Log "Espace disque libre sur C: $FreeSpaceGB Go"

# TPM
$tpmVersion = $null
try {
    $tpmData = tpmtool getdeviceinformation
    $tpmVersion = ($tpmData | Where-Object { $_ -match "TPM Version" }) -replace ".*TPM Version:\s*", ""
    Write-Log "Version TPM détectée : $tpmVersion"
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

# CPU
$cpu = Get-WmiObject Win32_Processor
$Is64Bit = $cpu.Architecture -eq 9
Write-Log "Architecture processeur : $($cpu.Architecture) (64 bits requis = 9)"

# RAM
$ramOK = (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory -ge 4GB
Write-Log "RAM suffisante (≥ 4 Go) : $ramOK"

# === DEBUG Section – Diagnostic Affiché en Console ===
Write-Host "`n======================= Résumé Compatibilité ======================="
Write-Host "TPM Version >= 2.0 : " ($tpmVersion -ge "2.0")
Write-Host "Secure Boot activé : " $SecureBootEnabled
Write-Host "Architecture 64 bits : " $Is64Bit
Write-Host "RAM ≥ 4 Go : " $ramOK
Write-Host "Espace disque ≥ $RequiredDiskSpaceGB Go : " ($FreeSpaceGB -ge $RequiredDiskSpaceGB)
Write-Host "====================================================================`n"
# =====================================================

# CONDITIONS DE MISE À NIVEAU
if (
    $tpmVersion -ge "2.0" -and
    $SecureBootEnabled -eq $true -and
    $Is64Bit -and
    $ramOK -and
    $FreeSpaceGB -ge $RequiredDiskSpaceGB
) {
    Write-Log "✅ Machine compatible avec Windows 11 24H2. Déclenchement de la remédiation."
    Exit 1  # Intune : remédiation nécessaire
} else {
    Write-Log "❌ Machine non compatible avec Windows 11 24H2. Mise à niveau bloquée."
    Exit 0  # Intune : ne rien faire
}



TPM Version = 2.0 :       False
Secure Boot activé :      False
Architecture 64 bits :    True
RAM ≥ 4 Go :              True
Espace disque ≥ 45 Go :  True






--------------------------------
# SYNOPSIS
# Détection proactive de l’éligibilité à la mise à niveau vers Windows 11 24H2

# DESCRIPTION
# Vérifie la compatibilité matérielle et logicielle avant mise à niveau via Intune ou localement

# NOTES
# Version :         V1.4
# Auteur :          Marzouk Larbi / ChatGPT
# Date :            5 Juillet 2025

#======================== Configuration ===========================
$RequiredDiskSpaceGB = 45
$MinOSBuildFor24H2 = 26100
#==================================================================

# Initialisation du log
$LogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Detection_Upgrade_Win11_24H2.log"
Function Write-Log {
    param([string]$Message)
    $timestamp = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    $timestamp | Out-File -FilePath $LogPath -Append
    Write-Host $timestamp
}

# Nettoyage erreurs
$error.clear()
$ErrorActionPreference = 'SilentlyContinue'

Write-Log "====== Détection de compatibilité pour Windows 11 24H2 - $(Get-Date -Format 'yyyy/MM/dd') ======"

# Nom machine
$ComputerName = $env:COMPUTERNAME
Write-Log "Machine : $ComputerName"

# Vérifier version actuelle
$OSBuild = ([System.Environment]::OSVersion.Version).Build
Write-Log "Build de l’OS détectée : $OSBuild"

if (-not $OSBuild) {
    Write-Log "Échec de récupération du numéro de build."
    Exit 1
}

if ($OSBuild -ge $MinOSBuildFor24H2) {
    Write-Log "✅ Système déjà en Windows 11 24H2 ou supérieur. Aucune action nécessaire."
    Exit 0
}

# Vérification espace disque
$drive = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
$FreeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
Write-Log "Espace disque libre sur C: $FreeSpaceGB Go"

# TPM (via WMI)
$tpmVersion = $null
try {
    $tpmInfo = Get-WmiObject -Namespace "Root\CIMV2\Security\MicrosoftTpm" -Class Win32_Tpm
    if ($tpmInfo.SpecVersion -match "2\.0") {
        $tpmVersion = "2.0"
        Write-Log "TPM version 2.0 détectée via WMI. OK"
    } else {
        Write-Log "Version TPM non conforme : $($tpmInfo.SpecVersion)"
    }
} catch {
    Write-Log "Erreur lors de la détection TPM via WMI."
}

# Secure Boot
$SecureBootEnabled = $false
try {
    $SecureBootEnabled = Confirm-SecureBootUEFI
    Write-Log "Secure Boot activé : $SecureBootEnabled"
} catch {
    Write-Log "Secure Boot non disponible ou BIOS non UEFI."
}

# CPU
$cpu = Get-WmiObject Win32_Processor
$Is64Bit = $cpu.Architecture -eq 9
Write-Log "Architecture processeur : $($cpu.Architecture) (64 bits requis = 9)"

# RAM
$ramOK = (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory -ge 4GB
Write-Log "RAM suffisante (≥ 4 Go) : $ramOK"

# === Résumé DEBUG Affiché à l’écran ===
Write-Host "`n======================= Résumé Compatibilité ======================="
Write-Host "TPM Version = 2.0 :      " ($tpmVersion -eq "2.0")
Write-Host "Secure Boot activé :     " $SecureBootEnabled
Write-Host "Architecture 64 bits :   " $Is64Bit
Write-Host "RAM ≥ 4 Go :             " $ramOK
Write-Host "Espace disque ≥ $RequiredDiskSpaceGB Go : " ($FreeSpaceGB -ge $RequiredDiskSpaceGB)
Write-Host "====================================================================`n"

# CONDITIONS DE MISE À NIVEAU
if (
    $tpmVersion -eq "2.0" -and
    $SecureBootEnabled -eq $true -and
    $Is64Bit -and
    $ramOK -and
    $FreeSpaceGB -ge $RequiredDiskSpaceGB
) {
    Write-Log "✅ Machine compatible avec Windows 11 24H2. Déclenchement de la remédiation."
    Exit 1  # Intune : remédiation nécessaire
} else {
    Write-Log "❌ Machine non compatible avec Windows 11 24H2. Mise à niveau bloquée."
    Exit 0  # Intune : ne rien faire
}




select 
    SMS_R_SYSTEM.Name, 
    SMS_G_System_OPERATING_SYSTEM.Caption,
    SMS_G_System_OPERATING_SYSTEM.BuildNumber,
    SMS_G_System_OPERATING_SYSTEM.TotalVisibleMemorySize,
    SMS_G_System_COMPUTER_SYSTEM.SystemType,
    SMS_G_System_FIRMWARE.SecureBoot,
    SMS_G_System_TPM.SpecVersion
from SMS_R_System 
inner join SMS_G_System_COMPUTER_SYSTEM on SMS_G_System_COMPUTER_SYSTEM.ResourceID = SMS_R_System.ResourceID 
inner join SMS_G_System_FIRMWARE on SMS_G_System_FIRMWARE.ResourceID = SMS_R_System.ResourceID 
inner join SMS_G_System_TPM on SMS_G_System_TPM.ResourceID = SMS_R_System.ResourceID 
inner join SMS_G_System_OPERATING_SYSTEM on SMS_G_System_OPERATING_SYSTEM.ResourceID = SMS_R_System.ResourceID 
where 
    SMS_G_System_COMPUTER_SYSTEM.SystemType = 'x64-based PC' 
    and SMS_G_System_FIRMWARE.SecureBoot = 1 
    and SMS_G_System_TPM.SpecVersion like '2.0%' 
    and SMS_G_System_OPERATING_SYSTEM.TotalVisibleMemorySize >= 4000000 
    and SMS_G_System_OPERATING_SYSTEM.BuildNumber < 26100


