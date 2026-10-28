
SET FEEDBACK OFF
SET LINESIZE 130
SET TIMING ON
SET FEEDBACK ON
SET LINESIZE 200
SET DEFINE OFF
SET TAB OFF
SET ARRAYSIZE 5000 
SET SERVEROUTPUT ON SIZE UNLIMITED

DECLARE 
  v_JOB_VERSION  VARCHAR2(100); 
BEGIN 
  BEGIN 
    SELECT DBMS_LOB.SUBSTR(VALUE, 100, 1) INTO v_JOB_VERSION FROM MAP_OPTION WHERE BUSINESS_AREA = 'DEMO' AND NAME = 'JOB_VERSION' AND ROWNUM = 1; 
  EXCEPTION WHEN OTHERS THEN 
    v_JOB_VERSION := '?'; 
  END; 
  DATAFLEX_PKG.PUT_LINE('JOB         : ' || v_JOB_VERSION); 
  DATAFLEX_PKG.PUT_LINE('Start       : ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') || ' ' ||  TO_CHAR(SYSDATE, 'DAY')); 
  DATAFLEX_PKG.PUT_LINE('DB NAME     : ' || DBMS_STANDARD.DATABASE_NAME); 
  DATAFLEX_PKG.PUT_LINE('INST_ID     : ' || TO_CHAR(DBMS_STANDARD.INSTANCE_NUM)); 
  DATAFLEX_PKG.PUT_LINE('Table Name  : ' || 'DEMOTOBE.TB_CUST'); 
  DATAFLEX_PKG.PUT_LINE('Entity Name : ' || '고객'); 
END; 
/ 

--PLSQL START----------------------------------------------------------------------------------------------------------- 

DECLARE 
  v_TAR_TABLE_NAME  MIG_LOG.TARGET_TABLE%TYPE            := 'DEMOTOBE.TB_CUST'; 
  v_TAR_TABOWNER    MIG_LOG.TARGET_TABLE%TYPE            := 'DEMOTOBE'; 
  v_TAR_TABNAME     MIG_LOG.TARGET_TABLE%TYPE            := 'TB_CUST'; 
  v_SRC_TABLE_NAME  MIG_LOG.SOURCE_TABLE%TYPE            := ''; 
  v_SRC_TABLE_ALL   MIG_LOG.SOURCE_TABLE%TYPE            := ''; 
  v_SRC_TABLE_ID    VARCHAR2(20)                         := ''; 
  v_TABLE_ID        MIG_LOG.TABLE_ID%TYPE                := 'T000003'; 
  v_TABLE_COMMENT   VARCHAR(4000)                        := '고객'; 
  v_JOB_STEP        MIG_LOG.JOB_STEP%TYPE                := SUBSTRB('02.고객:GUI', 1, 100); 
  c_START_DTM       CONSTANT  MIG_LOG.START_TIME%TYPE    :=  SYSTIMESTAMP;       
  v_START_DTM       MIG_LOG.START_TIME%TYPE              :=  SYSTIMESTAMP;       
  v_ROW             MIG_LOG.NUM_ROWS%TYPE                :=  0; 
  v_TOTAL_ROW       MIG_LOG.NUM_ROWS%TYPE                :=  0; 
  v_SEQ             MIG_LOG.SEQ%TYPE                     :=  0; 
  v_MERGE_BEFORE    NUMBER                               :=  0; 
  v_MERGE_INS       NUMBER                               :=  0; 
  v_NOTE            MIG_LOG.NOTE%TYPE; 
  v_GET_TIME        NUMBER                               :=  DBMS_UTILITY.GET_TIME; 

/*
고객 기본 + 상세 + 대표 주소. 주민번호는 암호화, 등급은 코드 변환
*/

