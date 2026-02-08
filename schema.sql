-- Go Touch Grass Database Schema
-- PostgreSQL Database Setup
-- Used in a Supabase Project
-- In Supabase, ensure RLS is enabled for created tables.

-- SUPABASE STORAGE SETUP:
-- 1. Create a storage bucket named "avatars" in Supabase Dashboard
-- 2. Set bucket to public or configure RLS policies as needed
-- 3. Recommended path structure: avatars/<user-id>/profile.jpg
-- 4. File upload size limit: 2MB recommended for profile pictures
-- 5. Allowed MIME types: image/jpeg, image/png, image/webp

-- To setup locally instead, you can run:
-- psql -U your_username -d go_touch_grass -f schema.sql

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop tables if they exist (for clean setup)
DROP TABLE IF EXISTS user_badges CASCADE;
DROP TABLE IF EXISTS level_milestones CASCADE;
DROP TABLE IF EXISTS badges CASCADE;
DROP TABLE IF EXISTS activity_likes CASCADE;
DROP TABLE IF EXISTS activities CASCADE;
DROP TABLE IF EXISTS activity_subtypes CASCADE;
DROP TABLE IF EXISTS activity_types CASCADE;
DROP TABLE IF EXISTS user_follows CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ============================================================================
-- USERS TABLE
-- ============================================================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,

    -- Profile picture stored as URL to Supabase Storage
    -- Best practice: Store images in Supabase Storage bucket, reference by URL
    -- Path format: <bucket-name>/avatars/<user-id>/<filename>
    -- Example: avatars/550e8400-e29b-41d4-a716-446655440000/profile.jpg
    profile_picture_url TEXT,

    -- Privacy settings
    is_private BOOLEAN DEFAULT false,

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
-- USER FOLLOWS TABLE (Following/Follower Relationships)
-- ============================================================================
-- This junction table tracks who follows whom
-- follower_id follows following_id
-- Example: If Alice follows Bob, then follower_id = Alice's ID, following_id = Bob's ID
CREATE TABLE user_follows (
    id SERIAL PRIMARY KEY,
    follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Prevent self-following
    CONSTRAINT no_self_follow CHECK (follower_id != following_id),

    -- Ensure one follow relationship per pair
    CONSTRAINT unique_follow UNIQUE(follower_id, following_id)
);

-- Indexes for efficient follow queries
CREATE INDEX idx_user_follows_follower_id ON user_follows(follower_id);
CREATE INDEX idx_user_follows_following_id ON user_follows(following_id);
CREATE INDEX idx_user_follows_created_at ON user_follows(created_at DESC);

-- ============================================================================
-- FOLLOW REQUESTS TABLE (For Private Accounts)
-- ============================================================================
-- This table tracks pending follow requests for private accounts
-- When a user tries to follow a private account, a request is created here
-- The request can be accepted (creates user_follows entry) or rejected (deleted)
CREATE TABLE follow_requests (
    id SERIAL PRIMARY KEY,
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    requested_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Prevent self-following requests
    CONSTRAINT no_self_follow_request CHECK (requester_id != requested_id),

    -- Ensure one request per pair
    CONSTRAINT unique_follow_request UNIQUE(requester_id, requested_id)
);

-- Indexes for efficient request queries
CREATE INDEX idx_follow_requests_requester_id ON follow_requests(requester_id);
CREATE INDEX idx_follow_requests_requested_id ON follow_requests(requested_id);
CREATE INDEX idx_follow_requests_status ON follow_requests(status);
CREATE INDEX idx_follow_requests_created_at ON follow_requests(created_at DESC);

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
    ('Kayaking', 'oar.2.crossed'),
    ('Camping', 'tent.fill'),
    ('Skiing', 'snowflake'),
    ('Surfing', 'water.waves'),
    ('Walking', 'figure.walk'),
    ('Other', 'figure.outdoor.cycle');

INSERT INTO activity_types (name, icon) VALUES
    ('Coffee', 'cup.and.saucer.fill');

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

-- Drop existing views first to avoid conflicts
DROP VIEW IF EXISTS user_badge_progress CASCADE;
DROP VIEW IF EXISTS user_current_levels CASCADE;
DROP VIEW IF EXISTS user_stats CASCADE;
DROP VIEW IF EXISTS activities_with_stats CASCADE;

-- View to get activity feed with like counts and user profile info
CREATE VIEW activities_with_stats
with (security_invoker = on) AS
SELECT
    a.id,
    a.user_id,
    u.username,
    u.email,
    u.profile_picture_url,
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
    a.id, u.id, u.username, u.email, u.profile_picture_url,
    at.id, at.name, at.icon,
    ast.id, ast.name,
    a.notes, a.timestamp, a.location_latitude,
    a.location_longitude, a.location_name,
    a.created_at, a.updated_at;

-- ============================================================================
-- USER FOLLOW FUNCTIONS
-- ============================================================================

-- Drop existing functions first
DROP FUNCTION IF EXISTS toggle_user_follow(UUID, UUID);
DROP FUNCTION IF EXISTS is_following(UUID, UUID);
DROP FUNCTION IF EXISTS get_follower_count(UUID);
DROP FUNCTION IF EXISTS get_following_count(UUID);

