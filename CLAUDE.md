# CLAUDE.md: goonmart (PX 견적기) 개발 가이드

PX/군마트 가격과 인터넷/할인마트 가격을 비교해 장바구니 절약률을 실시간으로 보여 주는 단일 페이지 앱입니다.
Vercel 정적 호스팅과 Supabase(PostgreSQL + REST API)로 동작합니다.

- 저장소: https://github.com/WS-Chung/goonmart (기본 브랜치 `main`)
- 배포: Vercel이 이 저장소에 연결돼 있으면 `main`에 푸시할 때 자동으로 배포됩니다. 빌드 단계는 없습니다.

## 파일 구성

| 파일 | 역할 |
|---|---|
| `index.html` | 앱 전체(HTML, `<style>`, `<script>`). 실제로 배포되는 유일한 파일 |
| `supabase_init.sql` | 테이블·트리거·RLS 최초 셋업. **첫 줄이 `DROP TABLE`이므로 운영 DB에서 다시 실행하면 안 됨** |
| `px_products.csv` | 시드/백업 데이터. Supabase Table Editor에서 import |
| `DESIGN-apple.md` | `index.html`의 CSS가 따르는 디자인 레퍼런스(색·타이포·라운드 토큰) |
| `.vercelignore` | 문서·SQL·CSV를 배포물에서 제외 |
| `.gitattributes` | 줄바꿈을 LF로 통일 |
| `.git-blame-ignore-revs` | 줄바꿈 정규화 커밋을 blame에서 제외 |

## 로컬 실행

설치도 빌드도 필요 없습니다. 정적 서버로 띄우면 코드에 하드코딩된 Supabase에 바로 연결되므로 **운영 DB를 그대로 사용하게 됩니다.**

```bash
python -m http.server 8000   # http://localhost:8000
# 또는
npx serve .
```

운영 데이터를 건드리지 않고 테스트하려면 별도 Supabase 프로젝트를 만들고(`supabase_init.sql` 실행 + CSV import),
브라우저 콘솔에서 `openConfigModal()`을 실행해 그 프로젝트의 URL과 키를 입력하세요. 이 값은 해당 브라우저의 LocalStorage에만 저장되며, 모달의 **설정 삭제**를 누르면 기본값으로 돌아갑니다.

## 아키텍처

- **프레임워크와 번들러 없음.** 바닐라 JS 전역 함수와 HTML 인라인 핸들러(`onclick="addToCart(1)"`)로 구성됩니다.
  함수 이름을 바꿀 때는 템플릿 문자열 안의 핸들러 이름도 함께 바꿔야 합니다.
- **CDN 의존성**: Pretendard 폰트(jsDelivr), `@supabase/supabase-js@2`(jsDelivr, 메이저 버전만 고정).
- **렌더링**: 상태가 바뀌면 해당 영역을 `innerHTML`로 통째로 다시 그립니다. 사용자 입력이나 DB 값을 HTML에 넣을 때는 **반드시 `esc()`를 거쳐야** 합니다.

### 전역 상태

| 변수 | 내용 | 영속화 |
|---|---|---|
| `products`, `productsById` | DB 상품 목록(`id,name,px_price,internet_price,category`) | 없음(로드할 때마다 조회) |
| `cart` | `{ [id]: qty }` | `localStorage["px_cart"]` |
| `edits`, `deletes` | 등록 모드에서 아직 저장하지 않은 편집·삭제 표시 | 없음 |
| `adminUnlocked` | 등록 모드 잠금 해제 여부 | 없음(새로고침하면 다시 잠김) |
| (설정 override) | Supabase URL·키 | `localStorage["px_cfg"]` |

### 처리 흐름

1. `init()`: `cart` 복원 → `loadConfigAndConnect()` → `reloadProducts()` → `reloadAll()`
2. `reloadAll()`은 `fillCategoryFilter()`, `renderCatalog()`, `renderCart()`, `renderAdminTable()`을 차례로 호출합니다.
3. 견적 모드: 검색어를 입력해야 카탈로그가 표시됩니다(최대 60개). `addToCart`, `adjustQty`, `setCartQty`, `removeFromCart`가 `saveCart()` 후 다시 렌더링하고, `updateSummary()`가 절약률 0~30% 구간에 따라 패널 배경색을 보간합니다.
4. 등록 모드: `switchTab('admin')` → 비밀번호 모달 → `addProduct()`(INSERT) 또는 표 인라인 편집 `onCellEdit()` → `saveEdits()`(UPDATE·DELETE를 건별로 순차 요청한 뒤 전체 재조회).

