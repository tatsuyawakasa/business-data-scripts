-- registrationテーブルから location_id 毎の登録数を集計
-- 条件: is_active = TRUE
-- 用途: MySQLのlocation情報とのJOIN用

SELECT 
    location_id, 
    COUNT(*) AS registered_children_count 
FROM public.registration 
WHERE is_active = TRUE 
GROUP BY location_id 
ORDER BY location_id; 