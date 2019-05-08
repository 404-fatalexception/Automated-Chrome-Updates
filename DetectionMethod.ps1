<#
.SYNOPSIS
    Detection Method

.DESCRIPTION
    Detects if the latest version of Chrome is installed, for use in System Center Configuration Manager
    
.PARAMETER none

.EXAMPLE
    DetectionMethod.ps1

.Notes
    FileName:    DetectionMethod.ps1
    Author:      William Hamilton
    Contact:     whamilton@zebra.com
    Created:     2019-03-22
    Updated:     

    Version history:
    1.0.0 - (2019-03-21) Initial release
    
#>

$ChromeReleaseFeed = 'http://feeds.feedburner.com/GoogleChromeReleases'
try {
    $Current = [version]((Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe' -ErrorAction SilentlyContinue).'(Default)').VersionInfo).ProductVersion
}
catch {
    $current = $null
}
try {
    [xml]$strReleaseFeed = Invoke-webRequest $ChromeReleaseFeed
    $available = ($strReleaseFeed.feed.entry | Where-object { $_.title.'#text' -match 'Stable' }).content | Select-Object { $_.'#text' } | Where-Object { $_ -match 'Windows' } | ForEach-Object{[version](($_ | Select-string -allmatches '(\d{1,4}\.){3}(\d{1,4})').matches | select-object -first 1 -expandProperty Value)} | Sort-Object -Descending | Select-Object -first 1
}
catch {
    [xml]$strReleaseFeed = (New-Object System.Net.WebClient).DownloadString($ChromeReleaseFeed)
    $available = ($strReleaseFeed.feed.entry | Where-Object { $_.title.'#text' -match 'stable'}) | foreach-object { $_.content.'#text' } | where-Object { $_ -match 'Windows' } | ForEach-Object{[version](($_ | Select-string -allmatches '(\d{1,4}\.){3}(\d{1,4})').matches | select-object -first 1 -expandProperty Value)} | Sort-Object -Descending | Select-Object -first 1
}

If($current -match $available){
    Write-Output "Installed"
}
else {
}