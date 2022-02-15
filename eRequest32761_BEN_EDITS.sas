/*
general approach:
1) Try source data as little possible for efficiency
	a) think about what base data is and ultimately its the lowest level data (MRNs) that I'm interested in getting more data about
	B) USE VARIABLES/AVOID HARDCODING IF YOU CAN
2) like to grab data and use the work library as much as possible
3) summarize
4) add the distrution info

*/

%include "/gpfsFS2/sasdata/adhoc/tpmg/moc/scl/code/Utilities/sch_general_utility.sas";

LIBNAME QLIB '/gpfsFS2/sasdata/adhoc/tpmg/moc/_shared/data/pmt';

%_pc_libora(_oralib=KPBINC,_oraschema=KPBINC);


DATA DATES;
	PERIOD_BEG = INTNX('YEAR', TODAY(), -2, 'S');
	PERIOD_END = TODAY();

	
	/*FORMAT DESIRED: TIMESTAMP'2020-12-31 00:00:00' */
	CALL SYMPUT('BEG_DT',"TIMESTAMP'" || PUT(PERIOD_BEG, YYMMDD10.) || " 00:00:00'");
	CALL SYMPUT('END_DT',"TIMESTAMP'" || PUT(PERIOD_END, YYMMDD10.) || " 23:59:59'");

	FUTURE_BEG = TODAY()+1;
	FUTURE_END = TODAY()+90;

		/*FORMAT DESIRED: TIMESTAMP'2020-12-31 00:00:00' */4
	CALL SYMPUT('FUT_STRT',"TIMESTAMP'" || PUT(FUTURE_BEG, YYMMDD10.) || " 00:00:00'");
	CALL SYMPUT('FUT_END',"TIMESTAMP'" || PUT(FUTURE_END, YYMMDD10.) || " 23:59:59'");


	FORMAT PERIOD_BEG PERIOD_END MMDDYY10.;
RUN;
%PUT prnt_beg_dt: &BEG_DT;

%let RSRCE_ID = '1160157';
%let USER_ID = '161P348123';

PROC SQL;
	CREATE TABLE PANEL_LIST AS SELECT
		MEDFAC
		,MEDPCPRESCID
		,MEDPCPNAME
		,NAMEFULL
		,MRN12
		,MEDPCPDT
		,PCPFABL
		,PCPFABLDT
		,STREET
		,city
		,state
		,zip
	FROM QLIB.PMT_SASDATA
	WHERE MEDPCPRESCID = &RSRCE_ID
	;
QUIT;


PROC SQL;
%_pc_connora(_CONNECTION=GLOBAL);
	CREATE TABLE VST_HX_SHONE
	AS SELECT  * FROM CONNECTION TO ORA 
	(SELECT 
		*
	FROM kpbinc.outpatient_clinic_enc
	
	WHERE  
		contact_date >= &BEG_DT and 
 		rsrc_id = &RSRCE_ID
 	ORDER BY CONTACT_DATE);

	create table RECENT_messages as select
	* from connection to ora (
	select  a.*, b.pat_mrn_id from hcclnc.myc_mesg A
	LEFT JOIN HCCLNC.PATIENT B ON A.PAT_ID=B.PAT_ID
	where CREATED_TIME BETWEEN &BEG_DT AND &END_DT AND
	(to_user_id=&user_id or from_user_id=&user_id)
	 );

		CREATE TABLE FUT_VST_INFO AS SELECT *FROM CONNECTION TO ORA
		(SELECT
			SUBSTR(PATIENT.PAT_MRN_ID,5,8) as MRN
			, patient.pat_mrn_id
			, pat_enc.pat_id
			, substr(dep.dept_abbreviation,1,3) as fac_id
			, pat_enc.contact_date
			, pat_enc.external_visit_id
			, PAT_ENC.CHECKIN_TIME as pat_checkin
			, PAT_ENC.entry_TIME as checkin_time
			, PAT_ENC.APPT_STATUS_C
			, PATIENT.PAT_NAME
			, pat_enc.checkin_user_Id
			, PAT_ENC.PAT_ENC_cSN_ID
			, pat_enc.APPT_PRC_ID
			, emp.name as checkin_personnel
			, pat_enc.APPT_ENTRY_user_Id
			, ENTRY.name as ENTRY_personnel
			, dep.department_name
			, PAT_ENC.VISIT_PROV_ID
			, CLARITY_SER.PROV_NAME AS VISIT_PROV_NAME
			, CLARITY_SER.PROV_TYPE AS PROV_TYPE_HR
			, CLARITY_SER.CLINICIAN_TITLE
			, IDENTITY_SER_ID.IDENTITY_ID AS RSRCE_ID

		FROM  hcclnc.PAT_ENC		
		LEFT JOIN HCCLNC.PATIENT 
			ON PAT_ENC.PAT_ID = PATIENT.PAT_iD	
		LEFT join hcclnc.clarity_dep dep
			on pat_enc.department_Id =  dep.department_id		
		left join hcclnc.clarity_emp emp
			on pat_enc.checkin_user_id = emp.user_id
		left join hcclnc.clarity_emp ENTRY
			on pat_enc.APPT_ENTRY_user_id = ENTRY.user_id		
		LEFT JOIN HCCLNC.CLARITY_SER CLARITY_SER
			ON	PAT_ENC.VISIT_PROV_ID=CLARITY_SER.PROV_ID
		LEFT OUTER JOIN HCCLNC.IDENTITY_SER_ID IDENTITY_SER_ID
			ON  CLARITY_SER.PROV_ID=IDENTITY_SER_ID.PROV_ID
				AND IDENTITY_SER_ID.IDENTITY_TYPE_ID=1204	
		where pat_enc.contact_date between &FUT_STRT and &FUT_END
			AND (substr(dep.dept_abbreviation,1,3) IN (&FAC))
			AND PAT_ENC.APPT_STATUS_C = 1
			AND PAT_ENC.VISIT_PROV_ID = &PROV_ID
		order by dep.department_name, pat_enc.contact_date
		);
