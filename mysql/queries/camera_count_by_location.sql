-- CoDMONサービスに登録されている施設のアプリログインカウントと施設情報を取得

SELECT 
    l.location_id,
    l.location_sid,
    l.location_name,
    lcm.custom_metadata as codmon_service_id,
    COUNT(c.camera_id) as app_login_count
FROM camera c 
INNER JOIN location l ON c.location_id = l.location_id 
JOIN external_service_location esl ON l.location_id = esl.location_id
JOIN external_service es ON esl.external_service_id = es.external_service_id
LEFT JOIN location_custom_metadata lcm ON l.location_id = lcm.location_id 
WHERE c.is_active = 1 
  AND es.external_service_name = 'CoDMON'
GROUP BY 
    l.location_id, 
    l.location_sid, 
    l.location_name, 
    lcm.custom_metadata 
ORDER BY app_login_count DESC;
