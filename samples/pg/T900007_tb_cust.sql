
\pset pager off
\timing on
SET client_min_messages = notice;

DO $DFX$
DECLARE
  v_job_version  text;
BEGIN
  SELECT left(value, 50) INTO v_job_version FROM map_option WHERE business_area = 'DEMO' AND name = 'JOB_VERSION' LIMIT 1;
  CALL put_line('JOB         : ' || coalesce(v_job_version, '?'));
  CALL put_line('Start       : ' || to_char(clock_timestamp(), 'YYYY-MM-DD HH24:MI:SS Day'));
  CALL put_line('DB NAME     : ' || current_database());
  CALL put_line('Server      : ' || coalesce(host(inet_server_addr()), 'local') || ' (PostgreSQL ' || current_setting('server_version') || ')');
  CALL put_line('Table Name  : ' || 'demotobe.tb_cust');
  CALL put_line('Entity Name : ' || '고객');
END $DFX$;

--PL/pgSQL START-------------------------------------------------------------------------------------------------------- 

-- 1. 준비 (병렬 조각 모드 — 이 블록이 끝나면 psql 이 커밋한다)
DO $DFX$
DECLARE
  v_table_comment   text       := '고객';
  v_job_step        text       := left('02.고객:GUI', 100);
  c_start_dtm       timestamp  := clock_timestamp();
  v_state           text;
  v_msg             text;
  v_ctx             text;
BEGIN
  PERFORM set_config('dataflex.prep_ok', 'N', false);
  PERFORM set_config('dataflex.load_ok', 'N', false);
  PERFORM set_config('dataflex.t_start', c_start_dtm::text, false);
  PERFORM set_config('dataflex.t_rows', '0', false);
  PERFORM set_config('dataflex.t_src_all', '', false);
  CALL remove_index('demotobe.tb_cust');
  CALL disable_trigger('demotobe.tb_cust');
  CALL p_init('demotobe.tb_cust', 'T900007', v_table_comment, v_job_step, 'TRUNC');
  PERFORM set_config('dataflex.prep_ok', 'Y', false);
  PERFORM set_config('dataflex.load_ok', 'Y', false);
EXCEPTION
  WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_state = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT, v_ctx = PG_EXCEPTION_CONTEXT;
    CALL put_line(v_job_step || ':' || 'demotobe.tb_cust' || ':' || 'T900007' || ' prepare failed : ' || v_state || ' ' || v_msg);
    CALL p_joblog(0, g_seq(), 'T900007', c_start_dtm, clock_timestamp()::timestamp(0), 0, v_state, v_msg, v_job_step, '', 'demotobe.tb_cust', v_ctx);
END $DFX$;

-- 2. 적재
DO $DFX$
DECLARE
  v_tar_table_name  text       := 'demotobe.tb_cust';
  v_src_table_name  text       := '';
  v_src_table_all   text       := '';
  v_src_table_id    text       := '';
  v_table_id        text       := 'T900007';
  v_table_comment   text       := '고객';
  v_job_step        text       := left('02.고객:GUI', 100);
  c_start_dtm       timestamp  := clock_timestamp();
  v_start_dtm       timestamp  := clock_timestamp();
  v_row             bigint     := 0;
  v_total_row       bigint     := 0;
  v_seq             integer    := 0;
  v_mig_no          integer    := 0;
  v_merge_ins       bigint     := 0;
  v_merge_upd       bigint     := 0;
  v_note            text;
  v_idx_fail        integer    := 0;
  v_state           text;
  v_msg             text;
  v_ctx             text;
  v_failed          text;
  v_tpl             text;
  v_blocks          bigint;
  v_from            bigint;
  v_to              bigint;
  v_status          text;
  v_n               integer;
  v_opened          integer;
  v_u_rel           text[];
  v_u_from          bigint[];
  v_u_to            bigint[];
  v_cur             integer[];
  v_units           integer;
  v_next            integer;
  v_busy            integer;
  v_csz             bigint;
  v_csz_raw         text;
  v_k               integer;
  v_j               integer;
  v_r               record;
  v_bs              bigint;
  v_blk             bigint;
  v_parts           integer;

/*
고객 기본 + 상세 + 대표 주소. 주민번호는 암호화, 등급은 코드 변환
*/

BEGIN

  IF current_setting('dataflex.load_ok', true) IS DISTINCT FROM 'Y' THEN
    CALL put_line(v_tar_table_name || ' : load skipped — prepare failed');
    RETURN;
  END IF;
  c_start_dtm := current_setting('dataflex.t_start')::timestamp;
  v_mig_no := g_seq();

