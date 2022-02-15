
%include "/gpfsFS2/sasdata/adhoc/tpmg/moc/scl/code/Utilities/sch_general_utility.sas";
LIBNAME RBNLIB '/gpfsFS2/sasdata/nfs/SCL_MOC_Analytics/Category/PNGJS2';

/*Clarity Tables*/
%_pc_libora(_oralib=HCCLNC,_oraschema=HCCLNC);
%_pc_libora(_oralib=KPBINC,_oraschema=KPBINC);


%LET FAC    = 'CMB';

/**LIBNAME PMT  '/gpfsFS2/sasdata/adhoc/tpmg/moc/_shared/data/pmt';*/
/*%_pc_libqip(_qiplib=PMT*/
/*	,_qipdatabase=QIPP01*/
/*	,_qipschema=PMTUser*/
/*	,_authdomain=NC_SQL_QIPDBPROD_Usr_Auth*/
/*	);*/

LIBNAME QLIB '/gpfsFS2/sasdata/adhoc/tpmg/moc/_shared/data/pmt';

%MACRO AGEMONTH(DTOBS1,DTOBS2);
INTCK('MONTH',&DTOBS1,&DTOBS2) - (DAY(&DTOBS2) < DAY(&DTOBS1))
%MEND AGEMONTH;



DATA DATES;
	
	today = TODAY();
	PERIOD_BEG = INTNX('YEAR', TODAY(), -2, 'S');
	

	
	/*FORMAT DESIRED: TIMESTAMP'2020-12-31 00:00:00' */
	
	CALL SYMPUT('today',"TIMESTAMP'" || PUT(today, YYMMDD10.) || " 23:59:59'");
	CALL SYMPUT('BEG_DT',"TIMESTAMP'" || PUT(PERIOD_BEG, YYMMDD10.) || " 00:00:00'");
	

	FORMAT PERIOD_BEG today MMDDYY10.;
RUN;

	

%PUT prnt_beg_dt: &today;
%LET FRAILTY_DX = 12144682;
%LET icd10_list = 'J96.20', 'K70.9','G30.9' ,'K74.5', 'I50.32' ,'N18.5', 'J96.10',
'I50.22', 'A81.00' ,'F02.81' ,'F02.80', 'J43.9' ,'N18.6' ,'I50.9', 'J84.10', 'J96.90', 'C77.0' ,'C78.00' ,'K74.60',
'F03.91', 'F03.90', 'I50.30', 'I50.20', 'A81.01', 'A81.01', 'A81.09', 'A81.00',
'A81.01',
'A81.09',
'C25.0',
'C25.1',
'C25.2',
'C25.3',
'C25.4',
'C25.7',
'C25.8',
'C25.9',
'C71.0',
'C71.1',
'C71.2',
'C71.3',
'C71.4',
'C71.5',
'C71.6',
'C71.7',
'C71.8',
'C71.9',
'C77.',
'C77.1',
'C77.2',
'C77.3',
'C77.4',
'C77.5',
'C77.8',
'C77.9',
'C78.00',
'C78.1',
'C78.2',
'C78.30',
'C78.39',
'C78.4',
'C78.5',
'C78.6',
'C78.7',
'C78.80',
'C78.89',
'C79.00',
'C79.10',
'C79.11',
'C79.19',
'C79.2',
'C79.31',
'C79.32',
'C79.40',
'C79.49',
'C79.51',
'C79.52',
'C79.60',
'C79.61',
'C79.62',
'C79.70',
'C79.71',
'C79.72',
'C79.81',
'C79.82',
'C79.89',
'C79.9',
'C91.00',
'C92.00',
'C93.00',
'C93.90,',
'C93.Z0',
'C94.30',
'C91.02',
' C92.02',
'C93.02',
'C93.92,',
'C93.Z2',
'C94.32',
'F01.50',
'F01.51',
'F02.80',
'F02.81,',
'F03.90',
'F03.91',
'F10.27',
'F10.97',
'G31.09',
'G31.83',
'F04',
'F10.96',
'F10.97',
'G10',
'G12.21',
'G20',
'G30.0',
'G30.1',
'G30.8',
'G30.9',
'G31.01',
'G31.09',
'G31.83',
'I09.81',
'I11.0',
'I13.0',
'I13.2',
'I50.20',
'I50.21',
'I50.22',
'I50.23',
'I50.30',
'I50.31',
'I50.32',
'I50.33',
'I50.40',
'I50.41',
'I50.42',
'I50.43',
'I50.810',
'I50.811',
'I50.812',
'I50.813',
'I50.814,',
'I50.82',
'I50.83',
'I50.84',
'I50.89',
'I50.9',
'I50.1',
'I12.0',
'I13.11',
'I13.2',
'N18.5',
'J43.0',
'J43.1',
'J43.2',
'J43.8',
'J43.9',
'J98.2',
'J98.3',
'J68.4',
'J84.10',
'J84.112',
'J84.17',
'J96.10',
'J96.11',
'J96.12',
'J96.20',
'J96.21',
'J96.22',
'J96.90',
'J96.91',
'J96.92',
'K70.10',
'K70.11',
'K70.2',
'K70.30',
'K70.31',
'K70.40',
'K70.41',
'K70.9',
'K74.0',
'K74.1',
'K74.2',
'K74.4',
'K74.5',
'K74.60',
'K74.69'
 ;