### 데이터 모델 (`public.px_products`)

| 컬럼 | 타입·제약 | 비고 |
|---|---|---|
| `id` | `BIGSERIAL` PK | |
| `name` | `TEXT NOT NULL UNIQUE` | "상품명 (용량)" 형식 |
| `px_price` | `INTEGER NOT NULL ≥ 0` | |
| `internet_price` | `INTEGER NOT NULL ≥ 0` | |
| `category` | `TEXT` | 라면, 음료, 생활 등 |
| `source_url` | `TEXT` | 앱에서는 사용하지 않음 |
| `created_at`, `updated_at` | `TIMESTAMPTZ` | `updated_at`은 트리거로 자동 갱신 |

RLS는 `anon` 역할에 SELECT, INSERT, UPDATE, DELETE를 모두 허용합니다.

### 업무 규칙

- 절약률 = `(인터넷가 − PX가) / 인터넷가`. 음수는 0으로 처리합니다(PX가 항상 싸다는 가정).
- 가격차 경고 = `|인터넷가 − PX가| / PX가 > 40%`. 분모가 PX가이므로 절약률과 기준이 다릅니다. 신규 등록에서는 '경고 무시' 체크박스로, 편집 저장에서는 확인 창으로 우회합니다.

## 수정할 때 지킬 규칙

- **디자인**: 색·라운드·간격은 `:root`의 CSS 변수만 쓰고 hex 값을 직접 쓰지 않습니다. 토큰의 의미는 `DESIGN-apple.md`를 참고하세요. 모바일 분기점은 `max-width:720px` 하나뿐입니다.
- **DB 스키마 변경**: `supabase_init.sql`을 다시 실행하지 말고, `ALTER TABLE` 같은 변경분만 SQL Editor에서 실행하세요. 그런 다음 같은 변경을 `supabase_init.sql`에도 반영해 둡니다.
- **비밀값**: `service_role`이나 `secret_…` 키는 코드, Git, Vercel 환경변수 어디에도 두지 않습니다. `.env*` 파일은 `.gitignore`에 등록돼 있습니다.
- **커밋**: 작은 단위로 나누고, 메시지는 한국어로 짧게 씁니다(`feat: …`, `fix: …`, `docs: …`, `chore: …`).

## 알려진 이슈와 개선 후보

**보안**
- 등록 모드 비밀번호가 `index.html`에 평문 상수(`ADMIN_PW`)로 들어 있어 소스 보기만으로 확인할 수 있습니다. 게다가 RLS가 anon에 쓰기를 모두 허용하므로, 비밀번호를 몰라도 API를 직접 호출해 수정·삭제할 수 있습니다. 실제 보호가 필요하면 Supabase Auth와 `auth.uid()` 기반 RLS로 바꿔야 합니다.

**기능과 버그**
- 예전에 있던 우상단 `⚙ DB 설정` 버튼은 `0e43d30 테마조절` 커밋에서 제거됐습니다. 지금은 연결에 실패할 때만 설정 모달이 자동으로 뜨고, 직접 열려면 콘솔에서 `openConfigModal()`을 실행해야 합니다.
- 인라인 편집에서 상품명을 지우면 빈 문자열이, 가격 칸을 지우면 0이 그대로 저장됩니다(`saveEdits()`에 입력 검증이 없음).
- `saveEdits()`는 변경 건수만큼 요청을 순차로 보냅니다. 대량 수정은 느리고, 중간에 실패하면 일부만 반영됩니다.
- 다른 기기에서 삭제된 상품 id가 LocalStorage 장바구니에 남아 있으면, 화면에는 보이지 않지만 저장소에는 계속 남습니다.

**정리**
- `@supabase/supabase-js@2`는 2.x의 최신 버전이 자동으로 적용됩니다. 재현성이 필요하면 정확한 버전으로 고정하세요.
- `darken()` 유틸 함수는 어디서도 쓰이지 않습니다.
