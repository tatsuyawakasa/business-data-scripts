-- childテーブル基準のこども登録状況分析
-- 旧定義（クラス所属）と新定義（園児ID連携＝名前登録）を並べて出す
-- 条件: registrated_at >= '2025-05-21 15:00:00'
--
-- 旧定義 anonymous: group.is_anonymous_group = 1
--   顔認識で見つかったこどもは匿名グループに入り、クラスを割り当てると普通のグループに移る
--   園児ID連携（2026-04-15リリース）以降は誰も匿名グループから出ないため、この列は事実上凍結している
--
-- 新定義 unnamed: child_custom_metadata の externalChildIds が空
--   画面の「名前を登録する」= POST /api/external/resources/children/{id}/link がこの JSON を書く
--   判定の正本は tlnk-web-external src/pinia/children.ts の unpairedChildren
--
-- このファイルは to_csv.sh / run_all_reports.sh で1行に潰されてから mysql -e に渡される。
-- 行末コメントを書かないこと、GROUP BY を1回だけにすることが前提になっている
-- （run_all_reports.sh が除外条件を最初の GROUP BY の直前に sed で挿し込むため）

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
    ) as anonymous_ratio_percent,
    SUM(CASE WHEN COALESCE(JSON_LENGTH(JSON_EXTRACT(ccm.custom_metadata, '$.externalChildIds')), 0) > 0 THEN 1 ELSE 0 END) as named_children,
    SUM(CASE WHEN COALESCE(JSON_LENGTH(JSON_EXTRACT(ccm.custom_metadata, '$.externalChildIds')), 0) = 0 THEN 1 ELSE 0 END) as unnamed_children,
    ROUND(
        (SUM(CASE WHEN COALESCE(JSON_LENGTH(JSON_EXTRACT(ccm.custom_metadata, '$.externalChildIds')), 0) = 0 THEN 1 ELSE 0 END) / COUNT(c.child_id) * 100), 2
    ) as unnamed_ratio_percent
FROM child c
JOIN `group` g ON c.group_id = g.group_id
JOIN location l ON g.location_id = l.location_id
JOIN external_service_location esl ON l.location_id = esl.location_id
JOIN external_service es ON esl.external_service_id = es.external_service_id
LEFT JOIN location_custom_metadata lcm ON l.location_id = lcm.location_id
LEFT JOIN child_custom_metadata ccm ON c.child_id = ccm.child_id
WHERE c.registrated_at >= '2025-05-21 15:00:00'
    AND c.status IN ('activate', 'anonymous')
    AND es.external_service_name = 'CoDMON'
GROUP BY lcm.custom_metadata, g.location_id, l.location_sid, l.location_name
ORDER BY g.location_id; 