--Main Block------------------------------------------------------------------------------------------------------------ 

  v_start_dtm      := clock_timestamp();

  v_src_table_name := 'demoasis.cu_cust, demoasis.cu_cust_dtl, demoasis.cu_cust_addr';
  v_src_table_all  := v_src_table_all || '[1/1 : ' || v_src_table_name || ']';
  v_seq            := 1;
  v_src_table_id   := 'A900008';

  CALL put_line('Start conversion script group# 1.');
  PERFORM set_config('application_name', left('T900007 - 1/1-' || to_char(clock_timestamp(), 'YYYYMMDD HH24:MI:SS'), 63), false);

  /* 1 Start */

  v_tpl := $DFQ$
  INSERT /* DataFlex.PG T900007 1 of 1 */
         INTO demotobe.tb_cust
        (
             cust_id                                                           -- character varying(10)  NN   Y     고객ID
         ,   cust_name                                                         -- character varying(50)  NN         고객명
         ,   rrn_enc                                                           -- character varying(200)             주민등록번호(암호화)
         ,   tel                                                               -- character varying(20)             연락처
         ,   email                                                             -- character varying(60)             이메일
         ----------------------------------------------------------------- 005
         ,   grade_code                                                        -- character varying(20)             등급코드
         ,   join_date                                                         -- timestamp(0) without time zone             가입일자
         ,   status_code                                                       -- character varying(20)             상태코드
         ,   zip                                                               -- character varying(6)             우편번호
         ,   addr                                                              -- character varying(400)             주소
         ----------------------------------------------------------------- 010
         ,   birth_date                                                        -- timestamp(0) without time zone             생년월일
         ,   sex_code                                                          -- character(1)                성별코드
         ,   job_code                                                          -- character varying(20)             직업코드
         ,   memo                                                              -- character varying(500)             메모
         ,   created                                                           -- timestamp(0) without time zone             등록일시
         ----------------------------------------------------------------- 015
        )
  SELECT   /*+ SeqScan(a2)
               Set(enable_nestloop off) Set(enable_mergejoin off)
           */
           A1.cust_no AS cust_id                                               -- ASIS: character varying(10)  NN   Y     고객번호
         , A1.cust_nm AS cust_name                                             -- ASIS: character varying(50)             
         , encode(sha256(convert_to(A1.rrn, 'UTF8')), 'hex') AS rrn_enc        -- ASIS: character varying(13)             주민등록번호대상 컬럼이 암호화(ENCRYPT_YN) — 옵션 ENCRYPT FUNCTION HEAD · TAIL 로 감싸인다
         , A1.tel AS tel                                                       -- ASIS: character varying(20)             
         , left(A1.email, 60) AS email                                         -- TOBE: character varying(60)             이메일
         ----------------------------------------------------------------- 005
         , coalesce((SELECT m.target_code FROM dataflex.map_code m
                     WHERE  m.source_system_name = 'DEMOASIS' AND m.source_code_group = 'GRADE'
                     AND    m.source_code = A1.grade_cd), A1.grade_cd) AS grade_code     -- TOBE: character varying(20)             등급코드
         , udf_char2date(A1.join_dt) AS join_date                              -- TOBE: timestamp(0) without time zone             가입일자
         , A1.stat_cd AS status_code                                           -- ASIS: character varying(2)             
         , A3.zip AS zip                                                       -- ASIS: character varying(6)             대표 주소 (rep_yn = Y) 인라인뷰
         , nullif(concat_ws(' ', A3.addr1, A3.addr2), '') AS addr              -- TOBE: character varying(400)             주소
         ----------------------------------------------------------------- 010
         , udf_char2date(A2.birth_dt) AS birth_date                            -- TOBE: timestamp(0) without time zone             생년월일
         , A2.sex_cd AS sex_code                                               -- ASIS: character(1)                
         , A2.job_cd AS job_code                                               -- ASIS: character varying(10)             
         , left(A2.memo, 500) AS memo                                          -- TOBE: character varying(500)             메모
         , localtimestamp(0) AS created                                        -- TOBE: timestamp(0) without time zone             등록일시
         ----------------------------------------------------------------- 015
  FROM    (SELECT * FROM __DFX_SRC__ A1 WHERE ctid >= '__DFX_FROM__'::tid AND ctid < '__DFX_TO__'::tid)  A1         -- A900008                     500 Rows                   고객                                                        
           LEFT  JOIN  demoasis.cu_cust_dtl                    A2         -- A900010                     500 Rows                   고객상세                                                    
                   ON (A1.cust_no = A2.cust_no)
           LEFT  JOIN (
                         SELECT cust_no, zip, addr1, addr2 
                          FROM   demoasis.cu_cust_addr 
                          WHERE  rep_yn = 'Y' 
                      )  A3
                   ON (A1.cust_no = A3.cust_no)
  WHERE    1 = 1
  $DFQ$;

  v_bs := current_setting('block_size')::bigint;

  SELECT count(*)::integer INTO v_parts FROM pg_partition_tree('demoasis.cu_cust'::regclass) WHERE isleaf;
  -- 일감 크기 (MB) — MAP_OPTION.CHUNK_SIZE_MB, 범위 64~65536 밖은 끝값, 없거나 0 · 숫자가 아니면 1024
  SELECT value INTO v_csz_raw FROM map_option WHERE business_area = 'DEMO' AND name = 'CHUNK_SIZE_MB';

  v_csz := CASE WHEN coalesce(v_csz_raw, '') !~ '^\s*[0-9]+\s*$' OR ltrim(btrim(v_csz_raw), '0') = '' THEN 1024
                WHEN length(ltrim(btrim(v_csz_raw), '0')) > 7 THEN 65536   -- bigint 넘침 방지
                ELSE least(greatest(ltrim(btrim(v_csz_raw), '0')::bigint, 64), 65536) END;

  IF FOUND AND coalesce(btrim(v_csz_raw), '') <> v_csz::text THEN
    CALL put_line('CHUNK_SIZE_MB ' || coalesce(quote_literal(v_csz_raw), 'NULL') || ' adjusted to ' || v_csz || ' (min 64 · max 65536 · default 1024)');
  END IF;

  v_csz := v_csz * 1048576 / v_bs;   -- 블록
  -- 기준 크기는 상한 — 전체 ÷ DOP 보다 크면 그만큼으로 줄인다. 기준보다 작은 원본도 DOP 만큼은 나뉜다(예전 DOP 등분과 같게)

  SELECT least(v_csz, greatest(1, ceil(sum(q.blocks)::numeric / 2)::bigint)) INTO v_csz FROM (SELECT quote_ident(n.nspname) || '.' || quote_ident(c.relname) AS rel, greatest(1, pg_relation_size(c.oid) / v_bs) AS blocks FROM (SELECT p.relid FROM pg_partition_tree('demoasis.cu_cust'::regclass) p WHERE p.isleaf UNION ALL SELECT 'demoasis.cu_cust'::regclass WHERE NOT EXISTS (SELECT 1 FROM pg_partition_tree('demoasis.cu_cust'::regclass))) p JOIN pg_class c ON c.oid = p.relid JOIN pg_namespace n ON n.oid = c.relnamespace) q;
  v_csz := coalesce(v_csz, 1);

  -- 일감 줄 — 맨 아래 파티션(보통 테이블은 자기 자신, 원격은 외부 테이블)마다, 일감 크기보다 크면 그 크기씩 ctid 범위로. 큰 것부터
  v_u_rel := '{}'; v_u_from := '{}'; v_u_to := '{}';
  FOR v_r IN SELECT quote_ident(n.nspname) || '.' || quote_ident(c.relname) AS rel, greatest(1, pg_relation_size(c.oid) / v_bs) AS blocks FROM (SELECT p.relid FROM pg_partition_tree('demoasis.cu_cust'::regclass) p WHERE p.isleaf UNION ALL SELECT 'demoasis.cu_cust'::regclass WHERE NOT EXISTS (SELECT 1 FROM pg_partition_tree('demoasis.cu_cust'::regclass))) p JOIN pg_class c ON c.oid = p.relid JOIN pg_namespace n ON n.oid = c.relnamespace ORDER BY 2 DESC LOOP
    v_k := greatest(1, ceil(v_r.blocks::numeric / v_csz)::integer);
    FOR v_j IN 0 .. v_k - 1 LOOP
      v_u_rel  := v_u_rel || v_r.rel;
      v_u_from := v_u_from || (v_j * v_csz);
      v_u_to   := v_u_to || CASE WHEN v_j < v_k - 1 THEN (v_j + 1) * v_csz ELSE 4294967294 END;   -- 마지막 일감은 끝을 연다
    END LOOP;
  END LOOP;

  IF coalesce(array_length(v_u_rel, 1), 0) = 0 THEN   -- 파티션이 하나도 없는 파티션 부모 — 부모 그대로(0행). 보통 테이블은 위에서 자기 자신이 들어간다
    v_u_rel := ARRAY['demoasis.cu_cust']; v_u_from := ARRAY[0::bigint]; v_u_to := ARRAY[4294967294::bigint];
  END IF;

  v_units := array_length(v_u_rel, 1);
  v_row := 0;
  v_failed := NULL;
  v_opened := 0;
  v_next := 1;

  BEGIN
    FOR v_n IN 0 .. least(2, v_units) - 1 LOOP
      PERFORM dblink_connect('dfw' || v_n, 'dataflex_self');
      v_opened := v_n + 1;
    END LOOP;
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_state = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT, v_ctx = PG_EXCEPTION_CONTEXT;
    v_failed := 'dispatch: ' || v_msg;
  END;

  v_cur := array_fill(0, ARRAY[greatest(v_opened, 1)]);
  CALL put_line('DOP 2 · ' || CASE WHEN coalesce(v_parts, 0) = 0 THEN 'no partition' ELSE v_parts || ' partitions' END || ' · ' || v_units || ' units · ' || v_opened || ' sessions (chunk ' || pg_size_pretty(v_csz * v_bs) || ')');

  -- 빈 세션이 다음 일감을 가져간다. 실패가 나면 새 일감은 보내지 않고 돌던 것만 끝까지 기다린다
  LOOP
    v_busy := 0;
    FOR v_n IN 0 .. v_opened - 1 LOOP
      IF v_cur[v_n + 1] > 0 THEN
        IF dblink_is_busy('dfw' || v_n) = 1 THEN v_busy := v_busy + 1; CONTINUE; END IF;
        BEGIN
          SELECT t.status INTO v_status FROM dblink_get_result('dfw' || v_n) AS t(status text);   -- 'INSERT 0 123'
          PERFORM * FROM dblink_get_result('dfw' || v_n, false) AS t(status text);               -- 남은 결과 비우기
          v_row := v_row + coalesce(nullif(split_part(v_status, ' ', 3), '')::bigint, 0);
        EXCEPTION WHEN OTHERS THEN
          GET STACKED DIAGNOSTICS v_state = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT, v_ctx = PG_EXCEPTION_CONTEXT;
          v_failed := coalesce(v_failed || ' / ', '') || 'unit ' || v_cur[v_n + 1] || ': ' || v_msg;
        END;
        v_cur[v_n + 1] := 0;
      END IF;
      IF v_failed IS NULL AND v_next <= v_units THEN
        BEGIN
          PERFORM dblink_exec('dfw' || v_n, format('SET application_name = %L', left('T900007 - 1/1 unit ' || v_next || '/' || v_units, 63)));
          IF dblink_send_query('dfw' || v_n, replace(replace(replace(v_tpl, '__DFX_SRC__', v_u_rel[v_next]),
                               '__DFX_FROM__', format('(%s,0)', v_u_from[v_next])), '__DFX_TO__', format('(%s,0)', v_u_to[v_next]))) <> 1 THEN
            RAISE EXCEPTION 'unit % could not be sent', v_next;
          END IF;
          v_cur[v_n + 1] := v_next;
          v_next := v_next + 1;
          v_busy := v_busy + 1;
        EXCEPTION WHEN OTHERS THEN
          GET STACKED DIAGNOSTICS v_state = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT, v_ctx = PG_EXCEPTION_CONTEXT;
          v_failed := coalesce(v_failed || ' / ', '') || 'unit ' || v_next || ': ' || v_msg;
        END;
      END IF;
    END LOOP;
    EXIT WHEN v_busy = 0;
    PERFORM pg_sleep(0.05);
  END LOOP;

  FOR v_n IN 0 .. v_opened - 1 LOOP
    BEGIN
      PERFORM dblink_disconnect('dfw' || v_n);
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
  END LOOP;

  v_note := v_units || ' units · ' || v_opened || ' sessions';

  /* 1 End */

  IF v_failed IS NOT NULL THEN
    CALL put_line(' ');
    CALL put_line('##### Conversion script group# ' || v_seq || ' failed. #####');
    CALL put_line(coalesce(v_state, '') || ' ' || v_failed);
    CALL put_line('Rows already committed in ' || v_tar_table_name || ' : ' || to_char(coalesce(v_total_row, 0) + coalesce(v_row, 0), 'FM999,999,999,999,990'));
    PERFORM autonomous(format('DELETE FROM dataflex.mig_rows WHERE target_table_id = %L', v_table_id));
    CALL p_joblog(v_seq, v_mig_no, v_table_id, v_start_dtm, clock_timestamp()::timestamp(0), 0, coalesce(v_state, '-1'), v_failed, v_job_step, v_src_table_name, v_tar_table_name, v_ctx, v_src_table_id);
    CALL p_joblog(0, v_mig_no, v_table_id, c_start_dtm, clock_timestamp()::timestamp(0), 0, coalesce(v_state, '-1'), v_failed, v_job_step, v_src_table_all, v_tar_table_name, p_src_table_id => v_src_table_id);
    PERFORM set_config('dataflex.load_ok', 'N', false);
    RETURN;
  END IF;
  COMMIT;
  v_total_row := v_row;

  CALL put_line(' ');
  CALL put_line('01 : ' || to_char(v_row, 'FM999,999,999,999,990') || ' Rows Inserted');
  CALL put_line('01 : ' || round(extract(epoch FROM clock_timestamp() - v_start_dtm)::numeric, 2) || ' Seconds (' || to_char(date_trunc('second', clock_timestamp() - v_start_dtm), 'HH24:MI:SS') || ')');
  CALL put_line(' ');

  CALL p_joblog(v_seq, v_mig_no, v_table_id, v_start_dtm, clock_timestamp()::timestamp(0), v_row, '0', NULL, v_job_step, v_src_table_name, v_tar_table_name, p_note => v_note, p_src_table_id => v_src_table_id);

  ----------------------------------------------------------------------------------------------------------------------

  PERFORM set_config('dataflex.t_rows', v_total_row::text, false);
  PERFORM set_config('dataflex.t_src_all', v_src_table_all, false);
