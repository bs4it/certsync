$services="haproxy.service sshd.service"
$server="172.24.0.26"
$user="certsync"

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

if ( -Not (Test-Path -Path $scriptPath\domains.conf -PathType Leaf )) {
    Write-Host "File '$scriptPath\domains.conf' not found. Creating it."
    Out-File -FilePath $scriptPath\domains.conf
}

$domains = Get-Content $scriptPath\domains.conf