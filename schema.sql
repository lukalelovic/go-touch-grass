-- Go Touch Grass Database Schema
-- PostgreSQL Database Setup
-- Used in a Supabase Project
-- In Supabase, ensure RLS is enabled for created tables.

-- To setup locally instead, you can run: 
-- psql -U your_username -d go_touch_grass -f schema.sql

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop tables if they exist (for clean setup)
-- DROP TABLE IF EXISTS activity_likes CASCADE;
-- DROP TABLE IF EXISTS activities CASCADE;
-- DROP TABLE IF EXISTS activity_subtypes CASCADE;
-- DROP TABLE IF EXISTS activity_types CASCADE;
-- DROP TABLE IF EXISTS users CASCADE;

-- ============================================================================
-- USERS TABLE
-- ============================================================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT username_min_length CHECK (char_length(username) >= 3),
    CONSTRAINT email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Index for faster username lookups
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);

-- ============================================================================
-- ACTIVITY TYPES TABLE
-- ============================================================================
CREATE TABLE activity_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    icon VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Seed default activity types
INSERT INTO activity_types (name, icon) VALUES
    ('Hiking', 'figure.hiking'),
    ('Running', 'figure.run'),
    ('Cycling', 'bicycle'),
    ('Swimming', 'figure.pool.swim'),
    ('Climbing', 'figure.climbing'),
    ('Kayaking', 'figure.kayaking'),
    ('Camping', 'tent.fill'),
    ('Skiing', 'snowflake'),
    ('Surfing', 'water.waves'),
    ('Walking', 'figure.walk'),
    ('Other', 'figure.outdoor.cycle');

-- ============================================================================
-- ACTIVITY SUBTYPES TABLE (Optional granular categorization)
-- ============================================================================
CREATE TABLE activity_subtypes (
    id SERIAL PRIMARY KEY,
    activity_type_id INTEGER NOT NULL REFERENCES activity_types(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Ensure unique subtypes per activity type
    CONSTRAINT unique_subtype_per_type UNIQUE(activity_type_id, name)
);

-- Example subtypes (optional - can be added as needed)
INSERT INTO activity_subtypes (activity_type_id, name) VALUES
    ((SELECT id FROM activity_types WHERE name = 'Hiking'), 'Trail Hiking'),
    ((SELECT id FROM activity_types WHERE name = 'Hiking'), 'Mountain Hiking'),
    ((SELECT id FROM activity_types WHERE name = 'Hiking'), 'Desert Hiking'),
    ((SELECT id FROM activity_types WHERE name = 'Running'), 'Trail Running'),
    ((SELECT id FROM activity_types WHERE name = 'Running'), 'Road Running'),
    ((SELECT id FROM activity_types WHERE name = 'Cycling'), 'Mountain Biking'),
    ((SELECT id FROM activity_types WHERE name = 'Cycling'), 'Road Cycling');

-- ============================================================================
-- ACTIVITIES TABLE (Touch Grass Events)
-- ============================================================================
CREATE TABLE activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_type_id INTEGER NOT NULL REFERENCES activity_types(id) ON DELETE RESTRICT,
    activity_subtype_id INTEGER REFERENCES activity_subtypes(id) ON DELETE SET NULL,

    -- Activity details
    notes TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Location data (stored denormalized for simplicity)
    location_latitude DECIMAL(10, 8),
    location_longitude DECIMAL(11, 8),
    location_name VARCHAR(255),

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT valid_coordinates CHECK (
        (location_latitude IS NULL AND location_longitude IS NULL) OR
        (location_latitude BETWEEN -90 AND 90 AND location_longitude BETWEEN -180 AND 180)
    )
);

-- Indexes for common queries
CREATE INDEX idx_activities_user_id ON activities(user_id);
CREATE INDEX idx_activities_activity_type_id ON activities(activity_type_id);
CREATE INDEX idx_activities_timestamp ON activities(timestamp DESC);
CREATE INDEX idx_activities_location ON activities(location_latitude, location_longitude) WHERE location_latitude IS NOT NULL;

-- ============================================================================
-- ACTIVITY LIKES TABLE (Nice Counter with User Tracking)
-- ============================================================================
-- This junction table tracks which users liked which activities
-- Prevents spam by enforcing one like per user per activity
CREATE TABLE activity_likes (
    id SERIAL PRIMARY KEY,
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Ensure one like per user per activity
    CONSTRAINT unique_user_activity_like UNIQUE(activity_id, user_id)
);

