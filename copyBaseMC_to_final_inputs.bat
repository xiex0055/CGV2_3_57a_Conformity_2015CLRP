:: O:\model_dev\Ver2.3.27\copyBaseMC_to_final_inputs.bat
:: 2011-06-30 Thu 14:19:12
:: Copy pre-existing NL mode choice model output into the input folder for new run

set dir1=O:\model_dev\Ver2.3.27\2040_base
set dir2=O:\model_dev\Ver2.3.27\2040_final

:: Copy any existing files to a backup copy
if exist %dir2%\inputs\???_NL_mc.mtt  copy %dir2%\inputs\???_NL_mc.mtt %dir2%\inputs\???_NL_mc_prev.mtt /y

:: Copy base files into final
copy %dir1%\???_NL_mc.mtt %dir2%\inputs /y

:: Clear environment variables
set dir1=
set dir2=