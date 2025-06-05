-- location テーブルと関連テーブルのJOINクエリ
-- CoDMONサービスに登録されている施設の基本情報とカスタムメタデータを取得

SELECT
    lcm.custom_metadata,
    l.location_id,
    l.location_sid,
    l.location_name
FROM location l 
JOIN external_service_location esl ON l.location_id = esl.location_id
JOIN external_service es ON esl.external_service_id = es.external_service_id
LEFT JOIN location_custom_metadata lcm ON l.location_id = lcm.location_id
WHERE es.external_service_name = 'CoDMON'
ORDER BY l.created_at DESC; 