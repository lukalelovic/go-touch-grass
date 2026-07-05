-- ============================================================================
-- Go Touch Grass Database Schema (Cleaned & Simplified)
-- PostgreSQL Database for Supabase
-- Last Updated: May 31, 2026
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- Users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    profile_picture_url TEXT,
    is_private BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT username_min_length CHECK (char_length(username) >= 3),
    CONSTRAINT email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);

-- User Follows
CREATE TABLE user_follows (
    id SERIAL PRIMARY KEY,
    follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT no_self_follow CHECK (follower_id != following_id),
    CONSTRAINT unique_follow UNIQUE(follower_id, following_id)
);

CREATE INDEX idx_user_follows_follower_id ON user_follows(follower_id);
CREATE INDEX idx_user_follows_following_id ON user_follows(following_id);
CREATE INDEX idx_user_follows_created_at ON user_follows(created_at DESC);

-- Follow Requests (for private accounts)
CREATE TABLE follow_requests (
    id SERIAL PRIMARY KEY,
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    requested_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT no_self_follow_request CHECK (requester_id != requested_id),
    CONSTRAINT unique_follow_request UNIQUE(requester_id, requested_id)
);

CREATE INDEX idx_follow_requests_requester_id ON follow_requests(requester_id);
CREATE INDEX idx_follow_requests_requested_id ON follow_requests(requested_id);
CREATE INDEX idx_follow_requests_status ON follow_requests(status);
CREATE INDEX idx_follow_requests_created_at ON follow_requests(created_at DESC);

-- Activity Types
CREATE TABLE activity_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    icon VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

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
    ('Other', 'figure.outdoor.cycle'),
    ('Coffee', 'cup.and.saucer.fill');

-- Activity Subtypes
CREATE TABLE activity_subtypes (
    id SERIAL PRIMARY KEY,
    activity_type_id INTEGER NOT NULL REFERENCES activity_types(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_subtype_per_type UNIQUE(activity_type_id, name)
);

INSERT INTO activity_subtypes (activity_type_id, name) VALUES
    ((SELECT id FROM activity_types WHERE name = 'Hiking'), 'Trail Hiking'),
    ((SELECT id FROM activity_types WHERE name = 'Hiking'), 'Mountain Hiking'),
    ((SELECT id FROM activity_types WHERE name = 'Hiking'), 'Desert Hiking'),
    ((SELECT id FROM activity_types WHERE name = 'Running'), 'Trail Running'),
    ((SELECT id FROM activity_types WHERE name = 'Running'), 'Road Running'),
    ((SELECT id FROM activity_types WHERE name = 'Cycling'), 'Mountain Biking'),
    ((SELECT id FROM activity_types WHERE name = 'Cycling'), 'Road Cycling');

-- Activities
CREATE TABLE activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_type_id INTEGER NOT NULL REFERENCES activity_types(id) ON DELETE RESTRICT,
    activity_subtype_id INTEGER REFERENCES activity_subtypes(id) ON DELETE SET NULL,
    notes TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    location_latitude DECIMAL(10, 8),
    location_longitude DECIMAL(11, 8),
    location_name VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_coordinates CHECK (
        (location_latitude IS NULL AND location_longitude IS NULL) OR
        (location_latitude BETWEEN -90 AND 90 AND location_longitude BETWEEN -180 AND 180)
    )
);

CREATE INDEX idx_activities_user_id ON activities(user_id);
CREATE INDEX idx_activities_activity_type_id ON activities(activity_type_id);
CREATE INDEX idx_activities_timestamp ON activities(timestamp DESC);
CREATE INDEX idx_activities_location ON activities(location_latitude, location_longitude) WHERE location_latitude IS NOT NULL;

-- Activity Likes
CREATE TABLE activity_likes (
    id SERIAL PRIMARY KEY,
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_activity_like UNIQUE(activity_id, user_id)
);

CREATE INDEX idx_activity_likes_activity_id ON activity_likes(activity_id);
CREATE INDEX idx_activity_likes_user_id ON activity_likes(user_id);

-- ============================================================================
-- RECOMMENDATION SYSTEM (Touch Grass Tab)
-- ============================================================================

