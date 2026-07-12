-- ============================================================================
-- Go Touch Grass Database Schema - Functions & Views
-- PostgreSQL Database for Supabase
-- Last Updated: May 31, 2026
-- ============================================================================

-- ============================================================================
-- VIEWS
-- ============================================================================

DROP VIEW IF EXISTS activities_with_stats;

CREATE VIEW activities_with_stats
WITH (security_invoker = on) AS
SELECT
    a.id, a.user_id, u.username, u.email, u.profile_picture_url,
    a.activity_type_id, at.name AS activity_type_name, at.icon AS activity_type_icon,
    a.activity_subtype_id, ast.name AS activity_subtype_name,
    a.notes, a.timestamp, a.location_latitude, a.location_longitude, a.location_name,
    a.recommendation_id,
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
    a.recommendation_id, a.created_at, a.updated_at;

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
    (COUNT(DISTINCT a.id) * 10) AS total_xp,
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
    us.user_id, us.username, us.total_activities, us.total_xp,
    GREATEST(FLOOR(us.total_xp / 50.0) + 1, 1) AS current_level,
    current_milestone.milestone_level AS current_milestone_level,
    current_milestone.name AS milestone_name,
    current_milestone.description AS milestone_description,
    current_milestone.icon AS milestone_icon,
    next_milestone.milestone_level AS next_milestone_level,
    next_milestone.name AS next_milestone_name,
    next_milestone.icon AS next_milestone_icon,
    (50 - (us.total_xp % 50)) AS xp_to_next_level,
    (us.total_xp % 50) AS current_level_xp,
    GREATEST(0, COALESCE(next_milestone.milestone_level, 0) - GREATEST(FLOOR(us.total_xp / 50.0) + 1, 1)) AS activities_to_next_milestone,
    CASE
        WHEN next_milestone.milestone_level IS NULL THEN 100
        WHEN next_milestone.milestone_level <= COALESCE(current_milestone.milestone_level, 0) THEN 100
        ELSE ROUND(
            ((GREATEST(FLOOR(us.total_xp / 50.0) + 1, 1) - COALESCE(current_milestone.milestone_level, 0))::NUMERIC /
            (next_milestone.milestone_level - COALESCE(current_milestone.milestone_level, 0))::NUMERIC * 100), 2)
    END AS progress_to_next_milestone
FROM user_stats us
LEFT JOIN level_milestones current_milestone ON GREATEST(FLOOR(us.total_xp / 50.0) + 1, 1) >= current_milestone.milestone_level
    AND current_milestone.milestone_level = (
        SELECT MAX(milestone_level) FROM level_milestones WHERE milestone_level <= GREATEST(FLOOR(us.total_xp / 50.0) + 1, 1))
LEFT JOIN level_milestones next_milestone ON next_milestone.id = (
    SELECT MIN(id) FROM level_milestones WHERE milestone_level > GREATEST(FLOOR(us.total_xp / 50.0) + 1, 1));

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
-- Drop any existing versions to avoid conflicts
DROP FUNCTION IF EXISTS update_user_profile_picture(UUID, TEXT);
DROP FUNCTION IF EXISTS update_user_profile_picture(TEXT, TEXT);
DROP FUNCTION IF EXISTS update_user_profile_picture;

CREATE FUNCTION update_user_profile_picture(p_user_id UUID, p_picture_url TEXT)
RETURNS TABLE(id UUID, profile_picture_url TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_auth_uid UUID;
    v_user_exists BOOLEAN;
BEGIN
    -- Get the authenticated user ID
    v_auth_uid := auth.uid();

    -- Debug: Log the values
    RAISE NOTICE 'Auth UID: %, Param UID: %', v_auth_uid, p_user_id;

    -- Check if user exists
    SELECT EXISTS(SELECT 1 FROM users WHERE users.id = p_user_id) INTO v_user_exists;

    IF NOT v_user_exists THEN
        RAISE EXCEPTION 'User with ID % does not exist', p_user_id;
    END IF;

    -- Check authorization
    IF v_auth_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF p_user_id != v_auth_uid THEN
        RAISE EXCEPTION 'Unauthorized: Cannot update another user''s profile picture. Auth: %, Param: %', v_auth_uid, p_user_id;
    END IF;

    -- Update and return the user
    RETURN QUERY
    UPDATE users
    SET
        profile_picture_url = p_picture_url,
        updated_at = CURRENT_TIMESTAMP
    WHERE users.id = p_user_id
    RETURNING users.id, users.profile_picture_url;

    -- Check if update was successful
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Failed to update profile picture for user %', p_user_id;
    END IF;
END;
$$;
