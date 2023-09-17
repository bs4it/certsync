
$services="haproxy.service sshd.service"
$server="172.24.0.3"
$user="certsync"

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

if ( -Not (Test-Path -Path $scriptPath\domains.conf -PathType Leaf )) {
    Write-Host "File '$scriptPath\domains.conf' not found. Creating it."
    Out-File -FilePath $scriptPath\domains.conf
}

$domains = Get-Content $scriptPath\domains.conf
$certchanged = 0
Import-Module Webadministration
$domains | ForEach-Object {
    $domain = $_
    $remotehome = ssh -i $scriptPath\..\ssh\certsync_id_ed25519 $user@$server printenv HOME
    $src_sha256 = ssh -i $scriptPath\..\ssh\certsync_id_ed25519 $user@$server "sha256sum $remotehome/certs/$_/cert_combined.pfx | cut -d ' ' -f 1"
    $tgt_sha256 = Get-FileHash -ErrorAction SilentlyContinue -Algorithm SHA256 -Path $scriptPath\..\certs\$_\cert_combined.pfx
    if ( $tgt_sha256 -eq $null ){
        $tgt_sha256 = 1
    } else {
        $tgt_sha256 = ($tgt_sha256.Hash).Tolower()
    }
    
    if ( $tgt_sha256 -ne $src_sha256 ) {
        Write-Host "Cert for $_ has changed."
        $certchanged = 1
        New-Item -Force -ItemType Directory $scriptPath\..\certs\$_ | Out-Null
        scp -i $scriptPath\..\ssh\certsync_id_ed25519 certsync@${server}:${remotehome}/certs/$_/cert_combined.pfx $scriptPath\..\certs\$_\cert_combined.pfx
        Write-Host "Removing old cert for " $domain
        Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -match $domain } | Remove-Item
        Write-Host "Deploying new cert for " $domain
        $NewCert = Import-PfxCertificate -FilePath $scriptPath\..\certs\$_\cert_combined.pfx -Password ( ConvertTo-SecureString "imp0rtp455" -AsPlainText -Force ) -CertStoreLocation Cert:\LocalMachine\My
        $site = Get-ChildItem -Path "IIS:\Sites" | Where-Object {( $_.Name -eq "Veeam Availability Console Web UI" )}
        $binding = $site.Bindings.Collection | Where-Object {( $_.protocol -eq 'https' -and $_.bindingInformation -match ':443:')}
        $binding.AddSslCertificate($NewCert.Thumbprint, "my")


    }
}
