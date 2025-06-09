-- location_id別のレコード数を取得するクエリ（tlnk_shooting_mode別集計付き）
-- 前週1週間のデータを抽出（月曜日から日曜日まで）
-- 日単位でグループ化、dateカラムを右端に配置

SELECT 
    location_id,
    COUNT(CASE WHEN tlnk_shooting_mode = 'NON_TLNK_CAMERA' THEN 1 END) as manual_upload_count,
    COUNT(CASE WHEN tlnk_shooting_mode = 'MANUAL_SHUTTER' THEN 1 END) as app_upload_count,
    COUNT(*) as total_count,
    DATE(created_datetime) as date
FROM media 
WHERE created_datetime >= date_trunc('week', CURRENT_DATE - INTERVAL '1 week')::timestamp
  AND created_datetime < date_trunc('week', CURRENT_DATE)::timestamp
GROUP BY location_id, DATE(created_datetime)
ORDER BY location_id, DATE(created_datetime); 