// Shared Supabase connection details for the LandBank Ghana site + admin dashboard.
// The anon/publishable key below is safe to expose in client-side code — it can only
// do what the database's Row Level Security policies allow (public read of site
// content, public insert of contact-form leads, everything else requires an
// authenticated admin). See /supabase/schema.sql for the full policy set.
window.LANDBANK_SUPABASE_URL = 'https://azweseaslsymvuilungg.supabase.co';
window.LANDBANK_SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF6d2VzZWFzbHN5bXZ1aWx1bmdnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU3NzE3NTcsImV4cCI6MjEwMTM0Nzc1N30.6xEyAPvL8bj4LKdiVJujq4VGj71ZpUxZ_tLcK54snsE';