/**/
/* Base Table*/
PROC SQL;                                                                       
     CREATE TABLE CMB_HTN_PTS AS
     SELECT A.MEDFAC
		,A.NAMELAST                                                          
		,A.NAMEFIRST                                                         
		,A.NAMEFULL
		,A.MRN
		,A.AGE
		,A.BIRTHDATE
		,A.GENDER
		,A.MEDPCPNAME                                                        
		,A.MEDPCPRESCID
		,A.MEDPCPDT
		,A.RACE
		,A.MEDDEPTDT
		,A.STREET                                                            
		,A.CITY                                                              
		,A.STATE                                                             
		,A.ZIP
		,A.PHONE1
		,A.PHONE2 
		,A.POPPHASE 
		,A.POPHTN AS INHTNGOALPOP
		,A.POPDIAB
		,A.POPHTN
		,A.INSNF
		,A.INHOSPICE
		,A.BP1DIASDEPT
		,A.BP1
		,A.BP1DIARANGE
		,A.BP1DT FORMAT MMDDYY10. 
		,A.BP1HTNSTAGE
		,A.BP1SYSRANGE
		,A.BP2
		,A.BP2DIARANGE
		,A.BP2DT  FORMAT MMDDYY10. 
		,A.BP2HTNSTAGE
		,A.BP2SYSRANGE
		,A.BPCOMINGDUE
		,A.BPDUE
		,a.HTNBPINCONTROL
		,a.BPVALUEINCONTROL
		,A.MRN12
		,A.PCPFABL
		,A.PCPFABLDT
		,A.SECUREMESSAGING AS KPORGUSER
		,A.LANGVERBAL
		,A.SMKSTATUS
		,A.SMKLASTDT
		,A.BP1VISITTYPE
		,a.popesrd
		
     FROM QLIB.PMT_SASDATA A
     WHERE 
		A.MEDFAC in(&FAC)
		AND A.POPHTN = 'Y'
		AND A.AGE BETWEEN 18 AND 85
     ORDER BY A.MRN;
QUIT;

PROC SORT DATA=CMB_HTN_PTS (KEEP=MRN12) OUT=PTLIST;
	BY MRN12;
RUN;


%USHARE_TABLE_LOAD_TEST(PTLIST);

PROC SQL;
%_pc_connora(_CONNECTION=GLOBAL);
	CREATE TABLE COVERAGE_INFO
	AS SELECT * FROM CONNECTION TO ORA 
	(SELECT 
		Z.MRN12		
		,A.*
	FROM SCHMOC_PTLIST Z
	INNER JOIN HCCLNC.COVERAGE_MEMBER_LIST A
		ON Z.MRN12 = A.MEM_NUMBER
	ORDER BY Z.MRN12, A.MEM_EFF_FROM_DATE, A.MEM_EFF_TO_DATE
 	);

DISCONNECT FROM ORA;
QUIT;

DATA RBNLIB.CMB_HTN_PTS_MBRSHIP;
	SET COVERAGE_INFO;
RUN;


DATA  coverage_member_list_dwnload;
	SET RBNLIB.CMB_HTN_PTS_MBRSHIP;
