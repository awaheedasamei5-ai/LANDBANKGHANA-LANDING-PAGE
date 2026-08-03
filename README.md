# LandBank Ghana — Landing Page

Public marketing site for **landbankghana.com**, plus a small admin dashboard for
managing homepage content (hero banner, stats, client logos, social links,
contact details) and viewing contact-form submissions.

This is a standalone project — separate from the internal PEP Landbank sales
portal repo, with its own Supabase backend.

## Structure

- `index.html` — the public landing page (single file, no build step).
- `admin/index.html` — password-protected content admin dashboard.
- `assets/logo.svg` — the LandBank Ghana logo (recreated as SVG from the logo
  image you shared, so it's crisp at any size — swap this file directly if
  you'd rather use your original artwork).
- `assets/supabase-config.js` — the Supabase project URL + public anon key
  shared by both `index.html` and `admin/index.html`.
- `supabase/schema.sql` — a record of the database schema (tables + security
  policies) already applied to the Supabase project. You don't need to run
  this yourself; it's there for reference/history.

## Backend

A **new, separate Supabase project** was created for this site (name:
`landbankghana-website`), independent of the internal sales-portal database.
It holds:

- `banners` — hero headline/subheadline/badge text shown on the homepage.
- `stats` — the number tiles (e.g. "7+ Years Experience").
- `clients` — the "Trusted by" logo strip (seeded with Trulander Jsf Limited).
- `social_links` — social icons shown in the contact section + footer.
- `site_settings` — phone/WhatsApp/email/office address.
- `leads` — every contact-form submission from the homepage.
- `admins` — the invite list of who's allowed to log into `/admin`.

Anyone can **read** banners/stats/clients/social links/settings (that's what
makes the public homepage work) and anyone can **submit** the contact form.
Only signed-in admins can add/edit/delete content or view leads — enforced by
Postgres Row Level Security, not just the frontend.

## Using the admin dashboard

1. Go to `/admin/` on your deployed site.
2. Click **Activate account**, enter your email
   (`awaheedasamei5@gmail.com` is already invited) and choose a password.
3. From then on, use **Sign in** with that email/password.
4. To invite a teammate later, ask me to add their email to the `admins`
   table (or run `insert into public.admins(email) values ('teammate@email');`
   in the Supabase SQL editor) — then they can activate their own account the
   same way.

## Deploying

Same flow as any static site:

1. Push this repo to GitHub (already done if you're reading this from the repo).
2. In Netlify: **Add new site → Import an existing project → GitHub** → pick
   this repo. Build command: empty. Publish directory: `/`. Deploy.
3. Point `landbankghana.com` at the Netlify site (Netlify → Domain settings →
   Add custom domain, then update your domain's DNS as instructed).

## What still needs your input

This page was built with your logo and starting copy, but a few things are
intentionally left as placeholders for you to swap in via the admin dashboard
or by sending me the assets:

- **Hero art** — the homepage currently uses an abstract geometric graphic
  (land-parcel outlines + a map pin) since we don't have real photography yet.
  Send me photos (site visits, handovers, team photos) and I can swap it in.
- **Stats numbers** — years of experience, acres secured, client count, etc.
  are placeholder figures. Edit them anytime under **Stats** in the admin
  dashboard.
- **Contact details** — phone, WhatsApp, email, and office address are blank
  until you fill them in under **Contact Info** in the admin dashboard.
- **Client logos** — only Trulander Jsf Limited is seeded in. Add more any
  time under **Clients**, with an optional logo upload.
- **Client stories / testimonials** — deliberately left as an honest
  "coming soon" empty state rather than invented quotes. Send me real
  references when you have them and I'll wire up a proper section.
- **Social links** — none are set yet; add your Facebook/Instagram/LinkedIn/
  TikTok/WhatsApp links under **Social Links** and they'll appear automatically.
