%LET CSVFILE = /gpfsFS2/sasdata/nfs/SCL_MOC_Analytics/Category/Appt_Access/Data/Appointment_Data.csv;



proc import datafile="&CSVFILE"
out=APPT_DATA_IMPORT
dbms=csv
replace;
run;


ods select none;
ods output nlevels=Summ_og;
proc freq data=APPT_DATA_IMPORT nlevels ;
table _all_/missing;
run;
ods select all;
%LET BEGIN_TIME='17:30:00't;
PROC SQL;
CREATE TABLE AFTER_HOURS AS 
SELECT * FROM APPT_DATA_IMPORT 
WHERE APPOINTMENT_TIME > &BEGIN_TIME AND SHOW_CODE ='Y' 
AND APPOINTMENT_TYPE='Telephone Visit';
QUIT;


PROC SQL;
CREATE TABLE FOLLOW_UPS AS SELECT 
A.PATIENT_ID,
A.APPOINTMENT_DATE AS AFTERHOURS_APPOINTMENT_DATE,
A.APPOINTMENT_TIME AS AFTERHOURS_APPOINTMENT_TIME,
B.APPOINTMENT_DATE AS FOLLOW_UP_APPT_DT,
B.APPOINTMENT_TIME AS FOLLOW_UP_APPT_TIME
FROM AFTER_HOURS A LEFT JOIN APPT_DATA_IMPORT B 
ON A.PATIENT_ID=B.PATIENT_ID 
WHERE B.APPOINTMENT_DATE BETWEEN A.APPOINTMENT_DATE+1 
AND A.APPOINTMENT_DATE+7
ORDER BY A.PATIENT_ID, A.APPOINTMENT_DATE, B.APPOINTMENT_DATE;
QUIT;

PROC SQL;
CREATE TABLE FOLLOW_UPS_NO_DUPLICATES AS SELECT DISTINCT 
PATIENT_ID,
AFTERHOURS_APPOINTMENT_DATE,
AFTERHOURS_APPOINTMENT_TIME
FROM FOLLOW_UPS
ORDER BY 1,2,3;
QUIT;
/*JUST CHECKING SOMETHING*/
PROC SQL;
CREATE TABLE FOLLOW_UPS_NO_DUPLICATES_2 AS SELECT  
PATIENT_ID,
AFTERHOURS_APPOINTMENT_DATE,
AFTERHOURS_APPOINTMENT_TIME
FROM FOLLOW_UPS
GROUP BY PATIENT_ID, AFTERHOURS_APPOINTMENT_DATE, AFTERHOURS_APPOINTMENT_TIME
ORDER BY 1,2,3;
QUIT;
/*DONE CHECKING*/


PROC SQL;
CREATE TABLE INNEFFECTIVES AS SELECT B.* 
FROM FOLLOW_UPS_NO_DUPLICATES A 
LEFT JOIN AFTER_HOURS B ON A.PATIENT_ID=B.PATIENT_ID AND
A.AFTERHOURS_APPOINTMENT_DATE=B.APPOINTMENT_DATE AND
B.APPOINTMENT_TIME=A.AFTERHOURS_APPOINTMENT_TIME;
QUIT;

PROC SQL;
CREATE TABLE AFTER_HOURS_FLAGGED AS SELECT B.*,
CASE
	WHEN A.PATIENT_ID AND A.APPOINTMENT_DATE AND A.APPOINTMENT_TIME 
	THEN 1
	ELSE 0
	END AS INEFF_YN
FROM APPT_DATA_IMPORT B
LEFT JOIN INNEFFECTIVES A ON A.PATIENT_ID=B.PATIENT_ID AND
A.APPOINTMENT_DATE=B.APPOINTMENT_DATE AND
B.APPOINTMENT_TIME=A.APPOINTMENT_TIME
ORDER BY B.PATIENT_ID, B.APPOINTMENT_DATE, B.APPOINTMENT_TIME;
QUIT;

DATA COUNT;
SET AFTER_HOURS_FLAGGED;
WHERE INEFF_YN = 1;
RUN;

DATA TEST;
SET FOLLOW_UPS;
WHERE PATIENT_ID='BABBAEAA';
RUN;

PROC SQL;
CREATE TABLE COMPARING_APPT_BOOKING_CHECKIN AS 
SELECT APPOINTMENT_DATE, APPOINTMENT_TIME, BOOKING_DATE, BOOKING_TIME, CHECKIN_DATE, CHECKIN_TIME
FROM INNEFFECTIVES;
QUIT;

PROC SQL;
CREATE TABLE COMPARING_BOOKING_CHECKIN_INEFF AS 
SELECT INTCK('MINUTE',BOOKING_TIME, CHECKIN_TIME), CHECKIN_TIME, BOOKING_TIME
FROM AFTER_HOURS_FLAGGED WHERE INEFF_YN =1;
QUIT;

PROC SQL;
CREATE TABLE COMPARING_BOOKING_CHECKIN_EFF AS 
SELECT INTCK('MINUTE',BOOKING_TIME, CHECKIN_TIME), CHECKIN_TIME, BOOKING_TIME
FROM AFTER_HOURS_FLAGGED WHERE INEFF_YN =0;
QUIT;

PROC SQL;
CREATE TABLE TIME_DIFF_ANALYSIS AS 
SELECT *, INTCK('MINUTE',BOOKING_TIME, CHECKIN_TIME) AS DIFF_CHK_BOOK
FROM AFTER_HOURS_FLAGGED;
QUIT;

PROC TTEST DATA=TIME_DIFF_ANALYSIS;
	CLASS INEFF_YN;
	VAR DIFF_CHK_BOOK;
RUN;

PROC FREQ DATA=TIME_DIFF_ANALYSIS;
  TABLES PROVIDER_ID*INEFF_YN / CHISQ ;
RUN;










