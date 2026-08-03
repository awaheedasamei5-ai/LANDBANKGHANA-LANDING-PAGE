# LandBank Ghana — Landing Page

Public marketing site for **landbankghana.com**, plus an admin dashboard for
managing homepage content (banners, photos, stats, clients, social links,
news, contact details, staff accounts) and viewing contact-form submissions.

This is a standalone project — separate from the internal PEP Landbank sales
portal repo, with its own Supabase backend.

## Structure

- `index.html` — the public landing page (single file, no build step).
- `admin/index.html` — password-protected content admin dashboard.
- `assets/logo.svg` — the LandBank Ghana logo (recreated as a vector from the
  image shared in chat — see "Logos" below).
- `assets/trulander-logo.svg` — Trulander Jsf Limited's logo, same situation.
- `assets/supabase-config.js` — the Supabase project URL + public anon key
  shared by both `index.html` and `admin/index.html`.
- `supabase/schema.sql` — a record of the database schema (tables + security
  policies) already applied to the Supabase project. You don't need to run
  this yourself; it's there for reference/history.

## Logos

Both logos are **recreations**, not your original files. Images pasted or
dropped directly into a chat message can be *seen* but not saved as an actual
file — there's no way to extract the real pixels from that. To use your exact
original artwork, upload the logo files somewhere I can fetch them from (e.g.
a Google Drive/Dropbox share link, or directly into the admin dashboard once
the site is live), and I'll swap them in exactly as-is.

## Backend

A **new, separate Supabase project** was created for this site (name:
`landbankghana-website`), independent of the internal sales-portal database.
It holds:

- `banners` — `kind='hero'` controls the homepage headline/subtext/badge;
  `kind='promo'` banners are slides in the animated advertisement carousel.
- `content_blocks` — photo placements: three fixed "named spots" (hero, about,
  process section) plus an open-ended gallery — see below.
- `stats` — the number tiles (e.g. "7+ Years Experience").
- `clients` — the "Trusted by" logo strip (seeded with Trulander Jsf Limited),
  each with optional Facebook/Instagram/TikTok links — clicking a client with
  socials set pops open icon links to their pages.
- `social_links` — your own social icons shown in the contact section +
  footer (seeded with real Instagram, Facebook, TikTok, WhatsApp).
- `news` — announcements shown in the site's notification-bell panel.
- `site_settings` — phone/WhatsApp/email/office address/urgent call number
  (seeded with WhatsApp +233 54 641 6566 and email
  digitalopsofficer@landbankghana.com; office address is still a placeholder).
- `leads` — every contact-form submission from the homepage.
- `admins` — staff accounts: invite list, claimed status, display name, avatar.

Anyone can **read** public content (banners/photos/stats/clients/social/news/
settings — that's what makes the homepage work) and anyone can **submit** the
contact form. Only signed-in admins can add/edit/delete content or view leads
— enforced by Postgres Row Level Security, not just the frontend.

## What's on the homepage now

- Sticky nav (Home/About/Services/Contact), hero, "Trusted by" clients strip
  with clickable social popovers, an animated promo banner carousel (hidden
  until you add a promo banner), "How We Help" cards, the buyer/seller
  qualifier questions, a 5-step process timeline, stats, About Us, an
  open-ended photo gallery (hidden until you add a photo), an honest
  "stories coming soon" placeholder instead of fake testimonials, and a
  contact form.
- Floating WhatsApp button (bottom-right).
- Floating, **draggable** notification bell (bottom-left, drag it anywhere —
  position is remembered) that opens a slide-in panel of your **News** items,
  with a red dot when there's something new.
- A "Need to talk to staff urgently?" button that dials your urgent-call
  number directly on mobile (`tel:` link) — pill-shaped on desktop, icon-only
  on mobile so it doesn't crowd the WhatsApp button.

## Adding photos yourself (no code needed)

In `/admin` → **Photos & Gallery**:

- **Named spots** — Hero photo, About section photo, Process section photo.
  Each replaces a specific piece of built-in artwork. Leave one empty (or hit
  "Remove photo") and that spot keeps its default look.
- **Gallery** — add as many photos as you want, with an optional caption.
  They show up automatically in a "More from LandBank Ghana" section — hidden
  until you add at least one.

In `/admin` → **Hero & Banners**, set "Kind" to **Promo** to add a slide to
the advertisement carousel (image + optional click-through link).

Every image field accepts either a pasted URL or a direct file upload
(resized client-side before saving).

## Staff accounts — how login works

There is **no default password** — that would be a security hole (anyone
could log in). Instead:

1. An email has to be **invited** first (already done for
   `awaheedasamei5@gmail.com`).
2. That person goes to `/admin`, clicks **Activate account**, enters their
   invited email, and **chooses their own password** — this creates their
   account.
3. From then on they just **Sign in** with that email + the password they chose.

To invite a teammate: sign in, go to **Team**, enter their email under
"Invite a teammate" — no SQL needed. The **Team** panel also lets you set
your own display name + profile photo, and remove a teammate's access later.

We kept this simple email/password system rather than "Sign in with Google" —
Google OAuth would need you to create credentials in the Google Cloud Console
first (a manual setup step on your end), whereas this works immediately with
zero external accounts. Happy to wire up Google sign-in later if you'd prefer
it once you're ready to set that up.

## Deploying (do this to actually see live data)

Opening `index.html` by double-clicking it only shows the static fallback
text — browsers restrict a `file://` page's ability to fetch live data from
Supabase, so banners/stats/clients/news/contact info won't populate until the
site is served over http(s). Deploying takes about 2 minutes and is the real
target anyway:

1. Push this repo to GitHub (already done if you're reading this from the repo).
2. In Netlify: **Add new site → Import an existing project → GitHub** → pick
   this repo. Build command: empty. Publish directory: `/`. Deploy.
3. Point `landbankghana.com` at the Netlify site (Netlify → Domain settings →
   Add custom domain, then update your domain's DNS as instructed).

Once deployed, everything — contact info, social icons, WhatsApp button,
urgent call button, news bell, client popovers — will populate from the
database automatically.

## What still needs your input

- **Your real logo files** (LandBank + Trulander) — see "Logos" above.
- **The 4 advertisement banner images** you shared — once the site is
  deployed, upload them yourself under **Hero & Banners** (set Kind = Promo)
  and they'll appear in the animated carousel exactly as designed, or send me
  a link to fetch them from and I'll add them for you.
- **Hero / About / Process photos** — currently abstract geometric artwork;
  add real ones anytime under **Photos & Gallery**.
- **Stats numbers** — years of experience, acres secured, client count, etc.
  are placeholder figures. Edit anytime under **Stats**.
- **Office address** — phone, WhatsApp, and email are set; office address is
  still blank until filled in under **Contact Info**.
- **Client logos** — only Trulander Jsf Limited is seeded in. Add more under
  **Clients**, each with optional social links for the click-to-reveal popover.
- **Client stories / testimonials** — deliberately left as an honest
  "coming soon" empty state rather than invented quotes. Send real references
  when you have them and I'll wire up a proper section.
