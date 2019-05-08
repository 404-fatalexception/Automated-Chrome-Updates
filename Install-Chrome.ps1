<#
.SYNOPSIS
    Installation of Google Chrome

.DESCRIPTION
    Installs the latest version of Google Chrome
    
.PARAMETER none

.EXAMPLE
    Install-Chrome.ps1

.Notes
    FileName:    Install-Chrome.ps1
    Author:      William Hamilton
    Contact:     whamilton@zebra.com
    Created:     2019-03-21
    Updated:     

    Version history:
    1.0.0 - (2019-03-21) Initial release
    1.0.1 - (2019-03-22) Changed script to use RSS feed from Google instead of Chocolatey and added logging.
    
#>

Function Get-LatestChromeVersionViaRSS{
    Param([uri]$ChromeReleaseFeed)
    try {
        [xml]$strReleaseFeed = Invoke-webRequest $ChromeReleaseFeed
        ($strReleaseFeed.feed.entry | Where-object { $_.title.'#text' -match 'Stable' }).content | Select-Object { $_.'#text' } | Where-Object { $_ -match 'Windows' } | ForEach-Object{[version](($_ | Select-string -allmatches '(\d{1,4}\.){3}(\d{1,4})').matches | select-object -first 1 -expandProperty Value)} | Sort-Object -Descending | Select-Object -first 1
    }
    catch {
        [xml]$strReleaseFeed = (New-Object System.Net.WebClient).DownloadString($ChromeReleaseFeed)
        ($strReleaseFeed.feed.entry | Where-Object { $_.title.'#text' -match 'stable'}) | foreach-object { $_.content.'#text' } | where-Object { $_ -match 'Windows' } | ForEach-Object{[version](($_ | Select-string -allmatches '(\d{1,4}\.){3}(\d{1,4})').matches | select-object -first 1 -expandProperty Value)} | Sort-Object -Descending | Select-Object -first 1
    }    
    
}

Function Download-ChromeMSI{
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

Function Install-Chrome {
    $tempdirectory = "$ENV:temp\chrome"
    $chromeMSI = """$tempdirectory\googlechromestandaloneenterprise64.msi"""
    $ExitCode = (Start-Process -filepath msiexec -argumentlist "/i $ChromeMSI /qn /norestart" -Wait -PassThru).ExitCode

    if ($ExitCode -eq 0) {
        Write-Output "Chrome Install Successful"
        xcopy "$SCRIPTDIR\master_preferences" "C:\Program Files (x86)\Google\Chrome\Application\" /y

    }
    else {
        Write-Output "Chrome Install Failed"
        Write-output "$exitcode"
        Exit
    }
}

$SCRIPTDIR = split-path -parent $MyInvocation.MyCommand.Path
if(!$SCRIPTDIR) { $SCRIPTDIR = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\') }
$ScriptName = "Chrome-Perpetual.log"
$logfile = "c:\windows\ccm\logs\$scriptname"

If(Test-Path -Path $logfile){
    remove-item -Path $logfile
}

try {
    stop-transcript | out-null
} 
catch {
}
Start-Transcript -Path $logfile


# Set Variables
$CurrentlyInstalled = [version]((Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe' -ErrorAction SilentlyContinue).'(Default)').VersionInfo).ProductVersion
$ChromeReleaseFeed = 'http://feeds.feedburner.com/GoogleChromeReleases'
$uriNewChromeURL = 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi'
$strChromeDownloadFolder = "$ENV:temp\Chrome"
$strChromeSaveAsName = 'googlechromestandaloneenterprise64.msi'
$LatestAvailable = Get-LatestChromeVersionViaRSS -ChromeReleaseFeed $ChromeReleaseFeed

Write-Output "Currently Installed Version: $CurrentlyInstalled"
Write-Output "Latest Available Version: $LatestAvailable"
Write-Output "Chrome will download to: $strChromeDownloadFolder"


if($CurrentlyInstalled -lt $LatestAvailable) {
    Write-Output "Current version less than Newest, downloading current"
    Download-ChromeMSI -ChromeDownloadPath $uriNewChromeURL -ChromeDownloadFolder $strChromeDownloadFolder -ChromeSaveAsName $strChromeSaveAsName
    Install-Chrome
}
elseif ($CurrentlyInstalled -ge $LatestAvailable) {
    Write-Output "Current version equal to Latest"
    Write-Output "Update not needed"
}
