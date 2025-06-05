-- registrationテーブルから location_id 毎の登録数を集計
-- 条件: is_active = TRUE, datetime >= '2025-05-21 15:00:00'
-- 日単位でグループ化、dateカラムは3列目に配置
-- 用途: MySQLのlocation情報とのJOIN用

SELECT 
    location_id,
    COUNT(*) AS registered_children_count,
    DATE(datetime) as date
FROM public.registration 
WHERE is_active = TRUE 
    AND datetime >= '2025-05-21 15:00:00'
    AND datetime < date_trunc('week', CURRENT_DATE)::timestamp
GROUP BY location_id, DATE(datetime)
ORDER BY location_id, DATE(datetime); 