-- location_id別のレコード数を取得するクエリ（tlnk_shooting_mode別集計付き）
-- 作成日時でフィルタリング（2025-05-21 15:00以降）
-- 日単位でグループ化、dateカラムを右端に配置

SELECT 
    location_id,
    COUNT(CASE WHEN tlnk_shooting_mode = 'NON_TLNK_CAMERA' THEN 1 END) as manual_upload_count,
    COUNT(CASE WHEN tlnk_shooting_mode = 'MANUAL_SHUTTER' THEN 1 END) as app_upload_count,
    COUNT(*) as total_count,
    DATE(created_datetime) as date
FROM media 
WHERE created_datetime >= '2025-05-21 15:00:00'
  AND created_datetime < date_trunc('week', CURRENT_DATE)::timestamp
GROUP BY location_id, DATE(created_datetime)
ORDER BY location_id, DATE(created_datetime); 