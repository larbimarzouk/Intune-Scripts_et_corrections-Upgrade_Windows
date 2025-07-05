# SYNOPSIS
# Mise à niveau vers Windows 11 24H2 depuis Windows 10 en utilisant Intune et la Remédiation Proactive.

# DESCRIPTION: Mise à niveau vers Windows 11 24H2 depuis Windows 10 en utilisant Intune et la Remédiation Proactive.

# NOTES
# Version :         V1.0  
# Auteur :          Marzouk Larbi
# Date de création : 4 Juillet 2025

# Mise à jour
# v1.1 ---> Correction de l’identification de la bonne version de build de l’OS

#========================Section de saisie utilisateur========

$DiskSpace = "45"  # Espace disque requis en Go

#==================================================

$error.clear() ## Réinitialisation de l’historique des erreurs
clear
#Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Force
$ErrorActionPreference = 'SilentlyContinue'  # Ignorer les erreurs

# Initialisation de la journalisation
$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Upgrade_To_Win11_24H2.log"         
Function Write-Log {
    Param([string]$Message)
    "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) - $Message" | Out-File -FilePath $LogPath  -Append
}
Write-Log "====================== Mise à niveau de Windows 10 vers Windows 11 24H2 via Intune avec script de détection proactive $(Get-Date -Format 'yyyy/MM/dd') ==================="

$HostName = hostname

# Vérifie si l’ESP (Enrollment Status Page) est en cours d’exécution
$ESP = Get-Process -ProcessName CloudExperienceHostBroker -ErrorAction SilentlyContinue
If ($ESP) {
    Write-Log "ESP Windows Autopilot en cours d'exécution"
    Exit 1 
}
Else {
    Write-Log "ESP Windows Autopilot non en cours d'exécution"
}

Write-Log "Vérification de la machine : $HostName - Version de l'OS"
$OSBuild = ([System.Environment]::OSVersion.Version).Build

IF (!($OSBuild)) {
    Write-Log "Impossible de trouver les informations de build"
    Exit 1
} else {
    Write-Log "Machine : $HostName - Version de l'OS : $OSBuild"
}

# Récupération de la date de dernière vérification des mises à jour
$CheckForUpdateA = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-WindowsUpdateClient/Operational'
}
$TopA = $CheckForUpdateA | Select-Object -First 1
Write-Log "Dernière vérification de mise à jour : $($TopA.TimeCreated)"

# Vérification de l’installation de l’outil "PC Health Check"
$AppName = "Windows PC Health Check"
$App = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq $AppName } 

if ($App.IdentifyingNumber -eq $null) {
    Write-Log "L'application '$AppName' n'est pas installée"
} else {
    Write-Log "L'application '$AppName' est déjà installée"
}

Write-Log "Vérification si le système respecte les exigences matérielles de Windows 11..."

# Vérification de la version du TPM
$tpmInfo = tpmtool getdeviceinformation
$tpmVersion = ($tpmInfo | Where-Object { $_ -match "TPM Version" }) -replace ".*TPM Version:\s*", ""
if ($tpmVersion) {
    if ($tpmVersion -ge "2.0") {
        Write-Log "TPM version 2.0 détecté. OK"
    } else {
        Write-Log "Version TPM inférieure à 2.0 — requis pour Windows 11."
    }
} else {
    Write-Log "Aucun TPM détecté sur ce système."
}

# Vérification de l’activation du Secure Boot
$firmwareInfo = Confirm-SecureBootUEFI
if ($firmwareInfo -eq "True") {
    Write-Log "Secure Boot est activé. OK"
} else {
    Write-Log "Secure Boot est désactivé — requis pour Windows 11."
}

# Vérification de l’architecture du processeur
$cpuInfo = Get-WmiObject -Class Win32_Processor
if ($cpuInfo) {
    if ($cpuInfo.Architecture -eq 9) {
        Write-Log "Processeur 64 bits détecté. OK"
    } else {
        Write-Log "Processeur non 64 bits — Windows 11 nécessite un CPU 64 bits."
    }
}

# Vérification de la mémoire RAM
$systemSpecs = Get-WmiObject -Class Win32_ComputerSystem
if ($systemSpecs.TotalPhysicalMemory -ge 4GB) {
    Write-Log "Le système dispose de 4 Go de RAM ou plus. OK"
} else {
    Write-Log "Mémoire RAM inférieure à 4 Go — insuffisante pour Windows 11."
}

# Vérification de l’espace disque disponible
$localDrives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
$availableSpaceGB = [math]::round($localDrives.FreeSpace / 1GB, 2)
if ($availableSpaceGB -ge $DiskSpace) {
    Write-Log "Espace disque disponible : au moins $DiskSpace Go. OK"
} else {
    Write-Log "Espace disque insuffisant — Windows 11 nécessite au moins $DiskSpace Go."
}

# Vérifie si le système n'est pas déjà en Windows 11 24H2 et s’il respecte les exigences matérielles
if ($OSBuild -lt 26100 -and `
    $tpmVersion -ge "2.0" -and `
    $firmwareInfo -eq "true" -and `
    $cpuInfo.Architecture -eq 9 -and `
    $systemSpecs.TotalPhysicalMemory -ge 4GB -and `
    $availableSpaceGB -ge $DiskSpace) 
{
    ## Ajout d’une clé registre pour ignorer l’état de l’outil PC Health Check
    Write-Log "Configuration du registre pour ignorer l'outil 'PC Health Check' lors de la vérification d'éligibilité"
    
    # Définir le chemin du registre
    $regPath = "HKCU:\Software\Microsoft\PCHC"

    # Créer la clé si elle n’existe pas
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }

    # Définir la valeur DWORD
    Set-ItemProperty -Path $regPath -Name "UpgradeEligibility" -Value 1 -Type DWord

    # Confirmation de la modification
    $Reg = Get-ItemProperty -Path $regPath | Select-Object UpgradeEligibility
    Write-Log "Préparation du périphérique à la mise à niveau vers Windows 11 : entrée registre créée pour ignorer la vérification d’éligibilité via l’outil 'PC Health Check' (HKCU:\Software\Microsoft\PCHC, valeur UpgradeEligibility=1)"

    Write-Log "Le système n’est pas encore en Windows 11 24H2 et remplit les exigences matérielles. Déclenchement de la remédiation proactive..."
    Write-Host "Le système n’est pas encore en Windows 11 24H2 et remplit les exigences matérielles. Déclenchement de la remédiation proactive..."
    Exit -1
}
elseif ($OSBuild -lt 26100) {
    Write-Log "Le système n’est pas en Windows 11 24H2 mais ne remplit pas les exigences matérielles. Mise à niveau ignorée."
    Write-Host "Le système n’est pas en Windows 11 24H2 mais ne remplit pas les exigences matérielles. Mise à niveau ignorée."
    Exit 0
}
else {
    Write-Log "Le système est déjà en Windows 11 24H2. Aucune remédiation nécessaire."
    Write-Host "Le système est déjà en Windows 11 24H2. Aucune remédiation nécessaire."
    Exit 0
}
