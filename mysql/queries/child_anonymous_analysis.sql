-- childテーブル基準のanonymous group分析
-- MySQL childテーブルとgroupテーブルのJOINによる分析
-- 条件: registrated_at >= '2025-05-21 15:00:00'
-- anonymous定義: group.is_anonymous_group = 1

SELECT 
    lcm.custom_metadata as facility_id,
    g.location_id,
    l.location_sid,
    l.location_name,
    COUNT(c.child_id) as total_children,
    SUM(CASE WHEN g.is_anonymous_group = 1 THEN 1 ELSE 0 END) as anonymous_children,
    SUM(CASE WHEN g.is_anonymous_group = 0 THEN 1 ELSE 0 END) as regular_children,
    ROUND(
        (SUM(CASE WHEN g.is_anonymous_group = 1 THEN 1 ELSE 0 END) / COUNT(c.child_id) * 100), 2
    ) as anonymous_ratio_percent
FROM child c
JOIN `group` g ON c.group_id = g.group_id
JOIN location l ON g.location_id = l.location_id
JOIN external_service_location esl ON l.location_id = esl.location_id
JOIN external_service es ON esl.external_service_id = es.external_service_id
LEFT JOIN location_custom_metadata lcm ON l.location_id = lcm.location_id
WHERE c.registrated_at >= '2025-05-21 15:00:00'
    AND c.status IN ('activate', 'anonymous')
    AND es.external_service_name = 'CoDMON'
GROUP BY lcm.custom_metadata, g.location_id, l.location_sid, l.location_name
ORDER BY g.location_id; 