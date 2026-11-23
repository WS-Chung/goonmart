# CLAUDE.md: goonmart (PX 견적기) 개발 가이드

PX/군마트 가격과 인터넷/할인마트 가격을 비교해 장바구니 절약 금액을 실시간으로 보여 주는 단일 페이지 앱입니다.
Vercel 정적 호스팅과 Supabase(PostgreSQL + REST API)로 동작합니다.

- 저장소: https://github.com/WS-Chung/goonmart (기본 브랜치 `main`)
- 배포: Vercel이 이 저장소에 연결돼 있으면 `main`에 푸시할 때 자동으로 배포됩니다. 빌드 단계는 없습니다.

## 파일 구성

| 파일 | 역할 |
|---|---|
| `index.html` | 앱 전체(HTML, `<style>`, `<script>`). 실제로 배포되는 유일한 파일 |
| `supabase_init.sql` | 테이블·트리거·RLS 최초 셋업. **첫 줄이 `DROP TABLE`이므로 운영 DB에서 다시 실행하면 안 됨** |
| `px_products.csv` | 시드/백업 데이터. Supabase Table Editor에서 import |
| `DA_UI_hallmark/` | 사내 디자인 규칙 v1.0. **로컬 전용**이라 `.gitignore`로 제외됨(없으면 아래 '디자인 규칙' 요약을 따른다) |
| `.vercelignore` | 문서·SQL·CSV·디자인 규칙을 배포물에서 제외 |
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
브라우저 콘솔에서 `openConfigModal()`을 실행해 그 프로젝트의 URL과 키를 입력하세요. 이 값은 해당 브라우저의 LocalStorage에만 저장되며, 창 안의 **기본값으로 되돌리기**를 누르면 기본값으로 돌아갑니다.

## 디자인 규칙 (DA UI hallmark v1.0, app 프로필)

apple 스타일 디자인은 폐기했고 `index.html`은 hallmark를 따릅니다. 전체 규칙은 `DA_UI_hallmark/01_foundation.md`(공통)와 `02_app_screens.md`(업무 화면)에 있고, 시작 틀은 `10_template_app.html`입니다. 아래는 꼭 지킬 요약입니다.

- **구조**: 회색 틀(`--frame`) 안의 흰 시트. 화면이 2개뿐이라 사이드바 없이 상단 막대 + 가운데 열(최대 1200px).
- **색**: 회사 8색과 무채색만 씁니다. `:root` 값은 바꾸지 않고 hex를 직접 쓰지 않습니다. 빨강·노랑·초록·보라 금지.
  강조색은 네이비 하나입니다. 절약 금액은 네이비 면 + 흰 글자(28px/700), PX 합계는 네이비 글자, 인터넷/할인마트 합계는 검정입니다.
  경고·오류는 색이 아니라 문장과 "확인 필요" 꼬리표(`.tag.o`)로 표시합니다.
- **글꼴**: Pretendard, 표는 맑은 고딕(`--sheet-font`). 크기는 28·22·15·14·13·12px, 굵기는 400·600·700.
- **표**: 엑셀형(`.xg` + `table.sh`). 행 24px(휴대폰 40px), 격자선 1px `--grid`, 행 번호 열, 머리글 띠, 숫자는 오른쪽 정렬. 고친 칸은 `td.ed`(연한 파랑 + 모서리 삼각).
- **버튼**: 주 버튼(`.btn-1`, 네이비)은 화면에 하나, 나머지는 `.btn-2`(흰 바탕 + 테두리)와 `.btn-t`(글자). 수량 `−/+`는 `.step`, 삭제 `×`는 `.xbtn`.
- **금지**: 이모지, 그라데이션, 반투명 흐림, 쉬고 있는 요소의 그림자, 대문자 변환, 등장 애니메이션, 마우스를 올리면 떠오르는 효과, eyebrow 라벨, 줄표(—). 그림자는 대화상자·토스트처럼 떠 있는 요소에만 `--float`로 씁니다.
- **아이콘**: 16px 선 아이콘(SVG `<symbol>`)만 씁니다. 이모지와 `✕`·`⚙` 같은 기호 문자는 쓰지 않습니다.
- **문구**: 결론을 먼저, 명사형 제목, 버튼은 동작 이름. 시스템 문장은 "~다" 체로 씁니다.
- **상태**: 모든 블록에 빈 상태, 불러오는 중(회색 막대), 오류(+ 다시 시도)를 둡니다.
- **폭**: 1100px 이하에서 양식이 2열, 640px 이하에서 틀이 사라지고 시트가 전체 화면이 되며 표는 자기 틀 안에서만 가로 스크롤(행 번호·상품명 열 고정)합니다.
- **화면 규약**: 화면은 `<section data-hm-view="이름">`, `window.hmShow("이름")`과 주소 `#이름`으로 엽니다.

