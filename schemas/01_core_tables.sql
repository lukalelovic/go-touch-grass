-- ============================================================================
-- Go Touch Grass Database Schema - Core Tables
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

-- Activity Subtypes
CREATE TABLE activity_subtypes (
    id SERIAL PRIMARY KEY,
    activity_type_id INTEGER NOT NULL REFERENCES activity_types(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_subtype_per_type UNIQUE(activity_type_id, name)
);

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

-- Activities
CREATE TABLE activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_type_id INTEGER NOT NULL REFERENCES activity_types(id) ON DELETE RESTRICT,
    activity_subtype_id INTEGER REFERENCES activity_subtypes(id) ON DELETE SET NULL,
    recommendation_id UUID REFERENCES daily_activity_recommendations(id) ON DELETE SET NULL,
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
CREATE INDEX idx_activities_recommendation_id ON activities(recommendation_id);
CREATE INDEX idx_activities_timestamp ON activities(timestamp DESC);
CREATE INDEX idx_activities_location ON activities(location_latitude, location_longitude) WHERE location_latitude IS NOT NULL;

COMMENT ON COLUMN activities.recommendation_id IS
  'Links to the activity_recommendation that prompted this activity, if applicable. Used to identify Touch Grass activities in the feed.';

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
