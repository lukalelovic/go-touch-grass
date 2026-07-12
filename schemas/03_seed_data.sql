-- ============================================================================
-- Go Touch Grass Database Schema - Seed Data
-- PostgreSQL Database for Supabase
-- Last Updated: May 31, 2026
-- ============================================================================

-- ============================================================================
-- SEED DATA
-- ============================================================================

-- Activity Types
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
INSERT INTO activity_subtypes (activity_type_id, name) VALUES
    ((SELECT id FROM activity_types WHERE name = 'Hiking'), 'Trail Hiking'),
    ((SELECT id FROM activity_types WHERE name = 'Hiking'), 'Mountain Hiking'),
    ((SELECT id FROM activity_types WHERE name = 'Hiking'), 'Desert Hiking'),
    ((SELECT id FROM activity_types WHERE name = 'Running'), 'Trail Running'),
    ((SELECT id FROM activity_types WHERE name = 'Running'), 'Road Running'),
    ((SELECT id FROM activity_types WHERE name = 'Cycling'), 'Mountain Biking'),
    ((SELECT id FROM activity_types WHERE name = 'Cycling'), 'Road Cycling');

-- Level Milestones
INSERT INTO level_milestones (milestone_level, name, description, icon) VALUES
    (1, 'Sprout', 'Taking your first steps outdoors', 'leaf.fill'),
    (5, 'Seedling', 'Starting to grow (25 activities)', 'leaf.circle.fill'),
    (10, 'Grass Toucher', 'Getting comfortable outside (50 activities)', 'tree.fill'),
    (25, 'Enthusiast', 'A regular outdoor enthusiast (125 activities)', 'tree.circle.fill'),
    (50, 'Explorer', 'Exploring new paths (250 activities)', 'figure.hiking'),
    (75, 'Naturalist', 'Dedicated to outdoor life (375 activities)', 'globe.americas.fill'),
    (100, 'Trailblazer', 'Master of outdoor activities (500 activities)', 'mountain.2.fill'),
    (250, 'Legend', 'An inspiration to all (1250 activities)', 'sparkles');

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

-- Sample Users (for testing)
INSERT INTO users (username, email) VALUES
    ('outdoor_enthusiast', 'outdoor@example.com'),
    ('trail_runner', 'runner@example.com'),
    ('nature_lover', 'nature@example.com'),
    ('adventure_seeker', 'adventure@example.com'),
    ('mountain_climber', 'climber@example.com');
