
; ====================================================================================================
; Program:    TS_V23_MD.S
;             VC-based toll search for MD peak period
;             COG/TPB Version 2.3 Model added
;             toll values in 2010$
;  Programer: JC Park
;  Date:      4/16/2012
;             developed based on Highway_Assignment.S from Version 2.3.38 OR 2.3.39
;             For 2013 CLRP
;             Toll Cap at $10/mile in 2012 $ jcpark 04/11/2013
; ====================================================================================================
PAGEHEIGHT=32767 ; preclude insertion of page headers

; A. INITIALIZATION:
D_FAC    =   0.876;  Deflation factor converting 2014$ --> 2007$
CONV_VAL =   20.00;  in current 2012 cents
ST       =     4  ;  First toll group
TGRPS    =     390;  Last toll group
VC_UW    =  1.0100; VC RATIO UPPER BOUND
PRD      = 'MD'   ;
T_NUM    =     387;  Total number of toll groups
pr       =     3  ;  iteration index
it       =     4  ;  iteration index
Toll_Cap =  1000.0;  toll cap $10.00 in 2012

; FOR ITERATION INDEX

loop _dd = 1,100      ; big outer loop for iteration; MAX 100 ITERATION TO FIND TOLL RATES

  prev = pr + _dd
  iter = it + _dd

;**********************************************************************************
;Step 1: Summarize network outputs and adjust toll rate based on HOT lane speed
;**********************************************************************************

run pgm=HIGHWAY
  neti =I@prev@_assign_output.net     ; I@prev@ highway network

ARRAY TG_@PRD@VMT = @TGRPS@, ; TollGrp VMT array               for each time prd
      TG_@PRD@WSP = @TGRPS@, ; TollGrp Speed-VMT product array for each time prd.
      TG_@PRD@SPD = @TGRPS@, ; TollGrp Weighted Speed array    for each time prd.
      TG_@PRD@BSP = @TGRPS@, ;
      TG_FTP      = @TGRPS@, ; ROUTE TYPE
      TG_@PRD@AVC = @TGRPS@, ; Average VC RATIO
      TG_@PRD@SVC = @TGRPS@, ; SUM OF VC RATIO
      TG_@PRD@VC  = @TGRPS@, ; VC RATIO
      TG_DST      = @TGRPS@, ; Distance
      TG_@PRD@LMT = @TGRPS@, ; LIMIT CODE
      TG_@PRD@OTL = @TGRPS@, ; 'OLD' Toll by time period in cents
      TG_@PRD@NTL = @TGRPS@, ; 'UPDATED' Toll by time period in cents
      D_@PRD@VC   = @TGRPS@, ; VC DIFFERENCE = LOWER BOUND VC RATIO (=0.6) - AVG. WGT. VC
      TG_@PRD@X   = @TGRPS@, ; DUMMY
      TG_@PRD@DT  = @TGRPS@  ; TOGGLE SWITCH

zones = 1

; Set up arrays
phase = linkread

     lw.tollgrp          = li.tollgrp             ; TOLLGRP IS REPLACED BY TLGP
     lw.ftype            = li.FTYPE            ; ROUTE TYPE
     lw.@prd@limit       = li.@PRD@LIMIT       ; LIMIT CODE
     lw.distance         = li.distance
     lw.i@prev@@PRD@spd  = li.i@prev@@PRD@spd
     lw.i@prev@@PRD@vol  = li.i@prev@@PRD@vol
     lw.@PRD@toll        = li.@PRD@toll
     lw.i@prev@@prd@vc   = (INT(li.i@prev@@prd@vc * 1000.0))/1000.0   ; vc ratio

endphase

;*************************************************************************************************************************
; estimate average V/C ratio in each tollgroup
;
;                  Sum of VC in each toll group
;  average V/C = ----------------------------------
;                  Number of links in a toll group
;
;*************************************************************************************************************************

phase = iloop
      linkloop
          if(lw.tollgrp > 1)