RUN;

/*pregnant*/
proc sql;
%_pc_connora(_CONNECTION=GLOBAL);
create table preg as select * from connection to ora(
		select pat_mrn_id
		from hcclnc.patient
		where edd_dt is not null
		and edd_dt > &today);
disconnect from ora;
		
		
quit;
/*Acute inpatient*/
proc sql;
%_pc_connora(_CONNECTION=GLOBAL);
create table acute as select * from connection to ora(
		select   B.pat_MRN_id
		from hcclnc.pat_enc_hsp A
		LEFT JOIN HCCLNC.PATIENT B ON
		a.pat_id=b.pat_id
		where OSHPD_ADMSN_SRC_C=5);
disconnect from ora;
quit;


/*Current members*/
proc sql ;
%_pc_connora(_CONNECTION=GLOBAL);
create table current_members as select * from connection to ora(
		select b.pat_mrn_id
		from hcclnc.coverage_member_list a
		left join hcclnc.patient b on
		a.pat_id=b.pat_id
	
		where a.mem_eff_from_date<=&beg_dt and (a.MEM_EFF_to_DATE >= &today or 
		a.MEM_EFF_to_DATE is null));
disconnect from ora;
quit;
/*Remove acute, keep only current members, remove preg*/
PROC SQL;                                                                       
     CREATE TABLE CMB_HTN_PT_INFO AS
     SELECT A.MEDFAC
		,A.NAMELAST                                                          
		,A.NAMEFIRST                                                         
		,A.NAMEFULL
		,A.MRN
		,A.AGE
		,A.BIRTHDATE
		,A.GENDER
		,A.MEDPCPNAME                                                        
		,A.MEDPCPRESCID
		,A.MEDPCPDT
		,A.RACE
		,A.MEDDEPTDT
		,A.STREET                                                            
		,A.CITY                                                              
		,A.STATE                                                             
		,A.ZIP
		,A.PHONE1
		,A.PHONE2 
		,A.POPPHASE 
		,A.POPHTN AS INHTNGOALPOP
		,A.POPDIAB
		,A.POPHTN
		,A.INSNF
		,A.INHOSPICE
		,A.BP1DIASDEPT
		,A.BP1
		,A.BP1DIARANGE
		,A.BP1DT FORMAT MMDDYY10. 
		,A.BP1HTNSTAGE
		,A.BP1SYSRANGE
		,A.BP2
		,A.BP2DIARANGE
		,A.BP2DT  FORMAT MMDDYY10. 
		,A.BP2HTNSTAGE
		,A.BP2SYSRANGE
		,A.BPCOMINGDUE
		,A.BPDUE
		,a.HTNBPINCONTROL
		,a.BPVALUEINCONTROL
		,A.MRN12
		,A.PCPFABL
		,A.PCPFABLDT
		,A.KPORGUSER
		,A.LANGVERBAL
		,A.SMKSTATUS
		,A.SMKLASTDT
		,A.BP1VISITTYPE
	
		
     FROM CMB_HTN_PTS A
	 left join preg b on a.mrn12=b.pat_mrn_id
	 LEFT JOIN acute c on a.mrn12=c.pat_mrn_id
	 inner join (select distinct d.pat_mrn_id from current_members d)
	current_member_ids on a.mrn12=current_member_ids.pat_mrn_id
     WHERE 
		b.pat_mrn_id is null
		and c.pat_mrn_id is null
		and a.inhospice=''
		and a.popesrd=''
	
     ORDER BY A.MRN;
QUIT;

/*proc sql;*/
/*create  table test as select */
/** */
/*from CMB_HTN_PTS*/
/*inner join current_members*/
/*on */
/*quit;*/





data temp;
	set cmb_htn_pts;
	where HTNBPINCONTROL ='Y'; /*FLAG FOR NUMERATOR*/
RUN;

/*TARGET DENOM ~4900*/
/*TARGET NUMERATOR ~4150*/

proc sql;
	CREATE TABLE HYP_CRIT1 AS SELECT distinct 	
	BP1VISITTYPE, count(*)	 FROM TEMP 
	group by BP1VISITTYPE;
QUIT;




/*SDFGSDFGSDFGDFG*/

