# PX 견적기 (Vercel 배포용)

PX/군마트에서 장 볼 때 인터넷/할인마트 가격 대비 얼마나 절약되는지
실시간으로 보여주는 단일 페이지 앱.

- 저장소: https://github.com/WS-Chung/goonmart
- 개발 가이드(구조·상태·규칙·알려진 이슈): [CLAUDE.md](CLAUDE.md)

```
goonmart/
├ index.html              ← Vercel에 그대로 올라가는 본체 (HTML+CSS+JS 한 장)
├ supabase_init.sql       ← Supabase 스키마/정책 셋업 (최초 1회)
├ px_products.csv         ← 초기 시드 / 백업 데이터
├ CLAUDE.md               ← 개발 가이드 (디자인 규칙 요약 포함)
├ README.md
├ .gitignore / .gitattributes / .git-blame-ignore-revs
└ .vercelignore           ← 문서·SQL·CSV를 배포물에서 제외
```

빌드 단계 없음, 의존성 없음. 배포되는 건 사실상 `index.html` 한 장입니다.

> 디자인은 사내 규칙 **DA UI hallmark v1.0**을 따릅니다. 규칙 폴더 `DA_UI_hallmark/`는
> 사내 자료라서 로컬에만 두고 저장소에는 올리지 않습니다(`.gitignore` 제외). 요약은 [CLAUDE.md](CLAUDE.md)에 있습니다.

---

## 1. Supabase 준비 (최초 1회만)

> ⚠ **중요**: `supabase_init.sql`은 첫 줄에 `DROP TABLE IF EXISTS px_products CASCADE;` 가 있습니다.
> 이미 운영 중인 프로젝트에서 다시 실행하면 그 동안 등록·수정한 가격이 모두 사라집니다.
> 처음 셋업할 때만 실행하세요.

### A. 스키마/정책 만들기

1. https://supabase.com → 새 프로젝트 생성 (Region: Seoul 권장)
2. 좌측 SQL Editor → New query → `supabase_init.sql` 전체 붙여넣기 → **Run**
   - 이 단계에서는 빈 테이블·트리거·RLS 정책만 만들어집니다(데이터 0건).

### B. 초기 데이터 부어넣기 (CSV)

3. 좌측 **Table Editor** → `px_products` 선택
4. 우상단 **Insert** → **Import data from CSV**
5. `px_products.csv` 선택 → 컬럼 자동 매핑 확인 → **Import**
   - CSV에는 `id` 컬럼이 들어있어 원래 ID 그대로 들어갑니다.
   - 이후에 새로 등록되는 상품은 ID 시퀀스가 알아서 다음 번호부터 매겨집니다.

### C. API 키는 이미 코드에 들어 있음

별도 작업 없습니다. `index.html` 상단의 `SUPABASE_URL` / `SUPABASE_ANON_KEY` 두 상수에
하드코딩되어 있어, 배포 URL에 접속하면 곧바로 DB와 연결됩니다.

다른 프로젝트로 갈아타려면 그 두 상수만 수정하고 재배포하세요.

> 이미 만들어 두고 운영 중인 프로젝트라면 이 1단계는 건너뛰면 됩니다.
> 새 환경(다른 PC, 다른 누군가에게 똑같이 깔아주기, 테스트용 별도 프로젝트)을 만들 때만 위 흐름을 다시 밟으세요.

### 데이터 백업 (권장)

가격을 크게 손볼 일이 있을 때마다 한 번씩 받아두면 안심됩니다.
SQL Editor에서 아래 한 줄 실행 → 결과 화면 우상단 **Export → Download CSV** 클릭 →
받은 파일을 `px_products.csv`로 덮어쓰면 그게 곧 새로운 시드입니다.

```sql
SELECT * FROM public.px_products ORDER BY id;
```

복원이 필요할 땐 위 셋업 흐름의 **B 단계**를 그대로 다시 밟으면 됩니다(필요 시 사전에
`TRUNCATE TABLE public.px_products RESTART IDENTITY;` 로 비운 뒤 import).

### 스키마만 갱신하고 싶을 때

데이터를 보존하면서 컬럼/제약/정책만 바꾸고 싶다면 `DROP TABLE`을 쓰지 말고
변경 부분만 골라 `ALTER TABLE`/`CREATE OR REPLACE POLICY` 같은 안전한 명령으로 적용하세요.
필요하면 알려주시면 변경분만 뽑아 드립니다.

---

## 2. Vercel 배포

### A. 소스 받기 / 수정 흐름

```bash
git clone https://github.com/WS-Chung/goonmart.git
cd goonmart
python -m http.server 8000      # 로컬 확인: http://localhost:8000 (운영 DB에 연결됨)
```

평소 작업 순서:

```bash
git pull                         # 다른 PC/사람의 변경 먼저 받기
# index.html 수정 후 로컬 확인
git add -A
git commit -m "fix: 무엇을 왜 고쳤는지"
git push                         # main 푸시 → Vercel 자동 배포
```

### B. Vercel에서 Import (최초 1회)

1. https://vercel.com → New Project → Import Git Repository
2. `WS-Chung/goonmart` 레포 선택
3. Framework Preset: **Other** (자동 감지될 수도 있음)
4. Build/Output 설정 모두 비워두고 **Deploy** — 정적 파일이라 빌드 단계 없음

배포 후 Vercel이 발급해 주는 URL(`https://<project>.vercel.app`)이 즉시 동작합니다.

---

## 3. 사용 시작

배포 URL에 접속하면 코드에 하드코딩된 Supabase 연결을 자동으로 사용해 즉시 동작합니다.
입력 모달이 뜨지 않습니다.

다른 Supabase 프로젝트(예: 테스트용 별도 프로젝트)를 임시로 가리키고 싶을 때는
브라우저 개발자 도구 콘솔에서 `openConfigModal()`을 실행해 URL/키를 덮어 쓸 수 있습니다
(이 브라우저에만 저장). 창 안의 **기본값으로 되돌리기**를 누르면 다시 코드 기본값으로 돌아갑니다.

> 예전에 있던 우상단 **DB 설정** 버튼은 디자인 정리 과정에서 제거됐습니다.
> 지금은 DB 연결에 실패할 때만 이 창이 자동으로 뜹니다.

> 키를 바꾸려면 `index.html` 상단의 `SUPABASE_URL` / `SUPABASE_ANON_KEY` 두 상수를 수정하고 재배포하세요.

---

## 4. 사용법

### 견적 화면 (기본, 주소 `#quote`)
- **상품 추가** 표는 처음부터 전체 상품을 보여 줍니다. 상품명 검색과 카테고리 필터로 좁히고 행 끝의 **담기**를 누릅니다.
- **장바구니** 표에서 수량을 `−` `+` 또는 직접 입력으로 고치고, 행 끝 `×`로 뺍니다. 맨 아래 합계 행이 소계를 모읍니다.
- 위쪽 합계 상자가 **PX 합계**, **인터넷/할인마트 합계**, **절약 금액**을 실시간으로 갱신합니다.
  절약 금액은 네이비 면에 가장 크게 표시되고, 아래로 스크롤해도 상단에 고정됩니다.
- PX 합계가 인터넷/할인마트 합계보다 비싼 경우는 발생하지 않는다는 가정으로 설계

### 상품 등록 화면 (주소 `#admin`, 비밀번호 잠금)
- 메뉴의 **상품 등록**을 누르면 비밀번호를 묻습니다. 주소로 직접 들어오면 잠금 안내 화면이 먼저 보입니다.
- **새 상품 등록**: 상품명·PX가·인터넷가·(선택)카테고리 입력
  - 가격차 40% 초과 시 다른 제품일 가능성을 경고. 같은 제품이 확실하면 ‘경고 무시’ 체크
- **등록된 상품**: 표 칸을 직접 눌러 수정. 변경한 칸은 연한 파랑 배경과 모서리 삼각 표시
  - 행 끝 `×` 클릭 → 삭제 표시 (되돌리기 아이콘으로 취소)
  - 변경 후 **변경사항 저장**으로 한 번에 반영, **변경 취소**로 모두 되돌림

---

## 5. 모바일 PWA로 쓰기 (선택)

폰에서 견적기를 자주 쓰실 거면, Chrome/Safari에서 배포 URL 접속 후
- 안드로이드(Chrome): 메뉴 → **홈 화면에 추가**
- 아이폰(Safari): 공유 → **홈 화면에 추가**

홈 화면 아이콘으로 앱처럼 띄울 수 있습니다.

---

## 6. 보안 메모

- 이 앱은 취미·비민감 데이터 전제이고 키를 코드에 박아 두었습니다.
  GitHub 공개 레포에 올라가도 정보 유출 위험이 거의 없는 가정.
- 단, 현재 RLS 정책은 anon 키에 SELECT/INSERT/UPDATE/DELETE 모두 허용합니다.
  즉 **그 키를 아는 사람은 누구나 데이터를 임의로 조작할 수 있다**는 의미라,
  이 앱은 “개인 사용 또는 친한 사람과 공유” 정도까지만 가정해 주세요.
- 가격이나 카테고리가 임의로 바뀌면 곤란한 환경(여러 사람 운영, 외부 공개)이라면:
  1) Supabase Auth 도입, 2) 정책을 `auth.uid()` 매칭으로 좁히기, 3) UPDATE/DELETE는 본인만 허용 — 이 셋을 단계별로 적용하면 됩니다.
- `secret_…` 키는 RLS 우회 풀권한이라 절대 클라이언트/Vercel/Git에 두지 마세요.
