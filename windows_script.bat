<script>
mkdir "C:\Users\Administrator\bcde_scale"
powershell.exe -command Invoke-WebRequest -Uri "https://suma-bcde-bkt.s3.amazonaws.com/bcde.zip" -OutFile "C:\Users\Administrator\bcde_scale\bcde.zip"
powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory('C:\Users\Administrator\bcde_scale\bcde.zip', 'C:\Users\Administrator\bcde_scale'); }
powershell.exe -command C:\Users\Administrator\bcde_scale\bcde.ps1 -f C:\Users\Administrator\bcde_scale\bcde.config -t 1 > "C:\Users\Administrator\bcde_scale\bcde_install.txt"
FOR /F "tokens=*" %%g IN ('powershell.exe -command Invoke-WebRequest -Uri "http://169.254.169.254/latest/meta-data/instance-id" ^| find "i-"') do (SET CMD=%%g)
set CMD=%CMD:~20%
set counter=1
:checkBCDEloop
find "Completed deployment/cleanup on endpoint" "C:\Users\Administrator\bcde_scale\bcde_install.txt"
if %ERRORLEVEL% NEQ 0 (
  if %counter% GTR 5 (
  echo "BCDE installation completion log is not seen after 10mins. Sending failure signal to the stack"
  cfn-signal -e 1 --stack win-wait2 --resource AutoScalingGroup --region ap-northeast-1 --reason "Instance %CMD% sent Failure signal"
  goto :checkBCDEfail
  )
  set /a counter=%counter%+1
  echo "BCDE installation completion log is not seen yet.  Will check again after 1 minute"
  ping -n 60 127.0.0.1 > nul
  goto :checkBCDEloop
  ) else (
  echo "BCDE installation completion log is seen. Sending success signal to the stack"
  cfn-signal -e 0 --stack win-wait2 --resource AutoScalingGroup --region ap-northeast-1 --reason "Instance %CMD% sent Success signal"
  )
  echo "Done sending the signal back to stack"
  :checkBCDEfail
</script>