-- Indexes for efficient like counting and checking
CREATE INDEX idx_activity_likes_activity_id ON activity_likes(activity_id);
CREATE INDEX idx_activity_likes_user_id ON activity_likes(user_id);

-- ============================================================================
-- VIEWS FOR CONVENIENT QUERYING
-- ============================================================================

-- View to get activity feed with like counts
CREATE OR REPLACE VIEW activities_with_stats 
with (security_invoker = on) AS
SELECT
    a.id,
    a.user_id,
    u.username,
    u.email,
    a.activity_type_id,
    at.name AS activity_type_name,
    at.icon AS activity_type_icon,
    a.activity_subtype_id,
    ast.name AS activity_subtype_name,
    a.notes,
    a.timestamp,
    a.location_latitude,
    a.location_longitude,
    a.location_name,
    COUNT(DISTINCT al.id) AS like_count,
    a.created_at,
    a.updated_at
FROM activities a
JOIN users u ON a.user_id = u.id
JOIN activity_types at ON a.activity_type_id = at.id
LEFT JOIN activity_subtypes ast ON a.activity_subtype_id = ast.id
LEFT JOIN activity_likes al ON a.id = al.activity_id
GROUP BY
    a.id, u.id, u.username, u.email,
    at.id, at.name, at.icon,
    ast.id, ast.name,
    a.notes, a.timestamp, a.location_latitude,
    a.location_longitude, a.location_name,
    a.created_at, a.updated_at;

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update trigger to users table
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply update trigger to activities table
CREATE TRIGGER update_activities_updated_at
    BEFORE UPDATE ON activities
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to toggle like (add if not exists, remove if exists)
CREATE OR REPLACE FUNCTION toggle_activity_like(
    p_activity_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    -- Check if like exists
    SELECT EXISTS(
        SELECT 1 FROM activity_likes
        WHERE activity_id = p_activity_id AND user_id = p_user_id
    ) INTO v_exists;

    IF v_exists THEN
        -- Unlike: Remove the like
        DELETE FROM activity_likes
        WHERE activity_id = p_activity_id AND user_id = p_user_id;
        RETURN FALSE; -- Indicates unliked
    ELSE
        -- Like: Add the like
        INSERT INTO activity_likes (activity_id, user_id)
        VALUES (p_activity_id, p_user_id);
        RETURN TRUE; -- Indicates liked
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to check if a user has liked an activity
CREATE OR REPLACE FUNCTION has_user_liked_activity(
    p_activity_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM activity_likes
        WHERE activity_id = p_activity_id AND user_id = p_user_id
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- BADGES AND LEVELS SYSTEM
-- ============================================================================

-- Badge categories for organizing different types of achievements
CREATE TYPE badge_category AS ENUM (
    'activity_count',      -- Based on total activities completed
    'activity_type',       -- Based on specific activity types
    'streak',              -- Based on consecutive days/activities
    'distance',            -- Based on total distance (future)
    'social',              -- Based on 'Nices' received/given
    'special'              -- Limited time or special achievements
);

-- Badge definitions table
CREATE TABLE badges (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT NOT NULL,
    category badge_category NOT NULL,
    icon VARCHAR(100),

    -- Criteria for unlocking (stored as JSONB for flexibility)
    -- Example formats:
    -- Activity count: {"type": "total_activities", "count": 10}
    -- Activity type: {"type": "specific_activity", "activity_type_id": 1, "count": 5}
    -- Streak: {"type": "consecutive_days", "days": 7}
    -- Social: {"type": "likes_received", "count": 50}
    criteria JSONB NOT NULL,

    -- Display order and rarity
    display_order INTEGER DEFAULT 0,
    rarity VARCHAR(20) DEFAULT 'common', -- common, rare, epic, legendary

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Level milestones table (markers for key progression points)
-- Users are always at a level equal to their total activity count (1 activity = level 1)
-- But they reach named "milestones" at specific thresholds
CREATE TABLE level_milestones (
    id SERIAL PRIMARY KEY,
    milestone_level INTEGER UNIQUE NOT NULL,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    icon VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT positive_milestone_level CHECK (milestone_level > 0)
);

-- User badges junction table (tracks which badges users have unlocked)
CREATE TABLE user_badges (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    badge_id INTEGER NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Progress tracking (if badge has progressive criteria)
    progress JSONB,

    -- Ensure user can only unlock each badge once
    CONSTRAINT unique_user_badge UNIQUE(user_id, badge_id)
);

-- Indexes for badge queries
CREATE INDEX idx_user_badges_user_id ON user_badges(user_id);
CREATE INDEX idx_user_badges_badge_id ON user_badges(badge_id);
CREATE INDEX idx_user_badges_unlocked_at ON user_badges(unlocked_at DESC);
CREATE INDEX idx_badges_category ON badges(category);

-- ============================================================================
-- BADGE AND LEVEL VIEWS
-- ============================================================================

-- View to calculate user statistics for badge/level calculations
CREATE OR REPLACE VIEW user_stats
with (security_invoker = on) AS
WITH activity_type_counts AS (
    SELECT
        a.user_id,
        at.name AS activity_type_name,
        COUNT(*) AS activity_count
    FROM activities a
    JOIN activity_types at ON a.activity_type_id = at.id
    GROUP BY a.user_id, at.name
)
SELECT
    u.id AS user_id,
    u.username,
    u.created_at AS user_created_at,

    -- Activity statistics
    COUNT(DISTINCT a.id) AS total_activities,
    COUNT(DISTINCT DATE(a.timestamp)) AS total_active_days,

    -- Activity type breakdown (as JSONB)
    COALESCE(
        (SELECT jsonb_object_agg(activity_type_name, activity_count)
         FROM activity_type_counts atc
         WHERE atc.user_id = u.id),
        '{}'::jsonb
    ) AS activities_by_type,

    -- Social statistics
    COUNT(DISTINCT al_received.id) AS total_likes_received,
    COUNT(DISTINCT al_given.id) AS total_likes_given,

    -- Dates for streak calculation
    MAX(a.timestamp) AS last_activity_date,
    MIN(a.timestamp) AS first_activity_date,

    -- Badge progress
    COUNT(DISTINCT ub.badge_id) AS badges_unlocked
FROM users u
    LEFT JOIN activities a ON u.id = a.user_id
    LEFT JOIN activity_likes al_received ON a.id = al_received.activity_id
    LEFT JOIN activity_likes al_given ON u.id = al_given.user_id
    LEFT JOIN user_badges ub ON u.id = ub.user_id
GROUP BY u.id, u.username, u.created_at;

-- View to calculate user current level and milestones
CREATE OR REPLACE VIEW user_current_levels
with (security_invoker = on) AS
SELECT
    us.user_id,
    us.username,
    us.total_activities,

    -- Current level equals total activities (1 activity = level 1)
    GREATEST(us.total_activities, 1) AS current_level,

    -- Current milestone information (highest milestone reached)
    current_milestone.milestone_level AS current_milestone_level,
    current_milestone.name AS milestone_name,
    current_milestone.description AS milestone_description,
    current_milestone.icon AS milestone_icon,

    -- Next milestone information
    next_milestone.milestone_level AS next_milestone_level,
    next_milestone.name AS next_milestone_name,
    next_milestone.icon AS next_milestone_icon,
    GREATEST(0, COALESCE(next_milestone.milestone_level, 0) - us.total_activities) AS activities_to_next_milestone,

    -- Progress percentage to next milestone
    CASE
        WHEN next_milestone.milestone_level IS NULL THEN 100
        WHEN next_milestone.milestone_level <= COALESCE(current_milestone.milestone_level, 0) THEN 100
        ELSE ROUND(
            ((us.total_activities - COALESCE(current_milestone.milestone_level, 0))::NUMERIC /
            (next_milestone.milestone_level - COALESCE(current_milestone.milestone_level, 0))::NUMERIC * 100),
            2
        )
    END AS progress_to_next_milestone

FROM user_stats us
LEFT JOIN level_milestones current_milestone ON us.total_activities >= current_milestone.milestone_level
    AND current_milestone.milestone_level = (
        SELECT MAX(milestone_level)
        FROM level_milestones
        WHERE milestone_level <= us.total_activities
    )
LEFT JOIN level_milestones next_milestone ON next_milestone.id = (
    SELECT MIN(id)
    FROM level_milestones
    WHERE milestone_level > us.total_activities
);

-- View to show user badge progress (unlocked and locked)
CREATE OR REPLACE VIEW user_badge_progress
with (security_invoker = on) AS
SELECT
    u.id AS user_id,
    u.username,
    b.id AS badge_id,
    b.name AS badge_name,
    b.description AS badge_description,
    b.category,
    b.icon,
    b.rarity,
    b.criteria,
    ub.unlocked_at,
    CASE WHEN ub.id IS NOT NULL THEN true ELSE false END AS is_unlocked,
    ub.progress
FROM users u
CROSS JOIN badges b
LEFT JOIN user_badges ub ON u.id = ub.user_id AND b.id = ub.badge_id;

-- ============================================================================
-- BADGE AND LEVEL FUNCTIONS
-- ============================================================================

-- Function to check and auto-award badges based on user stats
CREATE OR REPLACE FUNCTION check_and_award_badges(p_user_id UUID)
RETURNS TABLE(badge_id INTEGER, badge_name VARCHAR, newly_awarded BOOLEAN) AS $$
BEGIN
    RETURN QUERY
    WITH user_stat AS (
        SELECT * FROM user_stats WHERE user_id = p_user_id
    ),
    eligible_badges AS (
        SELECT
            b.id,
            b.name,
            b.criteria,
            CASE
                -- Total activity count badges
                WHEN b.criteria->>'type' = 'total_activities' THEN
                    (SELECT total_activities FROM user_stat) >= (b.criteria->>'count')::INTEGER

                -- Specific activity type badges
                WHEN b.criteria->>'type' = 'specific_activity' THEN
                    COALESCE(
                        (SELECT activities_by_type->(
                            SELECT name FROM activity_types WHERE id = (b.criteria->>'activity_type_id')::INTEGER
                        ) FROM user_stat)::TEXT::INTEGER,
                        0
                    ) >= (b.criteria->>'count')::INTEGER

                -- Social badges (likes received)
                WHEN b.criteria->>'type' = 'likes_received' THEN
                    (SELECT total_likes_received FROM user_stat) >= (b.criteria->>'count')::INTEGER

                -- Social badges (likes given)
                WHEN b.criteria->>'type' = 'likes_given' THEN
                    (SELECT total_likes_given FROM user_stat) >= (b.criteria->>'count')::INTEGER

                ELSE false
            END AS is_eligible
        FROM badges b
        WHERE NOT EXISTS (
            SELECT 1 FROM user_badges ub
            WHERE ub.user_id = p_user_id AND ub.badge_id = b.id
        )
    )
    -- Insert newly earned badges
    INSERT INTO user_badges (user_id, badge_id)
    SELECT p_user_id, eb.id
    FROM eligible_badges eb
    WHERE eb.is_eligible
    RETURNING
        user_badges.badge_id,
        (SELECT name FROM badges WHERE id = user_badges.badge_id),
        true AS newly_awarded;
END;
$$ LANGUAGE plpgsql;

-- Function to get user's current streak (consecutive days with activities)
CREATE OR REPLACE FUNCTION get_user_streak(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_streak INTEGER := 0;
    v_current_date DATE;
    v_check_date DATE := CURRENT_DATE;
BEGIN
    -- Check if user had activity today or yesterday (to maintain streak)
    SELECT MAX(DATE(timestamp)) INTO v_current_date
    FROM activities
    WHERE user_id = p_user_id;

    -- If no activity or last activity is more than 1 day old, streak is 0
    IF v_current_date IS NULL OR v_current_date < CURRENT_DATE - INTERVAL '1 day' THEN
        RETURN 0;
    END IF;

    -- Count consecutive days backwards
    WHILE EXISTS (
        SELECT 1 FROM activities
        WHERE user_id = p_user_id
        AND DATE(timestamp) = v_check_date
    ) LOOP
        v_streak := v_streak + 1;
        v_check_date := v_check_date - INTERVAL '1 day';
    END LOOP;

    RETURN v_streak;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SEED BADGE AND LEVEL DATA
-- ============================================================================

-- Insert level milestones (logarithmic scaling)
-- Level = total activities (1 activity = level 1, 100 activities = level 100)
-- Milestones are special markers at key progression points
INSERT INTO level_milestones (milestone_level, name, description, icon) VALUES
    (1, 'Sprout', 'Taking your first steps outdoors', 'leaf.fill'),
    (5, 'Seedling', 'Starting to grow', 'leaf.circle.fill'),
    (10, 'Grass Toucher', 'Getting comfortable outside', 'tree.fill'),
    (25, 'Enthusiast', 'A regular outdoor enthusiast', 'tree.circle.fill'),
    (50, 'Explorer', 'Exploring new paths', 'figure.hiking'),
    (75, 'Naturalist', 'Dedicated to outdoor life', 'globe.americas.fill'),
    (100, 'Trailblazer', 'Master of outdoor activities', 'mountain.2.fill'),
    (500, 'Legend', 'An inspiration to all', 'sparkles');

-- Insert achievement badges
INSERT INTO badges (name, description, category, icon, criteria, rarity, display_order) VALUES
    -- Activity count badges
    ('First Steps', 'Complete your first activity', 'activity_count', 'figure.walk',
     '{"type": "total_activities", "count": 1}', 'common', 1),

    ('Getting Started', 'Complete 5 activities', 'activity_count', 'leaf.fill',
     '{"type": "total_activities", "count": 5}', 'common', 2),

    ('Committed', 'Complete 25 activities', 'activity_count', 'flame.fill',
     '{"type": "total_activities", "count": 25}', 'rare', 3),

    ('Dedicated', 'Complete 50 activities', 'activity_count', 'star.fill',
     '{"type": "total_activities", "count": 50}', 'rare', 4),

    ('Century Club', 'Complete 100 activities', 'activity_count', 'star.circle.fill',
     '{"type": "total_activities", "count": 100}', 'epic', 5),

    ('Legendary', 'Complete 500 activities', 'activity_count', 'crown.fill',
     '{"type": "total_activities", "count": 500}', 'legendary', 6),

    -- Activity type specific badges
    ('Peak Performer', 'Complete 10 hiking activities', 'activity_type', 'mountain.2.fill',
     '{"type": "specific_activity", "activity_type_id": 1, "count": 10}', 'rare', 10),

    ('Marathon Runner', 'Complete 20 running activities', 'activity_type', 'figure.run',
     '{"type": "specific_activity", "activity_type_id": 2, "count": 20}', 'rare', 11),

    ('Cycling Enthusiast', 'Complete 15 cycling activities', 'activity_type', 'bicycle',
     '{"type": "specific_activity", "activity_type_id": 3, "count": 15}', 'rare', 12),

    -- Social badges
    ('Popular', 'Receive 10 likes on your activities', 'social', 'hand.thumbsup.fill',
     '{"type": "likes_received", "count": 10}', 'common', 20),

    ('Community Star', 'Receive 50 likes on your activities', 'social', 'star.leadinghalf.filled',
     '{"type": "likes_received", "count": 50}', 'rare', 21),

    ('Supportive', 'Give 25 likes to other activities', 'social', 'heart.fill',
     '{"type": "likes_given", "count": 25}', 'common', 22);

-- ============================================================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================================================

-- Insert sample users
INSERT INTO users (username, email) VALUES
    ('outdoor_enthusiast', 'outdoor@example.com'),
    ('trail_runner', 'runner@example.com'),
    ('nature_lover', 'nature@example.com'),
    ('adventure_seeker', 'adventure@example.com'),
    ('mountain_climber', 'climber@example.com');

-- Insert sample activities
INSERT INTO activities (
    user_id,
    activity_type_id,
    timestamp,
    notes,
    location_latitude,
    location_longitude,
    location_name
) VALUES
    (
        (SELECT id FROM users WHERE username = 'outdoor_enthusiast'),
        (SELECT id FROM activity_types WHERE name = 'Hiking'),
        CURRENT_TIMESTAMP - INTERVAL '1 hour',
        'Beautiful sunrise hike at the peak! The view was absolutely worth the early wake-up.',
        34.0,
        -118.0,
        'Mountain Trail'
    ),
    (
        (SELECT id FROM users WHERE username = 'trail_runner'),
        (SELECT id FROM activity_types WHERE name = 'Running'),
        CURRENT_TIMESTAMP - INTERVAL '2 hours',
        'Morning 5K run through the park. Feeling energized!',
        34.1,
        -118.1,
        'City Park'
    ),
    (
        (SELECT id FROM users WHERE username = 'nature_lover'),
        (SELECT id FROM activity_types WHERE name = 'Cycling'),
        CURRENT_TIMESTAMP - INTERVAL '3 hours',
        '30 mile bike ride along the coast. Perfect weather today.',
        33.9,
        -118.2,
        'Coastal Path'
    );

-- Add some sample likes
INSERT INTO activity_likes (activity_id, user_id)
SELECT
    a.id,
    u.id
FROM activities a
CROSS JOIN users u
WHERE a.notes LIKE '%sunrise%'
  AND u.username != (SELECT username FROM users WHERE id = a.user_id)
LIMIT 3;

-- ============================================================================
-- USEFUL QUERIES (Documentation)
-- ============================================================================

-- Get activity feed ordered by timestamp
-- SELECT * FROM activities_with_stats ORDER BY timestamp DESC;

-- Get activities by a specific user
-- SELECT * FROM activities_with_stats WHERE user_id = 'user-uuid-here' ORDER BY timestamp DESC;

-- Get like count for an activity
-- SELECT like_count FROM activities_with_stats WHERE id = 'activity-uuid-here';

-- Check if user liked an activity
-- SELECT has_user_liked_activity('activity-uuid-here', 'user-uuid-here');

-- Toggle a like (like or unlike)
-- SELECT toggle_activity_like('activity-uuid-here', 'user-uuid-here');

-- Get all users who liked an activity
-- SELECT u.* FROM activity_likes al
-- JOIN users u ON al.user_id = u.id
-- WHERE al.activity_id = 'activity-uuid-here';

-- Get all activities a user has liked
-- SELECT a.* FROM activity_likes al
-- JOIN activities_with_stats a ON al.activity_id = a.id
-- WHERE al.user_id = 'user-uuid-here';

-- ============================================================================
-- BADGE AND LEVEL QUERIES (Documentation)
-- ============================================================================

-- Get user's current level and milestone progress
-- Note: Level equals total activities (50 activities = level 50)
-- Milestones are named achievements at specific levels (1, 5, 10, 25, 50, 75, 100, 500)
-- SELECT * FROM user_current_levels WHERE user_id = 'user-uuid-here';

-- Get all user statistics (activities, likes, etc.)
-- SELECT * FROM user_stats WHERE user_id = 'user-uuid-here';

-- Get user's streak
-- SELECT get_user_streak('user-uuid-here');

-- Get all badges for a user (locked and unlocked)
-- SELECT * FROM user_badge_progress
-- WHERE user_id = 'user-uuid-here'
-- ORDER BY is_unlocked DESC, display_order;

-- Get only unlocked badges for a user
-- SELECT * FROM user_badge_progress
-- WHERE user_id = 'user-uuid-here' AND is_unlocked = true
-- ORDER BY unlocked_at DESC;

-- Get only locked badges for a user
-- SELECT * FROM user_badge_progress
-- WHERE user_id = 'user-uuid-here' AND is_unlocked = false
-- ORDER BY display_order;

-- Check and award any new badges user has earned
-- SELECT * FROM check_and_award_badges('user-uuid-here');

-- Get all level milestones
-- SELECT * FROM level_milestones ORDER BY milestone_level;

-- Check if user has reached a specific milestone
-- SELECT
--     us.user_id,
--     us.username,
--     us.total_activities AS current_level,
--     lm.milestone_level,
--     lm.name AS milestone_name,
--     us.total_activities >= lm.milestone_level AS has_reached_milestone
-- FROM user_stats us
-- CROSS JOIN level_milestones lm
-- WHERE us.user_id = 'user-uuid-here'
-- ORDER BY lm.milestone_level;

-- Get leaderboard by level (total activities)
-- SELECT
--     user_id,
--     username,
--     current_level,
--     total_activities,
--     milestone_name,
--     current_milestone_level
-- FROM user_current_levels
-- ORDER BY current_level DESC
-- LIMIT 10;

-- Get leaderboard by highest milestone reached
-- SELECT
--     user_id,
--     username,
--     current_level,
--     current_milestone_level,
--     milestone_name,
--     total_activities
-- FROM user_current_levels
-- ORDER BY current_milestone_level DESC NULLS LAST, current_level DESC
-- LIMIT 10;

-- Get users who recently unlocked a specific badge
-- SELECT u.username, ub.unlocked_at
-- FROM user_badges ub
-- JOIN users u ON ub.user_id = u.id
-- WHERE ub.badge_id = (SELECT id FROM badges WHERE name = 'First Steps')
-- ORDER BY ub.unlocked_at DESC
-- LIMIT 10;

-- Get users who recently reached a specific milestone
-- SELECT
--     u.username,
--     a.timestamp AS milestone_reached_at,
--     COUNT(*) OVER (PARTITION BY u.id ORDER BY a.timestamp) AS activity_count
-- FROM users u
-- JOIN activities a ON u.id = a.user_id
-- WHERE (
--     SELECT COUNT(*)
--     FROM activities a2
--     WHERE a2.user_id = u.id AND a2.timestamp <= a.timestamp
-- ) = 50  -- Replace 50 with desired milestone level
-- ORDER BY a.timestamp DESC
-- LIMIT 10;
