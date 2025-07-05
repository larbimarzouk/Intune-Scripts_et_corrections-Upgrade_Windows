# SYNOPSIS
# Mise à niveau vers Windows 11 24H2 à l'aide d'Intune et de la Remédiation Proactive.
# DESCRIPTION: Mise à niveau vers Windows 11 24H2 à l'aide d'Intune et de la Remédiation Proactive.
# NOTES
# Version :         V1.0  
# Auteur :          Marzouk Larbi
# Date de création : 4 juillet 2025
# Retrouvez l'auteur sur :
# Mise à jour
# v1.1 ---> Correction pour identifier correctement la version de build du système d’exploitation

#========================Section de saisie utilisateur========

$DiskSpace = "45"  # Espace disque requis en Go

#==================================================

$error.clear() ## ceci réinitialise l'historique des erreurs
clear
#Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Force
$ErrorActionPreference = 'SilentlyContinue'  # Ignore les erreurs silencieusement

# Initialiser la journalisation
$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Upgrade_To_Win11_24H2.log"         
Function Write-Log {
    Param([string]$Message)
    "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) - $Message" | Out-File -FilePath $LogPath  -Append
}
Write-Log "====================== Mise à niveau vers Windows 11 24H2 à l’aide du script de détection proactive Intune $(Get-Date -Format 'yyyy/MM/dd') ==================="

$HostName = hostname
# Vérifier si ESP (Enrollment Status Page) est en cours d'exécution
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
    Write-Log 'Impossible de trouver les informations de build'
    Exit 1
} else{
    Write-Log "Machine : $HostName - Version de l'OS : $OSBuild"
}

# Dernière vérification de mise à jour
$CheckForUpdateA = Get-WinEvent -FilterHashtable @{
    LogName   = 'Microsoft-Windows-WindowsUpdateClient/Operational'
 }
$TopA = $CheckForUpdateA | Select-Object -First 1

Write-Log "Date et heure de la dernière vérification des mises à jour : $($TopA.TimeCreated)"

# Vérifier l'installation de l'application "Windows PC Health Check"
$AppName = "Windows PC Health Check"

$App = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq $AppName } 

if ($App.IdentifyingNumber -eq $null)
{
    Write-Log "L'application '$AppName' n'est pas installée"
}
else
{
    Write-Log "L'application '$AppName' est déjà installée"
}

Write-Log "Vérification des exigences matérielles pour Windows 11..."

# Vérifier la version du TPM
$tpmInfo = tpmtool getdeviceinformation
$tpmVersion = ($tpmInfo | Where-Object { $_ -match "TPM Version" }) -replace ".*TPM Version:\s*", ""
if ($tpmVersion) {
    if ($tpmVersion -ge "2.0") {
        Write-Log "TPM version 2.
