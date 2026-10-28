# DataFlex

〔영어 한 줄 — 무엇을 하는 도구인지〕

| Edition | Migration | Repository DB | Generated scripts |
|---|---|---|---|
| DataFlex.Oracle | Oracle → Oracle | Oracle 12.2+ | PL/SQL |
| DataFlex.PG | PostgreSQL → PostgreSQL | PostgreSQL 14+ (MERGE 15+) | PL/pgSQL |
| DataFlex.MSSQL | SQL Server → SQL Server | SQL Server 2019+ · Azure SQL Managed Instance | T-SQL |

> 〔실행 파일은 없고 소개 문서만 있다는 안내 — 받는 방법 · 문의처〕

## Documents

| Edition | Introduction (Korean, PDF) |
|---|---|
| DataFlex.Oracle | [DataFlex.Oracle_소개.pdf](docs/DataFlex.Oracle_%EC%86%8C%EA%B0%9C.pdf) |
| DataFlex.PG | [DataFlex.PG_소개.pdf](docs/DataFlex.PG_%EC%86%8C%EA%B0%9C.pdf) |
| DataFlex.MSSQL | [DataFlex.MSSQL_소개.pdf](docs/DataFlex.MSSQL_%EC%86%8C%EA%B0%9C.pdf) |

## Screens

DataFlex.Oracle — Table Map

![DataFlex.Oracle Table Map](images/oracle_tablemap.jpg)

DataFlex.PG — Table Map

![DataFlex.PG Table Map](images/pg_tablemap.png)

DataFlex.MSSQL — Table Map

![DataFlex.MSSQL Table Map](images/mssql_tablemap.png)

## Requirements

〔영어 — 클라이언트 실행 환경: Windows 10+, .NET 설치 불필요, WebView2 런타임〕

---

## DataFlex (한국어)

### DataFlex.Oracle

DataFlex.Oracle 은 Oracle 데이터 이행의 **매핑 정의 · 이행 스크립트 생성 · 실행 · 결과 확인**을 하나의 리포지토리 DB 위에서 처리하는 도구입니다. 매핑은 화면에서 정의해 DB 에 보관하고, 실제 데이터 이행은 도구가 생성한 PL/SQL 스크립트가 DB 안에서 실행되면서 데이터를 적재합니다.

| 구분 | 내용 |
|---|---|
| 대상 | Oracle → Oracle 데이터 이행 (가공 · 변환 포함) |
| 형태 | Windows 클라이언트 + Oracle 리포지토리 DB (DATAFLEX 계정 + 부속 계정 2개) |
| 결과물 | 매핑 정의, PL/SQL 이행 스크립트, 실행 순서, 실행 기록 |
| 리포지토리 DB | Oracle 12.2 이상. 설치 마법사가 DATAFLEX 계정과 부속 계정 2개(DATAFLEX_DUP · DATAFLEX_BACK)를 만듭니다 |

### DataFlex.PG

DataFlex.PG 는 PostgreSQL 데이터 이행의 **매핑 정의 · 이행 스크립트 생성 · 실행 · 결과 확인**을 하나의 리포지토리 DB 위에서 처리하는 도구입니다. 매핑은 화면에서 정의해 DB 에 보관하고, 실제 데이터 이행은 도구가 생성한 PL/pgSQL 스크립트가 DB 안에서 실행되면서 데이터를 적재합니다.

| 구분 | 내용 |
|---|---|
| 대상 | PostgreSQL → PostgreSQL 데이터 이행 (가공 · 변환 포함) |
| 형태 | Windows 클라이언트 + PostgreSQL 리포지토리 DB (dataflex 롤 · 스키마 dataflex · dataflex_dup · dataflex_back) |
| 결과물 | 매핑 정의, PL/pgSQL 이행 스크립트, 실행 순서, 실행 기록 |
| 리포지토리 DB | PostgreSQL 14 이상(MERGE 적재는 15 이상). 설치 마법사가 dataflex 롤과 스키마 3개(dataflex · dataflex_dup · dataflex_back), 확장 dblink · postgres_fdw 를 만듭니다 |

### DataFlex.MSSQL

DataFlex.MSSQL 은 SQL Server 데이터 이행의 **매핑 정의 · 이행 스크립트 생성 · 실행 · 결과 확인**을 하나의 리포지토리 DB 위에서 처리하는 도구입니다. 매핑은 화면에서 정의해 DB 에 보관하고, 실제 데이터 이행은 도구가 생성한 T-SQL 스크립트가 DB 안에서 실행되면서 데이터를 적재합니다.

| 구분 | 내용 |
|---|---|
| 대상 | SQL Server → SQL Server 데이터 이행 (가공 · 변환 포함) |
| 형태 | Windows 클라이언트 + SQL Server 리포지토리 DB (dataflex 로그인 · 스키마 dataflex · dataflex_dup · dataflex_back) |
| 결과물 | 매핑 정의, T-SQL 이행 스크립트, 실행 순서, 실행 기록 |
| 리포지토리 DB | SQL Server 2019 이상 · Azure SQL Managed Instance(Managed Instance 는 아직 시험하지 않았습니다). 설치 마법사가 dataflex 로그인 · 사용자와 스키마 3개(dataflex · dataflex_dup · dataflex_back)를 만듭니다 |

### 공통

- 특징: 매핑 한 곳에서 스크립트 · 현황 · 기록이 모두 나온다
- 클라이언트: Windows 10 이상. .NET 설치 불필요. Microsoft Edge WebView2 런타임 필요 (Windows 11 기본 포함)
- 소개 문서: 위 [Documents](#documents) 의 PDF
- 〔실행 파일 · 문의처 안내〕

© 2026 DBMS Works