### 디자인을 고친 뒤 검사

1. 금지 패턴 검색: `DA_UI_hallmark/04_checklist.md` 4장의 파이썬 스크립트를 **프로젝트 밖 임시 위치**에 저장해 `python -I hallmark_scan.py index.html`로 실행합니다. 마지막 확인 결과는 FAIL 0 · WARN 0입니다.
2. 브라우저 검사(사람): `DA_UI_hallmark/checker.html`을 Edge로 열어 `index.html`을 끌어다 놓고, 1440·768·390 폭의 FAIL을 확인합니다. **아직 실행하지 않았습니다.**

## 아키텍처

- **프레임워크와 번들러 없음.** 바닐라 JS 전역 함수와 HTML 인라인 핸들러(`onclick="addToCart(1)"`)로 구성됩니다.
  함수 이름을 바꿀 때는 템플릿 문자열 안의 핸들러 이름도 함께 바꿔야 합니다.
- **CDN 의존성**: Pretendard 폰트(jsDelivr), `@supabase/supabase-js@2`(jsDelivr, 메이저 버전만 고정).
- **렌더링**: 상태가 바뀌면 해당 영역을 `innerHTML`로 다시 그립니다. 사용자 입력이나 DB 값을 HTML에 넣을 때는 **반드시 `esc()`를 거쳐야** 합니다.
  표의 스크롤 상자(`.xg-scroll`)는 HTML에 고정돼 있고 `tbody`만 다시 그립니다. 그래야 담기·수량 변경 때 스크롤 위치가 유지됩니다.
- **블록 상태**: 시트마다 `#xxxState`(빈 상태·불러오는 중·오류)와 `#xxxSheet`(표)가 짝이며, `setBlock(접두사, html|null)`이 둘 중 하나만 보이게 합니다(`cat`, `cart`, `admin`).
- **초점 유지**: 다시 그린 뒤 키보드 사용자가 자리를 잃지 않도록 `refocus()`가 같은 행의 같은 버튼(`data-k`)에 초점을 되돌립니다.

### 전역 상태

| 변수 | 내용 | 영속화 |
|---|---|---|
| `products`, `productsById` | DB 상품 목록(`id,name,px_price,internet_price,category`) | 없음(로드할 때마다 조회) |
| `dbState`, `dbError` | `loading`/`ok`/`error`와 오류 메시지. 모든 블록의 상태 표시에 쓰임 | 없음 |
| `cart` | `{ [id]: qty }` | `localStorage["px_cart"]` |
| `edits`, `deletes` | 등록 화면에서 아직 저장하지 않은 편집·삭제 표시 | 없음 |
| `adminUnlocked` | 상품 등록 잠금 해제 여부 | 없음(새로고침하면 다시 잠김) |
| `dlg` | 열려 있는 대화상자(버튼 목록, 돌아갈 초점) | 없음 |
| (설정 override) | Supabase URL·키 | `localStorage["px_cfg"]` |

### 처리 흐름

