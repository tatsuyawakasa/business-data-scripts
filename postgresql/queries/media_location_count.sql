-- location_id別のレコード数を取得するクエリ（tlnk_shooting_mode別集計付き）
-- 作成日時でフィルタリング（前週月曜日15時から当週月曜日0時まで）

SELECT 
    location_id,
    COUNT(CASE WHEN tlnk_shooting_mode = 'NON_TLNK_CAMERA' THEN 1 END) as manual_upload_count,
    COUNT(CASE WHEN tlnk_shooting_mode = 'MANUAL_SHUTTER' THEN 1 END) as app_upload_count,
    COUNT(*) as total_count
FROM media 
WHERE created_datetime >= '2025-05-21 15:00:00'
--  AND created_datetime < date_trunc('week', CURRENT_DATE)::timestamp
GROUP BY location_id
ORDER BY location_id; 