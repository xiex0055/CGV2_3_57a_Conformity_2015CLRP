CD %1

REM  Average Link Speeds

:: Write loaded links file from assignment to new file
:: current iteration speeds will be removed and rewritten with averaged speeds below

if exist %_iter_%_HWY.net   copy   %_iter_%_HWY.net    %_iter_%_Assign_Output.net /y
if exist %_iter_%_HWY.net   copy   %_iter_%_HWY.net    %_iter_%_HWY.tem1 /y


if exist voya*.*  del voya*.*
if exist %_iter_%_Average_Link_Speeds.rpt  del  %_iter_%_Average_Link_Speeds.rpt
start /w Voyager.exe  ..\scripts\Average_Link_Speeds.s /start -Pvoya -S..\%1
if errorlevel 1 goto error
if exist voya*.prn  copy voya*.prn %_iter_%_Average_Link_Speeds.rpt /y

:: Now copy over the original Loaded file with revised file containing new/avg speeds
:: Note: the original file from assignment is maintained as %_iter_%_Assigned_%HWY.net

if exist  %_iter_%_Averaged_HWY.net  copy %_iter_%_Averaged_HWY.net %_iter_%_HWY.net /y


goto end
:error
REM  Processing Error....
PAUSE
:end
CD..