;             TG_@PRD@CNT[lw.tollgrp] = TG_@PRD@CNT[lw.tollgrp] + lw.cnt_@prd@                                          ; COUNT NUMBER OF LINK IN EACH TOLLGRP
             TG_DST[lw.tollgrp]      = lw.distance
             TG_FTP[lw.tollgrp]      = lw.ftype
             TG_@PRD@SVC[lw.tollgrp] = TG_@PRD@SVC[lw.tollgrp]+((lw.i@prev@@PRD@vol * lw.distance)*lw.I@PREV@@prd@VC)  ; SUM OF VC RATIO                                                                   ;
             TG_@PRD@VMT[lw.tollgrp] = TG_@PRD@VMT[lw.tollgrp]+(lw.i@prev@@PRD@vol  * lw.distance)                     ;
             TG_@PRD@BSP[lw.tollgrp] = TG_@PRD@BSP[lw.tollgrp]+((lw.i@prev@@PRD@vol * lw.distance)*lw.i@prev@@PRD@spd) ;
             TG_@PRD@OTL[lw.tollgrp] = (lw.@PRD@toll/lw.distance)/@D_FAC@                                              ;
         endif
      endlinkloop

;*************************************************************************************************
; Estimate average V/C Ratio & avg wgt speed
;
;

LOOP k=@ST@,@TGRPS@           ; START - loop for estimating average vc ratio & avg wgt speed
   IF(TG_@PRD@DT[K]=0)
           IF  (TG_@PRD@VMT[k] == 0.0)
                TG_@PRD@AVC[k] =  0.0
                TG_@PRD@WSP[k] =  0.0
           ELSE
                TG_@PRD@AVC[k] =  TG_@PRD@SVC[k] / TG_@PRD@VMT[k] ; average VMT weighted V/C Ratio
                TG_@PRD@WSP[k] =  TG_@PRD@BSP[k] / TG_@PRD@VMT[k] ; average VMT weighted speed
           ENDIF
   ELSE
                TG_@PRD@AVC[k] =  0
                TG_@PRD@WSP[k] =  0
   ENDIF
    D_@PRD@VC[k] = TG_@PRD@AVC[k] - @VC_UW@

ENDLOOP                    ; END - loop for estimating average vc ratio & avg wgt speed

;*************
; toll setting
;
     LOOP K=@ST@,@TGRPS@
           IF (TG_@PRD@AVC[K] > 1.0100)                                                          ; CASE 1: when VC > 1.01 ADD TOLL
                IF(D_@PRD@VC[K] > 0.1000)                                                        ;
                   TG_@PRD@X[K]  = TG_@PRD@OTL[K] + 1*50.0*@CONV_VAL@/20.0                       ;             50 CENTS INCREASE
                   TG_@PRD@DT[K] = 0                                                             ;
                ELSEIF(D_@PRD@VC[K] =0.0500-0.0999)                                              ;
                   TG_@PRD@X[K]  = TG_@PRD@OTL[K] + 1*40.0*@CONV_VAL@/20.0                       ;             40 CENTS INCREASE
                   TG_@PRD@DT[K] = 0                                                             ;
                ELSEIF(D_@PRD@VC[K] =0.0200-0.0499)                                              ;
                   TG_@PRD@X[K]  = TG_@PRD@OTL[K] + 1*30.0*@CONV_VAL@/20.0                       ;             30 CENTS INCREASE
                   TG_@PRD@DT[K] = 0                                                             ;
                ELSEIF(D_@PRD@VC[K] =0.0100-0.0199)                                              ;
                   TG_@PRD@X[K]  = TG_@PRD@OTL[K] + 1*20.0*@CONV_VAL@/20.0                       ;             20 CENTS INCREASE
                   TG_@PRD@DT[K] = 0                                                             ;
                ELSE                                                                             ;
                   TG_@PRD@X[K]  = TG_@PRD@OTL[K] + 1*10.0*@CONV_VAL@/20.0                       ;             10 CENTS INCREASE
                   TG_@PRD@DT[K] = 0                                                             ;
                ENDIF                                                                            ;
            ELSEIF(TG_@PRD@AVC[K] < 0.9500)                                                      ; CASE 2: when VC < 0.95
                IF(TG_@PRD@OTL[K] <= 20.0)                                                       ; CASE 2.1: TOLL < BASE TOLL, KEEP BASE TOLL
                   TG_@PRD@X[K]  = TG_@PRD@OTL[K]                                                ;
                   TG_@PRD@DT[K] = 1                                                             ;
                ELSE                                                                             ; CASE 2.2: 'SUBSTRACT TOLL' FUNCTION IS DISABLED
                   TG_@PRD@X[K]  = TG_@PRD@OTL[K]                                                ;
                   TG_@PRD@DT[K] = 1                                                             ;
                ENDIF                                                                            ;
            ELSE                                                                                 ; CASE 3: NO TOLL CHANGE WHEN 0.95 <= VC <= 1.01
                  TG_@PRD@X[K]  = TG_@PRD@OTL[K]                                                 ;
                  TG_@PRD@DT[K] = 1                                                              ;
            ENDIF                                                                                ;
            IF (TG_@PRD@OTL[K] > @TOLL_CAP@)                                                     ;
                  TG_@PRD@X[K] = @TOLL_CAP@                                                      ;
                  TG_@PRD@DT[K] = 1                                                              ;
            ENDIF                                                                                ;
    ENDLOOP                                                                                      ; loop for toll update