-- Activity Templates
CREATE TABLE activity_templates (
    id SERIAL PRIMARY KEY,
    activity_type_id INTEGER NOT NULL REFERENCES activity_types(id) ON DELETE CASCADE,
    prompt_template TEXT NOT NULL,
    challenge_template TEXT,
    estimated_duration_minutes INTEGER,
    difficulty_level INTEGER CHECK (difficulty_level BETWEEN 1 AND 3),
    season_tags TEXT[],
    requires_equipment BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_templates_activity_type ON activity_templates(activity_type_id);
CREATE INDEX idx_templates_active ON activity_templates(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_templates_difficulty ON activity_templates(difficulty_level);

-- Daily Activity Recommendations
CREATE TABLE daily_activity_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recommendation_date DATE NOT NULL,
    activity_template_id INTEGER NOT NULL REFERENCES activity_templates(id) ON DELETE CASCADE,
    card_position INTEGER NOT NULL CHECK (card_position BETWEEN 1 AND 5),
    personalized_prompt TEXT NOT NULL,
    personalized_challenge TEXT,
    activity_type_id INTEGER NOT NULL REFERENCES activity_types(id) ON DELETE RESTRICT,
    estimated_duration_minutes INTEGER,
    was_logged BOOLEAN DEFAULT FALSE,
    logged_at TIMESTAMP WITH TIME ZONE,
    activity_posted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_date_position UNIQUE(user_id, recommendation_date, card_position)
);

CREATE INDEX idx_recommendations_user_date ON daily_activity_recommendations(user_id, recommendation_date);
CREATE INDEX idx_recommendations_user_id ON daily_activity_recommendations(user_id);
CREATE INDEX idx_recommendations_date ON daily_activity_recommendations(recommendation_date);
CREATE INDEX idx_recommendations_template ON daily_activity_recommendations(activity_template_id);
CREATE INDEX idx_recommendations_logged ON daily_activity_recommendations(was_logged);
CREATE INDEX idx_recommendations_posted ON daily_activity_recommendations(activity_posted);

-- User Activity Preferences
CREATE TABLE user_activity_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    preferred_activity_types INTEGER[] DEFAULT '{}',
    fitness_level INTEGER DEFAULT 2 CHECK (fitness_level BETWEEN 1 AND 3),
    preferred_duration_minutes INTEGER DEFAULT 30,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_preferences_user ON user_activity_preferences(user_id);

-- ============================================================================
-- BADGES & LEVELS SYSTEM
-- ============================================================================

CREATE TYPE badge_category AS ENUM (
    'activity_count',
    'activity_type',
    'streak',
    'distance',
    'social',
    'special'
);

CREATE TABLE badges (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT NOT NULL,
    category badge_category NOT NULL,
    icon VARCHAR(100),
    criteria JSONB NOT NULL,
    display_order INTEGER DEFAULT 0,
    rarity VARCHAR(20) DEFAULT 'common',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE level_milestones (
    id SERIAL PRIMARY KEY,
    milestone_level INTEGER UNIQUE NOT NULL,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    icon VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_milestone_level CHECK (milestone_level > 0)
);

CREATE TABLE user_badges (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    badge_id INTEGER NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    progress JSONB,
    CONSTRAINT unique_user_badge UNIQUE(user_id, badge_id)
);

CREATE INDEX idx_user_badges_user_id ON user_badges(user_id);
CREATE INDEX idx_user_badges_badge_id ON user_badges(badge_id);
CREATE INDEX idx_user_badges_unlocked_at ON user_badges(unlocked_at DESC);
CREATE INDEX idx_badges_category ON badges(category);

-- ============================================================================
-- VIEWS
-- ============================================================================

CREATE VIEW activities_with_stats
WITH (security_invoker = on) AS
SELECT
    a.id, a.user_id, u.username, u.email, u.profile_picture_url,
    a.activity_type_id, at.name AS activity_type_name, at.icon AS activity_type_icon,
    a.activity_subtype_id, ast.name AS activity_subtype_name,
    a.notes, a.timestamp, a.location_latitude, a.location_longitude, a.location_name,
    COUNT(DISTINCT al.id) AS like_count,
    a.created_at, a.updated_at
FROM activities a
JOIN users u ON a.user_id = u.id
JOIN activity_types at ON a.activity_type_id = at.id
LEFT JOIN activity_subtypes ast ON a.activity_subtype_id = ast.id
LEFT JOIN activity_likes al ON a.id = al.activity_id
GROUP BY a.id, u.id, u.username, u.email, u.profile_picture_url,
    at.id, at.name, at.icon, ast.id, ast.name,
    a.notes, a.timestamp, a.location_latitude, a.location_longitude, a.location_name,
    a.created_at, a.updated_at;

CREATE VIEW user_stats
WITH (security_invoker = on) AS
WITH activity_type_counts AS (
    SELECT a.user_id, at.name AS activity_type_name, COUNT(*) AS activity_count
    FROM activities a
    JOIN activity_types at ON a.activity_type_id = at.id
    GROUP BY a.user_id, at.name
)
SELECT
    u.id AS user_id, u.username, u.created_at AS user_created_at,
    COUNT(DISTINCT a.id) AS total_activities,
    COUNT(DISTINCT DATE(a.timestamp)) AS total_active_days,
    COALESCE((SELECT jsonb_object_agg(activity_type_name, activity_count)
             FROM activity_type_counts atc WHERE atc.user_id = u.id), '{}'::jsonb) AS activities_by_type,
    COUNT(DISTINCT al_received.id) AS total_likes_received,
    COUNT(DISTINCT al_given.id) AS total_likes_given,
    COUNT(DISTINCT followers.id) AS follower_count,
    COUNT(DISTINCT following.id) AS following_count,
    MAX(a.timestamp) AS last_activity_date,
    MIN(a.timestamp) AS first_activity_date,
    COUNT(DISTINCT ub.badge_id) AS badges_unlocked
FROM users u
LEFT JOIN activities a ON u.id = a.user_id
LEFT JOIN activity_likes al_received ON a.id = al_received.activity_id
LEFT JOIN activity_likes al_given ON u.id = al_given.user_id
LEFT JOIN user_follows followers ON u.id = followers.following_id
LEFT JOIN user_follows following ON u.id = following.follower_id
LEFT JOIN user_badges ub ON u.id = ub.user_id
GROUP BY u.id, u.username, u.created_at;

CREATE VIEW user_current_levels
WITH (security_invoker = on) AS
SELECT
    us.user_id, us.username, us.total_activities,
    GREATEST(us.total_activities, 1) AS current_level,
    current_milestone.milestone_level AS current_milestone_level,
    current_milestone.name AS milestone_name,
    current_milestone.description AS milestone_description,
    current_milestone.icon AS milestone_icon,
    next_milestone.milestone_level AS next_milestone_level,
    next_milestone.name AS next_milestone_name,
    next_milestone.icon AS next_milestone_icon,
    GREATEST(0, COALESCE(next_milestone.milestone_level, 0) - us.total_activities) AS activities_to_next_milestone,
    CASE
        WHEN next_milestone.milestone_level IS NULL THEN 100
        WHEN next_milestone.milestone_level <= COALESCE(current_milestone.milestone_level, 0) THEN 100
        ELSE ROUND(
            ((us.total_activities - COALESCE(current_milestone.milestone_level, 0))::NUMERIC /
            (next_milestone.milestone_level - COALESCE(current_milestone.milestone_level, 0))::NUMERIC * 100), 2)
    END AS progress_to_next_milestone
FROM user_stats us
LEFT JOIN level_milestones current_milestone ON us.total_activities >= current_milestone.milestone_level
    AND current_milestone.milestone_level = (
        SELECT MAX(milestone_level) FROM level_milestones WHERE milestone_level <= us.total_activities)
LEFT JOIN level_milestones next_milestone ON next_milestone.id = (
    SELECT MIN(id) FROM level_milestones WHERE milestone_level > us.total_activities);

CREATE VIEW user_badge_progress
WITH (security_invoker = on) AS
SELECT
    u.id AS user_id, u.username,
    b.id AS badge_id, b.name AS badge_name, b.description AS badge_description,
    b.category, b.icon, b.rarity, b.criteria,
    ub.unlocked_at,
    CASE WHEN ub.id IS NOT NULL THEN true ELSE false END AS is_unlocked,
    ub.progress
FROM users u
CROSS JOIN badges b
LEFT JOIN user_badges ub ON u.id = ub.user_id AND b.id = ub.badge_id;

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Auto-update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_activities_updated_at BEFORE UPDATE ON activities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Auto-create User Profile on Signup
-- This function runs with elevated privileges to bypass RLS
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.users (id, username, email, created_at)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
        NEW.email,
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-create user profile when auth user is created
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Activity Likes
CREATE OR REPLACE FUNCTION toggle_activity_like(p_activity_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE v_exists BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM activity_likes WHERE activity_id = p_activity_id AND user_id = p_user_id) INTO v_exists;
    IF v_exists THEN
        DELETE FROM activity_likes WHERE activity_id = p_activity_id AND user_id = p_user_id;
        RETURN FALSE;
    ELSE
        INSERT INTO activity_likes (activity_id, user_id) VALUES (p_activity_id, p_user_id);
        RETURN TRUE;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION has_user_liked_activity(p_activity_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(SELECT 1 FROM activity_likes WHERE activity_id = p_activity_id AND user_id = p_user_id);
END;
$$ LANGUAGE plpgsql;

-- User Follows
CREATE OR REPLACE FUNCTION toggle_user_follow(p_follower_id UUID, p_following_id UUID)
RETURNS BOOLEAN AS $$
DECLARE v_exists BOOLEAN; v_is_private BOOLEAN;
BEGIN
    IF p_follower_id = p_following_id THEN RAISE EXCEPTION 'Users cannot follow themselves'; END IF;
    SELECT EXISTS(SELECT 1 FROM user_follows WHERE follower_id = p_follower_id AND following_id = p_following_id) INTO v_exists;
    IF v_exists THEN
        DELETE FROM user_follows WHERE follower_id = p_follower_id AND following_id = p_following_id;
        DELETE FROM follow_requests WHERE requester_id = p_follower_id AND requested_id = p_following_id;
        RETURN FALSE;
    ELSE
        SELECT is_private INTO v_is_private FROM users WHERE id = p_following_id;
        IF v_is_private THEN RAISE EXCEPTION 'Cannot follow private account directly. Use send_follow_request instead.';
        ELSE INSERT INTO user_follows (follower_id, following_id) VALUES (p_follower_id, p_following_id); RETURN TRUE;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION is_following(p_follower_id UUID, p_following_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(SELECT 1 FROM user_follows WHERE follower_id = p_follower_id AND following_id = p_following_id);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_follower_count(p_user_id UUID) RETURNS INTEGER AS $$
BEGIN RETURN (SELECT COUNT(*) FROM user_follows WHERE following_id = p_user_id)::INTEGER; END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_following_count(p_user_id UUID) RETURNS INTEGER AS $$
BEGIN RETURN (SELECT COUNT(*) FROM user_follows WHERE follower_id = p_user_id)::INTEGER; END;
$$ LANGUAGE plpgsql;

-- Follow Requests
CREATE OR REPLACE FUNCTION send_follow_request(p_requester_id UUID, p_requested_id UUID)
RETURNS TABLE(success BOOLEAN, is_direct_follow BOOLEAN, message TEXT) AS $$
DECLARE v_is_private BOOLEAN; v_already_following BOOLEAN; v_pending_request BOOLEAN;
BEGIN
    IF p_requester_id = p_requested_id THEN RETURN QUERY SELECT false, false, 'Cannot follow yourself'::TEXT; RETURN; END IF;
    SELECT EXISTS(SELECT 1 FROM user_follows WHERE follower_id = p_requester_id AND following_id = p_requested_id) INTO v_already_following;
    IF v_already_following THEN RETURN QUERY SELECT false, false, 'Already following this user'::TEXT; RETURN; END IF;
    SELECT EXISTS(SELECT 1 FROM follow_requests WHERE requester_id = p_requester_id AND requested_id = p_requested_id AND status = 'pending') INTO v_pending_request;
    IF v_pending_request THEN RETURN QUERY SELECT false, false, 'Follow request already sent'::TEXT; RETURN; END IF;
    SELECT is_private INTO v_is_private FROM users WHERE id = p_requested_id;
    IF v_is_private THEN
        INSERT INTO follow_requests (requester_id, requested_id, status) VALUES (p_requester_id, p_requested_id, 'pending')
        ON CONFLICT (requester_id, requested_id) DO UPDATE SET status = 'pending', updated_at = CURRENT_TIMESTAMP;
        RETURN QUERY SELECT true, false, 'Follow request sent'::TEXT;
    ELSE
        INSERT INTO user_follows (follower_id, following_id) VALUES (p_requester_id, p_requested_id);
        RETURN QUERY SELECT true, true, 'Now following'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION accept_follow_request(p_requester_id UUID, p_requested_id UUID)
RETURNS BOOLEAN AS $$
DECLARE v_request_exists BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM follow_requests WHERE requester_id = p_requester_id AND requested_id = p_requested_id AND status = 'pending') INTO v_request_exists;
    IF NOT v_request_exists THEN RAISE EXCEPTION 'No pending follow request found'; END IF;
    INSERT INTO user_follows (follower_id, following_id) VALUES (p_requester_id, p_requested_id) ON CONFLICT DO NOTHING;
    UPDATE follow_requests SET status = 'accepted', updated_at = CURRENT_TIMESTAMP WHERE requester_id = p_requester_id AND requested_id = p_requested_id;
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION reject_follow_request(p_requester_id UUID, p_requested_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    DELETE FROM follow_requests WHERE requester_id = p_requester_id AND requested_id = p_requested_id AND status = 'pending';
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cancel_follow_request(p_requester_id UUID, p_requested_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    DELETE FROM follow_requests WHERE requester_id = p_requester_id AND requested_id = p_requested_id AND status = 'pending';
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_pending_follow_requests(p_user_id UUID)
RETURNS TABLE(request_id INTEGER, requester_id UUID, requester_username VARCHAR, requester_profile_picture_url TEXT, created_at TIMESTAMP WITH TIME ZONE) AS $$
BEGIN
    RETURN QUERY
    SELECT fr.id, fr.requester_id, u.username, u.profile_picture_url, fr.created_at
    FROM follow_requests fr JOIN users u ON fr.requester_id = u.id
    WHERE fr.requested_id = p_user_id AND fr.status = 'pending' ORDER BY fr.created_at DESC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_sent_follow_requests(p_user_id UUID)
RETURNS TABLE(request_id INTEGER, requested_id UUID, requested_username VARCHAR, requested_profile_picture_url TEXT, created_at TIMESTAMP WITH TIME ZONE) AS $$
BEGIN
    RETURN QUERY
    SELECT fr.id, fr.requested_id, u.username, u.profile_picture_url, fr.created_at
    FROM follow_requests fr JOIN users u ON fr.requested_id = u.id
    WHERE fr.requester_id = p_user_id AND fr.status = 'pending' ORDER BY fr.created_at DESC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION has_pending_follow_request(p_requester_id UUID, p_requested_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(SELECT 1 FROM follow_requests WHERE requester_id = p_requester_id AND requested_id = p_requested_id AND status = 'pending');
END;
$$ LANGUAGE plpgsql;

-- Recommendation Functions
CREATE OR REPLACE FUNCTION get_todays_recommendations(p_user_id UUID)
RETURNS TABLE (
    id UUID, card_position INTEGER, personalized_prompt TEXT, personalized_challenge TEXT,
    activity_type_id INTEGER, activity_type_name VARCHAR(50), activity_type_icon VARCHAR(100),
    estimated_duration_minutes INTEGER, was_logged BOOLEAN, logged_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT dar.id, dar.card_position, dar.personalized_prompt, dar.personalized_challenge,
           dar.activity_type_id, at.name AS activity_type_name, at.icon AS activity_type_icon,
           dar.estimated_duration_minutes, dar.was_logged, dar.logged_at
    FROM daily_activity_recommendations dar
    JOIN activity_types at ON dar.activity_type_id = at.id
    WHERE dar.user_id = p_user_id AND dar.recommendation_date = CURRENT_DATE
    ORDER BY dar.card_position ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION mark_recommendation_logged(p_recommendation_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE daily_activity_recommendations SET was_logged = TRUE, logged_at = CURRENT_TIMESTAMP WHERE id = p_recommendation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_user_activity_type_preferences(p_user_id UUID)
RETURNS INTEGER[] AS $$
DECLARE v_preferred_types INTEGER[];
BEGIN
    SELECT ARRAY_AGG(activity_type_id) INTO v_preferred_types
    FROM (SELECT activity_type_id, COUNT(*) as activity_count FROM activities WHERE user_id = p_user_id
          GROUP BY activity_type_id ORDER BY activity_count DESC LIMIT 3) top_types;
    RETURN COALESCE(v_preferred_types, '{}');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_template_completion_rate(p_template_id INTEGER, p_user_id UUID)
RETURNS DECIMAL AS $$
DECLARE v_total INTEGER; v_completed INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_total FROM daily_activity_recommendations WHERE activity_template_id = p_template_id AND user_id = p_user_id;
    IF v_total = 0 THEN RETURN 0.0; END IF;
    SELECT COUNT(*) INTO v_completed FROM daily_activity_recommendations WHERE activity_template_id = p_template_id AND user_id = p_user_id AND was_logged = TRUE;
    RETURN v_completed::DECIMAL / v_total::DECIMAL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Badge Functions
CREATE OR REPLACE FUNCTION check_and_award_badges(p_user_id UUID)
RETURNS TABLE(badge_id INTEGER, badge_name VARCHAR, newly_awarded BOOLEAN) AS $$
BEGIN
    RETURN QUERY
    WITH user_stat AS (SELECT * FROM user_stats WHERE user_id = p_user_id),
    eligible_badges AS (
        SELECT b.id, b.name, b.criteria,
        CASE
            WHEN b.criteria->>'type' = 'total_activities' THEN (SELECT total_activities FROM user_stat) >= (b.criteria->>'count')::INTEGER
            WHEN b.criteria->>'type' = 'specific_activity' THEN
                COALESCE((SELECT activities_by_type->(SELECT name FROM activity_types WHERE id = (b.criteria->>'activity_type_id')::INTEGER) FROM user_stat)::TEXT::INTEGER, 0) >= (b.criteria->>'count')::INTEGER
            WHEN b.criteria->>'type' = 'likes_received' THEN (SELECT total_likes_received FROM user_stat) >= (b.criteria->>'count')::INTEGER
            WHEN b.criteria->>'type' = 'likes_given' THEN (SELECT total_likes_given FROM user_stat) >= (b.criteria->>'count')::INTEGER
            ELSE false
        END AS is_eligible
        FROM badges b
        WHERE NOT EXISTS (SELECT 1 FROM user_badges ub WHERE ub.user_id = p_user_id AND ub.badge_id = b.id)
    )
    INSERT INTO user_badges (user_id, badge_id)
    SELECT p_user_id, eb.id FROM eligible_badges eb WHERE eb.is_eligible
    RETURNING user_badges.badge_id, (SELECT name FROM badges WHERE id = user_badges.badge_id), true AS newly_awarded;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_user_streak(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE v_streak INTEGER := 0; v_current_date DATE; v_check_date DATE := CURRENT_DATE;
BEGIN
    SELECT MAX(DATE(timestamp)) INTO v_current_date FROM activities WHERE user_id = p_user_id;
    IF v_current_date IS NULL OR v_current_date < CURRENT_DATE - INTERVAL '1 day' THEN RETURN 0; END IF;
    WHILE EXISTS (SELECT 1 FROM activities WHERE user_id = p_user_id AND DATE(timestamp) = v_check_date) LOOP
        v_streak := v_streak + 1;
        v_check_date := v_check_date - INTERVAL '1 day';
    END LOOP;
    RETURN v_streak;
END;
$$ LANGUAGE plpgsql;

-- Profile Picture Update
CREATE OR REPLACE FUNCTION update_user_profile_picture(p_user_id UUID, p_picture_url TEXT)
RETURNS TABLE(id UUID, profile_picture_url TEXT) AS $$
BEGIN
    IF p_user_id != auth.uid() THEN RAISE EXCEPTION 'Unauthorized: Cannot update another user''s profile picture'; END IF;
    RETURN QUERY UPDATE users SET profile_picture_url = p_picture_url, updated_at = CURRENT_TIMESTAMP
    WHERE users.id = p_user_id RETURNING users.id, users.profile_picture_url;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- SEED DATA
-- ============================================================================

-- Level Milestones
INSERT INTO level_milestones (milestone_level, name, description, icon) VALUES
    (1, 'Sprout', 'Taking your first steps outdoors', 'leaf.fill'),
    (5, 'Seedling', 'Starting to grow', 'leaf.circle.fill'),
    (10, 'Grass Toucher', 'Getting comfortable outside', 'tree.fill'),
    (25, 'Enthusiast', 'A regular outdoor enthusiast', 'tree.circle.fill'),
    (50, 'Explorer', 'Exploring new paths', 'figure.hiking'),
    (75, 'Naturalist', 'Dedicated to outdoor life', 'globe.americas.fill'),
    (100, 'Trailblazer', 'Master of outdoor activities', 'mountain.2.fill'),
    (500, 'Legend', 'An inspiration to all', 'sparkles');

-- Badges
INSERT INTO badges (name, description, category, icon, criteria, rarity, display_order) VALUES
    ('First Steps', 'Complete your first activity', 'activity_count', 'figure.walk', '{"type": "total_activities", "count": 1}', 'common', 1),
    ('Getting Started', 'Complete 5 activities', 'activity_count', 'leaf.fill', '{"type": "total_activities", "count": 5}', 'common', 2),
    ('Committed', 'Complete 25 activities', 'activity_count', 'flame.fill', '{"type": "total_activities", "count": 25}', 'rare', 3),
    ('Dedicated', 'Complete 50 activities', 'activity_count', 'star.fill', '{"type": "total_activities", "count": 50}', 'rare', 4),
    ('Century Club', 'Complete 100 activities', 'activity_count', 'star.circle.fill', '{"type": "total_activities", "count": 100}', 'epic', 5),
    ('Legendary', 'Complete 500 activities', 'activity_count', 'crown.fill', '{"type": "total_activities", "count": 500}', 'legendary', 6),
    ('Peak Performer', 'Complete 10 hiking activities', 'activity_type', 'mountain.2.fill', '{"type": "specific_activity", "activity_type_id": 1, "count": 10}', 'rare', 10),
    ('Marathon Runner', 'Complete 20 running activities', 'activity_type', 'figure.run', '{"type": "specific_activity", "activity_type_id": 2, "count": 20}', 'rare', 11),
    ('Cycling Enthusiast', 'Complete 15 cycling activities', 'activity_type', 'bicycle', '{"type": "specific_activity", "activity_type_id": 3, "count": 15}', 'rare', 12),
    ('Popular', 'Receive 10 likes on your activities', 'social', 'hand.thumbsup.fill', '{"type": "likes_received", "count": 10}', 'common', 20),
    ('Community Star', 'Receive 50 likes on your activities', 'social', 'star.leadinghalf.filled', '{"type": "likes_received", "count": 50}', 'rare', 21),
    ('Supportive', 'Give 25 likes to other activities', 'social', 'heart.fill', '{"type": "likes_given", "count": 25}', 'common', 22);

-- Activity Templates (50 templates) - See next section for full seed data
-- Due to length, run activity_templates_seed.sql separately or include inline

-- Sample Users (for testing)
INSERT INTO users (username, email) VALUES
    ('outdoor_enthusiast', 'outdoor@example.com'),
    ('trail_runner', 'runner@example.com'),
    ('nature_lover', 'nature@example.com'),
    ('adventure_seeker', 'adventure@example.com'),
    ('mountain_climber', 'climber@example.com');

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

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
ALTER TABLE activity_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_activity_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_activity_preferences ENABLE ROW LEVEL SECURITY;

-- Users
CREATE POLICY "Anyone can view user profiles" ON users FOR SELECT USING (true);
CREATE POLICY "Users can create their own profile" ON users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON users FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- User Follows
CREATE POLICY "Anyone can view follow relationships" ON user_follows FOR SELECT USING (true);
CREATE POLICY "Users can follow others" ON user_follows FOR INSERT WITH CHECK (follower_id = auth.uid());
CREATE POLICY "Users can unfollow others" ON user_follows FOR DELETE USING (follower_id = auth.uid());

-- Follow Requests
CREATE POLICY "Users can view their follow requests" ON follow_requests FOR SELECT USING (requester_id = auth.uid() OR requested_id = auth.uid());
CREATE POLICY "Users can send follow requests" ON follow_requests FOR INSERT WITH CHECK (requester_id = auth.uid());
CREATE POLICY "Users can update received follow requests" ON follow_requests FOR UPDATE USING (requested_id = auth.uid()) WITH CHECK (requested_id = auth.uid());
CREATE POLICY "Users can delete follow requests" ON follow_requests FOR DELETE USING (requester_id = auth.uid() OR requested_id = auth.uid());

-- Activities
CREATE POLICY "Users can view activities based on privacy" ON activities FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM users u WHERE u.id = activities.user_id AND (u.is_private = false OR u.is_private IS NULL)) OR
    EXISTS (SELECT 1 FROM users u WHERE u.id = activities.user_id AND u.is_private = true
            AND EXISTS (SELECT 1 FROM user_follows uf WHERE uf.follower_id = auth.uid() AND uf.following_id = activities.user_id))
);
CREATE POLICY "Users can create their own activities" ON activities FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update their own activities" ON activities FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can delete their own activities" ON activities FOR DELETE USING (user_id = auth.uid());

-- Activity Likes
CREATE POLICY "Anyone can view activity likes" ON activity_likes FOR SELECT USING (true);
CREATE POLICY "Users can like activities" ON activity_likes FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can unlike activities" ON activity_likes FOR DELETE USING (user_id = auth.uid());

-- Activity Types & Subtypes
CREATE POLICY "Anyone can view activity types" ON activity_types FOR SELECT USING (true);
CREATE POLICY "Anyone can view activity subtypes" ON activity_subtypes FOR SELECT USING (true);

-- Badges & Levels
CREATE POLICY "Anyone can view badges" ON badges FOR SELECT USING (true);
CREATE POLICY "Anyone can view user badges" ON user_badges FOR SELECT USING (true);
CREATE POLICY "Anyone can view level milestones" ON level_milestones FOR SELECT USING (true);

-- Recommendations
CREATE POLICY "Authenticated users can view active templates" ON activity_templates FOR SELECT TO authenticated USING (is_active = TRUE);
CREATE POLICY "Users can view their own recommendations" ON daily_activity_recommendations FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own recommendations" ON daily_activity_recommendations FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own recommendations" ON daily_activity_recommendations FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can view their own preferences" ON user_activity_preferences FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own preferences" ON user_activity_preferences FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own preferences" ON user_activity_preferences FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- TABLE-LEVEL GRANTS
-- ============================================================================
-- CRITICAL: RLS policies control WHAT rows users can see, but GRANTs control
-- WHETHER they can access tables at all. Both are required!

-- Core user tables
GRANT SELECT, INSERT, UPDATE ON users TO authenticated;
GRANT SELECT, INSERT, DELETE ON user_follows TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON follow_requests TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON activities TO authenticated;
GRANT SELECT, INSERT, DELETE ON activity_likes TO authenticated;

-- Reference tables (read-only)
GRANT SELECT ON activity_types TO authenticated;
GRANT SELECT ON activity_subtypes TO authenticated;
GRANT SELECT ON badges TO authenticated;
GRANT SELECT ON level_milestones TO authenticated;

-- User-specific tables
GRANT SELECT ON user_badges TO authenticated;

-- Recommendation system tables
GRANT SELECT ON activity_templates TO authenticated;
GRANT SELECT, INSERT, UPDATE ON daily_activity_recommendations TO authenticated;
GRANT SELECT, INSERT, UPDATE ON user_activity_preferences TO authenticated;

-- Sequence permissions (needed for INSERT operations)
GRANT USAGE, SELECT ON SEQUENCE activity_templates_id_seq TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- ============================================================================
-- FUNCTION PERMISSIONS
-- ============================================================================

-- Recommendation functions
GRANT EXECUTE ON FUNCTION public.get_todays_recommendations(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_recommendation_logged(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_activity_type_preferences(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_template_completion_rate(INTEGER, UUID) TO authenticated;

-- Activity functions
GRANT EXECUTE ON FUNCTION public.toggle_activity_like(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_user_liked_activity(UUID, UUID) TO authenticated;

-- Social functions
GRANT EXECUTE ON FUNCTION public.toggle_user_follow(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_following(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_follower_count(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_following_count(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.send_follow_request(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_follow_request(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reject_follow_request(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_follow_request(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_pending_follow_requests(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_sent_follow_requests(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_pending_follow_request(UUID, UUID) TO authenticated;

-- Badge & profile functions
GRANT EXECUTE ON FUNCTION public.check_and_award_badges(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_streak(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_user_profile_picture(UUID, TEXT) TO authenticated;

-- ============================================================================
-- STORAGE BUCKET (Avatars)
-- ============================================================================

INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT (id) DO UPDATE SET public = true;

CREATE POLICY "Users can upload their own avatar" ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (string_to_array(name, '/'))[1]);
CREATE POLICY "Users can update their own avatar" ON storage.objects FOR UPDATE TO authenticated
    USING (bucket_id = 'avatars' AND auth.uid()::text = (string_to_array(name, '/'))[1]);
CREATE POLICY "Users can delete their own avatar" ON storage.objects FOR DELETE TO authenticated
    USING (bucket_id = 'avatars' AND auth.uid()::text = (string_to_array(name, '/'))[1]);
CREATE POLICY "Anyone can view avatars" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
