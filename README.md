# Go Touch Grass

![Feed Tab](media/image.png)
![Profile Tab](media/image-1.png)

A new iOS social media and personal tracking app for all activities done outside.

Limited to *one* activity post per day to prevent spam, and encourage getting off the app and actually doing some activities (this also helps rate limit users and with pricing). Users on an eventual 'Pro' tier can post unlimited 'Touch Grass' activities per day.

Follow your friends to see what they are up to outside, and track your own activities. Earn badges for each new type of activity you do, and earn levels in each type that you're persistent in.

## Setup Instructions

### Prerequisites
- Xcode (latest version)
- A Supabase account and project

### Supabase Configuration
1. Create a Supabase project at [https://supabase.com](https://supabase.com)
2. Navigate to your project settings: `Settings > API`
3. Copy your **Project URL** and **anon/public key**
4. In the project directory, navigate to `Go Touch Grass/Go Touch Grass/Config/`
5. Copy `SupabaseConfig.swift.template` to `SupabaseConfig.swift`
6. Open `SupabaseConfig.swift` and replace the placeholder values:
   ```swift
   enum SupabaseConfig {
       static let url = "https://your-project-id.supabase.co"  // Your Project URL
       static let anonKey = "your-anon-key-here"               // Your anon/public key
   }
   ```
7. **IMPORTANT**: Never commit `SupabaseConfig.swift` to version control (it's already gitignored)

### Email Auth in Supabase

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Navigate to **Authentication** → **Providers** in the left sidebar
4. Find **Email** in the providers list
5. Make sure **Enable Email provider** is toggled ON
6. Configure the following settings:
   - **Confirm email:** Toggle OFF for development (toggle ON for production)
   - **Secure email change:** Toggle ON (recommended)
   - **Secure password change:** Toggle ON (recommended)
7. Click **Save**

### Register for Ticketmaster Discovery API
1. Go to https://developer.ticketmaster.com/
2. Click "Get Your Free API Key" or "Sign Up"
3. Create an account with your email
4. Once logged in, navigate to "My Apps" or "Get API Key"
5. Create a new app and you'll receive:
    - API Key (Consumer Key)
    - API Secret (optional, not needed for Discovery API)
6. Copy-paste the consumer key into the api-key variable in TicketmasterConfig.swift.template and rename this file to TicketmasterConfig.swift
The free tier gives you 5,000 API calls per day with a rate limit of 5 requests per second.

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


## TODO

- [ ] More Database Activity Types (Gym w/ subtypes, Cleaning, Dinner, Movie, Park)
- [ ] Improve event retrieval and leverage better event APIs
- [ ] Show list of attended events on user profile (with dates)
- [ ] Pro-tier: Pricing, enhanced event recommendations, unlimited activities per day
- [ ] Support event creation for only good-standing users (older account, good posts)
- [ ] Terms of Service, privacy policy, risk warnings
- [ ] Deploy and publish
