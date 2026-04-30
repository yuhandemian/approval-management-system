-- =============================================================
-- AMS (Approval Management System) DDL Script
-- 프로젝트  : ○○시청 행정 내부 업무 관리 시스템
-- DB       : MySQL 8.x
-- Charset  : utf8mb4
-- 작성일    : 2026-04-30
-- 작성자    : 박유한
-- =============================================================

-- -------------------------------------------------------------
-- 0. 기존 테이블 삭제 (FK 의존 역순)
-- -------------------------------------------------------------
DROP TABLE IF EXISTS TB_ATTACH;
DROP TABLE IF EXISTS TB_POST;
DROP TABLE IF EXISTS TB_BOARD;
DROP TABLE IF EXISTS TB_CIVIL;
DROP TABLE IF EXISTS TB_APVL_LINE;
DROP TABLE IF EXISTS TB_APPROVAL;
DROP TABLE IF EXISTS TB_USER_ROLE;
DROP TABLE IF EXISTS TB_USER;
DROP TABLE IF EXISTS TB_DEPT;
DROP TABLE IF EXISTS TB_CODE;


-- -------------------------------------------------------------
-- 1. TB_CODE (공통코드)
--    모든 상태값, 직급, 역할 등을 코드 테이블로 일원화
-- -------------------------------------------------------------
CREATE TABLE TB_CODE (
    CODE_GRP    VARCHAR(20)  NOT NULL COMMENT '코드그룹',
    CODE_ID     VARCHAR(20)  NOT NULL COMMENT '코드값',
    CODE_NM     VARCHAR(100) NOT NULL COMMENT '코드명칭',
    CODE_ORDER  INT          NOT NULL DEFAULT 0 COMMENT '정렬순서',
    USE_YN      CHAR(1)      NOT NULL DEFAULT 'Y' COMMENT '사용여부',
    CONSTRAINT PK_CODE PRIMARY KEY (CODE_GRP, CODE_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='공통코드';


-- -------------------------------------------------------------
-- 2. TB_DEPT (부서)
--    계층형 구조 (PARENT_DEPT_ID 자기참조)
-- -------------------------------------------------------------
CREATE TABLE TB_DEPT (
    DEPT_ID        VARCHAR(20)  NOT NULL COMMENT '부서ID',
    PARENT_DEPT_ID VARCHAR(20)  NULL     COMMENT '상위부서ID',
    DEPT_NM        VARCHAR(100) NOT NULL COMMENT '부서명',
    USE_YN         CHAR(1)      NOT NULL DEFAULT 'Y' COMMENT '사용여부',
    REG_DT         DATETIME     NOT NULL DEFAULT NOW() COMMENT '등록일시',
    UPD_DT         DATETIME     NULL COMMENT '수정일시',
    CONSTRAINT PK_DEPT PRIMARY KEY (DEPT_ID),
    CONSTRAINT FK_DEPT_PARENT FOREIGN KEY (PARENT_DEPT_ID)
        REFERENCES TB_DEPT (DEPT_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='부서';


-- -------------------------------------------------------------
-- 3. TB_USER (사용자)
--    로그인 실패 5회 시 LOCK_YN = 'Y' 처리
-- -------------------------------------------------------------
CREATE TABLE TB_USER (
    USER_ID     VARCHAR(20)  NOT NULL COMMENT '사용자ID',
    DEPT_ID     VARCHAR(20)  NOT NULL COMMENT '부서ID',
    LOGIN_ID    VARCHAR(50)  NOT NULL COMMENT '로그인ID',
    PASSWORD    VARCHAR(200) NOT NULL COMMENT '암호화 비밀번호',
    USER_NM     VARCHAR(50)  NOT NULL COMMENT '이름',
    POSITION_CD VARCHAR(10)  NOT NULL COMMENT '직급코드',
    EMAIL       VARCHAR(100) NULL COMMENT '이메일',
    PHONE       VARCHAR(20)  NULL COMMENT '전화번호',
    FAIL_CNT    INT          NOT NULL DEFAULT 0 COMMENT '로그인실패횟수',
    LOCK_YN     CHAR(1)      NOT NULL DEFAULT 'N' COMMENT '계정잠금여부',
    USE_YN      CHAR(1)      NOT NULL DEFAULT 'Y' COMMENT '사용여부',
    REG_DT      DATETIME     NOT NULL DEFAULT NOW() COMMENT '등록일시',
    UPD_DT      DATETIME     NULL COMMENT '수정일시',
    CONSTRAINT PK_USER PRIMARY KEY (USER_ID),
    CONSTRAINT UQ_USER_LOGIN UNIQUE (LOGIN_ID),
    CONSTRAINT FK_USER_DEPT FOREIGN KEY (DEPT_ID)
        REFERENCES TB_DEPT (DEPT_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='사용자';

CREATE INDEX IDX_USER_DEPT ON TB_USER (DEPT_ID);
CREATE INDEX IDX_USER_NM   ON TB_USER (USER_NM);


-- -------------------------------------------------------------
-- 4. TB_USER_ROLE (사용자 역할)
--    한 사용자에 역할 복수 부여 가능
-- -------------------------------------------------------------
CREATE TABLE TB_USER_ROLE (
    ROLE_SEQ BIGINT      NOT NULL AUTO_INCREMENT COMMENT '역할순번',
    USER_ID  VARCHAR(20) NOT NULL COMMENT '사용자ID',
    ROLE_CD  VARCHAR(20) NOT NULL COMMENT '역할코드',
    REG_DT   DATETIME    NOT NULL DEFAULT NOW() COMMENT '등록일시',
    CONSTRAINT PK_USER_ROLE PRIMARY KEY (ROLE_SEQ),
    CONSTRAINT UQ_USER_ROLE UNIQUE (USER_ID, ROLE_CD),
    CONSTRAINT FK_ROLE_USER FOREIGN KEY (USER_ID)
        REFERENCES TB_USER (USER_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='사용자역할';


-- -------------------------------------------------------------
-- 5. TB_APPROVAL (전자결재 기안서)
--    APVL_ID는 eGovFrame IdGnrService로 생성 (APVL-YYYYMMDD-NNNNNN)
-- -------------------------------------------------------------
CREATE TABLE TB_APPROVAL (
    APVL_ID    VARCHAR(30)  NOT NULL COMMENT '결재ID',
    DRAFTER_ID VARCHAR(20)  NOT NULL COMMENT '기안자ID',
    TITLE      VARCHAR(200) NOT NULL COMMENT '제목',
    CONTENT    TEXT         NOT NULL COMMENT '내용',
    STATUS_CD  VARCHAR(20)  NOT NULL DEFAULT 'DRAFT' COMMENT '상태코드',
    REG_DT     DATETIME     NOT NULL DEFAULT NOW() COMMENT '기안일시',
    UPD_DT     DATETIME     NULL COMMENT '수정일시',
    CONSTRAINT PK_APPROVAL PRIMARY KEY (APVL_ID),
    CONSTRAINT FK_APVL_DRAFTER FOREIGN KEY (DRAFTER_ID)
        REFERENCES TB_USER (USER_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='전자결재';

CREATE INDEX IDX_APVL_DRAFTER ON TB_APPROVAL (DRAFTER_ID);
CREATE INDEX IDX_APVL_STATUS  ON TB_APPROVAL (STATUS_CD);
CREATE INDEX IDX_APVL_REG_DT  ON TB_APPROVAL (REG_DT);


-- -------------------------------------------------------------
-- 6. TB_APVL_LINE (결재선)
--    ORDER_NO 순서대로 순차 결재
--    한 기안서에 결재선 최대 3개
-- -------------------------------------------------------------
CREATE TABLE TB_APVL_LINE (
    LINE_SEQ      BIGINT      NOT NULL AUTO_INCREMENT COMMENT '결재선순번',
    APVL_ID       VARCHAR(30) NOT NULL COMMENT '결재ID',
    APPROVER_ID   VARCHAR(20) NOT NULL COMMENT '결재자ID',
    ORDER_NO      INT         NOT NULL COMMENT '결재순서',
    STATUS_CD     VARCHAR(20) NOT NULL DEFAULT 'PENDING' COMMENT '결재상태',
    REJECT_REASON TEXT        NULL COMMENT '반려사유',
    APVL_DT       DATETIME    NULL COMMENT '결재처리일시',
    REG_DT        DATETIME    NOT NULL DEFAULT NOW() COMMENT '등록일시',
    CONSTRAINT PK_APVL_LINE PRIMARY KEY (LINE_SEQ),
    CONSTRAINT UQ_APVL_ORDER UNIQUE (APVL_ID, ORDER_NO),
    CONSTRAINT FK_LINE_APVL FOREIGN KEY (APVL_ID)
        REFERENCES TB_APPROVAL (APVL_ID),
    CONSTRAINT FK_LINE_APPROVER FOREIGN KEY (APPROVER_ID)
        REFERENCES TB_USER (USER_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='결재선';

CREATE INDEX IDX_LINE_APPROVER ON TB_APVL_LINE (APPROVER_ID);


-- -------------------------------------------------------------
-- 7. TB_CIVIL (민원)
--    HANDLER_ID는 배정 전까지 NULL
--    CIVIL_ID는 eGovFrame IdGnrService로 생성 (CIVIL-YYYYMMDD-NNNNNN)
-- -------------------------------------------------------------
CREATE TABLE TB_CIVIL (
    CIVIL_ID       VARCHAR(30)  NOT NULL COMMENT '민원ID',
    REQUESTER_ID   VARCHAR(20)  NOT NULL COMMENT '신청자ID',
    HANDLER_ID     VARCHAR(20)  NULL COMMENT '담당자ID',
    CIVIL_TYPE_CD  VARCHAR(20)  NOT NULL COMMENT '민원유형코드',
    TITLE          VARCHAR(200) NOT NULL COMMENT '제목',
    CONTENT        TEXT         NOT NULL COMMENT '내용',
    STATUS_CD      VARCHAR(20)  NOT NULL DEFAULT 'SUBMITTED' COMMENT '처리상태',
    RESULT_CONTENT TEXT         NULL COMMENT '처리결과',
    REG_DT         DATETIME     NOT NULL DEFAULT NOW() COMMENT '신청일시',
    UPD_DT         DATETIME     NULL COMMENT '수정일시',
    CONSTRAINT PK_CIVIL PRIMARY KEY (CIVIL_ID),
    CONSTRAINT FK_CIVIL_REQUESTER FOREIGN KEY (REQUESTER_ID)
        REFERENCES TB_USER (USER_ID),
    CONSTRAINT FK_CIVIL_HANDLER FOREIGN KEY (HANDLER_ID)
        REFERENCES TB_USER (USER_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='민원';

CREATE INDEX IDX_CIVIL_REQUESTER ON TB_CIVIL (REQUESTER_ID);
CREATE INDEX IDX_CIVIL_HANDLER   ON TB_CIVIL (HANDLER_ID);
CREATE INDEX IDX_CIVIL_STATUS    ON TB_CIVIL (STATUS_CD);
CREATE INDEX IDX_CIVIL_REG_DT    ON TB_CIVIL (REG_DT);


-- -------------------------------------------------------------
-- 8. TB_BOARD (게시판 마스터)
-- -------------------------------------------------------------
CREATE TABLE TB_BOARD (
    BOARD_ID      VARCHAR(10) NOT NULL COMMENT '게시판ID',
    BOARD_NM      VARCHAR(50) NOT NULL COMMENT '게시판명',
    BOARD_TYPE_CD VARCHAR(20) NOT NULL COMMENT '게시판유형코드',
    USE_YN        CHAR(1)     NOT NULL DEFAULT 'Y' COMMENT '사용여부',
    CONSTRAINT PK_BOARD PRIMARY KEY (BOARD_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='게시판';


-- -------------------------------------------------------------
-- 9. TB_POST (게시글)
--    PARENT_POST_ID 자기참조로 Q&A 답글 처리
-- -------------------------------------------------------------
CREATE TABLE TB_POST (
    POST_ID        BIGINT       NOT NULL AUTO_INCREMENT COMMENT '게시글ID',
    BOARD_ID       VARCHAR(10)  NOT NULL COMMENT '게시판ID',
    WRITER_ID      VARCHAR(20)  NOT NULL COMMENT '작성자ID',
    PARENT_POST_ID BIGINT       NULL COMMENT '부모게시글ID(답글)',
    TITLE          VARCHAR(200) NOT NULL COMMENT '제목',
    CONTENT        TEXT         NOT NULL COMMENT '내용',
    VIEW_CNT       INT          NOT NULL DEFAULT 0 COMMENT '조회수',
    REG_DT         DATETIME     NOT NULL DEFAULT NOW() COMMENT '작성일시',
    UPD_DT         DATETIME     NULL COMMENT '수정일시',
    CONSTRAINT PK_POST PRIMARY KEY (POST_ID),
    CONSTRAINT FK_POST_BOARD FOREIGN KEY (BOARD_ID)
        REFERENCES TB_BOARD (BOARD_ID),
    CONSTRAINT FK_POST_WRITER FOREIGN KEY (WRITER_ID)
        REFERENCES TB_USER (USER_ID),
    CONSTRAINT FK_POST_PARENT FOREIGN KEY (PARENT_POST_ID)
        REFERENCES TB_POST (POST_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='게시글';

CREATE INDEX IDX_POST_BOARD  ON TB_POST (BOARD_ID);
CREATE INDEX IDX_POST_WRITER ON TB_POST (WRITER_ID);


-- -------------------------------------------------------------
-- 10. TB_ATTACH (첨부파일 - 공통)
--     REF_TYPE : APPROVAL / CIVIL / POST
--     REF_ID   : 각 테이블의 PK 값
-- -------------------------------------------------------------
CREATE TABLE TB_ATTACH (
    ATTACH_ID    BIGINT       NOT NULL AUTO_INCREMENT COMMENT '첨부파일ID',
    REF_TYPE     VARCHAR(20)  NOT NULL COMMENT '참조유형(APPROVAL/CIVIL/POST)',
    REF_ID       VARCHAR(30)  NOT NULL COMMENT '참조레코드ID',
    ORIG_FILE_NM VARCHAR(200) NOT NULL COMMENT '원본파일명',
    SAVE_FILE_NM VARCHAR(200) NOT NULL COMMENT 'UUID저장파일명',
    FILE_PATH    VARCHAR(500) NOT NULL COMMENT '서버저장경로',
    FILE_SIZE    BIGINT       NOT NULL COMMENT '파일크기(byte)',
    REG_DT       DATETIME     NOT NULL DEFAULT NOW() COMMENT '등록일시',
    CONSTRAINT PK_ATTACH PRIMARY KEY (ATTACH_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='첨부파일';

CREATE INDEX IDX_ATTACH_REF ON TB_ATTACH (REF_TYPE, REF_ID);


-- =============================================================
-- 초기 데이터 INSERT
-- =============================================================

-- 공통코드: 직급
INSERT INTO TB_CODE VALUES ('POSITION', 'P01', '사원',   1, 'Y');
INSERT INTO TB_CODE VALUES ('POSITION', 'P02', '주임',   2, 'Y');
INSERT INTO TB_CODE VALUES ('POSITION', 'P03', '대리',   3, 'Y');
INSERT INTO TB_CODE VALUES ('POSITION', 'P04', '과장',   4, 'Y');
INSERT INTO TB_CODE VALUES ('POSITION', 'P05', '차장',   5, 'Y');
INSERT INTO TB_CODE VALUES ('POSITION', 'P06', '부장',   6, 'Y');

-- 공통코드: 전자결재 상태
INSERT INTO TB_CODE VALUES ('APVL_STATUS', 'DRAFT',       '임시저장',    1, 'Y');
INSERT INTO TB_CODE VALUES ('APVL_STATUS', 'PENDING',     '결재대기',    2, 'Y');
INSERT INTO TB_CODE VALUES ('APVL_STATUS', 'IN_PROGRESS', '결재중',      3, 'Y');
INSERT INTO TB_CODE VALUES ('APVL_STATUS', 'APPROVED',    '최종승인',    4, 'Y');
INSERT INTO TB_CODE VALUES ('APVL_STATUS', 'REJECTED',    '반려',        5, 'Y');
INSERT INTO TB_CODE VALUES ('APVL_STATUS', 'CANCELED',    '취소',        6, 'Y');

-- 공통코드: 민원 상태
INSERT INTO TB_CODE VALUES ('CIVIL_STATUS', 'SUBMITTED',   '신청',       1, 'Y');
INSERT INTO TB_CODE VALUES ('CIVIL_STATUS', 'RECEIVED',    '접수',       2, 'Y');
INSERT INTO TB_CODE VALUES ('CIVIL_STATUS', 'ASSIGNED',    '배정완료',   3, 'Y');
INSERT INTO TB_CODE VALUES ('CIVIL_STATUS', 'IN_PROGRESS', '처리중',     4, 'Y');
INSERT INTO TB_CODE VALUES ('CIVIL_STATUS', 'COMPLETED',   '처리완료',   5, 'Y');
INSERT INTO TB_CODE VALUES ('CIVIL_STATUS', 'REJECTED',    '반려',       6, 'Y');

-- 공통코드: 민원 유형
INSERT INTO TB_CODE VALUES ('CIVIL_TYPE', 'GEN',       '일반민원',   1, 'Y');
INSERT INTO TB_CODE VALUES ('CIVIL_TYPE', 'INFO',      '정보공개',   2, 'Y');
INSERT INTO TB_CODE VALUES ('CIVIL_TYPE', 'COMPLAINT', '불만/건의',  3, 'Y');

-- 공통코드: 역할
INSERT INTO TB_CODE VALUES ('ROLE', 'ROLE_ADMIN',    '시스템관리자', 1, 'Y');
INSERT INTO TB_CODE VALUES ('ROLE', 'ROLE_APPROVER', '결재자',       2, 'Y');
INSERT INTO TB_CODE VALUES ('ROLE', 'ROLE_HANDLER',  '담당자',       3, 'Y');
INSERT INTO TB_CODE VALUES ('ROLE', 'ROLE_USER',     '일반사용자',   4, 'Y');

-- 게시판 마스터
INSERT INTO TB_BOARD VALUES ('NOTICE',  '공지사항', 'NOTICE',  'Y');
INSERT INTO TB_BOARD VALUES ('ARCHIVE', '자료실',   'ARCHIVE', 'Y');
INSERT INTO TB_BOARD VALUES ('QNA',     'Q&A',      'QNA',     'Y');

-- 부서 초기 데이터
INSERT INTO TB_DEPT (DEPT_ID, PARENT_DEPT_ID, DEPT_NM) VALUES ('DEPT-001', NULL,      '○○시청');
INSERT INTO TB_DEPT (DEPT_ID, PARENT_DEPT_ID, DEPT_NM) VALUES ('DEPT-002', 'DEPT-001', '행정지원과');
INSERT INTO TB_DEPT (DEPT_ID, PARENT_DEPT_ID, DEPT_NM) VALUES ('DEPT-003', 'DEPT-001', '민원봉사과');
INSERT INTO TB_DEPT (DEPT_ID, PARENT_DEPT_ID, DEPT_NM) VALUES ('DEPT-004', 'DEPT-001', '기획예산과');

-- 관리자 계정 (비밀번호: admin123 → SHA-256)
INSERT INTO TB_USER (USER_ID, DEPT_ID, LOGIN_ID, PASSWORD, USER_NM, POSITION_CD)
VALUES ('USER-000', 'DEPT-002', 'admin',
        'sha256_hash_placeholder',
        '시스템관리자', 'P06');

INSERT INTO TB_USER_ROLE (USER_ID, ROLE_CD) VALUES ('USER-000', 'ROLE_ADMIN');
INSERT INTO TB_USER_ROLE (USER_ID, ROLE_CD) VALUES ('USER-000', 'ROLE_APPROVER');
