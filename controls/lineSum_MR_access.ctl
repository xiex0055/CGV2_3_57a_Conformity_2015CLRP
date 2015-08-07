## Access reports focus on riders who arrive or depart using transit access links
## i.e., the summary does not include transfers
TITLE                             Metrorail Station Access Summmary
DEFAULT_FILE_FORMAT               DBASE

PEAK_RIDERSHIP_FILE_1     				PK_VOL.DBF
PEAK_RIDERSHIP_FORMAT_1   				DBASE
OFFPEAK_RIDERSHIP_FILE_1  				OP_VOL.DBF
OFFPEAK_RIDERSHIP_FORMAT_1				DBASE

STOP_NAME_FILE                    ..\inputs\station_names.dbf
STOP_NAME_FORMAT                  DBASE

ACCESS_REPORT_TITLE_1					All
ACCESS_REPORT_STOPS_1					8001..8100, 8119..8140, 8145..8148, 8150..8154, 8160..8166, 8169..8182
##ACCESS_REPORT_MODES_1					11,12,14,15,16
ACCESS_REPORT_MODES_1					ALL
##ACCESS_REPORT_DETAILS_1       MODE
NEW_ACCESS_REPORT_FILE_1                MR_access.txt
NEW_ACCESS_REPORT_FORMAT_1              TAB_DELIMITED