BEGIN 

  -- following COMMIT prevents ALTER SESSION error 
  IF (DBMS_TRANSACTION.LOCAL_TRANSACTION_ID IS NOT NULL) THEN 
    COMMIT; 
  END IF; 

  DATAFLEX_PKG.g_RETURN := DATAFLEX_PKG.UDF_EXECUTE('ALTER TABLE DEMOTOBE.TB_CUST'); 

  -- REMOVE INDEXES BEFORE CONVERSION 
  DATAFLEX_INDEX_PKG.REMOVE_INDEX('DEMOTOBE.TB_CUST'); 

  -- DISABLE TRIGGERS BEFORE CONVERSION 
  DATAFLEX_INDEX_PKG.DISABLE_TRIGGER('DEMOTOBE.TB_CUST'); 

  -- 1. make table NOLOGGING.  2. SET_MODULE 
  DATAFLEX_PKG.P_INIT('DEMOTOBE.TB_CUST', 'T000003', v_TABLE_COMMENT, v_JOB_STEP, DATAFLEX_PKG.TRUNC_MODE); 

--Main Block------------------------------------------------------------------------------------------------------------ 

  v_GET_TIME       := DBMS_UTILITY.GET_TIME;
  v_START_DTM      := SYSDATE;

  v_SRC_TABLE_NAME := 'DEMOASIS.CU_CUST, DEMOASIS.CU_CUST_DTL, DEMOASIS.CU_CUST_ADDR';
  v_SRC_TABLE_ALL  := v_SRC_TABLE_ALL || '[1/1 : ' || v_SRC_TABLE_NAME || ']';
  v_SEQ            := 1;
  v_SRC_TABLE_ID   := 'A000005';

  DATAFLEX_PKG.PUT_LINE('Start conversion script group# 1.');
  DBMS_APPLICATION_INFO.SET_ACTION('T000003 - 1/1-' || TO_CHAR(SYSDATE, 'YYYYMMDD HH24:MI:SS'));

  /* 1 Start */

  INSERT /*+ APPEND PARALLEL(T 1) *//* DataFlex.Oracle T000003 1 of 1 */ 
         INTO DEMOTOBE.TB_CUST  T 
        (
           T.CUST_ID                                                           -- VARCHAR2(10)     NN   Y     고객ID
         , T.CUST_NAME                                                         -- VARCHAR2(50)     NN         고객명
         , T.RRN_ENC                                                           -- VARCHAR2(200)               주민등록번호(암호화)
         , T.TEL                                                               -- VARCHAR2(20)                연락처
         , T.EMAIL                                                             -- VARCHAR2(60)                이메일
         ----------------------------------------------------------------- 005
         , T.GRADE_CODE                                                        -- VARCHAR2(20)                등급코드
         , T.JOIN_DATE                                                         -- DATE                        가입일자
         , T.STATUS_CODE                                                       -- VARCHAR2(20)                상태코드
         , T.ZIP                                                               -- VARCHAR2(6)                 우편번호
         , T.ADDR                                                              -- VARCHAR2(400)               주소
         ----------------------------------------------------------------- 010
         , T.BIRTH_DATE                                                        -- DATE                        생년월일
         , T.SEX_CODE                                                          -- CHAR(1)                     성별코드
         , T.JOB_CODE                                                          -- VARCHAR2(20)                직업코드
         , T.MEMO                                                              -- VARCHAR2(500)               메모
         , T.CREATED                                                           -- DATE                        등록일시
         ----------------------------------------------------------------- 015
        )
  SELECT   /*+ FULL(A1) FULL(A2) FULL(A3)
               PARALLEL(A1 1) PARALLEL(A2 1) PARALLEL(A3 1)
               OPT_ESTIMATE(TABLE A1 ROWS=500) OPT_ESTIMATE(TABLE A2 ROWS=500) OPT_ESTIMATE(TABLE A3 ROWS=666)
               USE_HASH(A1 A2 A3)
           */
           A1.CUST_NO AS CUST_ID                                               -- ASIS: VARCHAR2(10)     NN   Y     고객번호
         , A1.CUST_NM AS CUST_NAME                                             -- ASIS: VARCHAR2(50)                
         , RAWTOHEX(STANDARD_HASH(A1.RRN, 'SHA256')) AS RRN_ENC                -- ASIS: VARCHAR2(13)                주민등록번호대상 컬럼이 암호화(ENCRYPT_YN) — 옵션 ENCRYPT FUNCTION HEAD · TAIL 로 감싸인다
         , A1.TEL AS TEL                                                       -- ASIS: VARCHAR2(20)                
         , SUBSTRB(A1.EMAIL, 1, 60) AS EMAIL                                   -- TOBE: VARCHAR2(60)                이메일
         ----------------------------------------------------------------- 005
         , NVL((SELECT M.TARGET_CODE FROM DATAFLEX.MAP_CODE M
                WHERE  M.SOURCE_SYSTEM_NAME = 'DEMOASIS' AND M.SOURCE_CODE_GROUP = 'GRADE'
                AND    M.SOURCE_CODE = A1.GRADE_CD), A1.GRADE_CD) AS GRADE_CODE     -- TOBE: VARCHAR2(20)                등급코드
         , DATAFLEX_PKG.UDF_CHAR2DATE(A1.JOIN_DT) AS JOIN_DATE                 -- TOBE: DATE                        가입일자
         , A1.STAT_CD AS STATUS_CODE                                           -- ASIS: VARCHAR2(2)                 
         , A3.ZIP AS ZIP                                                       -- ASIS: VARCHAR2(6)                 대표 주소 (REP_YN = Y) 인라인뷰
         , TRIM(A3.ADDR1 || ' ' || A3.ADDR2) AS ADDR                           -- TOBE: VARCHAR2(400)               주소
         ----------------------------------------------------------------- 010
         , DATAFLEX_PKG.UDF_CHAR2DATE(A2.BIRTH_DT) AS BIRTH_DATE               -- TOBE: DATE                        생년월일
         , A2.SEX_CD AS SEX_CODE                                               -- ASIS: CHAR(1)                     
         , A2.JOB_CD AS JOB_CODE                                               -- ASIS: VARCHAR2(10)                
         , SUBSTRB(A2.MEMO, 1, 500) AS MEMO                                    -- TOBE: VARCHAR2(500)               메모
         , SYSDATE AS CREATED                                                  -- TOBE: DATE                        등록일시
         ----------------------------------------------------------------- 015
  FROM     DEMOASIS.CU_CUST                                    A1         -- A000005                     500 Rows                   고객                                                        
           LEFT  JOIN  DEMOASIS.CU_CUST_DTL                    A2         -- A000007                     500 Rows                   고객상세                                                    
                   ON (A1.CUST_NO = A2.CUST_NO)
           LEFT  JOIN (
                         SELECT CUST_NO, ZIP, ADDR1, ADDR2 
                          FROM   DEMOASIS.CU_CUST_ADDR 
                          WHERE  REP_YN = 'Y' 
                      )  A3
                   ON (A1.CUST_NO = A3.CUST_NO)
  WHERE    1 = 1 
  ;

  /* 1 End */

  v_ROW := SQL%ROWCOUNT;
  v_TOTAL_ROW := v_ROW;
  COMMIT;

  DATAFLEX_PKG.PUT_LINE(' ');
  DATAFLEX_PKG.PUT_LINE('01 : ' || TRIM(TO_CHAR(v_ROW, '999,999,999,999,990')) || ' Rows Inserted');
  DATAFLEX_PKG.PUT_LINE('01 : ' || TO_CHAR(DATAFLEX_PKG.GET_ELAPSED_TIME(v_GET_TIME, DBMS_UTILITY.GET_TIME)) || ' Seconds (' || TRIM(DBMS_XPLAN.FORMAT_TIME_S(DATAFLEX_PKG.GET_ELAPSED_TIME(v_GET_TIME, DBMS_UTILITY.GET_TIME))) || ')');
  DATAFLEX_PKG.PUT_LINE(' ');

  DATAFLEX_PKG.P_JOBLOG(v_SEQ, DATAFLEX_PKG.g_SEQ, v_TABLE_ID, v_START_DTM, SYSDATE, v_ROW, SQLCODE, SQLERRM, v_JOB_STEP, v_SRC_TABLE_NAME, v_TAR_TABLE_NAME, p_SRC_TABLE_ID => v_SRC_TABLE_ID);

  ----------------------------------------------------------------------------------------------------------------------

  v_SEQ            := 0; 

  DATAFLEX_PKG.g_RETURN := DATAFLEX_PKG.UDF_EXECUTE('ALTER TABLE DEMOTOBE.TB_CUST LOGGING NOPARALLEL'); 

  -- Build INDEX After Load 
  DATAFLEX_INDEX_PKG.RESTORE_INDEX('DEMOTOBE.TB_CUST', 2); 

  IF (DATAFLEX_PKG.g_TRIGGER_REENABLED = 'Y') THEN 
    DATAFLEX_INDEX_PKG.ENABLE_TRIGGER('DEMOTOBE.TB_CUST'); 
  END IF; 

  DATAFLEX_PKG.PUT_LINE(''); 
  DATAFLEX_PKG.PUT_LINE(v_JOB_STEP || ':' || v_TAR_TABLE_NAME || ': ' || TRIM(TO_CHAR(v_TOTAL_ROW, '999,999,999,999,990')) || ' Rows Insert'); 
  DATAFLEX_PKG.PUT_LINE(v_JOB_STEP || ':' || v_TAR_TABLE_NAME || ':' || v_TABLE_ID || ':' || SUBSTRB(v_TABLE_COMMENT, 1, 100) || ' End : ' 
                                             || TO_CHAR(DATAFLEX_PKG.GET_ELAPSED_TIME(v_GET_TIME, DBMS_UTILITY.GET_TIME)) || ' Seconds (' || TRIM(DBMS_XPLAN.FORMAT_TIME_S(DATAFLEX_PKG.GET_ELAPSED_TIME(v_GET_TIME, DBMS_UTILITY.GET_TIME))) || ')'); 
  DATAFLEX_PKG.P_JOBLOG(0, DATAFLEX_PKG.g_SEQ, v_TABLE_ID, c_START_DTM, SYSDATE, v_TOTAL_ROW, SQLCODE, SQLERRM, v_JOB_STEP, v_SRC_TABLE_ALL, v_TAR_TABLE_NAME); 
  RETURN; 
 
