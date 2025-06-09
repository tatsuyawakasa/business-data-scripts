-- registrationテーブルから location_id 毎の登録数を集計
-- 前週1週間のデータを抽出（月曜日から日曜日まで）
-- 条件: is_active = TRUE
-- 日単位でグループ化、dateカラムは3列目に配置
-- 用途: MySQLのlocation情報とのJOIN用

SELECT 
    location_id,
    COUNT(*) AS registered_children_count,
    DATE(datetime) as date
FROM public.registration 
WHERE is_active = TRUE 
    AND datetime >= date_trunc('week', CURRENT_DATE - INTERVAL '1 week')::timestamp
    AND datetime < date_trunc('week', CURRENT_DATE)::timestamp
GROUP BY location_id, DATE(datetime)
ORDER BY location_id, DATE(datetime); 