-- 為 resources 表新增 category 和 important_info 欄位
-- 執行方式: psql $DATABASE_URL -f migrations/001_add_category_and_important_info.sql

ALTER TABLE resources
    ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT '其他',
    ADD COLUMN IF NOT EXISTS important_info JSONB;
