-- ============================================================================
-- ACTIVITY TEMPLATES SEED DATA (50 Templates)
-- ============================================================================
-- Run this after running schema.sql
-- This populates the activity_templates table with 50 curated activity prompts
-- ============================================================================

DO $$
DECLARE
    hiking_id INTEGER;
    running_id INTEGER;
    cycling_id INTEGER;
    swimming_id INTEGER;
    climbing_id INTEGER;
    kayaking_id INTEGER;
    walking_id INTEGER;
    other_id INTEGER;
BEGIN
    -- Get activity type IDs
    SELECT id INTO hiking_id FROM activity_types WHERE name = 'Hiking';
    SELECT id INTO running_id FROM activity_types WHERE name = 'Running';
    SELECT id INTO cycling_id FROM activity_types WHERE name = 'Cycling';
    SELECT id INTO swimming_id FROM activity_types WHERE name = 'Swimming';
    SELECT id INTO climbing_id FROM activity_types WHERE name = 'Climbing';
    SELECT id INTO kayaking_id FROM activity_types WHERE name = 'Kayaking';
    SELECT id INTO walking_id FROM activity_types WHERE name = 'Walking';
    SELECT id INTO other_id FROM activity_types WHERE name = 'Other';

    -- RUNNING TEMPLATES (10)
    INSERT INTO activity_templates (activity_type_id, prompt_template, challenge_template, estimated_duration_minutes, difficulty_level, season_tags, requires_equipment) VALUES
    (running_id, 'Go for a morning run!', 'Beat yesterday''s pace', 30, 2, NULL, FALSE),
    (running_id, 'Try sprint intervals!', '8 x 200m with rest', 30, 3, NULL, FALSE),
    (running_id, 'Run your usual route backwards!', 'Notice new details', 30, 2, NULL, FALSE),
    (running_id, 'Explore a new neighborhood!', 'Find a coffee shop mid-run', 45, 2, NULL, FALSE),
    (running_id, 'Run to a scenic viewpoint!', 'Take a photo at the top', 45, 2, NULL, FALSE),
    (running_id, 'Do a slow, easy recovery run!', 'Focus on breathing', 30, 1, NULL, FALSE),
    (running_id, 'Race a friend (virtually)!', 'Compare times later', 30, 2, NULL, FALSE),
    (running_id, 'Run hills for strength!', '5 x uphill sprints', 30, 3, NULL, FALSE),
    (running_id, 'Go for a sunset run!', 'Catch the golden hour', 30, 2, '{"spring", "summer", "fall"}', FALSE),
    (running_id, 'Try a trail run!', 'Get off the pavement', 45, 2, NULL, FALSE);

    -- WALKING TEMPLATES (8)
    INSERT INTO activity_templates (activity_type_id, prompt_template, challenge_template, estimated_duration_minutes, difficulty_level, season_tags, requires_equipment) VALUES
    (walking_id, 'Take a 15-minute nature walk!', 'Count different bird species', 15, 1, NULL, FALSE),
    (walking_id, 'Walk to a local landmark!', 'Learn its history', 30, 1, NULL, FALSE),
    (walking_id, 'Go for a sunset stroll!', 'Find the best view', 30, 1, '{"spring", "summer", "fall"}', FALSE),
    (walking_id, 'Walk with a podcast!', 'Finish one episode', 30, 1, NULL, FALSE),
    (walking_id, 'Explore a new street!', 'Discover hidden gems', 30, 1, NULL, FALSE),
    (walking_id, 'Take a mindful walk!', 'Leave your phone behind', 20, 1, NULL, FALSE),
    (walking_id, 'Walk to grab coffee!', 'Try a new route', 20, 1, NULL, FALSE),
    (walking_id, 'Go on a photo walk!', 'Capture 5 interesting things', 30, 1, NULL, FALSE);

    -- HIKING TEMPLATES (8)
    INSERT INTO activity_templates (activity_type_id, prompt_template, challenge_template, estimated_duration_minutes, difficulty_level, season_tags, requires_equipment) VALUES
    (hiking_id, 'Hike to a waterfall!', 'Pack a snack for the destination', 90, 2, '{"spring", "summer"}', FALSE),
    (hiking_id, 'Try a new trail!', 'Rate the difficulty', 60, 2, NULL, FALSE),
    (hiking_id, 'Summit a local peak!', 'Check the weather first', 120, 3, NULL, FALSE),
    (hiking_id, 'Go on a sunrise hike!', 'Start early to beat the heat', 90, 2, '{"spring", "summer", "fall"}', FALSE),
    (hiking_id, 'Explore a forest trail!', 'Listen for wildlife', 60, 2, NULL, FALSE),
    (hiking_id, 'Hike with a friend!', 'Catch up on the trail', 60, 2, NULL, FALSE),
    (hiking_id, 'Do a loop trail!', 'See how fast you can complete it', 60, 2, NULL, FALSE),
    (hiking_id, 'Find a scenic overlook!', 'Take a panorama photo', 60, 2, NULL, FALSE);

    -- CYCLING TEMPLATES (6)
    INSERT INTO activity_templates (activity_type_id, prompt_template, challenge_template, estimated_duration_minutes, difficulty_level, season_tags, requires_equipment) VALUES
    (cycling_id, 'Bike to a coffee shop!', 'Try a new cafe', 30, 2, NULL, TRUE),
    (cycling_id, 'Explore a bike path!', 'See where it leads', 45, 2, NULL, TRUE),
    (cycling_id, 'Do a hill climb!', 'Test your strength', 45, 3, NULL, TRUE),
    (cycling_id, 'Ride to a park!', 'Have a picnic', 30, 2, NULL, TRUE),
    (cycling_id, 'Try a new route!', 'Avoid your usual roads', 45, 2, NULL, TRUE),
    (cycling_id, 'Go for a sunset ride!', 'Chase the light', 30, 2, '{"spring", "summer", "fall"}', TRUE);

    -- CLIMBING TEMPLATES (5)
    INSERT INTO activity_templates (activity_type_id, prompt_template, challenge_template, estimated_duration_minutes, difficulty_level, season_tags, requires_equipment) VALUES
    (climbing_id, 'Try 3 new boulder problems!', 'Ask others for beta', 60, 2, NULL, TRUE),
    (climbing_id, 'Work on a project route!', 'Make progress on that hard one', 90, 3, NULL, TRUE),
    (climbing_id, 'Go top-rope climbing!', 'Push your grade', 90, 2, NULL, TRUE),
    (climbing_id, 'Practice footwork!', 'Focus on technique', 60, 2, NULL, TRUE),
    (climbing_id, 'Climb outdoors!', 'Find a local crag', 120, 3, '{"spring", "summer", "fall"}', TRUE);

    -- SWIMMING TEMPLATES (5)
    INSERT INTO activity_templates (activity_type_id, prompt_template, challenge_template, estimated_duration_minutes, difficulty_level, season_tags, requires_equipment) VALUES
    (swimming_id, 'Swim laps at the pool!', 'Count your strokes', 30, 2, NULL, TRUE),
    (swimming_id, 'Try open water swimming!', 'Find a lake or ocean', 45, 3, '{"summer"}', TRUE),
    (swimming_id, 'Do interval sprints!', '10 x 50m fast', 30, 3, NULL, TRUE),
    (swimming_id, 'Practice a new stroke!', 'Improve your butterfly', 30, 2, NULL, TRUE),
    (swimming_id, 'Swim for distance!', 'See how far you can go', 45, 2, NULL, TRUE);

    -- KAYAKING TEMPLATES (3)
    INSERT INTO activity_templates (activity_type_id, prompt_template, challenge_template, estimated_duration_minutes, difficulty_level, season_tags, requires_equipment) VALUES
    (kayaking_id, 'Paddle a local lake!', 'Explore the shoreline', 60, 2, '{"spring", "summer", "fall"}', TRUE),
    (kayaking_id, 'Try a river route!', 'Check water conditions', 90, 3, '{"spring", "summer", "fall"}', TRUE),
    (kayaking_id, 'Kayak at sunset!', 'Bring a waterproof camera', 60, 2, '{"spring", "summer", "fall"}', TRUE);

    -- OTHER TEMPLATES (5)
    INSERT INTO activity_templates (activity_type_id, prompt_template, challenge_template, estimated_duration_minutes, difficulty_level, season_tags, requires_equipment) VALUES
    (other_id, 'Do outdoor yoga!', 'Find a quiet spot', 30, 1, '{"spring", "summer", "fall"}', FALSE),
    (other_id, 'Have a picnic in the park!', 'Bring a book', 60, 1, '{"spring", "summer", "fall"}', FALSE),
    (other_id, 'Go stargazing!', 'Use a starmap app', 60, 1, '{"spring", "summer", "fall", "winter"}', FALSE),
    (other_id, 'Play frisbee!', 'Grab a friend', 30, 1, '{"spring", "summer", "fall"}', TRUE),
    (other_id, 'Sit outside and journal!', 'Reflect for 20 minutes', 20, 1, NULL, FALSE);

END $$;

-- Verify templates were inserted
SELECT
    at.name AS activity_type,
    COUNT(*) AS template_count
FROM activity_templates apt
JOIN activity_types at ON apt.activity_type_id = at.id
GROUP BY at.name
ORDER BY template_count DESC;
