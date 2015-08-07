@echo off
:: move_temp_files_v6.bat
:: 2012-12-12 msm Batch file created
:: 2013-01-21 msm Update: Restore report   files assoc. w/ SFB iters pp, i1, i2, and i3
:: 2013-03-04 msm Update: Restore TXT, TAB files assoc. w/ SFB iters pp, i1, i2, and i3
:: Usage (launched from root folder):  move_temp_files.bat <output_folder_name> 
::
:: When running the TPB Version 2.3.48 Travel Model, in addition to the useful
:: output files, such as i4_Assign_Output.net, a number of temporary ("temp")
:: files are created, such as i3_Assign_Output.net.  This program will move 
:: these temp files to a folder under the output folder.  For example, "2030_base"
:: will now include a subfolder called "temp_files".  After the batch file has
:: been run, the user may use Windows Explorer to manually delete the folders
:: containg the temp files.

:: The majority of temp files are those associated with the first four
:: speed-feedback (SFB) iterations of the model (pp, i1, i2, and i3).
:: Some of the "i3" files should be maintained, however, so this batch file
:: will restore five of the i3 files.

:: Robocopy (robust copy) is a powerful command and "robocopy /MOV" allows the
:: command to mimic the Windows move command (and even create a log file), but
:: "robocopy /MOV" is very slow, so we have refrained from using it.

:: Time delay, x, where x = (seconds of delay) - 1      Thus 6 => 5 sec. delay
set time_delay=6

:: Calculate number of and size of files BEFORE moving temp files
dir %1 | tail -2 | head -1 > tot_output_files1.txt

echo(
echo Change working folder to the output folder
ping -n %time_delay% 127.0.0.1 > nul
cd %1

echo(
echo Create the subfolder to hold the temp files
ping -n %time_delay% 127.0.0.1 > nul
if not exist temp_files  (mkdir temp_files)
 
echo(
echo Move temp files associated with SFB iterations pp, i1, i2, and i3
ping -n %time_delay% 127.0.0.1 > nul
for %%H in (pp i1 i2 i3) do (
  move %%H_*  .\temp_files
  ping -n %time_delay% 127.0.0.1 > nul
  )

echo(
echo Restore the i3 files that are used for truck trip gen, trip distr., and MC
ping -n %time_delay% 127.0.0.1 > nul
for %%H in (i3_SKIMTOT.TXT i3_AM_SOV.SKM i3_MD_SOV.SKM i3_HWY_AM.SKM i3_HWY_OP.SKM) do (
  move .\temp_files\%%H  .
  )

echo(
echo Restore files needed for the HOV3+ skims substitution technique (HOT-lane modeling)
ping -n %time_delay% 127.0.0.1 > nul
for %%H in (pp i1 i2 i3) do (
  move .\temp_files\%%H_am_hov3_mc.skm  .
  move .\temp_files\%%H_md_hov3_mc.skm  .
  )

echo(
echo Restore report files associated with SFB iterations pp, i1, i2, and i3
ping -n %time_delay% 127.0.0.1 > nul
for %%H in (pp i1 i2 i3) do (
  move .\temp_files\%%H_*.rpt .
  )

echo(
echo Restore TXT,TAB files associated with SFB iterations pp, i1, i2, and i3
ping -n %time_delay% 127.0.0.1 > nul
for %%H in (pp i1 i2 i3) do (
  move .\temp_files\%%H_*.txt .
  move .\temp_files\%%H_*.tab .
  )

echo(
echo Move temp files with the following pattern(s): *.tem?, temp.*, temp*.net,
echo                                                transit.temp.*
ping -n %time_delay% 127.0.0.1 > nul
@echo on
move *.tem?           .\temp_files
move temp.*           .\temp_files
move temp*.net        .\temp_files
move transit.temp.*   .\temp_files
@echo off

echo(
echo Move temp files with the following pattern(s): *.skf, *.def
ping -n %time_delay% 127.0.0.1 > nul
@echo on
move *.skf            .\temp_files
move *.def            .\temp_files
move *.lkloop         .\temp_files
@echo off


goto end
:error
REM  Processing Error....
PAUSE
:end

:: Change working folder back to the root folder
CD..

:: Calculate number of and size of files BEFORE moving temp files
dir %1 | tail -2 | head -1 > tot_output_files2.txt

echo(
echo ***** Number of and size of output files BEFORE moving temp files
type tot_output_files1.txt

echo(
echo ***** Number of and size of output files AFTER  moving temp files
type tot_output_files2.txt
