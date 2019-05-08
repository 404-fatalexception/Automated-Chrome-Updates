<#
.SYNOPSIS
    Uninstallation of Google Chrome

.DESCRIPTION
    Uninstalls Google Chrome from Machine.  In order to handle dynamic updated Chrome, downloads latest MSI and uses it to uninstall.
    
.PARAMETER none

.EXAMPLE
    Uninstall.ps1

.Notes
    FileName:    Uninstall.ps1
    Author:      William Hamilton
    Contact:     whamilton@zebra.com
    Created:     2019-03-22
    Updated:     

    Version history:
    1.0.0 - (2019-03-22) Initial release    
#>

Function Get-LatestChromeMSI{
    Param([uri]$ChromeDownloadPath,[string]$ChromeDownloadFolder,[string]$ChromeSaveAsName)
    if($psversiontable.psversion.major -gt 2) {
        Write-Output "PS Version 3+"
        try {
            New-Item -ItemType Directory "$ChromeDownloadFolder" -force | out-null
            $objWebRequest = Invoke-WebRequest $ChromeDownloadPath -outfile (Join-Path $ChromeDownloadFolder -childpath $ChromeSaveAsName)
            Write-Output "Successful download"
        }
        catch {
            Write-Output "Download Failed"
            exit
        }
    }
    else {
        Write-Output "PS Version 2 or below"
        try {
            New-Item -ItemType Directory "$ChromeDownloadFolder" -force | out-null
            $savepath = (Join-Path $ChromeDownloadFolder -childpath $ChromeSaveAsName)
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile("$ChromeDownloadPath","$savepath")
            Write-Output "Successful Download"
        }
        catch {
            Write-Output "Download Failed"
            exit
        }
    }
}

$uriNewChromeURL = 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi'
$strChromeDownloadFolder = "$ENV:temp\Chrome"
$strChromeSaveAsName = 'googlechromestandaloneenterprise64.msi'
$chromeMSI = """$strChromeDownloadFolder\$strChromeSaveAsName"""

(Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -match "Chrome"}).Version | ForEach-Object {& ${env:ProgramFiles(x86)}\Google\Chrome\Application\$_\Installer\setup.exe --uninstall --multi-install --chrome --system-level --force-uninstall}
Get-LatestChromeMSI -ChromeDownloadPath $uriNewChromeURL -ChromeDownloadFolder $strChromeDownloadFolder -ChromeSaveAsName $strChromeSaveAsName

(Start-Process -filepath msiexec -argumentlist "/f $ChromeMSI /qn /norestart" -Wait -PassThru).ExitCode
(Start-Process -filepath msiexec -argumentlist "/x $ChromeMSI /qn /norestart" -Wait -PassThru).ExitCode