%MACRO AGEMONTH(DTOBS1,DTOBS2);
INTCK('MONTH',&DTOBS1,&DTOBS2) - (DAY(&DTOBS2) < DAY(&DTOBS1))
%MEND AGEMONTH;

data temp;
	set RBNLIB.cmb_htn_pts_mbrship;
	from_date = datepart(MEM_EFF_FROM_DATE);
	if MEM_EFF_TO_DATE=. then to_date = '31jan2022'd;
			else to_date = datepart(MEM_EFF_TO_DATE);
	

	IF MEM_EFF_TO_DATE = MEM_EFF_FROM_DATE THEN DELETE;
	*IF MEM_EFF_TO_DATE < MEM_EFF_FROM_DATE THEN DELETE;

	keep mrn12 from_date to_date coverage_length;
	format from_date to_date mmddyy10.;
run;

proc sort data=temp;
	by mrn12 descending from_date descending to_date;
run;

PROC SQL;
	CREATE TABLE TEMP_CLEAN AS SELECT
		MRN12
		,FROM_DATE
		,MAX(TO_DATE) AS TO_DATE FORMAT MMDDYY10.
	FROM TEMP
	GROUP BY 1,2
	ORDER BY MRN12, FROM_DATE DESC, TO_DATE DESC
	;
QUIT;


DATA TEMP2;
	SET TEMP_CLEAN;
	by mrn12 descending from_date;
	IF FIRST.MRN12 THEN MRNCOUNT = 1;
		ELSE MRNCOUNT+1;
	coverage_length = %agemonth(from_date,to_date);
run;

PROC SQL;
	CREATE TABLE TEMP2_SELF_JOIN AS SELECT
		A.*
		,B.TO_DATE AS PREV_REC_TO_DATE
		,B.COVERAGE_LENGTH AS PREV_REC_LENGTH
		,A.FROM_DATE - B.TO_DATE -1  AS MBR_BREAK_IN_DAYS
		
	FROM TEMP2 A
	LEFT JOIN TEMP2 B
		ON A.MRN12 = B.MRN12
		AND A.MRNCOUNT+1 = B.MRNCOUNT
	ORDER BY A.MRN12, A.MRNCOUNT
	;
QUIT;

/**/
/*removing duplicate end dates*/
PROC SQL;
	CREATE TABLE REMOVE_DUP_ends AS SELECT	
		A.*
	FROM TEMP2_SELF_JOIN A
	INNER JOIN (
		SELECT MRN12, min(FROM_DATE) as min_TO_DATE, TO_DATE  
		FROM TEMP2_SELF_JOIN
		GROUP BY MRN12, to_date) AS B
		ON A.MRN12=B.MRN12
		AND A.FROM_DATE=B.min_TO_DATE
		AND A.TO_DATE=B.to_date
	ORDER BY A.MRN12, A.MRNCOUNT;

QUIT;

DATA REM_DUP_ENDS_RECOUNT;
	SET REMOVE_DUP_ends;
	by mrn12 descending from_date;
	
	IF FIRST.MRN12 THEN MRNCOUNT2 = 1;
		ELSE MRNCOUNT2+1;
	coverage_length = %agemonth(from_date,to_date);
run;

/*Roll sum*/
proc sql;
  create table roll_sum as
  select  mrn12,
          
          sum(coverage_length) as ROLLING_SUM
 from REM_DUP_ENDS_RECOUNT
  group by mrn12
           
           ;
quit;
/*Dementia patients pat_ids*/

PROC SQL ;
%_pc_connora(_CONNECTION=GLOBAL);
	CREATE TABLE dementia_medication
	AS SELECT * FROM CONNECTION TO ORA 
	(SELECT distinct
		a.pat_id,
		b.pat_mrn_id
	FROM HCCLNC.order_med a
	left join hcclnc.patient b on
		a.pat_id=b.pat_id
	where 
 		(lower(a.description) like '%memantine%'
		or lower(a.description) like '%rivastigmine%'
		or lower(a.description) like '%galantamine%')
		or lower(a.description) like '%donepezil%'
 	);

DISCONNECT FROM ORA;
QUIT;