DISCONNECT FROM ORA;
QUIT;

proc sql;
create table recent_visit_ct as select
pat_mrn_id, 
case when
ENC_TYPE_C IN('101','50') then 'OFFICE_VISITS'
when ENC_TYPE_C IN ('70', '121144') then  'TELEPHONE_VISITS'
when ENC_TYPE_C IN ('62', '12179') then 'VIDEO_VISITS'
else 'OTHER_APPTS'
end as visit_type,
count(*) as visit_count
from VST_HX_SHONE
group by 1,2
;
quit;

proc transpose data=recent_visit_ct out=recent_visit_sum (drop=_name_);
by pat_mrn_id;
id visit_type;
var visit_count;
run;

proc sql;
create table patient_msg_ct as select
pat_mrn_id,
case when length(to_user_id)>1 then 'from_pat'
when length(from_user_id)>1 then 'to_pat'
else 'xxx'
end as msg_type,
count(*) as msg_ct 
from recent_messages
group by pat_mrn_id, msg_type;
quit;

proc transpose data= patient_msg_ct out=pat_msg_sum(drop=_name_);
by pat_mrn_id;
id msg_type;
var msg_ct;
run;

/*CLEAN UP FUTURE APPTS*/
DATA FUT_VST_INFO_MORE;
	SET FUT_VST_INFO (WHERE=(APPT_STATUS_C = 1));
	CONTACT_DATE = DATEPART(CONTACT_DATE);
	IF SUBSTR(EXTERNAL_VISIT_ID,1,4) = '1200' THEN DELETE;
	PARRS_DEPT = SUBSTR(EXTERNAL_VISIT_ID,LENGTH(EXTERNAL_VISIT_ID)-2,3);
	APPT_TP = TRIM(SUBSTR(EXTERNAL_VISIT_ID,5,4));
	FUTURE_INFO = TRIM(VISIT_PROV_NAME)||" on "||PUT(CONTACT_DATE,MMDDYY8.);	
	FORMAT CONTACT_DATE MMDDYY10.;
RUN;

PROC SORT DATA=FUT_VST_INFO_MORE;
	BY PAT_MRN_ID CONTACT_DATE;
RUN;

DATA FUT_VST_INFO_FIRST;
	SET FUT_VST_INFO_MORE;
	BY PAT_MRN_ID CONTACT_DATE;
	IF FIRST.PAT_MRN_ID;

RUN;

PROC SQL;
	CREATE TABLE RPT_PT_DETAILS AS SELECT
		A.MEDFAC
		,A.MEDPCPRESCID
		,A.MEDPCPNAME
		,A.NAMEFULL
		,A.MRN12
		,A.MEDPCPDT
		,A.PCPFABL
		,A.PCPFABLDT
		,A.STREET
		,A.city
		,A.state
		,A.zip
		,B.*
		,SUM(B.OFFICE_VISITS,B.TELEPHONE_VISITS,B.VIDEO_VISITS) AS TOTAL_VST_COUNT
		,C.*
		,D.CONTACT_DATE AS FUT_VST_DT
	FROM PANEL_LIST A
	LEFT JOIN RECENT_VISIT_SUM B
		ON A.MRN12 = B.PAT_MRN_ID
	LEFT JOIN PAT_MSG_SUM C
		ON A.MRN12 = C.PAT_MRN_ID
	LEFT JOIN FUT_VST_INFO_FIRST D
		ON A.MRN12 = D.PAT_MRN_ID
	;
QUIT;
/*

IF SUMMING USING DATASET THEN NEED TO REPLACE MISSING WITH ZEROS

data RECENT_VISIT_SUM;
set RECENT_VISIT_SUM;
array change _numeric_;
    do over change;
        if change=. then change=0;
    end;
run ;


DATA TEMP;
	SET RECENT_VISIT_SUM;
	TOTAL_VST_COUNT = SUM(OFFICE_VISITS+TELEPHONE_VISITS+ VIDEO_vISITS);
RUN;
*/