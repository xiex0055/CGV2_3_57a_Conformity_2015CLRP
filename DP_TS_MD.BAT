:: Run 'Decomposed' V2.3 Highway assignment

rem run cluster and start up 3 nodes and exit cluster
rem both the Cube and CubeVoyager program folders should be on the Environment PATH

set path=C:\Program Files (x86)\Citilabs\Cube
set path=C:\Program Files (x86)\Citilabs\CubeVoyager

del voya*.*

Cluster.exe mwcog 1-3 start exit

start /w Voyager.exe  TS_V23_MD.S /start -Pvoya

Cluster.exe mwcog 1-3 close exit