/**/
/*frailty ids*/
PROC SQL;
%_pc_connora(_CONNECTION=GLOBAL);
	CREATE TABLE frailty
	AS SELECT * FROM CONNECTION TO ORA 
	(SELECT 
		a.*,
		b.pat_mrn_id
		
	FROM HCCLNC.problem_list a
	left join hcclnc.patient b on
		a.pat_id=b.pat_id
	where dx_id=&FRAILTY_DX
 	);

DISCONNECT FROM ORA;
quit;
/*Frailty over 81*/
proc sql;
	create table frality_over_81
	as select distinct a.pat_id, a.pat_mrn_id, b.age
	from frailty a
	left join qlib.PMT_SASDATA b on pat_mrn_id=b.mrn12
	where b.age>81;
quit;


QUIT;
/*advanced illness patients*/
PROC SQL ;
%_pc_connora(_CONNECTION=GLOBAL);
	CREATE TABLE advanced_illness_patients
	AS SELECT * FROM CONNECTION TO ORA 
	(SELECT distinct 
		c.pat_id,
		c.pat_mrn_id
	FROM HCCLNC.clarity_edg a

	left join HCCLNC.problem_list b on 
		a.dx_id=b.dx_id
	left join hcclnc.patient c on
		b.pat_id=c.pat_id
	where a.CURRENT_ICD10_LIST in (&icd10_list)
 	);

DISCONNECT FROM ORA;
QUIT;

/*advanced ill frailty over 66*/
proc sql;
	create table frailty_advanced_ill
	as select distinct a.pat_id, a.pat_mrn_id, b.age
	from advanced_illness_patients a
	left join qlib.PMT_SASDATA b on a.pat_mrn_id=b.mrn12
	left join frailty c on a.pat_mrn_id=c.pat_mrn_id
	where b.age>66 and c.pat_mrn_id is not null;
quit;


/*REMOVE ADVANCED ILLNESS, FRAILTY, DEMENTIA PATIENTS*/
PROC SQL;                                                                       
     CREATE TABLE CMB_HTN_PT_CRITERIA_2 AS
     SELECT A.MEDFAC
		,A.NAMELAST                                                          
		,A.NAMEFIRST                                                         
		,A.NAMEFULL
		,A.MRN
		,A.AGE
		,A.BIRTHDATE
		,A.GENDER
		,A.MEDPCPNAME                                                        
		,A.MEDPCPRESCID
		,A.MEDPCPDT
		,A.RACE
		,A.MEDDEPTDT
		,A.STREET                                                            
		,A.CITY                                                              
		,A.STATE                                                             
		,A.ZIP
		,A.PHONE1
		,A.PHONE2 
		,A.POPPHASE 
		,A.POPHTN AS INHTNGOALPOP
		,A.POPDIAB
		,A.POPHTN
		,A.INSNF
		,A.INHOSPICE
		,A.BP1DIASDEPT
		,A.BP1
		,A.BP1DIARANGE
		,A.BP1DT FORMAT MMDDYY10. 
		,A.BP1HTNSTAGE
		,A.BP1SYSRANGE
		,A.BP2
		,A.BP2DIARANGE
		,A.BP2DT  FORMAT MMDDYY10. 
		,A.BP2HTNSTAGE
		,A.BP2SYSRANGE
		,A.BPCOMINGDUE
		,A.BPDUE
		,a.HTNBPINCONTROL
		,a.BPVALUEINCONTROL
		,A.MRN12
		,A.PCPFABL
		,A.PCPFABLDT
		,A.KPORGUSER
		,A.LANGVERBAL
		,A.SMKSTATUS
		,A.SMKLASTDT
		,A.BP1VISITTYPE
	
		
     FROM CMB_HTN_PT_INFO A
	 left join frailty_advanced_ill b on a.mrn12=b.pat_mrn_id
	 LEFT JOIN frality_over_81 c on a.mrn12=c.pat_mrn_id
	 LEFT JOIN dementia_medication D ON A.MRN12=D.PAT_MRN_ID
     WHERE 
		b.pat_mrn_id is null
		and c.pat_mrn_id is null
		and D.PAT_MRN_ID IS NULL
	
     ORDER BY A.MRN;
QUIT;



data temp_CRIT_2;
	set CMB_HTN_PT_CRITERIA_2;
	where HTNBPINCONTROL ='Y'; /*FLAG FOR NUMERATOR*/
RUN;
