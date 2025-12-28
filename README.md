# Go Touch Grass

A new iOS social media and personal tracking app for all activities done outside.

Limited to *one* activity post per day to prevent spam, and encourage getting off the app and actually doing some activities (this also helps rate limit users and with pricing). Users on an eventual 'Pro' tier can post unlimited 'Touch Grass' activities per day.

Follow your friends to see what they are up to outside, and track your own activities. Earn badges for each new type of activity you do, and earn levels in each type that you're persistent in.

## Tech Stack
| Layer         | Choice                              |
| ------------- | ----------------------------------- |
| Frontend      | SwiftUI                             |
| State         | MVVM                                |
| Auth          | Supabase Auth                       |
| DB            | PostgreSQL                          |
| Realtime      | Supabase Realtime (limited)         |
| Media         | Supabase Storage                    |
| Backend Logic | Supabase Edge Functions             |
| Maps          | MapKit                              |
| Analytics     | PostHog (self-host later if needed) |


## Development Checklist

### Phase 0 — Project Setup
- [x] Install latest Xcode
- [x] Create new iOS App project
  - [x] Interface: SwiftUI
  - [x] Language: Swift
  - [x] Minimum iOS version: current – 1
- [x] Run app successfully on simulator
- [x] Set up Git repository
- [x] Add basic README

### Phase 1 — SwiftUI Foundations (No Backend)
Goal: App is fully navigable with fake data

#### App Structure
- [x] Set up TabView
  - [x] Feed tab
  - [x] Log Activity tab
  - [x] Profile tab
- [x] Create NavigationStack per tab

#### Data Models
- [x] Create Activity model
- [x] Create User model (minimal)

#### Feed Screen
- [x] Display list of activities
- [x] Activity row shows:
  - [x] Username
  - [x] Activity type
  - [x] Timestamp
- [x] Tap activity → Activity Detail screen

#### Activity Detail Screen
- [x] Notes / description
- [x] Map placeholder
- [x] “Nice” button (no functionality yet)

#### Share Activity Screen
- [x] Activity type picker
- [x] Notes text field
- [x] Location picker
- [x] Save button adds activity to in-memory list

#### Profile Screen
- [x] Username display
- [x] Activity streak placeholder
- [x] List of recent activities

#### Touch Grass Screen
- [x] Local activities in a user's area (static data for now)

### Phase 2 — Architecture Cleanup (Still No Backend)
Goal: Introduce MVVM without overengineering

- [x] Create FeedViewModel
- [x] Create ShareViewModel
- [x] Create EventViewModel
- [x] Create ProfileViewModel
- [x] Move activity logic out of views
- [x] Use Observable / ObservableObject
- [x] Inject view models via StateObject
- [x] Remove logic from SwiftUI views where possible

### Phase 3 — Backend (Minimal + Cost-Safe)
Goal: Replace fake data with real persistence

#### Supabase Setup
- [x] Create Supabase project
- [x] Choose free tier to start
- [ ] Set hard spending limit
- [ ] Enable email or anonymous auth
- [x] Add Supabase Swift SDK
- [ ] Connect views/models to supabase via PostgREST

#### Auth
- [ ] Apple sign-in
- [ ] Store user session
- [ ] Handle log out

#### Database Architecture
- [x] User database objects
- [x] Activity database objects
- [x] Activity types table
- [x] Activity subtypes
- [x] Activity likes
- [x] User badges and levels

### Phase 4 - Fully Fledged Features

#### More Activity Types
- [ ] Gym with subtypes (Push, Pull, Leg, Cardio)
- [ ] Cooking Class
- [ ] Dinner
- [ ] Movie
- [ ] Bar
- [ ] Basketball
- [ ] Football
- [ ] Soccer
- [ ] Groceries
- [ ] Cleaning
- [ ] Coffee
- [ ] Etc

### Enhanced Profiles
- [ ] Public/private access
- [ ] 'Friendship' requests
- [ ] Badges
- [ ] Badge levels
- [ ] Settings page (change username, pfp, delete account, export activities)

### Phase 5 - App Rollout

### Free and Pro-Tiers
- [ ] Pro-tier pricing and ecommerce logic
- [ ] Support unlimited activity posts per day based on a user's tier
- [ ] Event recommendations based on a user's preferred/most common activities

### iOS publication
- [ ] Terms of Service, privacy policy, risk warnings
- [ ] iOS page
- [ ] App logo