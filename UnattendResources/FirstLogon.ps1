$ErrorActionPreference = "Stop"
$resourcesDir = "$ENV:SystemDrive\UnattendResources"

function getHypervisor() {
    $hypervisor = & "$resourcesDir\checkhypervisor.exe"

    if ($LastExitCode -eq 1) {
        Write-Host "No hypervisor detected."
    } else {
        return $hypervisor
    }
}


try
{
    $hypervisorStr = getHypervisor
    Write-Host "Hypervisor: $hypervisorStr"
    # TODO: Add XenServer / XCP
    switch($hypervisorStr)
    {
        "VMwareVMware"
        {
            # Note: this command will generate a reboot.
            # "/qn REBOOT=ReallySuppress" does not seem to work properly
            $Host.UI.RawUI.WindowTitle = "Installing VMware tools..."
            E:\setup64.exe `/s `/v `/qn `/l `"$ENV:Temp\vmware_tools_install.log`"
            if (!$?) { throw "VMware tools setup failed" }
        }
        "KVMKVMKVM"
        {
            # Nothing to do as VirtIO drivers have already been provisioned
        }
        "Microsoft Hv"
        {
            # Nothing to do
        }
    }
    Write-Host "Setup Office 2019"
       
    $arguments1 = "/configure"," $resourcesDir\Office\office.xml"
    & "$resourcesDir\Office\setupodt.exe" $arguments1

    Write-Host "Setup Chrome"

    $LocalTempDir = $env:TEMP
    $ChromeInstaller = "ChromeInstaller.exe"
    (new-object System.Net.WebClient).DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', "$LocalTempDir\$ChromeInstaller")
    & "$LocalTempDir\$ChromeInstaller" /silent /install; 
    

    Write-Host "Setup Firefox"
    
    $FirefoxInstaller = "firefox.exe"
    (new-object System.Net.WebClient).DownloadFile('https://download.mozilla.org/?product=firefox-stub&os=win&lang=de', "$LocalTempDir\$FirefoxInstaller")
    & "$LocalTempDir\$FirefoxInstaller" /s; 
      
    Write-Host "Setup Adobe Reader"

    $AdobeReaderInstaller = "AcroRdrDC_de_DE.exe"
    (new-object System.Net.WebClient).DownloadFile('ftp://ftp.adobe.com/pub/adobe/reader/win/AcrobatDC/2001320064/AcroRdrDC2001320064_de_DE.exe', "$LocalTempDir\$AdobeReaderInstaller")
    Start-Process -FilePath "$LocalTempDir\$AdobeReaderInstaller" -ArgumentList "/sPB /rs"

    Write-Host "icedtea-web"
    $LocalTempDir = $env:TEMP
    $icedteaInstaller = "icedtea-web.msi"
    (new-object System.Net.WebClient).DownloadFile('https://github.com/AdoptOpenJDK/IcedTea-Web/releases/download/icedtea-web-1.8.4/icedtea-web-1.8.4.msi', "$LocalTempDir\$icedteaInstaller")
    Start-Process -FilePath "$LocalTempDir\$icedteaInstaller" -ArgumentList "/qn /norestart"
    

}
catch
{
    $host.ui.WriteErrorLine($_.Exception.ToString())
    $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    # Prevents the setup from proceeding

    $logonScriptPath = "$resourcesDir\Logon.ps1"
    if ( Test-Path $logonScriptPath ) { Remove-Item $logonScriptPath }
    throw
}