;*****************************************************************************************************************************************
; SUMMARIZE TOLL, SPEED, VMT

LOOP k=@ST@,@TGRPS@
;  IF( TG_@PRD@OTL[K] >0)
      Print form=13.0 list = k(10),k(10),TG_FTP[k](10),TG_@PRD@OTL[k](10.4),TG_@PRD@X[K](10.4),
                             TG_@PRD@WSP[k](10.4),TG_@PRD@AVC[k](10.4),
                             TG_@PRD@VMT[k](10.2E),D_@PRD@VC[K](10.4), TG_@PRD@DT[K](10),file=OUT@prev@@PRD@.TXT
;  ENDIF
ENDLOOP

endphase             ; End of Phase

ENDRUN               ; End of HIGHWAY

;*********************************************************************
;Step 2 Terminate the process upon conditions
;*********************************************************************

RUN PGM=HWYNET
ZONES=3722

NETI=I@prev@_assign_output.net               ; Input network in TP+ format

; READ TOLL RATE BY TOLLGRP

lookup name = TOLL@PRD@,        ; MD TOLL RATE
       lookup[1] = 1,result=2,  ; Toll group
       lookup[2] = 1,result=3,  ; Facility Type
       lookup[3] = 1,result=4,  ; Adjusted Toll
       lookup[4] = 1,result=5,  ; Speed
       lookup[5] = 1,result=6,  ; Model Toll
       lookup[6] = 1,result=7,  ; avg vc ratio
       lookup[7] = 1,result=8,  ; VMT
       lookup[8] = 1,result=9,  ; difference lb vc - avg vc ratio
       lookup[9] = 1,result=10, ; TOGGLE SWITCH to keep toll
       interpolate=N,fail=0,0,0,file=OUT@prev@@PRD@.TXT

;****************************************************************************************
;Check to see if design vc raio is achieved
;
 FLAG_@PRD@ = 0

LOOP _IDX=@ST@,@TGRPS@ ;
  IF (TOLL@PRD@(9,_IDX) = 1)
      FLAG_@PRD@ = FLAG_@PRD@ + 1
  ELSE
      FLAG_@PRD@ = FLAG_@PRD@ + 0
  ENDIF
ENDLOOP
;*****************************************************************************************
; Terminate

IF(FLAG_@PRD@==@T_NUM@)
  Print form=13.0 list = 'MD = ',FLAG_@PRD@(10)
  ABORT  ; TERMINATE THE PROCESS
ENDIF

ENDRUN

;*********************************************************************
;Step 3 Update MDTOLL in Highway Network
;*********************************************************************

RUN PGM=HWYNET
ZONES=3722

NETI=I@prev@_assign_output.net                ; ADJUSTED 2010 I@prev@ HWY NET
NETO=TEMP_@PRD@1.NET                  ; Output network in TP+ format


; READ TOLL RATE BY TOLLGRP
lookup name = TOLL@PRD@,           ; MD TOLL RATE
       lookup[1] = 1,result=2,  ; Toll group
       lookup[2] = 1,result=3,  ; Facility Type
       lookup[3] = 1,result=4,  ; Adjusted Toll
       lookup[4] = 1,result=5,  ; Speed
       lookup[5] = 1,result=6,  ; Model Toll
       lookup[6] = 1,result=7,  ; avg vc ratio
       lookup[7] = 1,result=8,  ; VMT
       lookup[8] = 1,result=9,  ; difference lb vc - avg vc ratio
       lookup[9] = 1,result=10, ; TOGGLE SWITCH to keep toll
       interpolate=N,fail=0,0,0,file=OUT@prev@@PRD@.TXT

