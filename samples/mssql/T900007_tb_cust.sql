/*
고객 기본 + 상세 + 대표 주소. 주민번호는 암호화, 등급은 코드 변환
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
GO

DECLARE @msg nvarchar(max), @job_version nvarchar(50);
SELECT TOP (1) @job_version = LEFT(value, 50) FROM dataflex.map_option WHERE business_area = N'DEMO' AND name = N'JOB_VERSION';
SET @msg = N'JOB         : ' + ISNULL(@job_version, N'?');
EXEC dataflex.put_line @msg;
SET @msg = N'Start       : ' + FORMAT(SYSDATETIME(), N'yyyy-MM-dd HH:mm:ss dddd', N'en-US');
EXEC dataflex.put_line @msg;
SET @msg = N'DB NAME     : ' + DB_NAME();
EXEC dataflex.put_line @msg;
SET @msg = N'Server      : ' + ISNULL(@@SERVERNAME, CAST(SERVERPROPERTY('ServerName') AS nvarchar(128))) + N' (SQL Server ' + CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(30)) + N')';
EXEC dataflex.put_line @msg;
EXEC dataflex.put_line N'Table Name  : demotobe.tb_cust';
EXEC dataflex.put_line N'Entity Name : 고객';
GO

-- 1. 준비 ------------------------------------------------------------------------------------------------------------
DECLARE @msg nvarchar(max), @err nvarchar(30), @emsg nvarchar(4000), @seq int, @now datetime2(0), @st datetime2(0) = SYSDATETIME(),
        @t_start nvarchar(30) = CONVERT(nvarchar(30), SYSDATETIME(), 121),
        @tar  nvarchar(400)  = N'demotobe.tb_cust',
        @tid  nvarchar(20)   = N'T900007',
        @cmt  nvarchar(4000) = N'고객',
        @step nvarchar(100)  = LEFT(N'02.고객:GUI', 100);
EXEC sys.sp_set_session_context N'dataflex.prep_ok', N'N';
EXEC sys.sp_set_session_context N'dataflex.load_ok', N'N';
EXEC sys.sp_set_session_context N'dataflex.t_start', @t_start;
EXEC sys.sp_set_session_context N'dataflex.t_rows', N'0';
EXEC sys.sp_set_session_context N'dataflex.t_src_all', N'';

BEGIN TRY
  BEGIN TRANSACTION;
  -- REMOVE INDEXES BEFORE CONVERSION 
  EXEC dataflex.remove_index @tar;
  -- DISABLE TRIGGERS BEFORE CONVERSION 
  EXEC dataflex.disable_trigger @tar;
  -- 1. TRUNCATE (TRUNC 모드)  2. CONTEXT_INFO  3. 진행 상태 MIG_LOG_FINAL 
  EXEC dataflex.p_init @tar, @tid, @cmt, @step, N'TRUNC';
  COMMIT;
  EXEC sys.sp_set_session_context N'dataflex.prep_ok', N'Y';
  EXEC sys.sp_set_session_context N'dataflex.load_ok', N'Y';
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK;
  SELECT @err = CAST(ERROR_NUMBER() AS nvarchar(30)), @emsg = ERROR_MESSAGE(), @now = SYSDATETIME(), @seq = dataflex.g_seq();
  SET @msg = @step + N':' + @tar + N':' + @tid + N' prepare failed : ' + @err + N' ' + @emsg;
  EXEC dataflex.put_line @msg;
  EXEC dataflex.p_joblog 0, @seq, @tid, @st, @now, 0, @err, @emsg, @step, N'', @tar;
END CATCH
GO

-- 2. 적재 ------------------------------------------------------------------------------------------------------------
DECLARE @msg nvarchar(max), @sql nvarchar(max), @ci varbinary(128), @failed bit = 0,
        @row bigint = 0, @total bigint = 0, @note nvarchar(4000), @seq int = 0, @mig_no int,
        @start datetime2(6), @c_start datetime2(6), @now datetime2(0), @err nvarchar(30), @emsg nvarchar(4000),
        @src nvarchar(max) = N'', @src_all nvarchar(4000) = N'', @src_id nvarchar(20),
        @tar  nvarchar(400)  = N'demotobe.tb_cust',
        @tid  nvarchar(20)   = N'T900007',
        @cmt  nvarchar(4000) = N'고객',
        @step nvarchar(100)  = LEFT(N'02.고객:GUI', 100);
IF ISNULL(CAST(SESSION_CONTEXT(N'dataflex.load_ok') AS nvarchar(1)), N'N') <> N'Y'
BEGIN
  SET @msg = @tar + N' : load skipped - prepare failed';
  EXEC dataflex.put_line @msg;
  SET @failed = 1;
END
SET @c_start = ISNULL(TRY_CAST(CAST(SESSION_CONTEXT(N'dataflex.t_start') AS nvarchar(30)) AS datetime2(6)), SYSDATETIME());
SET @mig_no  = dataflex.g_seq();

  -- 묶음 1 (1/1) ---------------------------------------------------------------------------------------------
  IF @failed = 0
  BEGIN
    SET @start   = SYSDATETIME();
    SET @src     = N'demoasis.cu_cust, demoasis.cu_cust_dtl, demoasis.cu_cust_addr';
    SET @src_all = LEFT(@src_all + N'[1/1 : ' + @src + N']', 4000);
    SET @seq     = 1;
    SET @src_id  = N'A900008';
    EXEC dataflex.put_line N'Start conversion script group# 1.';
    SET @ci = CAST(LEFT(N'DATAFLEX:T900007 - 1/1-' + CONVERT(nvarchar(20), SYSDATETIME(), 120), 64) AS varbinary(128));
    SET CONTEXT_INFO @ci;
    -- SQL Check: 자동 힌트 HASH JOIN 으로 계획을 만들지 못해(8622) 빼고 만들었습니다

    SET @row  = 0;
    SET @note = NULL;
    /* 1 Start */
    BEGIN TRY
      SET @sql = N'
  INSERT /* DataFlex.MSSQL T900007 1 of 1 */
         INTO demotobe.tb_cust WITH (TABLOCK)
        (
             cust_id                                                           -- nvarchar(10)     NN   Y     고객ID
         ,   cust_name                                                         -- nvarchar(50)     NN         고객명
         ,   rrn_enc                                                           -- nvarchar(200)               주민등록번호(암호화)
         ,   tel                                                               -- nvarchar(20)                연락처
         ,   email                                                             -- nvarchar(60)                이메일
         ----------------------------------------------------------------- 005
         ,   grade_code                                                        -- nvarchar(20)                등급코드
         ,   join_date                                                         -- datetime2(0)                가입일자
         ,   status_code                                                       -- nvarchar(20)                상태코드
         ,   zip                                                               -- nvarchar(6)                 우편번호
         ,   addr                                                              -- nvarchar(400)               주소
         ----------------------------------------------------------------- 010
         ,   birth_date                                                        -- datetime2(0)                생년월일
         ,   sex_code                                                          -- nchar(1)                    성별코드
         ,   job_code                                                          -- nvarchar(20)                직업코드
         ,   memo                                                              -- nvarchar(500)               메모
         ,   created                                                           -- datetime2(0)                등록일시
         ----------------------------------------------------------------- 015
        )
  SELECT
           A1.cust_no AS cust_id                                               -- ASIS: nvarchar(10)     NN   Y     고객번호
         , A1.cust_nm AS cust_name                                             -- ASIS: nvarchar(50)                
         , CONVERT(nvarchar(64), HASHBYTES(''SHA2_256'', CONVERT(nvarchar(4000),A1.rrn)), 2) AS rrn_enc -- ASIS: nvarchar(13)                주민등록번호대상 컬럼이 암호화(ENCRYPT_YN) — 옵션 ENCRYPT FUNCTION HEAD · TAIL 로 감싸인다
         , A1.tel AS tel                                                       -- ASIS: nvarchar(20)                
         , left(A1.email, 60) AS email                                         -- TOBE: nvarchar(60)                이메일
         ----------------------------------------------------------------- 005
         , coalesce((SELECT m.target_code FROM dataflex.map_code m
                     WHERE  m.source_system_name = ''DEMOASIS'' AND m.source_code_group = ''GRADE''
                     AND    m.source_code = A1.grade_cd), A1.grade_cd) AS grade_code     -- TOBE: nvarchar(20)                등급코드
         , dataflex.udf_char2date(A1.join_dt) AS join_date                     -- TOBE: datetime2(0)                가입일자
         , A1.stat_cd AS status_code                                           -- ASIS: nvarchar(2)                 
         , A3.zip AS zip                                                       -- ASIS: nvarchar(6)                 대표 주소 (rep_yn = Y) 인라인뷰
         , nullif(concat_ws('' '', A3.addr1, A3.addr2), '''') AS addr              -- TOBE: nvarchar(400)               주소
         ----------------------------------------------------------------- 010
         , dataflex.udf_char2date(A2.birth_dt) AS birth_date                   -- TOBE: datetime2(0)                생년월일
         , A2.sex_cd AS sex_code                                               -- ASIS: nchar(1)                    
         , A2.job_cd AS job_code                                               -- ASIS: nvarchar(10)                
         , left(A2.memo, 500) AS memo                                          -- TOBE: nvarchar(500)               메모
         , CONVERT(datetime2(0), SYSDATETIME()) AS created                     -- TOBE: datetime2(0)                등록일시
         ----------------------------------------------------------------- 015
  FROM     demoasis.cu_cust                                    A1         -- A900008                     500 Rows                   고객                                                        
           LEFT  JOIN  demoasis.cu_cust_dtl                    A2         -- A900010                     500 Rows                   고객상세                                                    
                   ON (A1.cust_no = A2.cust_no)
           LEFT  JOIN (
                         SELECT cust_no, zip, addr1, addr2 
                          FROM   demoasis.cu_cust_addr 
                          WHERE  rep_yn = ''Y'' 
                      )  A3
                   ON (A1.cust_no = A3.cust_no)
  WHERE    1 = 1
  OPTION (MAXDOP 2);
  SET @n = @@ROWCOUNT;
';
      EXEC sys.sp_executesql @sql, N'@n bigint OUTPUT', @n = @row OUTPUT;
    END TRY
    BEGIN CATCH
      IF @@TRANCOUNT > 0 ROLLBACK;
      SELECT @failed = 1, @err = CAST(ERROR_NUMBER() AS nvarchar(30)), @emsg = ERROR_MESSAGE(), @now = SYSDATETIME();
      EXEC dataflex.put_line N' ';
      EXEC dataflex.put_line N'##### Conversion script group# 1 failed. #####';
      SET @msg = @err + N' ' + @emsg;
      EXEC dataflex.put_line @msg;
      SET @msg = N'Rows already committed in ' + @tar + N' : ' + FORMAT(@total, N'#,0', N'en-US');
      EXEC dataflex.put_line @msg;
      EXEC dataflex.p_joblog @seq, @mig_no, @tid, @start, @now, 0, @err, @emsg, @step, @src, @tar, NULL, @src_id;
      EXEC dataflex.p_joblog 0, @mig_no, @tid, @c_start, @now, 0, @err, @emsg, @step, @src_all, @tar, NULL, @src_id;
      EXEC sys.sp_set_session_context N'dataflex.load_ok', N'N';
    END CATCH
    /* 1 End */

    IF @failed = 0
    BEGIN
      SET @total = @total + @row;
      SET @now = SYSDATETIME();
      EXEC dataflex.put_line N' ';
      SET @msg = N'01 : ' + FORMAT(@row, N'#,0', N'en-US') + N' Rows Inserted';
      EXEC dataflex.put_line @msg;
      SET @msg = N'01 : ' + CONVERT(nvarchar(30), CAST(DATEDIFF_BIG(millisecond, @start, SYSDATETIME()) / 1000.0 AS decimal(18,2))) + N' Seconds (' + CONVERT(nvarchar(8), DATEADD(second, DATEDIFF(second, @start, SYSDATETIME()), CAST('00:00:00' AS time(0))), 108) + N')';
      EXEC dataflex.put_line @msg;
      EXEC dataflex.put_line N' ';
      EXEC dataflex.p_joblog @seq, @mig_no, @tid, @start, @now, @row, N'0', NULL, @step, @src, @tar, @note, @src_id;
    END
  END

IF @failed = 0
BEGIN
  DECLARE @rows_txt nvarchar(30) = CAST(@total AS nvarchar(30));
  EXEC sys.sp_set_session_context N'dataflex.t_rows', @rows_txt;
  EXEC sys.sp_set_session_context N'dataflex.t_src_all', @src_all;
END
GO

-- 3. 마무리 (적재가 실패해도 돈다) ----------------------------------------------------------------------------------------
DECLARE @msg nvarchar(max), @fail int = 0, @err nvarchar(30), @emsg nvarchar(4000), @now datetime2(0), @seq int,
        @c_start datetime2(6) = ISNULL(TRY_CAST(CAST(SESSION_CONTEXT(N'dataflex.t_start') AS nvarchar(30)) AS datetime2(6)), SYSDATETIME()),
        @total   bigint         = ISNULL(TRY_CAST(CAST(SESSION_CONTEXT(N'dataflex.t_rows') AS nvarchar(30)) AS bigint), 0),
        @src_all nvarchar(4000) = ISNULL(CAST(SESSION_CONTEXT(N'dataflex.t_src_all') AS nvarchar(4000)), N''),
        @tar  nvarchar(400)  = N'demotobe.tb_cust',
        @tid  nvarchar(20)   = N'T900007',
        @cmt  nvarchar(4000) = N'고객',
        @step nvarchar(100)  = LEFT(N'02.고객:GUI', 100);
IF ISNULL(CAST(SESSION_CONTEXT(N'dataflex.prep_ok') AS nvarchar(1)), N'N') = N'Y'
BEGIN
  EXEC sys.sp_set_session_context N'dataflex.prep_ok', N'N';
  BEGIN TRY
    -- Build INDEX After Load (클러스터드 먼저)
    EXEC dataflex.restore_index @tar, 2, @o_failed = @fail OUTPUT;
    IF @fail > 0
    BEGIN
      SET @msg = N'Index rebuild failed : ' + CAST(@fail AS nvarchar(10)) + N' (KEEP_INDEX)';
      EXEC dataflex.put_line @msg;
    END
    EXEC dataflex.enable_trigger @tar;

    IF ISNULL(CAST(SESSION_CONTEXT(N'dataflex.load_ok') AS nvarchar(1)), N'N') = N'Y'
    BEGIN
      EXEC dataflex.put_line N'';
      SET @msg = @step + N':' + @tar + N': ' + FORMAT(@total, N'#,0', N'en-US') + N' Rows Insert';
      EXEC dataflex.put_line @msg;
      SET @msg = @step + N':' + @tar + N':' + @tid + N':' + LEFT(@cmt, 100) + N' End : ' + CONVERT(nvarchar(30), CAST(DATEDIFF_BIG(millisecond, @c_start, SYSDATETIME()) / 1000.0 AS decimal(18,2))) + N' Seconds (' + CONVERT(nvarchar(8), DATEADD(second, DATEDIFF(second, @c_start, SYSDATETIME()), CAST('00:00:00' AS time(0))), 108) + N')';
      EXEC dataflex.put_line @msg;
      SELECT @now = SYSDATETIME(), @seq = dataflex.g_seq();
      EXEC dataflex.p_joblog 0, @seq, @tid, @c_start, @now, @total, N'0', NULL, @step, @src_all, @tar;
    END
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    SELECT @err = CAST(ERROR_NUMBER() AS nvarchar(30)), @emsg = ERROR_MESSAGE(), @now = SYSDATETIME(), @seq = dataflex.g_seq();
    SET @msg = @step + N':' + @tar + N':' + @tid + N' finish failed : ' + @err + N' ' + @emsg;
    EXEC dataflex.put_line @msg;
    EXEC dataflex.p_joblog 0, @seq, @tid, @c_start, @now, @total, @err, @emsg, @step, @src_all, @tar;
  END CATCH
END
GO
PRINT N'## Finished : demotobe.tb_cust';
PRINT N'##############################################################################';
GO
