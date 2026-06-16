-- =============================================================================
-- PX/군마트 vs 인터넷·할인마트 가격 견적기 — Supabase 스키마 셋업
-- =============================================================================
-- ⚠️ 이 파일은 "최초 1회"만 실행합니다.
--   첫 줄의 DROP TABLE 때문에 이미 운영 중인 프로젝트에서 다시 실행하면
--   그 동안 등록·수정한 데이터가 모두 사라집니다.
--   초기 데이터는 이 SQL이 아니라 같은 폴더의 px_products.csv 로 별도 import 합니다.
--
-- 셋업 흐름:
--   1) 이 SQL 전체를 Supabase SQL Editor 에 붙여넣고 Run
--      → 빈 테이블 + 트리거 + RLS 정책이 만들어짐
--   2) Table Editor → px_products → Insert → Import data from CSV
--      → 같은 폴더의 px_products.csv 업로드
--   3) Settings → API Keys 에서 Project URL / Publishable key 복사 후
--      웹앱 우상단 ⚙ DB 설정 모달에 입력
-- =============================================================================

-- 1) 테이블 생성 ------------------------------------------------------------
DROP TABLE IF EXISTS public.px_products CASCADE;

CREATE TABLE public.px_products (
  id              BIGSERIAL PRIMARY KEY,
  name            TEXT      NOT NULL UNIQUE,    -- "상품명 (용량)" 통합 컬럼
  px_price        INTEGER   NOT NULL CHECK (px_price >= 0),
  internet_price  INTEGER   NOT NULL CHECK (internet_price >= 0),
  category        TEXT,                          -- 라면/즉석식/음료/주류/생활/구강/화장품 등
  source_url      TEXT,                          -- 출처(편의용, 비워도 무방)
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_px_products_name     ON public.px_products (name);
CREATE INDEX idx_px_products_category ON public.px_products (category);


-- 2) updated_at 자동 갱신 트리거 -------------------------------------------
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_px_products_touch ON public.px_products;
CREATE TRIGGER trg_px_products_touch
BEFORE UPDATE ON public.px_products
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();


-- 3) RLS (Row Level Security) ----------------------------------------------
-- 개인 사용 목적이라 anon 키만으로 모든 작업을 허용합니다.
-- ⚠ 누구나 anon 키만 알면 읽고 쓸 수 있으니, 키는 외부에 공개하지 마세요.
--   더 잠그려면 Supabase Auth 도입 후 user_id 매칭 정책으로 바꾸세요.
ALTER TABLE public.px_products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon read"   ON public.px_products;
DROP POLICY IF EXISTS "anon insert" ON public.px_products;
DROP POLICY IF EXISTS "anon update" ON public.px_products;
DROP POLICY IF EXISTS "anon delete" ON public.px_products;

CREATE POLICY "anon read"   ON public.px_products FOR SELECT TO anon USING (true);
CREATE POLICY "anon insert" ON public.px_products FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon update" ON public.px_products FOR UPDATE TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon delete" ON public.px_products FOR DELETE TO anon USING (true);


-- 4) (참고) 검증 쿼리 — CSV import 후 실행해서 확인용 -----------------------
-- SELECT COUNT(*) FROM public.px_products;
--
-- SELECT name, px_price, internet_price,
--        ROUND(((internet_price - px_price)::numeric / NULLIF(px_price,0)) * 100, 1) AS gap_pct
-- FROM   public.px_products
-- ORDER  BY gap_pct DESC NULLS LAST
-- LIMIT  20;
-- =============================================================================
