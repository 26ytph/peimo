-- citizen_profiles 新增 prefer_resources 欄位
-- 執行方式: psql $DATABASE_URL -f migrations/002_add_prefer_resources.sql

ALTER TABLE citizen_profiles
    ADD COLUMN IF NOT EXISTS prefer_resources VARCHAR(200);
