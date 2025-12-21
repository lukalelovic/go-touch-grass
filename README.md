# Go Touch Grass

A new iOS social media and personal tracking app for all activities done outside.

Limited to *three* activity posts per day to prevent spam, and to also get off the app and actually do some activities (this also helps rate limit users).

Follow your friends to see what they are up to outside, and track your own activities. Earn badges for each new type of activity you do, and earn levels in each type that you're persistent in.

## Tech Stack
| Layer         | Choice                              |
| ------------- | ----------------------------------- |
| Frontend        | SwiftUI                             |
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
- [ ] Install latest Xcode
- [ ] Create new iOS App project
  - [ ] Interface: SwiftUI
  - [ ] Language: Swift
  - [ ] Minimum iOS version: current – 1
- [ ] Run app successfully on simulator
- [ ] Set up Git repository
- [ ] Add basic README

### Phase 1 — SwiftUI Foundations (No Backend)
Goal: App is fully navigable with fake data

#### App Structure
- [ ] Set up TabView
  - [ ] Feed tab
  - [ ] Log Activity tab
  - [ ] Profile tab
- [ ] Create NavigationStack per tab

#### Data Models
- [ ] Create Activity model
- [ ] Create User model (minimal)

#### Feed Screen
- [ ] Display list of activities
- [ ] Activity row shows:
  - [ ] Username
  - [ ] Activity type
  - [ ] Timestamp
  - [ ] Photo placeholder
- [ ] Tap activity → Activity Detail screen

#### Activity Detail Screen
- [ ] Large photo placeholder
- [ ] Notes / description
- [ ] Map placeholder
- [ ] “Nice” button (no functionality yet)

#### Log Activity Screen
- [ ] Activity type picker
- [ ] Notes text field
- [ ] Optional photo placeholder
- [ ] Save button adds activity to in-memory list

#### Profile Screen
- [ ] Username display
- [ ] Activity streak placeholder
- [ ] List of recent activities

### Phase 2 — Architecture Cleanup (Still No Backend)
Goal: Introduce MVVM without overengineering

- [ ] Create ActivityViewModel
- [ ] Move activity logic out of views
- [ ] Use Observable / ObservableObject
- [ ] Inject view models via StateObject / EnvironmentObject
- [ ] Remove logic from SwiftUI views where possible

### Phase 3 — Backend (Minimal + Cost-Safe)
Goal: Replace fake data with real persistence

#### Supabase Setup
- [ ] Create Supabase project
- [ ] Set hard spending limit
- [ ] Enable email or anonymous auth
- [ ] Add Supabase Swift SDK

#### Auth
- [ ] Anonymous or email sign-in
- [ ] Store user session
- [ ] Handle logged-out