1. `init()`: `cart` 복원 → `route()` → `reloadAll()`(불러오는 중 틀) → `loadConfigAndConnect()` → `reloadProducts()` → `reloadAll()`
2. `reloadAll()`은 `fillCategoryFilter()`, `renderStatus()`, `renderCatalog()`, `renderCart()`, `renderAdmin()`을 차례로 호출합니다.
3. 견적 화면(`#quote`): 상품 목록은 검색어 없이도 전체(최대 `SHOW`=200행)를 보여 줍니다. `addToCart`, `adjustQty`, `setCartQty`, `removeFromCart`가 `commitCart()`(저장 + 장바구니·목록 다시 그림)를 부르고, `updateSummary()`가 합계 상자와 설명 문장을 갱신합니다.
4. 등록 화면(`#admin`): 잠겨 있으면 잠금 안내(`#adminLocked`)만 보입니다. 메뉴를 눌러 들어오면 `openPasswordModal()`이 자동으로 열립니다(주소로 들어오면 열리지 않음). 해제하면 `addProduct()`(INSERT)와 표 인라인 편집 `onCellEdit()` → `saveEdits()`(UPDATE·DELETE를 건별로 순차 요청한 뒤 전체 재조회)를 쓸 수 있습니다.
5. 대화상자: 연결 설정, 비밀번호, 확인, 새 카테고리 입력 모두 `openDlg({title, body, buttons})` 하나를 씁니다. 버튼의 `run`이 `false`를 돌려주면 열린 채로 남고, `cancel: true` 버튼은 Esc·배경 클릭에도 실행됩니다. 확인은 `await askConfirm(...)`로 받습니다. `confirm()`/`prompt()`는 쓰지 않습니다.

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

- 절약률 = `(인터넷가 − PX가) / 인터넷가`. 합계 상자의 절약 금액은 음수가 되면 0으로 처리합니다(PX가 항상 싸다는 가정). 표의 행별 값은 그대로 보입니다.
- 가격차 경고 = `|인터넷가 − PX가| / PX가 > 40%`. 분모가 PX가이므로 절약률과 기준이 다릅니다. 신규 등록에서는 '경고 무시' 체크박스로, 편집 저장에서는 확인 창으로 우회합니다.

## 수정할 때 지킬 규칙

- **디자인**: 위 '디자인 규칙'을 따릅니다. 색·라운드는 `:root` 변수만 쓰고, 고친 뒤에는 금지 패턴 검색을 돌립니다. 규칙과 다르게 해야 하면 이유를 커밋 메시지나 PR에 적습니다.
- **DB 스키마 변경**: `supabase_init.sql`을 다시 실행하지 말고, `ALTER TABLE` 같은 변경분만 SQL Editor에서 실행하세요. 그런 다음 같은 변경을 `supabase_init.sql`에도 반영해 둡니다.
- **비밀값**: `service_role`이나 `secret_…` 키는 코드, Git, Vercel 환경변수 어디에도 두지 않습니다. `.env*` 파일은 `.gitignore`에 등록돼 있습니다.
- **커밋**: 작은 단위로 나누고, 메시지는 한국어로 짧게 씁니다(`feat: …`, `fix: …`, `docs: …`, `chore: …`).

## 알려진 이슈와 개선 후보

**보안**
- 상품 등록 비밀번호가 `index.html`에 평문 상수(`ADMIN_PW`)로 들어 있어 소스 보기만으로 확인할 수 있습니다. 게다가 RLS가 anon에 쓰기를 모두 허용하므로, 비밀번호를 몰라도 API를 직접 호출해 수정·삭제할 수 있습니다. 실제 보호가 필요하면 Supabase Auth와 `auth.uid()` 기반 RLS로 바꿔야 합니다.

**기능과 버그**
- 우상단 `DB 설정` 버튼은 `0e43d30 테마조절` 커밋에서 제거됐습니다. 지금은 연결에 실패할 때만 설정 창이 자동으로 뜨고, 직접 열려면 콘솔에서 `openConfigModal()`을 실행해야 합니다.
- 인라인 편집에서 상품명을 지우면 빈 문자열이, 가격 칸을 지우면 0이 그대로 저장됩니다(`saveEdits()`에 입력 검증이 없음).
- `saveEdits()`는 변경 건수만큼 요청을 순차로 보냅니다. 대량 수정은 느리고, 중간에 실패하면 일부만 반영됩니다.
- 다른 기기에서 삭제된 상품 id가 LocalStorage 장바구니에 남아 있으면, 화면에는 보이지 않지만 저장소에는 계속 남습니다.
- 휴대폰(640px 이하)에서 표는 두 줄 목록이 아니라 자기 틀 안의 가로 스크롤 시트입니다(행 번호·상품명 열 고정). 장바구니 수량 조절은 한 화면에서 되지만 소계 열은 옆으로 밀어야 보입니다.

**정리**
- `@supabase/supabase-js@2`는 2.x의 최신 버전이 자동으로 적용됩니다. 재현성이 필요하면 정확한 버전으로 고정하세요.