;
; Replace MDTOLL
; DISCOUNTS TO CURRENT YEAR $ VALUE X D_FAC
; ONLY UNSATISFACTORY TOLL GETS UPDATED; OTHERWISE, TOLL IS KEPT

LOOP _IDX=@ST@,@TGRPS@          ;

IF(TOLL@PRD@(9,_IDX)=0)
   IF(LI.1.tollgrp = TOLL@PRD@(1,_IDX))
        @PRD@TOLL = TOLL@PRD@(4,_IDX) * LI.1.DISTANCE * @D_FAC@
   ELSE
        @PRD@TOLL = @PRD@TOLL
   ENDIF
ENDIF

ENDLOOP

ENDRUN



;  useIdp = t (true) or f (false);  this is set in the wrapper batch file
distribute intrastep=T multistep=f

; Choose traffic assignment type, using "enhance=" keyword
;   enhance=0 Frank-Wolfe
;   enhance=1 Conjugate Frank-Wolfe
;   enhance=2 Bi-conjugate Frank-Wolfe

assignType=2

PCTADT =   17.7           ;; %_MDPF_%  Midday PHF (% of traffic in pk hr of period)
CAPFAC=1/(PCTADT/100)     ;  Capacity Factor = 1/(PCTADT/100)
rel_gap =   0.001         ;  Relative gap threshold, normally set to 10E-3
mxIters =   300           ;  Max. number of user equilibrium (UE) iterations,
                          ;    normally set to 200
in_tmin     = '..\..\..\support\toll_minutes.txt'          ;; read in toll minutes equiv file
in_MDTfac   = '..\..\inputs\MD_Tfac.dbf'                   ;; AM Toll Factors by Veh. Type
in_capSpd   = '..\..\..\support\hwy_assign_capSpeedLookup.s' ;; FT x AT Speed & Capacity lookup
VDF_File    = '..\..\..\support\hwy_assign_Conical_VDF.s'    ;; Volume Delay Functions file
;
;;;*****************************************************************************
;;; Step 1: Execute off-peak-period traffic assignments (midday/MD & night/NT)
;;;         All 6 trip tables are assigned together.
;;;*****************************************************************************
PRD    =  'MD'                         ;
CAPFAC=1/(PCTADT/100)                  ; Capacity Factor = 1/(PCTADT/100)

  RUN PGM=HIGHWAY  ; Off-peak (midday & evening) traffic assignment
  distributeIntrastep processId='mwcog', ProcessList=1-3
  FILEI NETI     =  TEMP_@PRD@1.NET                          ; TP+ Network
  ;
  ;  The input trip table has 6 Vehicle Tables:
  ;     1 - 1-Occ Auto Drivers
  ;     2 - 2-Occ Auto Drivers
  ;     3 - 3+Occ Auto Drivers
  ;     4 - Commercial Vehicles
  ;     5 - Trucks
  ;     6 - Airport Pass. Auto Driver Trips

  FILEI MATI=..\..\I4_@prd@.VTT ;
  ;
  FILEO NETO=TEMP_@PRD@2.NET                  ; Output loaded network of current iter/time prd.
  PARAMETERS COMBINE=EQUI ENHANCE=@assignType@;
  PARAMETERS RELATIVEGAP=@rel_gap@            ; Set a relative gap tolerance
  PARAMETERS MAXITERS=@mxIters@               ; We control on relative gap.  This is backup criterion
  ;
  ;------------------------------------------------------$
  ;    Read in LOS'E' Capacities and Freeflow Speeds     $
  ;------------------------------------------------------$
  READ FILE = @in_capSpd@
