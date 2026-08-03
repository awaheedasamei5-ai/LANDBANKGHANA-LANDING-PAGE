# LandBank Ghana — Landing Page

Public marketing site for **landbankghana.com**, plus a small admin dashboard for
managing homepage content (hero banner, photos, stats, client logos, social
links, contact details) and viewing contact-form submissions.

This is a standalone project — separate from the internal PEP Landbank sales
portal repo, with its own Supabase backend.

## Structure

- `index.html` — the public landing page (single file, no build step).
- `admin/index.html` — password-protected content admin dashboard.
- `assets/logo.svg` — the LandBank Ghana logo. This is currently a **recreation**
  from the logo image pasted in chat, not your original file — pasted images
  can't be saved from chat as real files, so send the actual logo file as an
  attachment and I'll swap it in directly.
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
- `content_blocks` — photo placements: three fixed "named spots" (hero, about,
  process section) plus an open-ended gallery — see below.
- `stats` — the number tiles (e.g. "7+ Years Experience").
- `clients` — the "Trusted by" logo strip (seeded with Trulander Jsf Limited).
- `social_links` — social icons shown in the contact section + footer
  (seeded with your real Instagram, Facebook, TikTok, and WhatsApp).
- `site_settings` — phone/WhatsApp/email/office address (seeded with your
  WhatsApp +233 54 641 6566 and email digitalopsofficer@landbankghana.com;
  office address is still a placeholder).
- `leads` — every contact-form submission from the homepage.
- `admins` — the invite list of who's allowed to log into `/admin`.

Anyone can **read** banners/content/stats/clients/social links/settings
(that's what makes the public homepage work) and anyone can **submit** the
contact form. Only signed-in admins can add/edit/delete content or view
leads — enforced by Postgres Row Level Security, not just the frontend.

## Adding photos yourself (no code needed)

In `/admin` → **Photos & Gallery**:

- **Named spots** — Hero photo, About section photo, Process section photo.
  Each replaces a specific piece of built-in artwork on the homepage. Leave
  one empty (or hit "Remove photo") and that spot keeps its default look.
- **Gallery** — add as many photos as you want, with an optional caption.
  They show up automatically in a "More from LandBank Ghana" section on the
  homepage — this section stays hidden until you add at least one photo.
  This is the easiest way to drop in new images (site visits, team photos,
  handovers, etc.) without touching any other setting.

Every image field accepts either a pasted URL or a direct file upload
(resized client-side before saving).

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

- **Your real logo file** — sent as an attachment, not pasted inline (see above).
- **Hero / About / Process photos** — the homepage currently uses abstract
  geometric artwork in these three spots since we don't have real photography
  yet. Add them anytime under **Photos & Gallery** in the admin dashboard, or
  send me the images and I'll add them for you.
- **Stats numbers** — years of experience, acres secured, client count, etc.
  are placeholder figures. Edit them anytime under **Stats** in the admin
  dashboard.
- **Office address** — phone, WhatsApp, and email are set; the office address
  is still blank until you fill it in under **Contact Info**.
- **Client logos** — only Trulander Jsf Limited is seeded in. Add more any
  time under **Clients**, with an optional logo upload.
- **Client stories / testimonials** — deliberately left as an honest
  "coming soon" empty state rather than invented quotes. Send me real
  references when you have them and I'll wire up a proper section.
