
$services="haproxy.service sshd.service"
$server="172.24.0.26"
$user="certsync"

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

if ( -Not (Test-Path -Path $scriptPath\domains.conf -PathType Leaf )) {
    Write-Host "File '$scriptPath\domains.conf' not found. Creating it."
    Out-File -FilePath $scriptPath\domains.conf
}

$domains = Get-Content $scriptPath\domains.conf
$certchanged = 0
$domains | ForEach-Object {
    $remotehome = ssh -i c:\opt\bs4it\ssh\certsync_id_ed25519 $user@$server printenv HOME
    $src_sha256 = ssh -i c:\opt\bs4it\ssh\certsync_id_ed25519 $user@$server sha256sum $remotehome/certs/$_/cert_combined.pfx
    $tgt_sha256 = ((Get-FileHash -Algorithm SHA256 -Path $scriptPath\..\certs\$_\cert_combined.pfx).Hash).Tolower()
    if ( $tgt_sha256 -ne $src_sha256 ) {
        Write-Host "Cert for $domain has changed."
        $certchanged = 1
        New-Item -ItemType Directory $scriptPath\..\certs\$_
        scp certsync@${server}:${remotehome}/certs/$domain/cert_combined.pfx $scriptPath\..\certs\$_\cert_combined.pfx
    }
}

# if ( $certchanged -eq 1 ) {
#     Write-Host "Deploy Cerificate..."
#     for service in $services;
#     do
#     echo Issuing restart command to $service
#     /usr/bin/systemctl restart $service
#     done
# }
  