;$
  ;------------------------------------------------------$
  ;    Read in Toll Parameters:                          $
  ;------------------------------------------------------$
  READ FILE = @in_tmin@

  FileI  LOOKUPI[1] =         "@in_MDtfac@"      ;
  LOOKUP LOOKUPI=1,           NAME=MD_Tfac,      ;
        LOOKUP[1]= TOLLGrp, result=MDSOVTFTR,    ;
        LOOKUP[2]= TOLLGrp, result=MDHV2TFTR,    ;
        LOOKUP[3]= TOLLGrp, result=MDHV3TFTR,    ;
        LOOKUP[4]= TOLLGrp, result=MDCOMTFTR,    ;
        LOOKUP[5]= TOLLGrp, result=MDTRKTFTR,    ;
        LOOKUP[6]= TOLLGrp, result=MDAPXTFTR,    ;
        INTERPOLATE=N, FAIL= 0,0,0, LIST=N
  ;
  ;------------------------------------------------------$
  ;    VDF (Volume Delay Function) establishment:        $
  ;------------------------------------------------------$
  ; Note:  curves updated 2/16/06 rjm/msm
  ;
  LOOKUP NAME=VCRV,
         lookup[1] = 1,result = 2,  ;Centroids   old VCRV1
         lookup[2] = 1,result = 3,  ;Fwys        old VCRV2
         lookup[3] = 1,result = 4,  ;MajArts     old VCRV3
         lookup[4] = 1,result = 5,  ;MinArts     old VCRV4
         lookup[5] = 1,result = 6,  ;Colls       old VCRV5
         lookup[6] = 1,result = 7,  ;Expways     old VCRV6
         lookup[7] = 1,result = 8,  ;Ramps       old VCRV2
         FAIL=0.00,0.00,0.00, INTERPOLATE=T,file=@VDF_File@

  FUNCTION {                                ; Congested Time (TC)specification:
    TC[1]= T0*VCRV(1,VC)   ; TC(LINKCLASS) =
    TC[2]= T0*VCRV(2,VC)   ;   Uncongested Time(T0) *
    TC[3]= T0*VCRV(3,VC)   ;   Volume Delay Funtion(VDF)Value
    TC[4]= T0*VCRV(4,VC)   ;   VDF function is based on VC
    TC[5]= T0*VCRV(5,VC)   ; Note: the LINKCLASS is defined
    TC[6]= T0*VCRV(6,VC)   ; during the LINKREAD phase below.
    TC[7]= T0*VCRV(7,VC)   ; during the LINKREAD phase below.
  }
  ;
  ;
  CAPFAC=@CAPFAC@  ;
  ;MAXITERS=3      ;
  ;GAP  = 0.0      ;
  ;AAD  = 0.0      ;
  ;RMSE = 0.0      ;
  ;RAAD = 0.0      ;


PHASE=LINKREAD
      C     = CAPACITYFOR(LI.@PRD@LANE,LI.CAPCLASS) * @CAPFAC@  ; Convert hourly capacities to period-specific
      SPEED = SPEEDFOR(LI.@PRD@LANE,LI.SPDCLASS)
      T0    = (LI.DISTANCE/SPEED)*60.0
      ;  Since there is no "DISTANCE =" statement, this assumes that DISTANCE is avail. on input network


   IF (ITERATION = 0)
     ; Define        link level tolls by vehicle type here:
        LW.SOV@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(1,LI.TOLLGRP) ; SOV       TOLLS in 2007 cents
        LW.HV2@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(2,LI.TOLLGRP) ; HOV 2 occ TOLLS in 2007 cents
        LW.HV3@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(3,LI.TOLLGRP) ; HOV 3+occ TOLLS in 2007 cents
        LW.CV@PRD@TOLL  = LI.@PRD@TOLL * @PRD@_TFAC(4,LI.TOLLGRP) ; CV        TOLLS in 2007 cents
        LW.TRK@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(5,LI.TOLLGRP) ; Truck     TOLLS in 2007 cents
        LW.APX@PRD@TOLL = LI.@PRD@TOLL * @PRD@_TFAC(6,LI.TOLLGRP) ; AP Pax    TOLLS in 2007 cents

