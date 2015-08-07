## Line reports summarize boardings, alightings, and ridership for one or more line
TITLE                             Metrorail Line Summmary
DEFAULT_FILE_FORMAT               DBASE

PEAK_RIDERSHIP_FILE_1     				PK_VOL.DBF
PEAK_RIDERSHIP_FORMAT_1   				DBASE
OFFPEAK_RIDERSHIP_FILE_1  				OP_VOL.DBF
OFFPEAK_RIDERSHIP_FORMAT_1				DBASE

STOP_NAME_FILE                    ..\inputs\station_names.dbf
STOP_NAME_FORMAT                  DBASE

LINE_REPORT_TITLE_1					  All
LINE_REPORT_LINES_1           All
LINE_REPORT_MODES_1           3
NEW_TOTAL_RIDERSHIP_FILE_1    MR_line.txt
NEW_TOTAL_RIDERSHIP_FORMAT_1  TAB_DELIMITED
