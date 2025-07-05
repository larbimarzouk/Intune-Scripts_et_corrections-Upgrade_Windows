# Détection : Vérifie si l'OS est Windows 11 24H2 (build 26100+)
$OSBuild = ([System.Environment]::OSVersion.Version).Build
if ($OSBuild -lt 26100) {
    exit 1  # Remédiation nécessaire
} else {
    exit 0  # Rien à faire
}


OperatingSystem
| join kind=inner (
    Firmware
    | where SecureBoot == 1
) on Device
| join kind=inner (
    TPM
    | where SpecVersion contains "2.0"
) on Device
| join kind=inner (
    ComputerSystem
    | where SystemType == "x64-based PC" and TotalPhysicalMemory >= 4294967296
) on Device
| where BuildNumber < 26100
| project Device, Caption, BuildNumber, TotalPhysicalMemory, SecureBoot, SpecVersion
