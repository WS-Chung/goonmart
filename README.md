# PX 견적기 (Vercel 배포용)

PX/군마트에서 장 볼 때 인터넷/할인마트 가격 대비 얼마나 절약되는지
실시간으로 보여주는 단일 페이지 앱.

```
shopping/
├ index.html          ← Vercel에 그대로 올라가는 본체 (HTML+CSS+JS 한 장)
├ supabase_init.sql   ← Supabase 스키마/정책 셋업 (최초 1회)
├ px_products.csv     ← 초기 시드 데이터 (188행 가량)
└ README.md
```

GitHub에 이 네 파일만 올리면 됩니다. 빌드 단계 없음, 의존성 없음.

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

### C. API 키 복사

6. Settings → API Keys 에서 두 값 복사
   - **Project URL** (예: `https://xxxx.supabase.co`)
   - **Publishable key** (`sb_publishable_…`)  ← `secret` 키는 절대 사용 금지

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

### A. GitHub 레포에 올리기

```bat
cd C:\Users\Drimaes\Downloads\shopping
git init
git add .
git commit -m "init: PX price tracker"
git branch -M main
git remote add origin https://github.com/<your-id>/<repo-name>.git
git push -u origin main
```

### B. Vercel에서 Import

1. https://vercel.com → New Project → Import Git Repository
2. 위에서 만든 레포 선택
3. Framework Preset: **Other** (자동 감지될 수도 있음)
4. Build/Output 설정 모두 비워두고 **Deploy** — 정적 파일이라 빌드 단계 없음

배포 후 Vercel이 발급해 주는 URL(`https://<project>.vercel.app`)이 즉시 동작합니다.

---

## 3. DB 키 입력 (각 기기에서 1회)

Vercel 배포 URL에 처음 접속하면 우상단 **⚙ DB 설정** 모달이 자동으로 열립니다.

- **Supabase Project URL**: `https://xxxx.supabase.co`
- **Publishable / anon Key**: `sb_publishable_…`

저장하면 해당 브라우저의 LocalStorage에만 보관되며 GitHub/서버에는 올라가지 않습니다.
다른 기기(폰 등)에서 접속할 땐 한 번 더 입력해 주세요.

설정을 바꾸거나 지우려면 언제든 우상단 **⚙ DB 설정** 버튼을 누르면 됩니다.

---

## 4. 사용법

### 견적 모드 (기본)
- 검색창에 상품명 입력 → 결과 카드에서 수량 입력 후 **＋** 클릭
- 장바구니 표에서 수량 직접 수정/삭제
- 상단 패널이 **절약률(파랑 그라디언트)** 과 **절약 금액(노랑 강조)** 을 실시간 갱신
- PX 합계가 인터넷/할인마트 합계보다 비싼 경우는 발생하지 않는다는 가정으로 설계

### 상품 등록 모드
- **새 상품 등록**: 상품명·PX가·인터넷가·(선택)카테고리 입력
  - 가격차 40% 초과 시 다른 제품일 가능성을 경고. 같은 제품이 확실하면 ‘경고 무시’ 체크
- **등록된 상품 (편집/삭제)**: 표 셀을 직접 클릭해 수정. 변경된 셀은 노란색 음영
  - 우측 ✕ 클릭 → 삭제 표시 (다시 누르면 취소)
  - 변경 후 **💾 변경사항 저장** 한 번에 일괄 반영

---

## 5. 모바일 PWA로 쓰기 (선택)

폰에서 견적기를 자주 쓰실 거면, Chrome/Safari에서 배포 URL 접속 후
- 안드로이드(Chrome): 메뉴 → **홈 화면에 추가**
- 아이폰(Safari): 공유 → **홈 화면에 추가**

홈 화면 아이콘으로 앱처럼 띄울 수 있습니다.

---

## 6. 보안 메모

- `Publishable key`는 RLS 정책으로 보호되는 **공개해도 안전한 등급**이지만,
  지금 SQL 정책은 anon에게 SELECT/INSERT/UPDATE/DELETE를 모두 허용합니다.
  즉 “해당 키를 아는 사람은 누구나 읽고 쓸 수 있음”이라 **개인 사용 한정**입니다.
- `secret_…` 키는 RLS 우회 풀권한이라 절대 클라이언트/Vercel/Git에 두지 마세요.
- 더 잠그고 싶으면 Supabase Auth로 본인 로그인 후 `auth.uid()` 매칭 정책으로 바꾸면 됩니다.