;;     ; Initial Iteration LINK IMPEDANCE (HIGHWAY TIME + Equiv.Toll/Time) by vehicle type here:
;;         LW.SOV@PRD@IMP = T0    + (LW.SOV@PRD@TOLL/100.0)* SV@PRD@EQM ;SOV   IMP
;;         LW.HV2@PRD@IMP = T0    + (LW.HV2@PRD@TOLL/100.0)* H2@PRD@EQM ;HOV 2 IMP
;;         LW.HV3@PRD@IMP = T0    + (LW.HV3@PRD@TOLL/100.0)* H3@PRD@EQM ;HOV 3+IMP
;;         LW.CV@PRD@IMP  = T0    + (LW.CV@PRD@TOLL /100.0)* CV@PRD@EQM ;CV    IMP
;;         LW.TRK@PRD@IMP = T0    + (LW.TRK@PRD@TOLL/100.0)* TK@PRD@EQM ;Truck IMP
;;         LW.APX@PRD@IMP = T0    + (LW.APX@PRD@TOLL/100.0)* AP@PRD@EQM ;APAX  IMP
;;
;;         IF (LI.@PRD@TOLL > 0)
;;            PRINT LIST = 'iteration: ',iteration(3),' A: ',A(7),' B: ',B(7),
;;           ' DISTANCE: ',LI.DISTANCE(6.2),
;;           ' LI.@PRD@TOLL: ',                        LI.@PRD@TOLL(5.2),
;;           ' FFSPEED: ',                                    SPEED(5.2),
;;           ' @PRD@_TFAC(1,LI.TOLLGRP): ',@PRD@_TFAC(1,LI.TOLLGRP)(5.1),
;;           ' SV@PRD@EQM: ',                            SV@PRD@EQM(5.1),
;;           ' LW.SOV@PRD@TOLL: ',                  LW.SOV@PRD@TOLL(5.2),
;;           ' T0: ',                                            T0(5.2),
;;           ' LW.SOV@PRD@IMP',                      LW.SOV@PRD@IMP(5.2),
;;            file = @prd@CHK.LKREAD
;;         ENDIF

    ENDIF


;$
    ;
    ;   The highway network is coded with limit codes from 1 to 9
    ;     LimitCode addGrp  Definition
    ;     --------  -----   --------------------------------------------------------
    ;        1        1     All vehicles accepted
    ;        2        2     Only HOV2 (or greater) vehicles accepted only
    ;        3        3     Only HOV3 vehicles accepted only
    ;        4        4     Med,Hvy Trks not accepted, all other traffic is accepted
    ;        5        5     Airport Passenger Veh. Trips
    ;        6-8      6     (Unused)
    ;        9        7     No vehicles are accepted at all
    ;
    IF     (LI.@PRD@LIMIT==1)
      ADDTOGROUP=1
    ELSEIF (LI.@PRD@LIMIT==2)
      ADDTOGROUP=2
    ELSEIF (LI.@PRD@LIMIT==3)
      ADDTOGROUP=3
    ELSEIF (LI.@PRD@LIMIT==4)
      ADDTOGROUP=4
    ELSEIF (LI.@PRD@LIMIT==5)
      ADDTOGROUP=5
    ELSEIF (LI.@PRD@LIMIT==6-8)
      ADDTOGROUP=6
    ELSEIF (LI.@PRD@LIMIT==9)
      ADDTOGROUP=7
    ENDIF

    IF (LI.FTYPE = 0)      ;  LinkClass related to TC[?] above
       LINKCLASS = 1       ;
    ELSEIF (LI.FTYPE = 1)  ;
       LINKCLASS= 2        ;
    ELSEIF (LI.FTYPE = 2)  ;
       LINKCLASS= 3        ;
    ELSEIF (LI.FTYPE = 3)  ;
       LINKCLASS= 4        ;
    ELSEIF (LI.FTYPE = 4)  ;
       LINKCLASS= 5        ;
    ELSEIF (LI.FTYPE = 5)  ;
       LINKCLASS= 6        ;
    ELSEIF (LI.FTYPE = 6)  ;
       LINKCLASS= 7        ;
    ENDIF

ENDPHASE