END $DFX$;

-- 3. 마무리 (적재가 실패해도 돈다)
DO $DFX$
DECLARE
  v_tar_table_name  text       := 'demotobe.tb_cust';
  v_table_id        text       := 'T900007';
  v_table_comment   text       := '고객';
  v_job_step        text       := left('02.고객:GUI', 100);
  c_start_dtm       timestamp  := coalesce(nullif(current_setting('dataflex.t_start', true), '')::timestamp, clock_timestamp());
  v_total_row       bigint     := coalesce(nullif(current_setting('dataflex.t_rows', true), '')::bigint, 0);
  v_src_table_all   text       := current_setting('dataflex.t_src_all', true);
  v_idx_fail        integer    := 0;
  v_state           text;
  v_msg             text;
  v_ctx             text;
BEGIN
  IF current_setting('dataflex.prep_ok', true) IS DISTINCT FROM 'Y' THEN
    RETURN;
  END IF;
  PERFORM set_config('dataflex.prep_ok', 'N', false);

  -- Build INDEX After Load 
  v_idx_fail := restore_index(v_tar_table_name, 2);
  IF v_idx_fail > 0 THEN
    CALL put_line('Index rebuild failed : ' || v_idx_fail || ' (KEEP_INDEX)');
  END IF;
  CALL enable_trigger(v_tar_table_name);

  IF current_setting('dataflex.load_ok', true) = 'Y' THEN
    CALL put_line('');
    CALL put_line(v_job_step || ':' || v_tar_table_name || ': ' || to_char(v_total_row, 'FM999,999,999,999,990') || ' Rows Insert');
    CALL put_line(v_job_step || ':' || v_tar_table_name || ':' || v_table_id || ':' || left(v_table_comment, 100) || ' End : ' || round(extract(epoch FROM clock_timestamp() - c_start_dtm)::numeric, 2) || ' Seconds (' || to_char(date_trunc('second', clock_timestamp() - c_start_dtm), 'HH24:MI:SS') || ')');
    CALL p_joblog(0, g_seq(), v_table_id, c_start_dtm, clock_timestamp()::timestamp(0), v_total_row, '0', NULL, v_job_step, v_src_table_all, v_tar_table_name);
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_state = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT, v_ctx = PG_EXCEPTION_CONTEXT;
    CALL put_line(v_job_step || ':' || v_tar_table_name || ':' || v_table_id || ' finish failed : ' || v_state || ' ' || v_msg);
    CALL p_joblog(0, g_seq(), v_table_id, c_start_dtm, clock_timestamp()::timestamp(0), v_total_row, v_state, v_msg, v_job_step, v_src_table_all, v_tar_table_name, v_ctx);
END $DFX$;
--PL/pgSQL END---------------------------------------------------------------------------------------------------------- 
\echo '## Finished : demotobe.tb_cust'
\echo '##############################################################################'

