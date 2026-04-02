# RideOn Admin Panel — Claude Instructions

## Project Info
- App: RideOn Admin Panel (Flutter Web)
- Backend: Supabase
- Router: GoRouter
- State: setState (no Provider/Riverpod)
- Maps: flutter_map + OpenStreetMap
- Tables: DataTable2 package

## Supabase Tables
- profiles (id, full_name, phone_number, email, 
  is_admin, is_banned)
- rides (id, driver_id, origin, destination, 
  ride_date, departure_time, fare_per_seat, 
  total_seats, status, created_at)
- bookings (id, ride_id, user_id, seats_booked, 
  status, created_at)
- sos_alerts (id, user_id, latitude, longitude, 
  created_at) — NO status column!
- documents (id, user_id, doc_type, file_url, 
  status, created_at)

## Critical Rules
1. NEVER add Expanded inside SingleChildScrollView
2. NEVER use Flexible inside horizontal ScrollView
3. DataTable ALWAYS use dataRowHeight (not min/max)
4. ListView inside Column MUST have Expanded wrapper
5. Always use mounted check before setState
6. All async functions need try/catch/finally
7. Supabase RLS is enabled — admin queries may fail

## File Structure
lib/
  screens/
    dashboard/dashboard_screen.dart
    users/users_screen.dart
    documents/documents_screen.dart
    sos/sos_screen.dart
    rides/rides_screen.dart
    bookings/bookings_screen.dart
  services/
    supabase_service.dart
  models/
    ride_model.dart
    user_model.dart

## What is Working — DO NOT TOUCH
- Login/auth flow
- Dashboard stats cards
- SOS map widget (flutter_map)
- Document approve/reject buttons
- GoRouter navigation
- Sidebar navigation

## Known Issues
- sos_alerts table has NO 'status' column
  Use 'is_resolved': true (boolean) instead
- Bookings table has NO foreign key to profiles
  Fetch passenger separately using user_id
- Auto-expire rides fail due to RLS policy
  Filter expired rides on frontend instead
- Rides status values: active, scheduled, 
  completed, cancelled, ongoing

## UI Standards
- Sidebar width: 220px expanded, 64px collapsed
- Card max height: 110px
- Font sizes: title 14, subtitle 12, label 11
- All text in Hinglish (Hindi + English mix)
- Currency always in ₹ INR
- Dates in Indian format (DD MMM YY)

## OpenRouter Model
- Current: stepfun/step-3.5-flash:free
- Fallback: meta-llama/llama-3.3-70b-instruct:free
- Rate limit: 200 requests/day

## Do's
- Read file before editing
- Make surgical changes only
- Confirm what changed after every edit
- Test on /users, /rides, /documents screens

## Don'ts  
- Don't change working screens
- Don't add new packages without asking
- Don't remove existing Supabase queries
- Don't use print() excessively in production