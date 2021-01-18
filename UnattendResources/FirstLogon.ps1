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

    Write-Host "Setup icedtea-web"
    $LocalTempDir = $env:TEMP
    $icedteaInstaller = "icedtea-web.msi"
    (new-object System.Net.WebClient).DownloadFile('https://github.com/AdoptOpenJDK/IcedTea-Web/releases/download/icedtea-web-1.8.4/icedtea-web-1.8.4.msi', "$LocalTempDir\$icedteaInstaller")
    Start-Process -FilePath "$LocalTempDir\$icedteaInstaller" -ArgumentList "/qn /norestart"
    
    Write-Host "Setup OpenWebStart"
    $arguments2 = "-q"," -varfile"," $resourcesDir\OpenWebStart\OpenWebStart_windows-x64_1_3_0.varfile"
    & "$resourcesDir\OpenWebStart\OpenWebStart_windows-x64_1_3_0.exe" $arguments2


    Write-Host "Setup AI_WEBLAUNCHER64bit"
    $LocalTempDir = $env:TEMP
    $AI_WEBLAUNCHER64bit = "AI_WEBLAUNCHER64bit.exe"
    (new-object System.Net.WebClient).DownloadFile('https://www.bietercockpit.de/res/files/AI_WEBLAUNCHER64bit.exe', "$LocalTempDir\$AI_WEBLAUNCHER64bit")
    Start-Process -FilePath "$LocalTempDir\$AI_WEBLAUNCHER64bit" -ArgumentList "-q"


    Write-Host "Setup Cosinex Bietertool"
    $LocalTempDir = $env:TEMP
    $Bietertool_windows = "Bietertool_windows-x86_1_0_10.exe"
    (new-object System.Net.WebClient).DownloadFile('https://www.bietertool.de/updates/releases/?os=windows-x86', "$LocalTempDir\$Bietertool_windows")
    Start-Process -FilePath "$LocalTempDir\$Bietertool_windows" -ArgumentList "-q"
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
