/*
eRequest ID: 32761
Please proved me with a visit/panel list for Dr. Paul Shone, MD, Internal Medicine at MTN. 
This list should include patient First Name, Last Name, Address, City, State, Zip, MRN#, First Visit, Last Visit, Total Visits & Upcoming Visits. 
It will need to include all patients who haven't utilized his services at all over the last 2 years (ALL DOV, TAV, VAV, Online Encounters.) 
Paul Shone, MD, NUID P348123, Resource ID 1160157, MNEUMONIC: SHONE

pmt dataset
(quality section will have 2 ways to connect, use the file location instead of the pdat macro)
visit info: kpbinc.outpatient_cinic_enc
secure messages: look at priority testing code

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

/*	CALL SYMPUT('BEG_DT',PERIOD_BEG);*/
/*	CALL SYMPUT('END_DT', PERIOD_END);*/


	FORMAT PERIOD_BEG PERIOD_END MMDDYY10.;
RUN;
%PUT prnt_beg_dt: &BEG_DT;


PROC SQL;
%_pc_connora(_CONNECTION=GLOBAL);
	CREATE TABLE BASE_OP_TABLE
	AS SELECT * FROM CONNECTION TO ORA 
	(SELECT 
		*
	FROM kpbinc.outpatient_clinic_enc
	
	WHERE  
		 
 rsrc_id = '1160157'
 	ORDER BY CONTACT_DATE);

DISCONNECT FROM ORA;
QUIT;
data base_op_table;
SET BASE_OP_TABLE;
CONTACT_DATE=DATEPART(CONTACT_DATE);
FORMAT CONTACT_DATE MMDDYY10.;
RUN;

PROC SQL;
%_pc_connora(_CONNECTION=GLOBAL);
	CREATE TABLE BEFORE_2_YRS
	AS SELECT  * FROM CONNECTION TO ORA 
	(SELECT 
		*
	FROM kpbinc.outpatient_clinic_enc
	
	WHERE  
		contact_date < &BEG_DT and 
 rsrc_id = '1160157'
 	ORDER BY CONTACT_DATE);

DISCONNECT FROM ORA;
QUIT;


PROC SQL;
CREATE TABLE NOT_RECENT_PATIENTS AS
SELECT DISTINCT A.PAT_MRN_ID
FROM BEFORE_2_YRS A
LEFT JOIN RECENT_2_YRS B  ON B.PAT_MRN_ID = A.PAT_MRN_ID
WHERE B.PAT_MRN_ID IS NULL;
QUIT;


PROC SQL;
%_pc_connora(_CONNECTION=GLOBAL);
	CREATE TABLE recent_2_yrs
	AS SELECT * FROM CONNECTION TO ORA 
	(SELECT 
		*
	FROM kpbinc.outpatient_clinic_enc
	
	WHERE  
		contact_date BETWEEN &BEG_DT AND &END_DT and 
 rsrc_id = '1160157'
 	ORDER BY CONTACT_DATE);

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
from recent_2_yrs
group by 1,2
;
quit;
proc transpose data=recent_visit_ct out=recent_visit_sum (drop=_name_);
by pat_mrn_id;
id visit_type;
var visit_count;
run;

PROC SQL;
CREATE TABLE NOT_RECENT_PATIENTS AS
SELECT DISTINCT A.PAT_MRN_ID
FROM BEFORE_2_YRS A
LEFT JOIN RECENT_2_YRS B  ON B.PAT_MRN_ID = A.PAT_MRN_ID
WHERE B.PAT_MRN_ID IS NULL;
QUIT;



proc sql;
%_pc_connora(_CONNECTION=GLOBAL);
create table RECENT_messages as select
* from connection to ora (
select  a.*, b.pat_mrn_id from hcclnc.myc_mesg A
LEFT JOIN HCCLNC.PATIENT B ON A.PAT_ID=B.PAT_ID
where CREATED_TIME BETWEEN &BEG_DT AND &END_DT AND
(to_user_id=&user_id or from_user_id=&user_id)
 );
disconnect from ora;
quit;

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

PROC SQL;
CREATE TABLE NOT_RECENT_PATIENTS_W_MESG AS
SELECT DISTINCT A.PAT_MRN_ID
FROM BEFORE_2_YRS A
LEFT JOIN RECENT_messages B  ON B.PAT_MRN_ID = A.PAT_MRN_ID
WHERE B.PAT_MRN_ID IS NULL;
QUIT;

proc sql;
%_pc_connora(_CONNECTION=GLOBAL);
create table OLD_messages as select
* from connection to ora (
select  B.PAT_MRN_ID from hcclnc.myc_mesg A
LEFT JOIN HCCLNC.PATIENT B ON A.PAT_ID=B.PAT_ID
where CREATED_TIME <&BEG_DT  AND
to_user_id=&user_id or from_user_id=&user_id
 );
disconnect from ora;
quit;




PROC SQL;

CREATE TABLE PATIENT_INFO_NOT_RECENT AS SELECT DISTINCT MRN12, NAMEFIRST, NAMELAST, STREET, CITY, STATE,ZIP, 
MIN(C.CONTACT_DATE) AS FIRST_VISIT FORMAT=mmddyy10.,
MAX(C.CONTACT_DATE) AS LAST_VISIT FORMAT=mmddyy10.,
COUNT(C.CONTACT_DATE) AS TOTAL_VISITS,
SUM(C.ENC_TYPE_C IN('101','50'))  AS OFFICE_VISITS,
SUM(C.ENC_TYPE_C IN ('70', '121144'))  AS TELEPHONE_VISITS,
SUM(C.ENC_TYPE_C IN ('62', '12179')) AS VIDEO_VISITS,
SUM(C.ENC_TYPE_C NOT IN ('101','50','70', '121144','62', '12179')) AS OTHER_APPTs

FROM qlib.PMT_SASDATA A 
LEFT JOIN NOT_RECENT_PATIENTS_W_MESG B ON A.MRN12=B.PAT_MRN_ID 
LEFT JOIN BASE_OP_TABLE C ON B.PAT_MRN_ID=C.PAT_MRN_ID 

WHERE B.PAT_MRN_ID IS NOT NULL
GROUP BY B.PAT_MRN_ID;
QUIT;



PROC SQL;

CREATE TABLE PATIENT_INFO_RECENT AS SELECT DISTINCT MRN12, NAMEFIRST, NAMELAST, STREET, CITY, STATE,ZIP, 
MIN(C.CONTACT_DATE) AS FIRST_VISIT FORMAT=mmddyy10.,
MAX(C.CONTACT_DATE) AS LAST_VISIT FORMAT=mmddyy10.,
COUNT(C.CONTACT_DATE) AS TOTAL_VISITS, 
B.*,
D.*
FROM qlib.PMT_SASDATA A 
LEFT JOIN recent_visit_sum B ON A.MRN12=B.PAT_MRN_ID 
LEFT JOIN BASE_OP_TABLE C ON B.PAT_MRN_ID=C.PAT_MRN_ID
left join pat_msg_sum d on a.mrn12=d.pat_mrn_id
WHERE medpcprescid= '1160157'
GROUP BY B.PAT_MRN_ID;
QUIT;