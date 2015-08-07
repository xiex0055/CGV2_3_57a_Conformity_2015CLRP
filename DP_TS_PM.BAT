:: Run 'Decomposed' V2.3 Highway assignment

rem run cluster and start up 8 nodes and exit cluster
rem both the Cube and CubeVoyager program folders should be on the Environment PATH

set path=C:\Program Files (x86)\Citilabs\Cube
set path=C:\Program Files (x86)\Citilabs\CubeVoyager

del voya*.*

Cluster.exe mwcog 1-8 start exit

start /w Voyager.exe  TS_V23_PM.S /start -Pvoya

Cluster.exe mwcog 1-8 close exit

