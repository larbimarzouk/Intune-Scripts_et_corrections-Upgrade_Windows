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


$error.clear() ## ceci est l'historique clair des erreurs 
clear
Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -force
$ErrorActionPreference = 'SilentlyContinue'

# Initialiser la journalisation
$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Upgrade_To_Win11_24H2.log"         
Function Write-Log {
    Param([string]$Message)
    "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) - $Message" | Out-File -FilePath $LogPath  -Append
}
Write-Log "====================== Mise à niveau de Windows vers Windows 11 24H2 à l'aide du script de correction proactive Intune $(Get-Date -Format 'yyyy/MM/dd') ==================="

$HostName = hostname
# Vérifiez si ESP est en cours d'exécution
$ESP = Get-Process -ProcessName CloudExperienceHostBroker -ErrorAction SilentlyContinue
If ($ESP) {
    #Write-Host "Windows Autopilot ESP en cours d'exécution"
    Write-Log "Pilote automatique Windows ESP en cours d'exécution"
    Exit 1 
     }
Else {
    #Write-Host « Windows Autopilot ESP ne fonctionne pas"
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

$OSInfo = Get-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion'
$DevicesInfos ="$($OSInfo.CurrentMajorVersionNumber).$($OSInfo.CurrentMinorVersionNumber).$($OSInfo.CurrentBuild).$($OSInfo.UBR)"
Write-Log "OS Build version $DevicesInfos"

# Obtenir l'heure du dernier redémarrage
$LastReboot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
Write-Log "Machine Last Reboot Time: $LastReboot"

# Obtenez l'espace total et libre sur le lecteur C: en Go
$Disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$TotalSpaceGB = [math]::round($Disk.Size / 1GB, 2)
$FreeSpaceGB = [math]::round($Disk.FreeSpace / 1GB, 2)

Write-Log "Machine Total C: Espace disque : $TotalSpaceGB Go"
Write-Log "Espace disque libre sur la machine C: : $FreeSpaceGB Go"



# Vérification de Windows Update
$ServiceName = 'wuauserv'
$ServiceType = (Get-Service -Name $ServiceName).StartType
Write-Log "Windows Update Service startup type is '$ServiceType'"
if ([string]$ServiceType -ne 'Manual') {
    Write-Log "Startup type for Windows Update is not Manual. Consider setting it to Manual." "WARNING"
    # Set-Service -Name $ServiceName -StartupType Manuel
}

# Checking Microsoft Account Sign-in Assistant Service
$ServiceName = 'wlidsvc'
$ServiceType = (Get-Service -Name $ServiceName).StartType
Write-Log "Microsoft Account Sign-in Assistant Service startup type is '$ServiceType'"
if ([string]$ServiceType -ne 'Manual') {
    Write-Log "Startup type for Microsoft Account Sign-in Assistant is not Manual. Consider setting it to Manual." "WARNING"
    # Set-Service -Name $ServiceName -StartupType Manual
}

# Checking Update Orchestrator Service
$ServiceName = 'UsoSvc'
$ServiceType = (Get-Service -Name $ServiceName).StartType
if ($ServiceType) {
    Write-Log "Update Orchestrator Service startup type is '$ServiceType'"
    if ([string]$ServiceType -ne 'Automatic') {
        Write-Log "Startup type for Update Orchestrator Service is not Automatic. Consider setting it to Automatic." "WARNING"
        # Set-Service -Name $ServiceName -StartupType Automatic
    }
    }

Function Get-LatestWindowsUpdateInfo {
    # Get the current build number
    $currentBuild = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuild
    $osBuildMajor = $currentBuild.Substring(0, 1)

    # Décidez quelle URL d'historique de mise à jour utiliser en fonction du système d'exploitation de l'appareil Win10 ou Win11
    $updateUrl = if ($osBuildMajor -eq "2") {
        "https://aka.ms/Windows11UpdateHistory"
    } else {
        "https://support.microsoft.com/en-us/help/4043454"
    }

    # Obtenir le contenu de la page
    $response = if ($PSVersionTable.PSVersion.Major -ge 6) {
        Invoke-WebRequest -Uri $updateUrl -ErrorAction Stop
    } else {
        Invoke-WebRequest -Uri $updateUrl -UseBasicParsing -ErrorAction Stop
    }

    # Filter all KB links
    $updateLinks = $response.Links | Where-Object {
        $_.outerHTML -match "supLeftNavLink" -and
        $_.outerHTML -match "KB" -and
        $_.outerHTML -notmatch "Preview" -and
        $_.outerHTML -notmatch "Out-of-band"
    }

    # Get the latest relevant update
    $latest = $updateLinks | Where-Object {
        $_.outerHTML -match $currentBuild
    } | Select-Object -First 1

    if ($latest) {
        $title = $latest.outerHTML.Split('>')[1].Replace('</a','').Replace('&#x2014;', ' - ')
        $kbId  = "KB" + $latest.href.Split('/')[-1]

        [PSCustomObject]@{
            LatestUpdate_Title = $title
            LatestUpdate_KB    = $kbId
        }
    } else {
        Write-log "No update found for current build."
        
    }
}
    
#Si vous souhaitez redémarrer le service, supprimez # de ces commandes
#Restart-Service -Name wlidsvc -Force
#Restart-Service -Name uhssvc -Force
#Restart-Service -Name wuauserv -Force

# Run and show the result
$latestUpdateInfo = Get-LatestWindowsUpdateInfo
$LastHotFix = $latestUpdateInfo.LatestUpdate_KB
$LastPatchDate = $hotfix.InstalledOn
$KB = $LastHotFix-replace "^KB", ""
$InfoURL = "https://support.microsoft.com/en-us/help/$KB"
Write-Log "Dernière mise à jour de sécurité du Patch Tuesday : numéro de la base de connaissances : $($latestUpdateInfo.LatestUpdate_KB)"
Write-Log "URL d'informations de la base de connaissances sur la dernière mise à jour de sécurité : $InfoURL"
Write-Log "Titre et date de la dernière mise à jour de sécurité de la base de connaissances : $($latestUpdateInfo.LatestUpdate_Title)"
rebootRequiredKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
    if (Test-Path $rebootRequiredKey) {
    $rebootGuid = Get-ItemProperty -Path $rebootRequiredKey 
    $guidOnly = ($rebootGuid | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }) | Where-Object { $_ -match '^[a-f0-9\-]{36}$' }
    if ($rebootGuid)
    
     { Write-Log "Redémarrage de Windows Update en attente par rapport à.GUID : $guidOnly"
       Write-Log "Redémarrer manuellement le système"
     } 
     else { Write-Log "Aucun correctif de mise à jour Windows, redémarrage requis."}
     }

