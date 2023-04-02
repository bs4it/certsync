
$services="haproxy.service sshd.service"
$server="172.24.0.26"
$user="certsync"

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

if ( -Not (Test-Path -Path $scriptPath\domains.conf -PathType Leaf )) {
    Write-Host "File '$scriptPath\domains.conf' not found. Creating it."
    Out-File -FilePath $scriptPath\domains.conf
}

$domains = Get-Content $scriptPath\domains.conf

$domains | ForEach-Object {
    $remotehome = ssh -i c:\opt\bs4it\ssh\certsync_id_ed25519 $user@$server printenv HOME
    $src_sha256 = ssh -i c:\opt\bs4it\ssh\certsync_id_ed25519 $user@$server cat $remotehome/certs/$domain/sha256sum
    $tgt_sha256 = ((Get-FileHash -Algorithm SHA256 -Path $scriptPath\..\certs\$_\cert_combined.pfx).Hash).Tolower()
    Write-Host $tgt_sha256
}
