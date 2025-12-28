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