PHASE=ILOOP

   IF (i=FirstZone)
     LINKLOOP
       ; Initial Iteration LINK IMPEDANCE (HIGHWAY TIME + Equiv.Toll/Time) by vehicle type here:
         LW.SOV@PRD@IMP = TIME    + LI.TIMEPEN + (LW.SOV@PRD@TOLL/100.0)* SV@PRD@EQM ;SOV   IMP
         LW.HV2@PRD@IMP = TIME    + LI.TIMEPEN + (LW.HV2@PRD@TOLL/100.0)* H2@PRD@EQM ;HOV 2 IMP
         LW.HV3@PRD@IMP = TIME    + LI.TIMEPEN + (LW.HV3@PRD@TOLL/100.0)* H3@PRD@EQM ;HOV 3+IMP
         LW.CV@PRD@IMP  = TIME    + LI.TIMEPEN + (LW.CV@PRD@TOLL /100.0)* CV@PRD@EQM ;CV    IMP
         LW.TRK@PRD@IMP = TIME    + LI.TIMEPEN + (LW.TRK@PRD@TOLL/100.0)* TK@PRD@EQM ;Truck IMP
         LW.APX@PRD@IMP = TIME    + LI.TIMEPEN + (LW.APX@PRD@TOLL/100.0)* AP@PRD@EQM ;APAX  IMP

          IF (LI.@PRD@TOLL > 0)
               PRINT LIST = 'iteration: ',iteration(3),' A: ',A(7),' B: ',B(7),
              ' DISTANCE: ',LI.DISTANCE(6.2),
              ' LI.@PRD@TOLL: ',                        LI.@PRD@TOLL(5.2),
              ' FFSPEED: ',                                    SPEED(5.2),
              ' @PRD@_TFAC(1,LI.TOLLGRP): ',@PRD@_TFAC(1,LI.TOLLGRP)(5.1),
              ' SV@PRD@EQM: ',                            SV@PRD@EQM(5.1),
              ' LW.SOV@PRD@TOLL: ',                  LW.SOV@PRD@TOLL(5.2),
              ' T0: ',                                            T0(5.2),
              ' TIME: ',                                        TIME(5.2),
              ' TIMEPEN: ',                                  TIMEPEN(5.2),
              ' LW.SOV@PRD@IMP',                      LW.SOV@PRD@IMP(5.2),
               file = @prd@CHK.LKLOOP
          ENDIF

     ENDLINKLOOP

   ENDIF

