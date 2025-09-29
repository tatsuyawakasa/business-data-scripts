-- location_id別のレコード数を取得するクエリ（tlnk_shooting_mode別集計付き）
-- 直近の月曜日0時から現在までのデータを抽出（現在進行中の週）
-- 日単位でグループ化、dateカラムを右端に配置

SELECT 
    location_id,
    COUNT(CASE WHEN tlnk_shooting_mode = 'NON_TLNK_CAMERA' THEN 1 END) as manual_upload_count,
    COUNT(CASE WHEN tlnk_shooting_mode = 'MANUAL_SHUTTER' THEN 1 END) as app_upload_count,
    COUNT(*) as total_count,
    DATE(created_datetime) as date
FROM media 
WHERE created_datetime >= date_trunc('week', CURRENT_DATE)::timestamp
  AND created_datetime <= CURRENT_TIMESTAMP
GROUP BY location_id, DATE(created_datetime)
ORDER BY location_id, DATE(created_datetime);