EXCEPTION 
  WHEN OTHERS THEN 
    IF (DBMS_TRANSACTION.LOCAL_TRANSACTION_ID IS NOT NULL) THEN 
      ROLLBACK; 
    END IF; 
 
    IF (v_SEQ > 0) THEN 
      DATAFLEX_PKG.PUT_LINE(' '); 
      DATAFLEX_PKG.PUT_LINE('##### Conversion script group# '|| TO_CHAR(v_SEQ) ||' failed. #####'); 
      DATAFLEX_PKG.PUT_LINE(' '); 
    END IF; 

    DATAFLEX_PKG.PUT_LINE(v_JOB_STEP || ':' || v_TAR_TABLE_NAME || ':' || v_TABLE_ID || ':' || SUBSTRB(v_TABLE_COMMENT, 1, 100) || ' End : ' 
                                               || TO_CHAR(DATAFLEX_PKG.GET_ELAPSED_TIME(v_GET_TIME, DBMS_UTILITY.GET_TIME)) || ' Seconds (' || TRIM(DBMS_XPLAN.FORMAT_TIME_S(DATAFLEX_PKG.GET_ELAPSED_TIME(v_GET_TIME, DBMS_UTILITY.GET_TIME))) || ')'); 
    DATAFLEX_PKG.PUT_LINE(TO_CHAR(SQLCODE) || ' ' || SQLERRM); 
    DATAFLEX_PKG.PUT_LINE(' '); 
    DATAFLEX_PKG.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_STACK); 
    DATAFLEX_PKG.P_JOBLOG(v_SEQ, DATAFLEX_PKG.g_SEQ, v_TABLE_ID, v_START_DTM, SYSDATE, v_TOTAL_ROW, SQLCODE, SQLERRM, v_JOB_STEP, v_SRC_TABLE_NAME, v_TAR_TABLE_NAME, DBMS_UTILITY.FORMAT_ERROR_STACK, p_SRC_TABLE_ID => v_SRC_TABLE_ID); 
    IF (v_SEQ > 0) THEN 
      DATAFLEX_PKG.P_JOBLOG(0, DATAFLEX_PKG.g_SEQ, v_TABLE_ID, c_START_DTM, SYSDATE, v_TOTAL_ROW, SQLCODE, SQLERRM, v_JOB_STEP, v_SRC_TABLE_ALL, v_TAR_TABLE_NAME, p_SRC_TABLE_ID => v_SRC_TABLE_ID); 
    END IF; 

END; 
--PLSQL END------------------------------------------------------------------------------------------------------------- 
/ 
PROMPT ## Finished : DEMOTOBE.TB_CUST 
PROMPT ############################################################################## 

