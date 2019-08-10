# =======================================================================================
# * Script Name : PixRelocation                                                         *
# *                                                                                     *
# * Company     : private                                                               *
# * Author      : Tingle Driftwood                                                      *
# * E-Mail      : har_lea_quin@gmx.de                                                   *
# *                                                                                     *
# * Description :                                                                       *
# * Script should help to copy all pictures from my old NAS to the new one. I also want *
# * a new file and folder structure on the new NAS.                                     *
# * all pictures should be stored under year-->month-->day regarding their meta data.   *
# * Script uses for meta data actions EXIFTOOL by Phil Harvey.                          *
# * (https://www.sno.phy.queensu.ca/~phil/exiftool/)                                    *
# *                                                                                     *
# * Version     : 1.0                                                                   *
# =======================================================================================

# ======================================== SETUP ========================================
# Region for script setup and module import
$myDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import modules
# https://www.powershellgallery.com/packages/Logging/4.1.1 (Logging Module page)
Import-Module Logging
# https://www.powershellgallery.com/packages/CredentialManager/2.0 (Credential Manager page)
Import-Module CredentialManager

# Import parameter from config.xml
$confFilePath = $myDir + '\config.xml'
[xml]$configFile = Get-Content $confFilePath

$logLevel = $configFile.Settings.Log.Level
$logFile = $configFile.Settings.Log.LogPath + $configFile.Settings.Log.LogName + '_%{+%Y%m%d}.log'

# Basic log settings
Set-LoggingDefaultLevel -Level $logLevel 
Add-LoggingTarget -Name File -Configuration @{Path = $logFile } 
 
Write-Log -Level INFO -Message "============================== SCRIPT STARTED ==============================" 


# ---------------------------------------------------------------------------------------


# ====================================== VARIABLES ======================================
# Region for script variables

# ---------------------------------------------------------------------------------------

# ==================================== ERRORHANDLING ====================================
# Region defining the error handling of script

$ErrorActionPreference = "Stop"

trap {
    $errorOut = Get-ErrorOutString -exception $_
    Write-Warning $errorout
    continue
}

# ---------------------------------------------------------------------------------------

# ====================================== FUNCTIONS ======================================
# Region for script functions

function Get-ErrorOutString {
    param(
        $exception
    )

    $line = $exception.InvocationInfo.Line
    $scriptname = $exception.InvocationInfo.ScriptName
    $linenumber = $exception.InvocationInfo.ScriptLineNumber
    $offset = $exception.InvocationInfo.OffsetInLine
    $message = $exception.Exception.Message
    $time = Get-Date
    $user = $env:username

    $template = @'
#####################################################################
Skripterror in "{0}"
on {1} in line {2} offset {3}:

Cause:
"{4}"

Errorline:
{5}
Script run by {6}

#####################################################################
'@

    $errorout = $template -f $scriptname, $time, $linenumber, $offset, $message, $line, $user
    return $errorout
}

function Get-PixsMetadata {
    
# old:\2018\Langeoog
# old:\1992\02
$pixs = Get-ChildItem -Path 'old:\2018\Langeoog' -Recurse -File

foreach ($pix in $pixs) {
    # Extract meta data (file name & create date) with exiftool
    # exiftool -T -filename -createdate d:\exiftool > out.txt
    $txt = 'FILE: ' + $pix.FullName + ' CREATION: ' + $pix.CreationTime
    Write-Host $txt
}

Write-Host $pixs.Length
}

# Function mapping network ressource to local machine
function New-Connection {
    param (
        [parameter(Mandatory = $true ,Position = 0)]
        $DriveName,
        [parameter(Mandatory = $true ,Position = 1)]
        $Ressource,
        [parameter(Mandatory = $true ,Position = 2)]
        [SecureString] $CredName
    )
    # Check if network drice exists
    $exists = Test-Path -Path $DriveName

    if (-not $exists) {
        $creds = Get-StoredCredential -Target $CredName
        New-PSDrive -Name $DriveName -PSProvider 'Filesystem' -Root $Ressource -Credential $creds
    }
}

# ---------------------------------------------------------------------------------------

# ========================================= MAIN ========================================

New-Connection 'OldNAS' -Ressource '\192.168.192.13\photo\2006\10' -CredName 'zyklotrop'

# ---------------------------------------------------------------------------------------