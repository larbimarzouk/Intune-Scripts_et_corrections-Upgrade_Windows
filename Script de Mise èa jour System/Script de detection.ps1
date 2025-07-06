# SYNOPSIS
# Upgrade to Windows 11 24H2 from Windows 10 using Intune and Proactive Remediation.

# DESCRIPTION
# Upgrade to Windows 11 24H2 from Windows 10 using Intune and Proactive Remediation.

# Version:         V1.0  
# Author:          Marzouk Larbi
# Creation Date:   4 Juillet 2025

# Find the author on: 
# Update
# v1.1 ---> Fixed to find the correct os build version  

#========================User Input Section========

$DiskSpace = "64"

#==================================================


$error.clear() ## c'est l'historique clair des erreurs
clear
#Définir-Politique d'exécution -Politique d'exécution 'ByPass' -Force
$ErrorActionPreference = 'SilentlyContinue'

# Initialiser la journalisation
$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Upgrade_To_Win11_24H2.log"         
Function Write-Log {
    Param([string]$Message)
    "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) - $Message" | Out-File -FilePath $LogPath  -Append
}
Write-Log "====================== Mise à niveau de Windows 10 vers Windows 11 24H2 à l'aide du script de détection proactive Intune $(Get-Date -Format 'yyyy/MM/dd') ==================="

$HostName = hostname
# Vérifiez si ESP est en cours d'exécution
$ESP = Get-Process -ProcessName CloudExperienceHostBroker -ErrorAction SilentlyContinue
If ($ESP) {
    ##Write-Host "Windows Autopilot ESP en cours d'exécution"
    Write-Log "Pilote automatique Windows ESP en cours d'exécution"
    Exit 1 
     }
Else {
    #Write-Host "Windows Autopilot ESP ne fonctionne pas"
    Write-Log "Windows Autopilot ESP ne fonctionne pas"
    
     }

Write-Log "Vérification de la machine : $HostName Version du système d'exploitation"
$OSBuild = ([System.Environment]::OSVersion.Version).Build

IF (!($OSBuild)) {
    Write-Log 'Impossible de trouver les informations de build'
    Exit 1
} else{
    Write-Log "Machine : $HostName La version du système d'exploitation est $OSBuild"
}
$CheckForUpdateA = Get-WinEvent -FilterHashtable @{
    LogName   = 'Microsoft-Windows-WindowsUpdateClient/Operational'
 }
$TopA = $CheckForUpdateA | Select-Object -First 1

Write-Log "La date et l'heure de la dernière vérification de mise à jour sont : $($TopA.TimeCreated)"

#Vérification de l'état d'installation du contrôle de santé du PC Windows

$AppName = "Windows PC Health Check"

$App = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq $AppName } 

if ($App.IdentifyingNumber -eq $null)
{
    Write-Log "L'application « $AppName » n'est pas installée"
}
else
{
    Write-Log "L'application « $AppName » est déjà installée"
}

Write-Log "Vérification si le système répond aux exigences matérielles de Windows 11..."

# Vérifier la version TPM
$tpmInfo = tpmtool getdeviceinformation
$tpmVersion = ($tpmInfo | Where-Object { $_ -match "TPM Version" }) -replace ".*TPM Version:\s*", ""
if ($tpmVersion) {
    if ($tpmVersion -ge "2.0") {
        Write-Log "La version 2.0 du TPM est présente.OK"
    } else {
        Write-Log "La version TPM est inférieure à 2.0 — requise pour Windows 11."
        
    }
} else {
    Write-Log "Aucun TPM détecté sur ce système."
    
}

# Vérifier le démarrage sécurisé
$firmwareInfo = Confirm-SecureBootUEFI

if ($firmwareInfo -eq "True") {
    Write-Log "Le démarrage sécurisé est activé.OK"
} else {
    Write-Log "Le démarrage sécurisé est désactivé — il s’agit d’une exigence de Windows 11."
    }

# Vérifier l'architecture du processeur
$cpuInfo = Get-WmiObject -Class Win32_Processor
if ($cpuInfo) {
    if ($cpuInfo.Architecture -eq 9) {
        Write-Log "Le processeur est 64 bits.OK."
    } else {
        Write-Log "Le processeur n’est pas 64 bits — Windows 11 a besoin d’un processeur 64 bits."
     }
}

# Vérifier la RAM
$systemSpecs = Get-WmiObject -Class Win32_ComputerSystem
if ($systemSpecs.TotalPhysicalMemory -ge 4GB) {
    Write-Log "Le système dispose de 4 Go ou plus de RAM.OK"
} else {
    Write-Log "La RAM est inférieure à 4 Go, ce qui n’est pas suffisant pour Windows 11."
 }

# Vérifier l'espace de stockage
$localDrives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
$availableSpaceGB = [math]::round($localDrives.FreeSpace / 1GB, 2)
if ($availableSpaceGB -ge $DiskSpace) {
    Write-Log "L'espace disque disponible est d'au moins $DiskSpace GB.OK"
} else {
    Write-Log "Espace disque insuffisant — Windows 11 nécessite un minimum de $Disk Space Go."
}


# Vérifiez si le système n'est pas sous Windows 11 24H2 et répond aux exigences matérielles
if ($OSBuild -lt 26100 -and `
    $tpmVersion -ge "2.0" -and `
    $firmwareInfo -eq "true" -and `
    $cpuInfo.Architecture -eq 9 -and `
    $systemSpecs.TotalPhysicalMemory -ge 4GB -and `
    $availableSpaceGB -ge $DiskSpace) 
{
# Paramétrer le registre pour ignorer l'état de vérification de l'état de santé du PC Windows
         Write-log "Paramétrer le registre pour ignorer l'outil « PC Health Check » pour vérifier l'état d'éligibilité à la mise à niveau"
         # Définir le chemin du registre
                $regPath = "HKCU:\Software\Microsoft\PCHC"

                    # Créer la clé si elle n'existe pas
                        if (-not (Test-Path $regPath)) {
                         New-Item -Path $regPath -Force | Out-Null
                            }

                            # Définir la valeur DWORD
                    Set-ItemProperty -Path $regPath -Name "UpgradeEligibility" -Value 1 -Type DWord

                    # Confirmer le changement
                    $Reg = Get-ItemProperty -Path $regPath | Select-Object UpgradeEligibility
                    Write-log "Préparez l'appareil pour une mise à niveau vers Windows 11 en créant une entrée de registre pour ignorer les vérifications d'éligibilité de l'outil 'PC Health Check'. Pour ce faire, créez le chemin de registre HKCU:\Software\Microsoft\PCHC et définissez la valeur UpgradeEligibility (DWORD) sur 1.."

    Write-Log "Le système n'est pas sous Windows 11 24H2 et répond aux exigences matérielles. Lancement de la correction proactive…"
    Write-Host "Le système n'est pas sous Windows 11 24H2 et répond aux exigences matérielles. Lancement de la correction proactive…"
    Exit -1
}
elseif ($OSBuild-lt 26100) {
    Write-Log "Le système n est pas équipé de Windows 11 24H2, mais ne répond pas aux exigences matérielles. Mise à niveau ignorée."
    Write-Host "Le système n est pas équipé de Windows 11 24H2, mais ne répond pas aux exigences matérielles. Mise à niveau ignorée.."
    Exit 0
}
else {
    Write-Log "Le système fonctionne déjà sous Windows 11 24H2. Aucune correction nécessaire."
    Write-Host "Le système fonctionne déjà sous Windows 11 24H2. Aucune correction nécessaire."
    Exit 0
}
