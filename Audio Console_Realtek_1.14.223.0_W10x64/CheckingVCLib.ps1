

# $TargetVCLib = $args[0]
$TargetVCLib = "Microsoft.VCLibs.140.00"
# $TargetVCLibVer = "14.0.26706.0"
$TargetVCLibVer = $args[1]
$TargetArchitecture = $args[2]
Write-Host "[PS1] Getting Current VCLib infomation `r"
$GetCurrentVCLib = Get-AppxPackage -AllUsers "$TargetVCLib" | Where-Object {$_.Architecture -eq "$TargetArchitecture"} | select Name, PackageFullName, version, Architecture
Write-Host ($GetCurrentVCLib | Format-Table | Out-String)
$CurrentVer = $GetCurrentVCLib.version
if ($CurrentVer -ge $TargetVCLibVer) {
    Write-Host ("[PS1] $CurrentVer Greater than or equal to $TargetVCLibVer, exitcode 5 `r")
	exit 5
} else {
    Write-Host ("[PS1] $CurrentVer not greater than or equal to $TargetVCLibVer, exitcode 9 `r")
	exit 9
}

