-- ============================================================================
-- Go Touch Grass Database Schema - Policies & Permissions
-- PostgreSQL Database for Supabase
-- Last Updated: May 31, 2026
-- ============================================================================

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

-- Ensure the avatars bucket exists and is public
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/jpg'])
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/jpg'];

-- Create simple, permissive policies for avatars bucket
CREATE POLICY "avatar_upload_policy"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'avatars');

CREATE POLICY "avatar_update_policy"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'avatars')
WITH CHECK (bucket_id = 'avatars');

CREATE POLICY "avatar_delete_policy"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'avatars');

CREATE POLICY "avatar_select_policy"
ON storage.objects
FOR SELECT
USING (bucket_id = 'avatars');
