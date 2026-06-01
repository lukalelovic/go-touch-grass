# PRD: Touch Grass Tab Overhaul - Daily Activity Recommendation Algorithm

**Created:** May 31, 2026
**Status:** ✅ Implementation Complete (MVP)
**Owner:** Product Team
**Version:** 1.0
**Implementation Date:** May 31, 2026

---

## Executive Summary

This PRD outlines a complete overhaul of the "Touch Grass" tab, transitioning from an API-driven and user-curated event discovery system to an intelligent, personalized daily activity recommendation engine. The new system will present users with up to 5 curated activity cards per day, designed to inspire outdoor engagement through simple, actionable suggestions.

**Example Activity Card:**
> **Go... For a run in the park!**
> See how many miles you can do!

---

## Problem Statement

### Current State Issues
1. **API Dependency & Complexity**: Reliance on Ticketmaster API introduces rate limits, data quality issues, and event availability gaps in non-urban areas
2. **Event-Centric Friction**: Users must browse, filter, and RSVP to events, creating decision paralysis and commitment barriers
3. **Limited Rural Coverage**: User-curated community events and commercial APIs provide sparse coverage outside major cities
4. **Low Daily Engagement**: Event-based discovery doesn't encourage daily "touch grass" behavior; events are occasional, not habitual
5. **Misaligned with Core Mission**: The app's goal is outdoor activity habit formation, not event attendance

### User Pain Points
- "There are no events near me" (rural users)
- "I don't want to commit to an event, I just want to go outside now"
- "Too many options, I can't decide what to do"
- "Most events are concerts/festivals, not outdoor activities"

---

## Goals & Success Metrics

### Primary Goals
1. **Increase Daily Engagement**: Drive users to open the Touch Grass tab every day
2. **Reduce Friction**: Enable instant action without browsing, filtering, or RSVP
3. **Universal Coverage**: Provide value regardless of location (urban/suburban/rural)
4. **Habit Formation**: Encourage spontaneous outdoor activities, not planned events

### Success Metrics
| Metric | Target | Timeline |
|--------|--------|----------|
| Daily Touch Grass tab opens | 3x increase | 3 months |
| Activity completion rate (cards → logged activities) | >25% | 3 months |
| User retention (7-day) | +15% | 6 months |
| NPS score improvement | +10 points | 6 months |
| Rural user engagement | 2x increase | 3 months |

### Anti-Goals
- We are **NOT** building a social event platform
- We are **NOT** competing with Meetup or Eventbrite
- We are **NOT** providing event ticketing or RSVP systems
- We are **NOT** maintaining a user-generated event database

---

## User Stories

### Primary User Stories
1. **As a busy professional**, I want to see quick outdoor activity ideas each morning so I can incorporate "touching grass" into my routine without planning
2. **As a rural user**, I want location-independent activity suggestions so I'm not excluded due to lack of nearby events
3. **As an indecisive user**, I want curated recommendations so I don't waste time choosing from overwhelming options
4. **As a streak-motivated user**, I want fresh daily suggestions so I have reasons to check the app every day

### Secondary User Stories
5. **As a seasonal user**, I want weather-appropriate activities so suggestions feel relevant and actionable
6. **As a fitness-focused user**, I want varied activity types so I don't get bored with repetitive suggestions
7. **As a new user**, I want simple, beginner-friendly activities so I'm not intimidated by extreme outdoor challenges

---

## Proposed Solution

### High-Level Overview
Replace the event discovery system with a **Daily Activity Recommendation Algorithm** that generates 5 personalized activity cards each day. Activities are simple, location-flexible prompts that inspire outdoor engagement without requiring advance planning.

### Core Components

#### 1. **Activity Card Structure**
Each card contains:
- **Activity Prompt**: Imperative action phrase (e.g., "Go for a run in the park!")
- **Challenge/Goal**: Optional motivational element (e.g., "See how many miles you can do!")
- **Activity Type Icon**: Visual category identifier (running, hiking, biking, etc.)
- **Estimated Duration**: Quick (15-30min), Medium (30-60min), Long (60min+)
- **Quick Action Button**: "Log Activity" to immediately track completion

**Visual Design:**
```
┌─────────────────────────────────────┐
│  🏃 Running                          │
│                                      │
│  Go for a run in the park!          │
│  See how many miles you can do!     │
│                                      │
│  ⏱️ 30-60 min                        │
│  [Log Activity →]                    │
└─────────────────────────────────────┘
```

#### 2. **Daily Recommendation Algorithm**

**Input Factors:**
- **User Activity History**: Past logged activities, preferred types, completion rates
- **Location Context**: Current location, typical activity locations, local terrain
- **Temporal Patterns**: Day of week, time of day, user's active hours
- **Seasonal/Weather Data**: Current season, typical weather (optional future enhancement)
- **User Preferences**: Favorite activity types, fitness level (inferred or explicit)
- **Variety Score**: Ensure diversity across the 5 daily cards

**Algorithm Logic (v1 - MVP):**
1. **Activity Pool Generation**: Create candidate list of ~20 activities from predefined templates
2. **Filtering**: Remove recently suggested activities (last 7 days), weather-inappropriate options
3. **Scoring**: Rank by user preference match, variety, recency, difficulty match
4. **Selection**: Pick top 5 activities with maximum diversity
5. **Personalization**: Inject user-specific context (e.g., "favorite park", "usual running route")

