CD %1

REM  Auto Driver Trips

if exist voya*.*  del voya*.*
if exist %_iter_%_mc_Auto_Drivers.rpt  del  %_iter_%_mc_Auto_Drivers.rpt
start /w Voyager.exe  ..\scripts\mc_Auto_Drivers.s /start -Pvoya -S..\%1
if errorlevel 1 goto error
if exist voya*.prn  copy voya*.prn %_iter_%_mc_Auto_Drivers.rpt /y
if exist %_iter_%_mc_Auto_Drivers.rpt  copy %_iter_%_mc_Auto_Drivers.rpt temp.dat /y
..\software\extrtab    temp.dat
if exist extrtab.out  copy extrtab.out       %_iter_%_mc_Auto_Drivers.tab /y
if exist extrtab.out  del  extrtab.out
if exist temp.out     del  temp.out

goto end
:error
REM  Processing Error....
PAUSE
:end
CD..
