# Détection : Vérifie si l'OS est Windows 11 24H2 (build 26100+)
$OSBuild = ([System.Environment]::OSVersion.Version).Build
if ($OSBuild -lt 26100) {
    exit 1  # Remédiation nécessaire
} else {
    exit 0  # Rien à faire
}