-- Function to toggle follow (follow if not following, unfollow if following)
-- NOTE: This function is deprecated for private accounts. Use send_follow_request instead.
-- This function will only work for public accounts or if you're already following.
CREATE OR REPLACE FUNCTION toggle_user_follow(
    p_follower_id UUID,
    p_following_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_exists BOOLEAN;
    v_is_private BOOLEAN;
BEGIN
    -- Prevent self-follow
    IF p_follower_id = p_following_id THEN
        RAISE EXCEPTION 'Users cannot follow themselves';
    END IF;

    -- Check if follow exists
    SELECT EXISTS(
        SELECT 1 FROM user_follows
        WHERE follower_id = p_follower_id AND following_id = p_following_id
    ) INTO v_exists;

    IF v_exists THEN
        -- Unfollow: Remove the follow
        DELETE FROM user_follows
        WHERE follower_id = p_follower_id AND following_id = p_following_id;

        -- Also remove any accepted follow requests
        DELETE FROM follow_requests
        WHERE requester_id = p_follower_id AND requested_id = p_following_id;

        RETURN FALSE; -- Indicates unfollowed
    ELSE
        -- Check if the target account is private
        SELECT is_private INTO v_is_private
        FROM users
        WHERE id = p_following_id;

        IF v_is_private THEN
            RAISE EXCEPTION 'Cannot follow private account directly. Use send_follow_request instead.';
        ELSE
            -- Follow: Add the follow
            INSERT INTO user_follows (follower_id, following_id)
            VALUES (p_follower_id, p_following_id);
            RETURN TRUE; -- Indicates followed
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to check if user A is following user B
CREATE OR REPLACE FUNCTION is_following(
    p_follower_id UUID,
    p_following_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM user_follows
        WHERE follower_id = p_follower_id AND following_id = p_following_id
    );
END;
$$ LANGUAGE plpgsql;

-- Function to get follower count for a user
CREATE OR REPLACE FUNCTION get_follower_count(p_user_id UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM user_follows
        WHERE following_id = p_user_id
    )::INTEGER;
END;
$$ LANGUAGE plpgsql;

-- Function to get following count for a user
CREATE OR REPLACE FUNCTION get_following_count(p_user_id UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM user_follows
        WHERE follower_id = p_user_id
    )::INTEGER;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FOLLOW REQUEST FUNCTIONS
-- ============================================================================

-- Drop existing functions first
DROP FUNCTION IF EXISTS send_follow_request(UUID, UUID);
DROP FUNCTION IF EXISTS accept_follow_request(UUID, UUID);
DROP FUNCTION IF EXISTS reject_follow_request(UUID, UUID);
DROP FUNCTION IF EXISTS cancel_follow_request(UUID, UUID);
DROP FUNCTION IF EXISTS get_pending_follow_requests(UUID);
DROP FUNCTION IF EXISTS get_sent_follow_requests(UUID);
DROP FUNCTION IF EXISTS has_pending_follow_request(UUID, UUID);

-- Function to send a follow request (or directly follow if account is public)
CREATE OR REPLACE FUNCTION send_follow_request(
    p_requester_id UUID,
    p_requested_id UUID
)
RETURNS TABLE(success BOOLEAN, is_direct_follow BOOLEAN, message TEXT) AS $$
DECLARE
    v_is_private BOOLEAN;
    v_already_following BOOLEAN;
    v_pending_request BOOLEAN;
BEGIN
    -- Prevent self-follow
    IF p_requester_id = p_requested_id THEN
        RETURN QUERY SELECT false, false, 'Cannot follow yourself'::TEXT;
        RETURN;
    END IF;

    -- Check if already following
    SELECT EXISTS(
        SELECT 1 FROM user_follows
        WHERE follower_id = p_requester_id AND following_id = p_requested_id
    ) INTO v_already_following;

    IF v_already_following THEN
        RETURN QUERY SELECT false, false, 'Already following this user'::TEXT;
        RETURN;
    END IF;

    -- Check if there's already a pending request
    SELECT EXISTS(
        SELECT 1 FROM follow_requests
        WHERE requester_id = p_requester_id AND requested_id = p_requested_id AND status = 'pending'
    ) INTO v_pending_request;

    IF v_pending_request THEN
        RETURN QUERY SELECT false, false, 'Follow request already sent'::TEXT;
        RETURN;
    END IF;

    -- Check if the target account is private
    SELECT is_private INTO v_is_private
    FROM users
    WHERE id = p_requested_id;

    IF v_is_private THEN
        -- Create a follow request
        INSERT INTO follow_requests (requester_id, requested_id, status)
        VALUES (p_requester_id, p_requested_id, 'pending')
        ON CONFLICT (requester_id, requested_id) DO UPDATE SET status = 'pending', updated_at = CURRENT_TIMESTAMP;

        RETURN QUERY SELECT true, false, 'Follow request sent'::TEXT;
    ELSE
        -- Directly create the follow relationship
        INSERT INTO user_follows (follower_id, following_id)
        VALUES (p_requester_id, p_requested_id);

        RETURN QUERY SELECT true, true, 'Now following'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to accept a follow request
CREATE OR REPLACE FUNCTION accept_follow_request(
    p_requester_id UUID,
    p_requested_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_request_exists BOOLEAN;
BEGIN
    -- Check if there's a pending request
    SELECT EXISTS(
        SELECT 1 FROM follow_requests
        WHERE requester_id = p_requester_id AND requested_id = p_requested_id AND status = 'pending'
    ) INTO v_request_exists;

    IF NOT v_request_exists THEN
        RAISE EXCEPTION 'No pending follow request found';
    END IF;

    -- Create the follow relationship
    INSERT INTO user_follows (follower_id, following_id)
    VALUES (p_requester_id, p_requested_id)
    ON CONFLICT DO NOTHING;

    -- Update the request status to accepted
    UPDATE follow_requests
    SET status = 'accepted', updated_at = CURRENT_TIMESTAMP
    WHERE requester_id = p_requester_id AND requested_id = p_requested_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to reject a follow request
CREATE OR REPLACE FUNCTION reject_follow_request(
    p_requester_id UUID,
    p_requested_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Update the request status to rejected (or delete it)
    DELETE FROM follow_requests
    WHERE requester_id = p_requester_id AND requested_id = p_requested_id AND status = 'pending';

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to cancel a follow request (by the requester)
CREATE OR REPLACE FUNCTION cancel_follow_request(
    p_requester_id UUID,
    p_requested_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    DELETE FROM follow_requests
    WHERE requester_id = p_requester_id AND requested_id = p_requested_id AND status = 'pending';

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to get pending follow requests for a user (requests received)
CREATE OR REPLACE FUNCTION get_pending_follow_requests(p_user_id UUID)
RETURNS TABLE(
    request_id INTEGER,
    requester_id UUID,
    requester_username VARCHAR,
    requester_profile_picture_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        fr.id,
        fr.requester_id,
        u.username,
        u.profile_picture_url,
        fr.created_at
    FROM follow_requests fr
    JOIN users u ON fr.requester_id = u.id
    WHERE fr.requested_id = p_user_id AND fr.status = 'pending'
    ORDER BY fr.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get sent follow requests (requests sent by user)
CREATE OR REPLACE FUNCTION get_sent_follow_requests(p_user_id UUID)
RETURNS TABLE(
    request_id INTEGER,
    requested_id UUID,
    requested_username VARCHAR,
    requested_profile_picture_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        fr.id,
        fr.requested_id,
        u.username,
        u.profile_picture_url,
        fr.created_at
    FROM follow_requests fr
    JOIN users u ON fr.requested_id = u.id
    WHERE fr.requester_id = p_user_id AND fr.status = 'pending'
    ORDER BY fr.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to check if there's a pending follow request
CREATE OR REPLACE FUNCTION has_pending_follow_request(
    p_requester_id UUID,
    p_requested_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM follow_requests
        WHERE requester_id = p_requester_id AND requested_id = p_requested_id AND status = 'pending'
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Drop existing functions and triggers
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS toggle_activity_like(UUID, UUID);
DROP FUNCTION IF EXISTS has_user_liked_activity(UUID, UUID);

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

DROP TABLE IF EXISTS user_badges;
DROP TABLE IF EXISTS badges;
DROP TYPE IF EXISTS badge_category;

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

-- Drop existing views first to avoid column order conflicts
DROP VIEW IF EXISTS user_stats CASCADE;
DROP VIEW IF EXISTS user_current_levels CASCADE;
DROP VIEW IF EXISTS user_badge_progress CASCADE;

-- View to calculate user statistics for badge/level calculations
CREATE VIEW user_stats
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
    COUNT(DISTINCT followers.id) AS follower_count,
    COUNT(DISTINCT following.id) AS following_count,

    -- Dates for streak calculation
    MAX(a.timestamp) AS last_activity_date,
    MIN(a.timestamp) AS first_activity_date,

    -- Badge progress
    COUNT(DISTINCT ub.badge_id) AS badges_unlocked
FROM users u
    LEFT JOIN activities a ON u.id = a.user_id
    LEFT JOIN activity_likes al_received ON a.id = al_received.activity_id
    LEFT JOIN activity_likes al_given ON u.id = al_given.user_id
    LEFT JOIN user_follows followers ON u.id = followers.following_id
    LEFT JOIN user_follows following ON u.id = following.follower_id
    LEFT JOIN user_badges ub ON u.id = ub.user_id
GROUP BY u.id, u.username, u.created_at;

-- View to calculate user current level and milestones
CREATE VIEW user_current_levels
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
CREATE VIEW user_badge_progress
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
-- SECURITY DEFINER allows this function to bypass RLS and insert badges
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

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

-- Add some sample follow relationships
-- outdoor_enthusiast follows trail_runner and nature_lover
INSERT INTO user_follows (follower_id, following_id) VALUES
    (
        (SELECT id FROM users WHERE username = 'outdoor_enthusiast'),
        (SELECT id FROM users WHERE username = 'trail_runner')
    ),
    (
        (SELECT id FROM users WHERE username = 'outdoor_enthusiast'),
        (SELECT id FROM users WHERE username = 'nature_lover')
    ),
    (
        (SELECT id FROM users WHERE username = 'trail_runner'),
        (SELECT id FROM users WHERE username = 'outdoor_enthusiast')
    ),
    (
        (SELECT id FROM users WHERE username = 'nature_lover'),
        (SELECT id FROM users WHERE username = 'adventure_seeker')
    ),
    (
        (SELECT id FROM users WHERE username = 'mountain_climber'),
        (SELECT id FROM users WHERE username = 'outdoor_enthusiast')
    );

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE follow_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_subtypes ENABLE ROW LEVEL SECURITY;
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE level_milestones ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- USERS TABLE POLICIES
-- ----------------------------------------------------------------------------

-- Anyone can view user profiles (for search and discovery)
CREATE POLICY "Anyone can view user profiles"
ON users
FOR SELECT
USING (true);

-- Users can insert their own profile during signup
-- Drop existing policy if it exists to recreate with proper casting
DROP POLICY IF EXISTS "Users can create their own profile" ON users;

CREATE POLICY "Users can create their own profile"
ON users
FOR INSERT
WITH CHECK (auth.uid()::uuid = id::uuid);

-- Users can update their own profile
-- Drop existing policy if it exists to recreate with proper casting
DROP POLICY IF EXISTS "Users can update their own profile" ON users;

CREATE POLICY "Users can update their own profile"
ON users
FOR UPDATE
USING (auth.uid()::uuid = id::uuid)
WITH CHECK (auth.uid()::uuid = id::uuid);

-- Users cannot delete their profile (handle through auth.users deletion)
-- No DELETE policy = no one can delete

-- ----------------------------------------------------------------------------
-- USER_FOLLOWS TABLE POLICIES
-- ----------------------------------------------------------------------------

-- Anyone can view follow relationships (for follower/following lists)
CREATE POLICY "Anyone can view follow relationships"
ON user_follows
FOR SELECT
USING (true);

-- Users can only create follows where they are the follower
CREATE POLICY "Users can follow others"
ON user_follows
FOR INSERT
WITH CHECK (follower_id = auth.uid());

-- Users can only delete follows where they are the follower (unfollow)
CREATE POLICY "Users can unfollow others"
ON user_follows
FOR DELETE
USING (follower_id = auth.uid());

-- No UPDATE policy = follows cannot be modified, only created or deleted

-- ----------------------------------------------------------------------------
-- FOLLOW_REQUESTS TABLE POLICIES
-- ----------------------------------------------------------------------------

-- Users can view requests they sent or received
CREATE POLICY "Users can view their follow requests"
ON follow_requests
FOR SELECT
USING (requester_id = auth.uid() OR requested_id = auth.uid());

-- Users can create follow requests where they are the requester
CREATE POLICY "Users can send follow requests"
ON follow_requests
FOR INSERT
WITH CHECK (requester_id = auth.uid());

-- Users can update requests they received (to accept/reject)
CREATE POLICY "Users can update received follow requests"
ON follow_requests
FOR UPDATE
USING (requested_id = auth.uid())
WITH CHECK (requested_id = auth.uid());

-- Users can delete requests they sent or received
CREATE POLICY "Users can delete follow requests"
ON follow_requests
FOR DELETE
USING (requester_id = auth.uid() OR requested_id = auth.uid());

-- ----------------------------------------------------------------------------
-- ACTIVITIES TABLE POLICIES
-- ----------------------------------------------------------------------------

-- Drop the old "Anyone can view activities" policy
DROP POLICY IF EXISTS "Anyone can view activities" ON activities;

-- Users can view activities based on privacy settings:
-- 1. Own activities (always visible)
-- 2. Activities from public accounts (not private)
-- 3. Activities from private accounts if you're following them
CREATE POLICY "Users can view activities based on privacy"
ON activities
FOR SELECT
USING (
    -- Own activities are always visible
    user_id = auth.uid()
    OR
    -- Activities from public accounts are visible to everyone
    EXISTS (
        SELECT 1 FROM users u
        WHERE u.id = activities.user_id
        AND (u.is_private = false OR u.is_private IS NULL)
    )
    OR
    -- Activities from private accounts are only visible to followers
    EXISTS (
        SELECT 1 FROM users u
        WHERE u.id = activities.user_id
        AND u.is_private = true
        AND EXISTS (
            SELECT 1 FROM user_follows uf
            WHERE uf.follower_id = auth.uid()
            AND uf.following_id = activities.user_id
        )
    )
);

-- Users can only create activities for themselves
CREATE POLICY "Users can create their own activities"
ON activities
FOR INSERT
WITH CHECK (user_id = auth.uid());

-- Users can only update their own activities
CREATE POLICY "Users can update their own activities"
ON activities
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Users can only delete their own activities
CREATE POLICY "Users can delete their own activities"
ON activities
FOR DELETE
USING (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- ACTIVITY_LIKES TABLE POLICIES
-- ----------------------------------------------------------------------------

-- Anyone can view likes (for like counts)
CREATE POLICY "Anyone can view activity likes"
ON activity_likes
FOR SELECT
USING (true);

-- Users can only create likes for themselves
CREATE POLICY "Users can like activities"
ON activity_likes
FOR INSERT
WITH CHECK (user_id = auth.uid());

-- Users can only delete their own likes (unlike)
CREATE POLICY "Users can unlike activities"
ON activity_likes
FOR DELETE
USING (user_id = auth.uid());

-- No UPDATE policy = likes cannot be modified

-- ----------------------------------------------------------------------------
-- ACTIVITY_TYPES TABLE POLICIES
-- ----------------------------------------------------------------------------

-- Anyone can view activity types (needed for creating activities)
CREATE POLICY "Anyone can view activity types"
ON activity_types
FOR SELECT
USING (true);

-- Only service role can modify activity types (admin only)
-- No INSERT, UPDATE, or DELETE policies = only service role can modify

-- ----------------------------------------------------------------------------
-- ACTIVITY_SUBTYPES TABLE POLICIES
-- ----------------------------------------------------------------------------

-- Anyone can view activity subtypes
CREATE POLICY "Anyone can view activity subtypes"
ON activity_subtypes
FOR SELECT
USING (true);

-- Only service role can modify activity subtypes (admin only)
-- No INSERT, UPDATE, or DELETE policies = only service role can modify

-- ----------------------------------------------------------------------------
-- BADGES TABLE POLICIES
-- ----------------------------------------------------------------------------

-- Anyone can view badges (needed for badge system)
CREATE POLICY "Anyone can view badges"
ON badges
FOR SELECT
USING (true);

-- Only service role can modify badges (admin only)
-- No INSERT, UPDATE, or DELETE policies = only service role can modify

-- ----------------------------------------------------------------------------
-- USER_BADGES TABLE POLICIES
-- ----------------------------------------------------------------------------

-- Anyone can view user badges (for profiles and achievements)
CREATE POLICY "Anyone can view user badges"
ON user_badges
FOR SELECT
USING (true);

-- Only the badge award function can create user badges
-- This is handled through the check_and_award_badges function
-- which runs with elevated privileges
-- No INSERT policy for users = only server functions can award badges

-- Users cannot delete or update their badges
-- No UPDATE or DELETE policies = badges are permanent once earned

-- ----------------------------------------------------------------------------
-- LEVEL_MILESTONES TABLE POLICIES
-- ----------------------------------------------------------------------------

-- Anyone can view level milestones (needed for level system)
CREATE POLICY "Anyone can view level milestones"
ON level_milestones
FOR SELECT
USING (true);

-- ----------------------------------------------------------------------------
-- STORAGE POLICIES FOR AVATARS BUCKET
-- ----------------------------------------------------------------------------

-- Create the avatars bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view avatars" ON storage.objects;

-- Allow authenticated users to upload their own avatar
CREATE POLICY "Users can upload their own avatar"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to update their own avatar
CREATE POLICY "Users can update their own avatar"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to delete their own avatar
CREATE POLICY "Users can delete their own avatar"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow anyone to view avatars (public bucket)
CREATE POLICY "Anyone can view avatars"
ON storage.objects
FOR SELECT
USING (bucket_id = 'avatars');

-- ============================================================================
-- USER PROFILE PICTURE UPDATE FUNCTION
-- ============================================================================

-- Function to update user profile picture URL
-- This function runs with SECURITY DEFINER to bypass RLS
DROP FUNCTION IF EXISTS update_user_profile_picture(UUID, TEXT);

CREATE OR REPLACE FUNCTION update_user_profile_picture(
    p_user_id UUID,
    p_picture_url TEXT
)
RETURNS TABLE(id UUID, profile_picture_url TEXT) AS $$
BEGIN
    -- Security check: only allow users to update their own profile picture
    IF p_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Unauthorized: Cannot update another user''s profile picture';
    END IF;

    -- Update and return the result
    RETURN QUERY
    UPDATE users
    SET profile_picture_url = p_picture_url,
        updated_at = CURRENT_TIMESTAMP
    WHERE users.id = p_user_id
    RETURNING users.id, users.profile_picture_url;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Only service role can modify level milestones (admin only)
-- No INSERT, UPDATE, or DELETE policies = only service role can modify

-- ============================================================================
-- EVENTS
-- ============================================================================
CREATE TYPE event_source AS ENUM (
    'ticketmaster',
    'manual'
);

CREATE TABLE events (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source event_source NOT NULL,
    source_id VARCHAR(255), -- External ID from source API
    content_hash VARCHAR(64) UNIQUE NOT NULL, -- SHA-256 for deduplication

    -- Event details
    name VARCHAR(500) NOT NULL,
    description TEXT,
    event_url TEXT,

    -- Date/Time
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE,
    timezone VARCHAR(100),

    -- Location
    venue_name VARCHAR(255),
    venue_address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),

    -- Categorization (maps to activity_types)
    activity_type_id INTEGER REFERENCES activity_types(id) ON DELETE SET NULL,
    source_category VARCHAR(100), -- Original category from source
    source_tags TEXT[], -- Array of tags from source

    -- Pricing
    price_min DECIMAL(10, 2),
    price_max DECIMAL(10, 2),
    currency VARCHAR(10) DEFAULT 'USD',
    is_free BOOLEAN DEFAULT false,

    -- Media
    image_url TEXT,
    thumbnail_url TEXT,

    -- Metadata
    retrieved_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    search_location_lat DECIMAL(10, 8),
    search_location_long DECIMAL(11, 8),
    search_radius_miles INTEGER,

    -- Relevance scoring (calculated)
    relevance_score DECIMAL(5, 2) DEFAULT 50.0, -- 0-100 based on user preferences

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT valid_event_coordinates CHECK (
        (latitude IS NULL AND longitude IS NULL) OR
        (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)
    ),
    CONSTRAINT valid_search_coords CHECK (
        (search_location_lat IS NULL AND search_location_long IS NULL) OR
        (search_location_lat BETWEEN -90 AND 90 AND search_location_long BETWEEN -180 AND 180)
    ),
    CONSTRAINT valid_relevance_score CHECK (relevance_score BETWEEN 0 AND 100)
);

-- Indexes
CREATE INDEX idx_events_source ON events(source);
CREATE INDEX idx_events_activity_type ON events(activity_type_id);
CREATE INDEX idx_events_start_date ON events(start_date);
CREATE INDEX idx_events_location ON events(latitude, longitude) WHERE latitude IS NOT NULL;
CREATE INDEX idx_events_content_hash ON events(content_hash);
CREATE INDEX idx_events_is_free ON events(is_free);
CREATE INDEX idx_events_relevance_score ON events(relevance_score DESC);
CREATE INDEX idx_events_city ON events(city);
CREATE INDEX idx_events_retrieved_at ON events(retrieved_at DESC);

CREATE TABLE event_category_mappings (
    id SERIAL PRIMARY KEY,
    source event_source NOT NULL,
    source_category VARCHAR(255) NOT NULL,
    source_tag VARCHAR(255),
    activity_type_id INTEGER REFERENCES activity_types(id) ON DELETE CASCADE,
    confidence DECIMAL(3, 2) DEFAULT 1.0 CHECK (confidence BETWEEN 0 AND 1)
);

-- Create unique index with COALESCE for nullable source_tag
CREATE UNIQUE INDEX idx_event_category_mappings_unique
ON event_category_mappings(source, source_category, COALESCE(source_tag, ''));

CREATE INDEX idx_event_category_mappings_source ON event_category_mappings(source);
CREATE INDEX idx_event_category_mappings_activity_type ON event_category_mappings(activity_type_id);

-- Seed initial mappings for Ticketmaster categories
INSERT INTO event_category_mappings (source, source_category, activity_type_id, confidence) VALUES
    -- Ticketmaster mappings
    ('ticketmaster', 'Sports', (SELECT id FROM activity_types WHERE name = 'Running'), 0.5),
    ('ticketmaster', 'Music', (SELECT id FROM activity_types WHERE name = 'Other'), 0.3),
    ('ticketmaster', 'Arts & Theatre', (SELECT id FROM activity_types WHERE name = 'Other'), 0.2),
    ('ticketmaster', 'Family', (SELECT id FROM activity_types WHERE name = 'Walking'), 0.4);

-- Create new attendance table with UUID references
CREATE TABLE user_event_attendance (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,

    -- Attendance details
    attended_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Ensure user can only mark attendance once per event
    CONSTRAINT unique_user_event_attendance UNIQUE(user_id, event_id)
);

CREATE INDEX idx_user_event_attendance_user_id ON user_event_attendance(user_id);
CREATE INDEX idx_user_event_attendance_event_id ON user_event_attendance(event_id);
CREATE INDEX idx_user_event_attendance_attended_at ON user_event_attendance(attended_at DESC);

create table event_api_calls (
  id serial not null,
  user_id uuid not null,
  search_latitude numeric(10, 8) null,
  search_longitude numeric(11, 8) null,
  search_location_name character varying(255) null,
  search_radius_miles integer null default 50,
  called_at timestamp with time zone null default CURRENT_TIMESTAMP,
  events_retrieved integer null default 0,
  success boolean null default true,
  error_message text null,
  source public.event_source null default 'ticketmaster'::event_source,
  constraint user_event_api_calls_pkey primary key (id),
  constraint user_event_api_calls_user_id_fkey foreign KEY (user_id) references users (id) on delete CASCADE,
  constraint valid_search_coords check (
    (
      (
        (search_latitude is null)
        and (search_longitude is null)
      )
      or (
        (
          (search_latitude >= ('-90'::integer)::numeric)
          and (search_latitude <= (90)::numeric)
        )
        and (
          (search_longitude >= ('-180'::integer)::numeric)
          and (search_longitude <= (180)::numeric)
        )
      )
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_user_event_api_calls_user_id on public.event_api_calls using btree (user_id) TABLESPACE pg_default;
create index IF not exists idx_user_event_api_calls_called_at on public.event_api_calls using btree (called_at desc) TABLESPACE pg_default;

CREATE OR REPLACE FUNCTION upsert_event(
    p_content_hash VARCHAR(64),
    p_source event_source,
    p_source_id VARCHAR(255),
    p_name VARCHAR(500),
    p_description TEXT,
    p_event_url TEXT,
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE,
    p_timezone VARCHAR(100),
    p_venue_name VARCHAR(255),
    p_venue_address TEXT,
    p_city VARCHAR(100),
    p_state VARCHAR(100),
    p_country VARCHAR(100),
    p_postal_code VARCHAR(20),
    p_latitude DECIMAL(10, 8),
    p_longitude DECIMAL(11, 8),
    p_source_category VARCHAR(100),
    p_source_tags TEXT[],
    p_price_min DECIMAL(10, 2),
    p_price_max DECIMAL(10, 2),
    p_currency VARCHAR(10),
    p_is_free BOOLEAN,
    p_image_url TEXT,
    p_thumbnail_url TEXT,
    p_search_location_lat DECIMAL(10, 8),
    p_search_location_long DECIMAL(11, 8),
    p_search_radius_miles INTEGER
) RETURNS UUID AS $$
DECLARE
    v_event_id UUID;
BEGIN
    -- Try to find existing event by hash
    SELECT id INTO v_event_id
    FROM events
    WHERE content_hash = p_content_hash;

    IF v_event_id IS NOT NULL THEN
        -- Event exists - update retrieved_at and merge data
        UPDATE events
        SET
            retrieved_at = CURRENT_TIMESTAMP,
            updated_at = CURRENT_TIMESTAMP,
            -- Update image if new one is better (has value and old doesn't)
            image_url = COALESCE(events.image_url, p_image_url),
            thumbnail_url = COALESCE(events.thumbnail_url, p_thumbnail_url),
            -- Update description if new one is longer/better
            description = CASE
                WHEN LENGTH(COALESCE(p_description, '')) > LENGTH(COALESCE(events.description, ''))
                THEN p_description
                ELSE events.description
            END,
            -- Update other potentially missing fields
            event_url = COALESCE(events.event_url, p_event_url),
            venue_address = COALESCE(events.venue_address, p_venue_address),
            postal_code = COALESCE(events.postal_code, p_postal_code)
        WHERE id = v_event_id;
    ELSE
        -- New event - insert
        INSERT INTO events (
            content_hash,
            source,
            source_id,
            name,
            description,
            event_url,
            start_date,
            end_date,
            timezone,
            venue_name,
            venue_address,
            city,
            state,
            country,
            postal_code,
            latitude,
            longitude,
            source_category,
            source_tags,
            price_min,
            price_max,
            currency,
            is_free,
            image_url,
            thumbnail_url,
            search_location_lat,
            search_location_long,
            search_radius_miles
        ) VALUES (
            p_content_hash,
            p_source,
            p_source_id,
            p_name,
            p_description,
            p_event_url,
            p_start_date,
            p_end_date,
            p_timezone,
            p_venue_name,
            p_venue_address,
            p_city,
            p_state,
            p_country,
            p_postal_code,
            p_latitude,
            p_longitude,
            p_source_category,
            p_source_tags,
            p_price_min,
            p_price_max,
            p_currency,
            p_is_free,
            p_image_url,
            p_thumbnail_url,
            p_search_location_lat,
            p_search_location_long,
            p_search_radius_miles
        )
        RETURNING id INTO v_event_id;

        -- Auto-classify activity type for new event
        PERFORM classify_event_activity_type(v_event_id);
    END IF;

    RETURN v_event_id;
END;
$$ LANGUAGE plpgsql;

-- Function to classify event's activity type
CREATE OR REPLACE FUNCTION classify_event_activity_type(p_event_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_activity_type_id INTEGER;
    v_event_source event_source;
    v_source_category VARCHAR(255);
    v_source_tags TEXT[];
BEGIN
    -- Get event details
    SELECT source, source_category, source_tags
    INTO v_event_source, v_source_category, v_source_tags
    FROM events
    WHERE id = p_event_id;

    -- Try to find mapping by source category
    SELECT activity_type_id INTO v_activity_type_id
    FROM event_category_mappings
    WHERE source = v_event_source
      AND LOWER(source_category) = LOWER(v_source_category)
      AND source_tag IS NULL
    ORDER BY confidence DESC
    LIMIT 1;

    -- If not found, try by tags
    IF v_activity_type_id IS NULL AND v_source_tags IS NOT NULL THEN
        SELECT activity_type_id INTO v_activity_type_id
        FROM event_category_mappings
        WHERE source = v_event_source
          AND source_tag = ANY(v_source_tags)
        ORDER BY confidence DESC
        LIMIT 1;
    END IF;

    -- Default to 'Other' if no mapping found
    v_activity_type_id := COALESCE(
        v_activity_type_id,
        (SELECT id FROM activity_types WHERE name = 'Other')
    );

    -- Update event with classified activity type
    UPDATE events
    SET activity_type_id = v_activity_type_id
    WHERE id = p_event_id;

    RETURN v_activity_type_id;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate event relevance for a user
CREATE OR REPLACE FUNCTION calculate_event_relevance(
    p_user_id UUID,
    p_event_id UUID
) RETURNS DECIMAL(5,2) AS $$
DECLARE
    v_score DECIMAL(5,2) := 50.0; -- Base score
    v_user_activity_types JSONB;
    v_event_activity_type INTEGER;
    v_activity_type_name VARCHAR(50);
    v_user_activity_count INTEGER;
    v_is_free BOOLEAN;
BEGIN
    -- Get user's activity type preferences
    SELECT activities_by_type INTO v_user_activity_types
    FROM user_stats
    WHERE user_id = p_user_id;

    -- Get event's activity type and free status
    SELECT activity_type_id, is_free INTO v_event_activity_type, v_is_free
    FROM events
    WHERE id = p_event_id;

    -- If user has activity history and event has activity type
    IF v_user_activity_types IS NOT NULL AND v_event_activity_type IS NOT NULL THEN
        -- Get activity type name
        SELECT name INTO v_activity_type_name
        FROM activity_types
        WHERE id = v_event_activity_type;

        -- Get user's count for this activity type
        v_user_activity_count := COALESCE(
            (v_user_activity_types->>v_activity_type_name)::INTEGER,
            0
        );

        -- Boost score based on user's experience (up to +30 points)
        -- More activities of this type = higher relevance
        v_score := v_score + LEAST(30, v_user_activity_count * 2);
    END IF;

    -- Boost for free events (+10 points)
    IF v_is_free THEN
        v_score := v_score + 10;
    END IF;

    -- TODO: Add location-based scoring (proximity boost)
    -- TODO: Add time-based scoring (events happening soon)

    -- Cap at 100
    v_score := LEAST(v_score, 100);

    -- Update the event's relevance score
    UPDATE events
    SET relevance_score = v_score
    WHERE id = p_event_id;

    RETURN v_score;
END;
$$ LANGUAGE plpgsql;

-- Function to clean up old events
CREATE OR REPLACE FUNCTION cleanup_old_events()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    -- Delete events that:
    -- 1. Started more than 7 days ago
    -- 2. Have no attendance records (keep attended events for history)
    DELETE FROM events
    WHERE start_date < (CURRENT_TIMESTAMP - INTERVAL '7 days')
      AND id NOT IN (
          SELECT DISTINCT event_id
          FROM user_event_attendance
      );

    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Drop old ticketmaster-specific functions
DROP FUNCTION IF EXISTS can_user_call_event_api(UUID);
DROP FUNCTION IF EXISTS record_event_api_call(UUID, DECIMAL, DECIMAL, VARCHAR, INTEGER, INTEGER, BOOLEAN, TEXT);

-- Function to check if user can call API (per source)
CREATE OR REPLACE FUNCTION can_user_call_event_api(
    p_user_id UUID,
    p_source event_source
) RETURNS BOOLEAN AS $$
DECLARE
    v_last_call TIMESTAMP WITH TIME ZONE;
    v_interval INTERVAL;
BEGIN
    -- Different rate limits per source
    v_interval := CASE p_source
        WHEN 'eventbrite' THEN INTERVAL '24 hours'
        WHEN 'ticketmaster' THEN INTERVAL '24 hours'
        WHEN 'rss_feed' THEN INTERVAL '6 hours'
        ELSE INTERVAL '24 hours'
    END;

    -- Get the most recent API call for this user and source
    SELECT called_at INTO v_last_call
    FROM event_api_calls
    WHERE user_id = p_user_id AND source = p_source
    ORDER BY called_at DESC
    LIMIT 1;

    -- If no previous call, allow
    IF v_last_call IS NULL THEN
        RETURN TRUE;
    END IF;

    -- Check if last call was more than interval ago
    RETURN (v_last_call < (CURRENT_TIMESTAMP - v_interval));
END;
$$ LANGUAGE plpgsql;

-- Function to record API call with source
CREATE OR REPLACE FUNCTION record_event_api_call(
    p_user_id UUID,
    p_source event_source,
    p_search_lat DECIMAL,
    p_search_long DECIMAL,
    p_search_location_name VARCHAR,
    p_search_radius INTEGER,
    p_events_retrieved INTEGER,
    p_success BOOLEAN DEFAULT true,
    p_error_message TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_call_id INTEGER;
BEGIN
    INSERT INTO event_api_calls (
        user_id,
        source,
        search_latitude,
        search_longitude,
        search_location_name,
        search_radius_miles,
        events_retrieved,
        success,
        error_message
    ) VALUES (
        p_user_id,
        p_source,
        p_search_lat,
        p_search_long,
        p_search_location_name,
        p_search_radius,
        p_events_retrieved,
        p_success,
        p_error_message
    )
    RETURNING id INTO v_call_id;

    RETURN v_call_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE VIEW user_event_stats AS
SELECT
    u.id AS user_id,
    u.username,
    COUNT(DISTINCT uea.event_id) AS events_attended,
    COUNT(DISTINCT eac.id) AS total_api_calls,
    MAX(eac.called_at) AS last_api_call,
    -- Check if user can call any API (defaults to ticketmaster for backward compatibility)
    can_user_call_event_api(u.id, 'ticketmaster'::event_source) AS can_call_api_now
FROM users u
    LEFT JOIN user_event_attendance uea ON u.id = uea.user_id
    LEFT JOIN event_api_calls eac ON u.id = eac.user_id
GROUP BY u.id, u.username;

-- Recreate with UUID event_id parameter
CREATE OR REPLACE FUNCTION has_user_attended_event(
    p_user_id UUID,
    p_event_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM user_event_attendance
        WHERE user_id = p_user_id AND event_id = p_event_id
    );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION mark_event_attended(
    p_user_id UUID,
    p_event_id UUID,
    p_notes TEXT DEFAULT NULL,
    p_rating INTEGER DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO user_event_attendance (user_id, event_id, notes, rating)
    VALUES (p_user_id, p_event_id, p_notes, p_rating)
    ON CONFLICT (user_id, event_id) DO UPDATE
    SET notes = EXCLUDED.notes,
        rating = EXCLUDED.rating;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_events_updated_at
    BEFORE UPDATE ON events
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- STEP 10: Enable RLS on Events
-- ============================================================================

ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_category_mappings ENABLE ROW LEVEL SECURITY;

-- Events policies (same as before - public read)
CREATE POLICY "Anyone can view events"
ON events FOR SELECT USING (true);

-- Category mappings policies (public read)
CREATE POLICY "Anyone can view category mappings"
ON event_category_mappings FOR SELECT USING (true);

-- Update event_api_calls policies
DROP POLICY IF EXISTS "Users can view their own API calls" ON event_api_calls;
DROP POLICY IF EXISTS "Users can record their own API calls" ON event_api_calls;

CREATE POLICY "Users can view their own API calls"
ON event_api_calls FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can record their own API calls"
ON event_api_calls FOR INSERT
WITH CHECK (user_id = auth.uid());