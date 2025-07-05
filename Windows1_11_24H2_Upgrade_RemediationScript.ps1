# SYNOPSIS  
# Mise à niveau vers Windows 11 24H2 depuis Windows 10 en utilisant Intune et la remédiation proactive.

# DESCRIPTION : Mise à niveau vers Windows 11 24H2 depuis Windows 10 en utilisant Intune et la remédiation proactive.


# NOTES  
# Version : V1.0  
#Auteur :          Marzouk Larbi
# Date de création : 4 Juillet 2025


$error.clear() ## ceci efface l’historique des erreurs  
clear

# Définir la stratégie d'exécution PowerShell pour ignorer les restrictions  
Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -force

# Définir l’action par défaut sur les erreurs  
$ErrorActionPreference = 'SilentlyContinue'

# Initialiser la journalisation  
$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Upgrade_To_Win11_24H2.log"         
Function Write-Log {
...
}

Write-Log "====================== Mise à niveau de Windows 10 vers Windows 11 24H2 à l'aide du script de remédiation proactive Intune ==================="

# Vérifier si l'expérience de configuration (ESP) est en cours  
#Write-Host "L'ESP de Windows Autopilot est en cours d'exécution"
#Write-Host "L'ESP de Windows Autopilot n'est pas en cours d'exécution"

# Vérifier la version de Windows de la machine  
Write-Log "Vérification de la version du système d'exploitation de la machine"

# Récupérer le dernier redémarrage  
Write-Log "Dernier redémarrage de la machine"

# Obtenir l'espace total et libre sur le disque C: en Go  
Write-Log "Espace total du disque C: de la machine"
Write-Log "Espace libre du disque C: de la machine"

# Vérification du service Windows Update  
# Vérification du type de démarrage du service Windows Update

# Vérification du service Microsoft Account Sign-in Assistant  
# Vérification du type de démarrage du service Microsoft Account Sign-in Assistant

# Vérification du service Update Orchestrator  
# Vérification du type de démarrage du service Update Orchestrator

Function Get-LatestWindowsUpdateInfo {
    # Récupérer le numéro de build actuel
    # Choisir l'URL de l'historique des mises à jour en fonction de l'OS (Windows 10 ou 11)
    # Obtenir le contenu de la page
    # Filtrer tous les liens vers des KB
    # Obtenir la dernière mise à jour pertinente
}

# Si vous souhaitez redémarrer les services, retirez le # devant ces lignes
#Restart-Service -Name wlidsvc -Force
#Restart-Service -Name uhssvc -Force
#Restart-Service -Name wuauserv -Force

# Exécuter et afficher le résultat

Write-Log "Dernière mise à jour de sécurité Patch Tuesday KB :"
Write-Log "URL d'information sur la dernière mise à jour KB :"
Write-Log "Titre et date de la dernière mise à jour KB de sécurité :"

# Vérifier s'il y a un redémarrage en attente à cause de Windows Update
Write-Log "Redémarrage en attente à cause de Windows Update. GUID :"
Write-Log "Redémarrer manuellement le système"
Write-Log "Aucun redémarrage nécessaire pour le patch Windows Update"

# Vérifier si le système est inférieur à la version 26100 (Windows 11 24H2)
Write-Log "Le système n'est pas en version 26100. Action requise."

# Vérifier si l'outil Windows PC Health Check est installé
Write-Log "Vérification de l'installation de l'outil Windows PC Health Check"

# Télécharger la dernière version de l'assistant de mise à niveau Windows 11
Write-Log "Téléchargement de la dernière version de l’assistant de mise à niveau Windows 11 (Win11_24H2)"

# Exécuter la mise à niveau en mode silencieux
Write-Log "Exécution de l'assistant de mise à niveau Windows 11 avec les options silencieuses et sans redémarrage"

Write-Log "Le processus de mise à niveau vers Win11 24H2 est en cours d’exécution..."

# Attendre que le processus se termine
Write-Log "Le processus de mise à niveau vers Win11 24H2 est toujours en cours..."
Write-Log "La mise à niveau vers Win11 24H2 est terminée"

# Supprimer les dossiers de travail
Write-Log "Suppression du dossier $DownloadDir"
Write-Log "$DownloadDir supprimé"
Write-Host "Mise à niveau terminée. Une action utilisateur est requise pour redémarrer l'appareil"
Write-Log "Mise à niveau terminée. Une action utilisateur est requise pour redémarrer l'appareil"

# Si déjà en 24H2
Write-Log 'Le système est déjà sur Windows 11 24H2. Mise à niveau non nécessaire.'
Write-Host 'Le système est déjà sur Windows 11 24H2. Mise à niveau non nécessaire.'
