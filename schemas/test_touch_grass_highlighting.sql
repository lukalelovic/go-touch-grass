-- ============================================================================
-- Test Touch Grass Activity Highlighting
-- This script will help you test the highlighting by creating test data
-- ============================================================================

-- Option 1: Check if you have any recommendations
SELECT 'Your daily recommendations:' AS info;
SELECT id, user_id, personalized_prompt, recommendation_date, was_logged
FROM daily_activity_recommendations
ORDER BY recommendation_date DESC
LIMIT 5;

-- Option 2: Manually link an existing activity to a recommendation (for testing)
-- This will make one of your existing activities show up as a "Touch Grass" activity
-- UNCOMMENT THE LINES BELOW and replace the IDs with actual values from your database

/*
-- First, get an activity ID and a recommendation ID:
SELECT 'Recent activities:' AS info;
SELECT id, user_id, notes, timestamp FROM activities ORDER BY timestamp DESC LIMIT 3;

SELECT 'Recent recommendations:' AS info;
SELECT id, user_id, personalized_prompt FROM daily_activity_recommendations LIMIT 3;

-- Then update an activity to link it to a recommendation (replace the UUIDs):
UPDATE activities
SET recommendation_id = 'YOUR_RECOMMENDATION_ID_HERE'
WHERE id = 'YOUR_ACTIVITY_ID_HERE';

-- Verify it worked:
SELECT id, user_id, notes, recommendation_id
FROM activities
WHERE recommendation_id IS NOT NULL;
*/

-- Option 3: Create a test recommendation and activity
-- This creates a complete test case to see the highlighting

-- Step 1: Get your user ID
SELECT 'Your user ID:' AS info, id FROM users LIMIT 1;

-- Step 2: Create a test recommendation (uncomment and replace YOUR_USER_ID)
/*
INSERT INTO daily_activity_recommendations (
    user_id,
    recommendation_date,
    activity_template_id,
    card_position,
    personalized_prompt,
    personalized_challenge,
    activity_type_id,
    estimated_duration_minutes,
    was_logged
) VALUES (
    'YOUR_USER_ID_HERE'::UUID,
    CURRENT_DATE,
    1,  -- Assumes template 1 exists
    1,
    'Test Touch Grass Activity: Go for a walk!',
    'Take a 15-minute walk and notice 3 things in nature.',
    10, -- Walking activity type (adjust if needed)
    15,
    false
) RETURNING id;
*/

-- Step 3: After getting the recommendation ID from above, create an activity linked to it
/*
INSERT INTO activities (
    user_id,
    activity_type_id,
    notes,
    recommendation_id,
    timestamp
) VALUES (
    'YOUR_USER_ID_HERE'::UUID,
    10, -- Walking
    'Test Touch Grass activity - this should appear highlighted!',
    'RECOMMENDATION_ID_FROM_ABOVE'::UUID,
    NOW()
) RETURNING id;
*/

SELECT '✅ Follow the instructions above to test Touch Grass highlighting!' AS result;