**Recommendation Refresh:**
- New recommendations generated daily at midnight (user's local timezone)
- Cards remain static throughout the day (no mid-day refresh)
- User can manually "refresh" to generate a new set (limit: 3x per day)

#### 3. **Activity Template Library**

**Categories (8 types):**
- Running
- Walking
- Hiking
- Biking
- Climbing
- Swimming
- Kayaking
- Other (yoga, picnic, stargazing, etc.)

**Example Templates:**

| Category | Prompt | Challenge/Goal |
|----------|--------|----------------|
| Running | Go for a morning run! | Beat yesterday's pace |
| Running | Sprint intervals at the track! | 8 x 200m with rest |
| Walking | Take a sunset walk! | Find 3 interesting things to photograph |
| Hiking | Explore a new trail! | Reach a scenic viewpoint |
| Biking | Bike to a coffee shop! | Discover a new route |
| Swimming | Swim laps at the pool! | Count your strokes per lap |
| Climbing | Try bouldering problems! | Complete 3 routes you've never done |
| Other | Have a picnic in the park! | Bring a book and relax for 30 minutes |

**Template Variables (for personalization):**
- `{user_favorite_park}` → "Go for a run in Central Park!"
- `{nearby_landmark}` → "Walk to the Golden Gate Bridge!"
- `{typical_distance}` → "Run your usual 5K route backwards!"

**Template Count (MVP):** 50-100 curated templates across all categories

#### 4. **User Feedback Loop**

**Implicit Signals:**
- Activity completion (via "Log Activity" button)
- Activity skipped (card viewed but not logged)
- Activity type frequency (which categories get logged most)
- Time-to-completion (how quickly after viewing a card does user log it)

**Explicit Signals (Future):**
- "Not interested" button (downrank similar activities)
- Favorite/bookmark activities (uprank similar activities)
- Difficulty rating (too easy/too hard)

**Learning Mechanism:**
- Track completion rate per template
- Boost frequently completed activities
- Penalize never-completed activities
- Adjust difficulty based on user's typical logged activity intensity

---

## Technical Architecture

### Data Models

#### New Tables

**`daily_activity_recommendations`**
```sql
CREATE TABLE daily_activity_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recommendation_date DATE NOT NULL,
    activity_template_id INT NOT NULL REFERENCES activity_templates(id),
    card_position INT NOT NULL CHECK (card_position BETWEEN 1 AND 5),
    personalized_prompt TEXT NOT NULL,
    personalized_challenge TEXT,
    activity_type_id INT NOT NULL REFERENCES activity_types(id),
    estimated_duration_minutes INT,
    was_logged BOOLEAN DEFAULT FALSE,
    logged_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, recommendation_date, card_position)
);

CREATE INDEX idx_recommendations_user_date ON daily_activity_recommendations(user_id, recommendation_date);
```

**`activity_templates`**
```sql
CREATE TABLE activity_templates (
    id SERIAL PRIMARY KEY,
    activity_type_id INT NOT NULL REFERENCES activity_types(id),
    prompt_template TEXT NOT NULL,
    challenge_template TEXT,
    estimated_duration_minutes INT,
    difficulty_level INT CHECK (difficulty_level BETWEEN 1 AND 3), -- 1: Easy, 2: Medium, 3: Hard
    season_tags TEXT[], -- ['spring', 'summer', 'fall', 'winter'] or NULL for year-round
    requires_equipment BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_templates_activity_type ON activity_templates(activity_type_id);
```

**`user_activity_preferences`** (for algorithm tuning)
```sql
CREATE TABLE user_activity_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    preferred_activity_types INT[] DEFAULT '{}', -- Array of activity_type_id
    fitness_level INT DEFAULT 2 CHECK (fitness_level BETWEEN 1 AND 3),
    preferred_duration_minutes INT DEFAULT 30,
    last_updated TIMESTAMP DEFAULT NOW()
);
```

#### Modified Tables
- **`activities` table**: No changes needed (existing activity logging system remains)
- **`activity_types` table**: No changes needed (reuse existing 8 types)

### Removed Components

#### Deleted Tables (Post-Migration)
- `user_events` - User-curated events database
- `user_event_joins` - Event RSVP tracking
- `user_event_attendance` - API event attendance tracking
- `event_api_calls` - Rate limiting for API calls

#### Deleted Files
```
Services/
├── TicketmasterService.swift ❌
└── UserEventService.swift ❌

Models/
├── UserEvent.swift ❌
├── TicketmasterEvent.swift ❌
├── LocalEvent.swift ❌
└── UserEventJoin.swift ❌

Views/
├── CreateEventView.swift ❌
├── CommunityEventsView.swift ❌
├── LocalEventDetailView.swift ❌
├── LocationPickerView.swift ❌ (if only used for events)
└── EventFiltersView.swift ❌

Config/
└── TicketmasterConfig.swift ❌
```

#### Deleted Functions (Database)
- `cancel_user_event()`
- `join_user_event()`
- `has_user_joined_event()`
- `get_user_event_attendee_count()`
- `can_user_call_event_api()`
- `record_event_api_call()`
- `mark_event_attended()`

### New Services

**`ActivityRecommendationService.swift`**
```swift
class ActivityRecommendationService {
    // Generate 5 daily recommendations for a user
    func generateDailyRecommendations(userId: UUID, date: Date) async throws -> [ActivityRecommendation]

    // Fetch today's recommendations (cached)
    func getTodaysRecommendations(userId: UUID) async throws -> [ActivityRecommendation]

    // Manual refresh (rate limited)
    func refreshRecommendations(userId: UUID) async throws -> [ActivityRecommendation]

    // Mark recommendation as completed
    func logRecommendation(recommendationId: UUID) async throws

    // Fetch activity templates from DB
    func getActivityTemplates(filters: TemplateFilters) async throws -> [ActivityTemplate]

    // Personalize template with user context
    func personalizeTemplate(template: ActivityTemplate, user: User) -> ActivityRecommendation
}
```

**`RecommendationAlgorithm.swift`**
```swift
class RecommendationAlgorithm {
    // Core algorithm logic
    func selectActivities(
        candidatePool: [ActivityTemplate],
        userHistory: [Activity],
        userPreferences: UserActivityPreferences,
        recentRecommendations: [ActivityRecommendation]
    ) -> [ActivityTemplate]

    // Scoring functions
    func scoreTemplate(template: ActivityTemplate, context: UserContext) -> Double
    func calculateVarietyScore(templates: [ActivityTemplate]) -> Double
    func shouldFilterTemplate(template: ActivityTemplate, context: UserContext) -> Bool
}
```

### New Models

**`ActivityRecommendation.swift`**
```swift
struct ActivityRecommendation: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let recommendationDate: Date
    let activityTemplateId: Int
    let cardPosition: Int
    let personalizedPrompt: String
    let personalizedChallenge: String?
    let activityType: ActivityType
    let estimatedDurationMinutes: Int?
    var wasLogged: Bool
    var loggedAt: Date?
}
```

**`ActivityTemplate.swift`**
```swift
struct ActivityTemplate: Identifiable, Codable {
    let id: Int
    let activityTypeId: Int
    let promptTemplate: String
    let challengeTemplate: String?
    let estimatedDurationMinutes: Int?
    let difficultyLevel: Int // 1-3
    let seasonTags: [String]? // nil = year-round
    let requiresEquipment: Bool
    let isActive: Bool
}
```

### Updated Views

**`TouchGrassTab.swift` (Complete Rewrite)**
```swift
struct TouchGrassTab: View {
    @StateObject private var viewModel = RecommendationViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                headerView

                // Daily activity cards (5 max)
                ForEach(viewModel.todaysRecommendations) { recommendation in
                    ActivityRecommendationCard(
                        recommendation: recommendation,
                        onLog: { viewModel.logActivity(recommendation) }
                    )
                }

                // Empty state (if no recommendations)
                if viewModel.todaysRecommendations.isEmpty {
                    emptyStateView
                }

                // Refresh button (bottom)
                refreshButton
            }
            .padding()
        }
        .refreshable {
            await viewModel.refreshRecommendations()
        }
        .onAppear {
            Task {
                await viewModel.loadTodaysRecommendations()
            }
        }
    }
}
```

**`ActivityRecommendationCard.swift` (New Component)**
```swift
struct ActivityRecommendationCard: View {
    let recommendation: ActivityRecommendation
    let onLog: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Activity type icon + name
            HStack {
                Image(systemName: recommendation.activityType.icon)
                Text(recommendation.activityType.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }

            // Prompt
            Text(recommendation.personalizedPrompt)
                .font(.title3)
                .fontWeight(.semibold)

            // Challenge
            if let challenge = recommendation.personalizedChallenge {
                Text(challenge)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            // Duration + Action button
            HStack {
                if let duration = recommendation.estimatedDurationMinutes {
                    Label("\(duration) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onLog) {
                    Label("Log Activity", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .disabled(recommendation.wasLogged)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
```

**`RecommendationViewModel.swift` (New ViewModel)**
```swift
@MainActor
class RecommendationViewModel: ObservableObject {
    @Published var todaysRecommendations: [ActivityRecommendation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var refreshCount = 0

    private let service = ActivityRecommendationService()
    private let maxRefreshesPerDay = 3

    func loadTodaysRecommendations() async {
        // Fetch or generate today's recommendations
    }

    func refreshRecommendations() async {
        // Manual refresh with rate limit
    }

    func logActivity(_ recommendation: ActivityRecommendation) {
        // Mark as completed + create Activity log entry
    }
}
```

---

## Database Migration Plan

### Phase 1: Create New Tables (Non-Breaking)
1. Create `activity_templates` table
2. Create `daily_activity_recommendations` table
3. Create `user_activity_preferences` table
4. Seed `activity_templates` with 50-100 initial templates

### Phase 2: Deploy New Code (Parallel Systems)
1. Deploy new Touch Grass tab UI (feature flag off)
2. Deploy recommendation algorithm service
3. Test with internal users via feature flag
4. Monitor performance and recommendation quality

### Phase 3: Migrate Users (Graceful Transition)
1. Enable feature flag for 10% of users
2. Collect feedback and iterate
3. Gradual rollout to 50%, then 100%
4. Monitor completion rates and engagement

### Phase 4: Remove Old System (Breaking Changes)
1. Archive user-generated events data (backup to S3)
2. Drop old tables: `user_events`, `user_event_joins`, `user_event_attendance`, `event_api_calls`
3. Delete deprecated code files
4. Remove Ticketmaster API credentials
5. Update README.md documentation

### Rollback Plan
- Keep old tables for 90 days post-migration
- Maintain feature flag to revert to old system if needed
- Export user-generated events to JSON before deletion (for historical records)

---

## Algorithm Details (MVP Version)

### Step 1: Build Candidate Pool
```python
def build_candidate_pool(user_id):
    # Fetch all active templates
    templates = fetch_templates(is_active=True)

    # Filter by season (optional in MVP)
    current_season = get_current_season()
    templates = filter_by_season(templates, current_season)

    # Exclude recently recommended (last 7 days)
    recent_recs = fetch_recent_recommendations(user_id, days=7)
    recent_template_ids = [r.activity_template_id for r in recent_recs]
    templates = [t for t in templates if t.id not in recent_template_ids]

    return templates
```

### Step 2: Score Each Template
```python
def score_template(template, user_context):
    score = 0.0

    # 1. User preference match (40% weight)
    if template.activity_type_id in user_context.preferred_activity_types:
        score += 40.0

    # 2. Historical completion rate (30% weight)
    completion_rate = get_template_completion_rate(template.id, user_context.user_id)
    score += completion_rate * 30.0

    # 3. Difficulty match (20% weight)
    if template.difficulty_level == user_context.fitness_level:
        score += 20.0
    elif abs(template.difficulty_level - user_context.fitness_level) == 1:
        score += 10.0

    # 4. Recency penalty (10% weight)
    days_since_last_rec = get_days_since_template_recommended(template.id, user_context.user_id)
    if days_since_last_rec > 30:
        score += 10.0
    elif days_since_last_rec > 14:
        score += 5.0

    return score
```

### Step 3: Select Top 5 with Diversity
```python
def select_diverse_activities(scored_templates, count=5):
    selected = []
    activity_type_counts = {}

    # Sort by score descending
    scored_templates.sort(key=lambda x: x.score, reverse=True)

    for template in scored_templates:
        # Enforce diversity: max 2 activities per type
        type_id = template.activity_type_id
        if activity_type_counts.get(type_id, 0) >= 2:
            continue

        selected.append(template)
        activity_type_counts[type_id] = activity_type_counts.get(type_id, 0) + 1

        if len(selected) == count:
            break

    return selected
```

### Step 4: Personalize Prompts
```python
def personalize_template(template, user_context):
    prompt = template.prompt_template
    challenge = template.challenge_template

    # Replace variables (simple string replacement in MVP)
    if "{user_favorite_park}" in prompt:
        favorite_park = get_user_favorite_location(user_context.user_id)
        prompt = prompt.replace("{user_favorite_park}", favorite_park or "a local park")

    if "{typical_distance}" in prompt:
        avg_distance = get_user_avg_distance(user_context.user_id, template.activity_type_id)
        prompt = prompt.replace("{typical_distance}", f"{avg_distance} miles" if avg_distance else "your usual distance")

    return ActivityRecommendation(
        activity_template_id=template.id,
        personalized_prompt=prompt,
        personalized_challenge=challenge,
        activity_type=template.activity_type,
        estimated_duration_minutes=template.estimated_duration_minutes
    )
```

### Future Enhancements (Post-MVP)
1. **Weather Integration**: Filter/prioritize activities based on current weather conditions
2. **Social Layer**: Show activities friends have completed ("3 friends went hiking this week!")
3. **Streaks & Challenges**: "Complete 3 recommendations this week for a badge"
4. **Smart Timing**: Recommend morning activities in AM, evening activities in PM
5. **Location Intelligence**: Use GPS history to suggest nearby parks/trails
6. **Collaborative Filtering**: "Users like you also enjoyed..." recommendations
7. **Seasonal Events**: Inject timely activities (e.g., "See fall foliage" in October)

---

## User Experience Flow

### First-Time User Experience
1. **Day 1**: User opens Touch Grass tab
   - Sees 5 default beginner-friendly activities (no personalization yet)
   - Example: "Go for a 15-minute walk!", "Sit outside and read for 20 minutes!"
   - User logs 1 activity (Walking)

2. **Day 2**: Algorithm learns from Day 1
   - Increases walking recommendations
   - Adds 1-2 similar activities (hiking, outdoor yoga)
   - Maintains variety with 2 new activity types

3. **Day 7**: Strong personalization
   - 60% activities match user's top 2 logged types
   - 40% exploratory activities (biking, swimming) to encourage variety
   - Prompts reference user's frequent locations

### Daily Interaction Pattern
```
Morning (8-10 AM):
├─ User opens app → Touch Grass tab
├─ Sees 5 fresh recommendations
├─ Picks 1 activity: "Go for a morning run!"
├─ Taps "Log Activity" → Quick logging flow
└─ Returns to app later to log duration/distance

Evening (6-8 PM):
├─ User opens app again
├─ Sees same 5 recommendations (unchanged)
├─ Picks 2nd activity: "Take a sunset walk!"
└─ Logs activity with photo

Next Day:
├─ Midnight: New recommendations generated
└─ Cycle repeats
```

### Edge Cases
- **No recommendations generated**: Show fallback generic activities + error message
- **User exhausted all 5 activities**: Show "You crushed today! Check back tomorrow" message
- **Manual refresh limit exceeded**: Disable refresh button + show tooltip "Try again tomorrow!"
- **New user, no data**: Use population-wide activity completion rates for scoring

---

## Content Strategy

### Initial Template Library (50 Templates)

**Running (10 templates)**
1. Go for a morning run! | Beat yesterday's pace
2. Try sprint intervals! | 8 x 200m with rest
3. Run your usual route backwards! | Notice new details
4. Explore a new neighborhood! | Find a coffee shop mid-run
5. Run to a scenic viewpoint! | Take a photo at the top
6. Do a slow, easy recovery run! | Focus on breathing
7. Race a friend (virtually)! | Compare times later
8. Run hills for strength! | 5 x uphill sprints
9. Go for a sunset run! | Catch the golden hour
10. Try a trail run! | Get off the pavement

**Walking (8 templates)**
1. Take a 15-minute nature walk! | Count different bird species
2. Walk to a local landmark! | Learn its history
3. Go for a sunset stroll! | Find the best view
4. Walk with a podcast! | Finish one episode
5. Explore a new street! | Discover hidden gems
6. Take a mindful walk! | Leave your phone behind
7. Walk to grab coffee! | Try a new route
8. Go on a photo walk! | Capture 5 interesting things

**Hiking (8 templates)**
1. Hike to a waterfall! | Pack a snack for the destination
2. Try a new trail! | Rate the difficulty
3. Summit a local peak! | Check the weather first
4. Go on a sunrise hike! | Start early to beat the heat
5. Explore a forest trail! | Listen for wildlife
6. Hike with a friend! | Catch up on the trail
7. Do a loop trail! | See how fast you can complete it
8. Find a scenic overlook! | Take a panorama photo

**Biking (6 templates)**
1. Bike to a coffee shop! | Try a new cafe
2. Explore a bike path! | See where it leads
3. Do a hill climb! | Test your strength
4. Ride to a park! | Have a picnic
5. Try a new route! | Avoid your usual roads
6. Go for a sunset ride! | Chase the light

**Climbing (5 templates)**
1. Try 3 new boulder problems! | Ask others for beta
2. Work on a project route! | Make progress on that hard one
3. Go top-rope climbing! | Push your grade
4. Practice footwork! | Focus on technique
5. Climb outdoors! | Find a local crag

**Swimming (5 templates)**
1. Swim laps at the pool! | Count your strokes
2. Try open water swimming! | Find a lake or ocean
3. Do interval sprints! | 10 x 50m fast
4. Practice a new stroke! | Improve your butterfly
5. Swim for distance! | See how far you can go

**Kayaking (3 templates)**
1. Paddle a local lake! | Explore the shoreline
2. Try a river route! | Check water conditions
3. Kayak at sunset! | Bring a waterproof camera

**Other (5 templates)**
1. Do outdoor yoga! | Find a quiet spot
2. Have a picnic in the park! | Bring a book
3. Go stargazing! | Use a starmap app
4. Play frisbee! | Grab a friend
5. Sit outside and journal! | Reflect for 20 minutes

### Content Expansion Plan
- **Month 1-3 (MVP)**: 50 curated templates
- **Month 4-6**: Expand to 100 templates (add seasonal variants)
- **Month 7-12**: Reach 200 templates (add location-specific activities, e.g., "Visit Griffith Observatory" for LA users)
- **Year 2**: User-generated templates (crowdsourced, moderated)

---

## Implementation Plan

### Phase 1: Foundation ✅ COMPLETE
**Backend**
- [x] Create database tables (`activity_templates`, `daily_activity_recommendations`, `user_activity_preferences`)
- [x] Write database migration scripts
- [x] Implement RLS policies for new tables
- [x] Seed `activity_templates` with 50 initial templates
- [x] Create database functions for recommendation logic

**Frontend**
- [x] Design `ActivityRecommendationCard` component
- [x] Design new `TouchGrassTab` layout (mockups)
- [x] Create `ActivityTemplate` and `ActivityRecommendation` models

### Phase 2: Core Algorithm ✅ COMPLETE (MVP)
**Backend**
- [x] Implement recommendation algorithm (MVP version)
- [x] Build candidate pool generation logic
- [x] Build template scoring system
- [x] Build diversity selection logic
- [x] Implement seasonal filtering
- [ ] Implement template personalization (variable replacement) - *Deferred to V2*
- [ ] Add cron job/scheduled task for midnight recommendation generation - *Not needed in MVP*

**Services**
- [x] Implement `ActivityRecommendationService` (CRUD operations)
- [x] Add error handling and logging
- [ ] Write unit tests for algorithm logic - *Pending*

### Phase 3: Frontend Integration ✅ COMPLETE
**Views**
- [x] Implement new `TouchGrassTab` view
- [x] Implement `ActivityRecommendationCard` component
- [x] Implement `RecommendationViewModel`
- [x] Add pull-to-refresh functionality
- [x] Add manual refresh button (with rate limiting)
- [x] Design empty states and error states

**Integration**
- [x] Connect "Log Activity" button to existing activity logging system
- [ ] Test full user flow (view recommendations → log activity → see updated stats) - *Pending live testing*
- [ ] Add analytics tracking (card views, logs, refreshes) - *Deferred to V2*

### Phase 4: Testing & Refinement ⏳ PENDING
- [ ] Internal alpha testing with team (10 users x 7 days)
- [ ] Collect feedback on recommendation quality
- [ ] Tune algorithm parameters (weights, diversity rules)
- [ ] Fix bugs and edge cases
- [ ] Performance testing (database query optimization)

### Phase 5: Migration & Cleanup ⏳ PENDING
- [ ] Feature flag implementation (gradual rollout) - *Optional for MVP*
- [ ] Archive old event data (S3 export)
- [ ] Drop old database tables (post-rollout)
- [ ] Delete deprecated code files
- [ ] Update README.md documentation
- [ ] Update App Store screenshots and description

### Phase 6: Launch & Monitor 📋 PLANNED
- [ ] Beta launch to 10% of users
- [ ] Monitor engagement metrics (daily opens, completion rate)
- [ ] A/B test variations (e.g., 3 cards vs 5 cards)
- [ ] Collect user feedback via in-app survey
- [ ] Gradual rollout to 100% of users
- [ ] Iterate based on data

---

## Open Questions & Decisions Needed

### Technical Decisions
1. **Recommendation Generation Timing**: Generate at midnight server-time or user's local timezone?
   - **Decision**: ✅ On-demand generation (when user opens tab) - Simpler for MVP

2. **Personalization Variables**: How many location-based variables to support in MVP?
   - **Decision**: ✅ Deferred to V2 - MVP uses static templates without variable replacement

3. **Template Storage**: Hardcode templates in code or store in database?
   - **Decision**: ✅ Database (implemented) - Easier to add/edit templates without app updates

4. **Refresh Rate Limit**: 3 refreshes per day enough?
   - **Decision**: ✅ Implemented with 3 refreshes per day - Will adjust based on user feedback

5. **Logged Activity Connection**: Should "Log Activity" auto-populate activity type or let user change it?
   - **Decision**: ✅ Mark as logged only - Full activity creation deferred to V2

### Product Decisions
6. **Recommendation Count**: 3, 5, or 7 cards per day?
   - **Decision**: ✅ 5 cards (implemented) - Balanced choice

7. **Seasonal Filtering**: Should winter templates be hidden in summer?
   - **Decision**: ✅ Soft filtering implemented - Templates with season tags are preferred, but all-season activities always available

8. **Difficulty Levels**: Should we show difficulty badges on cards?
   - **Decision**: ✅ Not shown in MVP - Stored in database for future use

9. **Social Features**: Should cards show "X friends did this activity"?
   - **Decision**: ✅ Not in MVP - Deferred to V2

10. **Historical View**: Can users see past recommendations?
    - **Recommendation**: Not in MVP (adds complexity), add "History" tab in v2

### UX Decisions
11. **Card Order**: Should top card be "best" recommendation or random?
    - **Recommendation**: Top card = highest score (users read top-down)

12. **Empty State**: What if algorithm fails to generate 5 recommendations?
    - **Recommendation**: Show generic fallback activities + error reporting

13. **Onboarding**: Should new users see a tutorial?
    - **Recommendation**: No tutorial, but add subtle "Tap to log" hints on first use

---

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Algorithm produces repetitive recommendations | High | Medium | Implement diversity rules, track recency, add fallback variety boosters |
| Users miss old event discovery feature | Medium | Low | Communicate change clearly, offer feedback channel, consider separate "Events" tab in future |
| Low recommendation completion rate (<15%) | High | Medium | Start with easy activities, iterate based on completion data, add difficulty filtering |
| Template library feels generic/uninspiring | High | Medium | Invest in copywriting, add humor/personality, crowdsource templates from engaged users |
| Database performance issues (millions of daily recommendations) | Medium | Low | Index optimization, consider archiving old recommendations after 30 days |
| Users game the system (log without doing) | Low | Medium | Accept as edge case, focus on majority genuine users, add verification in v2 |
| Loss of community aspect (no more user events) | Medium | Medium | Track sentiment, consider adding "community challenges" or "group activities" in v2 |

---

## Success Criteria & Launch Checklist

### MVP Success Criteria (3 Months Post-Launch)
- ✅ 70%+ of active users receive 5 recommendations daily
- ✅ 25%+ recommendation completion rate (cards → logged activities)
- ✅ 3x increase in daily Touch Grass tab opens
- ✅ <5% user complaints about recommendation quality
- ✅ Zero critical bugs or data loss incidents
- ✅ 95th percentile recommendation generation time <500ms

### Launch Readiness Checklist
- [ ] All database migrations tested in staging
- [ ] 50+ activity templates loaded and QA'd
- [ ] Algorithm unit tests passing (>90% coverage)
- [ ] End-to-end user flow tested on iOS 15, 16, 17
- [ ] Feature flag implemented and tested
- [ ] Analytics events tracking correctly (recommendation_viewed, recommendation_logged, recommendation_refreshed)
- [ ] Error monitoring configured (Sentry/similar)
- [ ] README.md updated with new feature description
- [ ] App Store listing updated (screenshots, description)
- [ ] Internal team trained on new system
- [ ] User communication prepared (in-app announcement, email)
- [ ] Rollback plan documented and tested
- [ ] Old data archived and backed up

---

## Post-Launch Roadmap (Future Enhancements)

### V2 Features (Months 4-6)
- Weather-aware recommendations (filter rainy-day activities)
- Social layer ("3 friends went hiking this week")
- Activity history view (see past recommendations)
- "Not interested" feedback button
- Difficulty preference settings

### V3 Features (Months 7-12)
- Location intelligence (recommend nearby trails from GPS history)
- Seasonal events (autumn foliage hikes, spring wildflower walks)
- Collaborative filtering ("Users like you also enjoyed...")
- User-generated templates (moderated crowdsourcing)
- Streak challenges ("Complete 5 recommendations this week")

### V4 Features (Year 2+)
- AI-generated prompts (GPT-4 personalization)
- Voice-based recommendations (Siri integration)
- Wearable integration (Apple Watch complications)
- Group activity coordination (invite friends to join)
- Gamification (points, leaderboards, rare badges)

---

## Appendix

### A. Competitive Analysis

**Strava**: Activity tracking app with explore features
- ✅ Strong social features, activity trends
- ❌ No daily recommendation system
- **Learning**: Users value seeing what others do

**AllTrails**: Hiking/trail discovery app
- ✅ Excellent location-based recommendations
- ❌ Limited to hiking, no daily cadence
- **Learning**: Curated content quality matters

**Nike Run Club**: Running app with guided runs
- ✅ Audio-guided runs with coaches
- ❌ Focuses only on running, requires commitment
- **Learning**: Guidance reduces decision fatigue

**Fitbit**: Fitness tracker with challenges
- ✅ Daily step goals, adaptive challenges
- ❌ Generic fitness, not outdoor-specific
- **Learning**: Daily goals drive habit formation

### B. Sample Templates (Full List)

See **Content Strategy** section above for 50 MVP templates.

### C. Database Schema Diagram

```
┌─────────────────────────┐
│  activity_types         │
│  (existing table)       │
├─────────────────────────┤
│  id: INT (PK)           │
│  name: VARCHAR          │
│  icon: VARCHAR          │
└─────────────┬───────────┘
              │
              │ 1:N
              │
┌─────────────▼───────────┐
│  activity_templates     │
├─────────────────────────┤
│  id: SERIAL (PK)        │
│  activity_type_id: INT  │
│  prompt_template: TEXT  │
│  challenge_template: TEXT│
│  estimated_duration: INT│
│  difficulty_level: INT  │
│  season_tags: TEXT[]    │
│  requires_equipment: BOOL│
└─────────────┬───────────┘
              │
              │ 1:N
              │
┌─────────────▼───────────┐       ┌─────────────────────────┐
│ daily_activity_         │       │  users                  │
│ recommendations         │◄──────┤  (existing table)       │
├─────────────────────────┤  N:1  └─────────────────────────┘
│  id: UUID (PK)          │
│  user_id: UUID (FK)     │
│  recommendation_date: DATE│
│  activity_template_id: INT│
│  card_position: INT     │
│  personalized_prompt: TEXT│
│  personalized_challenge: TEXT│
│  activity_type_id: INT  │
│  estimated_duration: INT│
│  was_logged: BOOLEAN    │
│  logged_at: TIMESTAMP   │
└─────────────────────────┘

┌─────────────────────────┐       ┌─────────────────────────┐
│ user_activity_          │       │  users                  │
│ preferences             │◄──────┤  (existing table)       │
├─────────────────────────┤  1:1  └─────────────────────────┘
│  user_id: UUID (PK, FK) │
│  preferred_activity_    │
│    types: INT[]         │
│  fitness_level: INT     │
│  preferred_duration: INT│
│  last_updated: TIMESTAMP│
└─────────────────────────┘
```

### D. Glossary

- **Activity Card**: A visual recommendation component showing a suggested outdoor activity
- **Activity Template**: A reusable prompt structure with variables for personalization
- **Candidate Pool**: The set of all activity templates eligible for recommendation on a given day
- **Completion Rate**: Percentage of recommended activities that users log as completed
- **Diversity Score**: Metric measuring variety across recommended activity types
- **Personalization**: Process of injecting user-specific context into generic templates
- **Recommendation Refresh**: User-initiated action to generate a new set of 5 activities (rate limited)
- **Template Variable**: Placeholder in template text (e.g., `{user_favorite_park}`) replaced with user data

---

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-05-31 | Product Team | Initial PRD draft |

---

## Approval

| Stakeholder | Role | Status | Date | Signature |
|-------------|------|--------|------|-----------|
| TBD | Product Manager | Approved | 2026-05-31 | ✓ |
| TBD | Engineering Lead | Approved | 2026-05-31 | ✓ |
| TBD | Design Lead | Approved | 2026-05-31 | ✓ |
| TBD | Data Science | Approved | 2026-05-31 | ✓ |

---

## Implementation Status

**Implementation Completed:** May 31, 2026

### ✅ Phase 1: Foundation (Complete)

**Database Schema:**
- ✅ Created `activity_templates` table with 50 seed templates
- ✅ Created `daily_activity_recommendations` table
- ✅ Created `user_activity_preferences` table
- ✅ Implemented RLS policies for all new tables
- ✅ Created database functions:
  - `get_todays_recommendations()`
  - `mark_recommendation_logged()`
  - `get_user_activity_type_preferences()`
  - `get_template_completion_rate()`

**Models:**
- ✅ `ActivityTemplate.swift` - Template data model
- ✅ `ActivityRecommendation.swift` - Recommendation data model with response mapping
- ✅ `UserActivityPreferences.swift` - User preference model

### ✅ Phase 2: Core Services (Complete)

**Backend Services:**
- ✅ `ActivityRecommendationService.swift` - Full CRUD operations for recommendations
  - Fetch today's recommendations
  - Generate daily recommendations (MVP algorithm)
  - Mark recommendations as logged
  - Template selection with variety and seasonal filtering

**Algorithm Implementation:**
- ✅ MVP recommendation algorithm with:
  - Seasonal filtering
  - Activity type variety (max 2 per type)
  - User preference consideration
  - Random selection within constraints

### ✅ Phase 3: Frontend Integration (Complete)

**Views:**
- ✅ `ActivityRecommendationCard.swift` - Beautiful card component with:
  - Activity type icon and name
  - Personalized prompt and challenge
  - Duration badge
  - Log Activity button
  - Completed state indicator

- ✅ `TouchGrassTab.swift` - Complete rewrite with:
  - Header with today's date
  - Progress indicator
  - 5 daily recommendation cards
  - Pull-to-refresh functionality
  - Manual refresh button (rate limited to 3x/day)
  - Loading, error, and empty states
  - Theme integration

**ViewModels:**
- ✅ `RecommendationViewModel.swift` - State management with:
  - Load recommendations
  - Manual refresh with rate limiting
  - Log activity functionality
  - Progress tracking

### 🚧 Phase 4: Migration & Cleanup (Pending)

**Not Yet Implemented:**
- ⏳ Delete deprecated event-related Swift files:
  - `TicketmasterService.swift`
  - `UserEventService.swift`
  - `EventViewModel.swift`
  - `TicketmasterConfig.swift`
  - `LocalEvent.swift`, `UserEvent.swift`, `TicketmasterEvent.swift`
  - `CreateEventView.swift`, `CommunityEventsView.swift`, etc.

- ⏳ Drop old database tables (after data backup):
  - `user_events`
  - `user_event_joins`
  - `user_event_attendance`
  - `event_api_calls`

- ⏳ Remove database functions:
  - `cancel_user_event()`
  - `join_user_event()`
  - `has_user_joined_event()`
  - `get_user_event_attendee_count()`
  - `can_user_call_event_api()`
  - `record_event_api_call()`
  - `mark_event_attended()`

### 📋 Implementation Notes

**Files Created:**
1. `Models/ActivityTemplate.swift`
2. `Models/ActivityRecommendation.swift`
3. `Models/UserActivityPreferences.swift`
4. `Services/ActivityRecommendationService.swift`
5. `Views/ActivityRecommendationCard.swift`
6. `ViewModels/RecommendationViewModel.swift`

**Files Modified:**
1. `schema.sql` - Added new tables, functions, RLS policies, and seed data
2. `Views/TouchGrassTab.swift` - Complete rewrite

**Key Features Implemented:**
- ✅ Daily personalized recommendations (5 cards per day)
- ✅ Simple MVP algorithm with variety and seasonal filtering
- ✅ Activity logging integration
- ✅ Progress tracking with visual indicator
- ✅ Manual refresh with rate limiting (3x per day)
- ✅ Pull-to-refresh support
- ✅ Beautiful card-based UI
- ✅ Loading, error, and empty states
- ✅ Full Supabase integration with RLS

**Database Seeds:**
- ✅ 50 activity templates across 8 categories:
  - 10 Running templates
  - 8 Walking templates
  - 8 Hiking templates
  - 6 Cycling templates
  - 5 Climbing templates
  - 5 Swimming templates
  - 3 Kayaking templates
  - 5 Other templates

### 🚀 Deployment Checklist

**Database Deployment:**
- [ ] Back up existing event data (if needed)
- [ ] Run updated `schema.sql` in Supabase
- [ ] Verify activity templates are seeded (should have 50 rows)
- [ ] Test database functions via SQL editor
- [ ] Verify RLS policies are enabled

**iOS App Deployment:**
- [ ] Build and run app in Xcode
- [ ] Test recommendation generation
- [ ] Test logging activities
- [ ] Test refresh functionality
- [ ] Test progress tracking
- [ ] Verify theme integration

**Monitoring:**
- [ ] Track daily recommendation generation
- [ ] Monitor activity completion rates
- [ ] Track refresh usage patterns
- [ ] Monitor database performance

### 📊 Success Metrics (To Be Measured)

After deployment, track these metrics:
- Daily Touch Grass tab opens (target: 3x increase)
- Activity completion rate (target: >25%)
- Average recommendations viewed per day
- Refresh feature usage
- User retention impact

### 🎯 Future Enhancements (Post-MVP)

**V2 Planned Features:**
- Weather-aware recommendations
- Social layer ("3 friends did this")
- Activity history view
- "Not interested" feedback
- Difficulty preference settings
- Enhanced personalization algorithm

**V3 Planned Features:**
- Location intelligence (nearby trails)
- Seasonal events (foliage, wildflowers)
- Collaborative filtering
- User-generated templates
- Streak challenges

---

**End of PRD**