; Multi-user class or multiclass assignment implemented through volume sets (vol[#])

    PATHLOAD PATH=LW.SOV@PRD@IMP,  EXCLUDEGROUP=2,3,5,6,7,  VOL[1]=MI.1.1   ;  SOV veh
    PATHLOAD PATH=LW.HV2@PRD@IMP,  EXCLUDEGROUP=3,5,6,7,    VOL[2]=MI.1.2   ;  HOV 2
    PATHLOAD PATH=LW.HV3@PRD@IMP,  EXCLUDEGROUP=5,6,7,      VOL[3]=MI.1.3   ;  HOV 3
    PATHLOAD PATH=LW.CV@PRD@IMP,   EXCLUDEGROUP=2,3,5,6,7,  VOL[4]=MI.1.4   ;  CVs
    PATHLOAD PATH=LW.TRK@PRD@IMP,  EXCLUDEGROUP=2,3,4,5,6,7,VOL[5]=MI.1.5   ;  Trucks
    PATHLOAD PATH=LW.APX@PRD@IMP,  EXCLUDEGROUP=6,7,        VOL[6]=MI.1.6   ;  Airport

;$

ENDPHASE

PHASE=ADJUST

ENDPHASE

PHASE=CONVERGE
  Fileo Printo[1] = "I@prev@_itr_@prd@.txt"
  Print List= "Iter: ", Iteration(3.0),"   Gap: ",GAP(16.15),"   Relative Gap: ",RGAP(16.15), PRINTO=1
  if (rgap < rgapcutoff)
  balance=1
  endif
ENDPHASE

ENDRUN


;
; END OF MIDDAY ASSIGNMENT
;

;;;*****************************************************************************
;;; Step 3: Calculate restrained final Volumes, speeds, V/Cs (No MSA)
;;;*****************************************************************************

;;;*****************************************************************************
;;; Step 3.2: Loop thru 3 (MD)
;;;*****************************************************************************

PRD    =  'MD'         ;
PCTADT =   17.7
CAPFAC=1/(PCTADT/100)      ; Capacity Factor = 1/(PCTADT/100)

  RUN PGM=HWYNET   ; Calculate restrained speed/perform MSA volume averaging
  FILEI NETI=TEMP_@PRD@2.NET      ; input network from highway assignment
  FILEO NETO=TEMP_@PRD@3.NET,       ; output/@PRD@ network with updated speeds
       EXCLUDE=V_1,TIME_1,VC_1,V1_1, V2_1, V3_1, V4_1,V5_1,V6_1,
                          VT_1,V1T_1,V2T_1,V3T_1,V4T_1,V5T_1,V6T_1,
                          CSPD_1,VDT_1,VHT_1,WRSPD,WFFSPD

  ;
  ;------------------------------------------------------$
  ;    VDF (Volume Delay Function) establishment:        $
  ;------------------------------------------------------$
  ; Note:  curves updated 2/16/06 rjm/msm
  ;
  LOOKUP NAME=VCRV,
         lookup[1] = 1,result = 2,  ;Centroids   old VCRV1
         lookup[2] = 1,result = 3,  ;Fwys        old VCRV2
         lookup[3] = 1,result = 4,  ;MajArts     old VCRV3
         lookup[4] = 1,result = 5,  ;MinArts     old VCRV4
         lookup[5] = 1,result = 6,  ;Colls       old VCRV5
         lookup[6] = 1,result = 7,  ;Expways     old VCRV6
         lookup[7] = 1,result = 8,  ;Rmps
         FAIL=0.00,0.00,0.00, INTERPOLATE=T,file=@VDF_File@

 ;
 ; SUMMARIZE FINAL VOL.
 ;
 I@ITER@@prd@VOL  = V_1                                                       ;  Final PM Link Volume TOTAL
 I@ITER@@prd@VOL1 = V1_1                                                      ;  Final PM Link Volume SOV
 I@ITER@@prd@VOL2 = V2_1                                                      ;  Final PM Link Volume HOV2
 I@ITER@@prd@VOL3 = V3_1                                                      ;  Final PM Link Volume HOV3+
 I@ITER@@prd@VOL4 = V4_1                                                      ;  Final PM Link Volume COM VEH
 I@ITER@@prd@VOL5 = V5_1                                                      ;  Final PM Link Volume TRUCKS
 I@ITER@@prd@VOL6 = V6_1                                                      ;  Final PM Link Volume AIRPAX
 ;
 I@ITER@@prd@VMT =I@ITER@@prd@VOL * distance                                  ;  Final PM link VMT
 I@ITER@@prd@FFSPD  =SPEEDFOR(@prd@LANE,SPDCLASS)                             ;  Freeflow speed
 @prd@HRLKCAP=CAPACITYFOR(@prd@LANE,CAPCLASS)                                 ;  Hrly Link capacity
 @prd@HRLNCAP=CAPACITYFOR(1,CAPCLASS)                                         ;  Hrly Lane capacity
 I@ITER@@prd@VC=(I@ITER@@prd@VOL*(@pctadt@/100.0)/@prd@HRLKCAP)               ;  PM VC  ratio
 I@ITER@@prd@VDF = VCRV((Ftype + 1),I@ITER@@prd@VC)                           ;  PM VDF
  if (I@ITER@@prd@VDF > 0) I@ITER@@prd@SPD =I@ITER@@prd@FFSPD/I@ITER@@prd@VDF ;  PM speed (No queuing)
  ATYPE=SPDCLASS%10                                                           ;  Area Type
  _cnt = 1.0

ENDRUN

;;;*****************************************************************************
;;; Step 4: Summarize 24-hour VMT of current MD assignments
;;;*****************************************************************************
RUN PGM=HWYNET                                 ; Summarize MD VMT
  FILEI NETI = TEMP_@PRD@3.NET
  FILEO NETO =I@iter@_assign_output.net,
             EXCLUDE=OLDVOL1,NEWVOL1,OLDVOL2,NEWVOL2,OLDVOL3,NEWVOL3,
                     OLDVOL4,NEWVOL4,OLDVOL5,NEWVOL5,OLDVOL6,NEWVOL6,
                     OLDSPD1,OLDSPD2,OLDSPD3,OLDSPD4,OLDSPD5,OLDSPD6,
                     I@PREV@@PRD@VOL,I@PREV@@PRD@VOL1,I@PREV@@PRD@VOL2,
                     I@PREV@@PRD@VOL3,I@PREV@@PRD@VOL4,I@PREV@@PRD@VOL5,
                     I@PREV@@PRD@VOL6,I@PREV@@PRD@VMT,I@PREV@@PRD@FFSPD,
                     I@PREV@@PRD@VC,I@PREV@@PRD@VDF,I@PREV@@PRD@SPD

 I@ITER@MDspd =  LI.1.I@ITER@MDspd
;
;
  _VOLMD =  LI.1.I@ITER@MDVOL
;
;
ENDRUN
ENDLOOP            ;