#https://download.microsoft.com/download/6/8/3/683178b7-baac-4b0d-95be-065a945aadee/Windows11InstallationAssistant.exe

$OSVersion = (Get-WMIObject win32_operatingsystem).buildnumber

if ($OSVersion -lt 26100) {
 Write-Log "System is not on Win11 26100 version.Action Required."
   
    Write-Log "Checking Windows PC Health Check installation status"
    $DownloadDir = "C:\windows\temp\Upgrade_Win11_24H2"
    New-Item -ItemType Directory -Path $DownloadDir
	
    #Checking Windows PC Health Check installation status
    $AppName = "Bilan de santé du PC Windows"

    $App = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq $AppName } 

    if ($App.IdentifyingNumber -eq $null)
     {
    Write-Log "'$AppName' application non installée"
     
      }
     else
     {
    Write-Log "'$AppName' application déjà installée"
     }

        
      #Téléchargez le dernier assistant de mise à niveau de Windows 11
    Write-Log "Téléchargement du dernier assistant de mise à niveau vers Windows 11 (Win11_24H2)."
     
    $Url = "https://download.microsoft.com/download/6/8/3/683178b7-baac-4b0d-95be-065a945aadee/Windows11InstallationAssistant.exe"
    
    $UpdaterBinary = "$($DownloadDir)\Windows11InstallationAssistant.exe"
    
    [System.Net.WebClient]$webClient = New-Object System.Net.WebClient
      
    
    if (Test-Path $UpdaterBinary) {
    
        Remove-Item -Path $UpdaterBinary -Force
    }
    
    Write-Log "Windows 11 Installation Assistant.exe téléchargé et enregistré dans $UpdaterBinary"
    
    $webClient.DownloadFile($Url, $UpdaterBinary)

    # exécuter la mise à jour en mode silencieux. 
    #$UpdaterArguments = '/quietinstall /skipeula /auto upgrade'
    #$UpdaterArguments = '/skipeula /auto upgrade'
    $UpdaterArguments = '/quietinstall /skipeula /auto upgrade'
      

    # $UpdaterArguments = "$updaterbinary /skipeula /auto upgrade"
    Write-Log "Exécution de Windows 11 Installation Assistant.exe avec commutateur silencieux et suppression du redémarrage"

    Start-Process -FilePath C:\windows\temp\Upgrade_Win11_24H2\Windows11InstallationAssistant.exe -ArgumentList $UpdaterArguments
    # -Patientez
    Start-Sleep -Seconds 30
    $process = Get-Process -Name "Application de mise à niveau Windows" -ErrorAction SilentlyContinue


       if ($process) {
        Write-Log "Le processus de mise à niveau de Win11 24H2 est en cours d'exécution..."

        # -Patientez pendant que le processus est en cours d'exécution
        while (Get-Process -Name "Application de mise à niveau Windows" -ErrorAction SilentlyContinue) {
        Write-Log "Le processus de mise à niveau de Win11 24H2 est toujours en cours..."
        Start-Sleep -Seconds 30
        }
        
        Write-Log "Mise à niveau vers Win11 24H2 terminée"

        # Suppression des dossiers de travail
        Write-Log "Suppression du dossier $DownloadDir" 
        Remove-Item -Path $DownloadDir -Recurse -Force 
        Write-Log "$DownloadDir folder Removed" 
        Write-Host "Mise à niveau terminée. Une intervention de l'utilisateur est nécessaire pour redémarrer l'appareil."   
        Write-Log "Mise à niveau terminée. Une intervention de l'utilisateur est nécessaire pour redémarrer l'appareil."   
        Exit 0

    

        } 
       }
Else 
       {
        Write-Log 'Le système est déjà sous Windows 11 24H2. Mise à niveau ignorée'
        Write-Host 'Le système est déjà sous Windows 11 24H2. Mise à niveau ignorée'
        Exit 0
         }
