# LandBank Ghana — Landing Page

Public marketing site for **landbankghana.com**, plus an admin dashboard for
managing homepage content (banners, photos, stats, clients, social links,
news, contact details, staff accounts, plot listings, sellers, reviews).

This is a standalone project — separate from the internal PEP Landbank sales
portal repo, with its own Supabase backend.

## Structure

- `index.html` — the public landing page (single file, no build step).
- `admin/index.html` — password-protected content admin dashboard.
- `assets/logo.png` — the real LandBank Ghana logo, extracted from the files
  you sent.
- `assets/trulander-logo.png` — Trulander Jsf Limited's real logo, same.
- `assets/photos/` — real photos you provided (hero photo, About/Process
  section photos, the 3 promo/ad banners, and gallery photos).
- `assets/supabase-config.js` — the Supabase project URL + public anon key
  shared by both `index.html` and `admin/index.html`.
- `supabase/schema.sql` — a record of the database schema (tables + security
  policies) already applied to the Supabase project. You don't need to run
  this yourself; it's there for reference/history.

## Backend

A **new, separate Supabase project** was created for this site (name:
`landbankghana-website`), independent of the internal sales-portal database.
It holds:

- `banners` — `kind='hero'` controls the homepage headline/subtext/badge;
  `kind='promo'` banners are slides in the animated advertisement carousel
  (seeded with your 3 ad creatives).
- `content_blocks` — photo placements: three fixed "named spots" (hero, about,
  process section — seeded with your real photos) plus an open-ended gallery.
- `stats` — the number tiles (e.g. "7+ Years Experience").
- `clients` — the "Trusted by" logo strip (seeded with Trulander Jsf Limited
  and their real logo), each with optional Facebook/Instagram/TikTok links —
  clicking a client with socials set pops open icon links to their pages.
- `social_links` — your own social icons shown in the contact section +
  footer (seeded with real Instagram, Facebook, TikTok, WhatsApp).
- `news` — announcements shown in the site's notification-bell panel.
- `site_settings` — phone/WhatsApp/email/office address/urgent call number
  (seeded with WhatsApp +233 54 641 6566 and email
  digitalopsofficer@landbankghana.com; office address is still a placeholder).
- `sellers` — seller profiles for the Hot Plots marketplace: name, company,
  registration no., tags (free text — "Verified", "Premium", etc.), document
  types held (free text — "Title", "Certified Site Plan & Indenture", etc.),
  contact info.
- `plots` — the plot listings themselves: title, size, price, location,
  nearest landmark, description, up to 3 photos, linked seller, status
  (available/reserved/sold), and a "Hot" featured flag.
- `reviews` — public star-rating submissions (1–5 stars + comment), held for
  moderation until an admin approves them, at which point they appear
  automatically in the "Client Stories" section.
- `leads` — every contact-form submission from the homepage.
- `admins` — staff accounts: invite list, claimed status, display name, avatar.

Anyone can **read** public content and anyone can **submit** the contact
form or a review. Only signed-in admins can add/edit/delete content, approve
reviews, or view leads — enforced by Postgres Row Level Security, not just
the frontend.

## What's on the homepage now

- Sticky nav (Home/About/Services/Contact), a hero with a real photo of a
  team member, "Trusted by" clients strip with clickable social popovers, an
  animated promo banner carousel with your 3 ad creatives, "How We Help"
  cards, the buyer/seller qualifier questions.
- **Hot Plots** — a marketplace grid of available plots (photo, size, price,
  status badge, "Hot" tag for featured listings). Clicking one opens a detail
  modal with a photo gallery, full facts (size/location/nearest landmark/
  description), and a seller card showing their tags (Verified ✓, Premium ★,
  or any custom tag you add), company info, document types held, and direct
  call/WhatsApp/email buttons. Shows an honest "new plots coming soon" message
  until you add your first one.
- A 5-step process timeline (with a real photo of the team verifying a site),
  stats, About Us (with a real photo), an open-ended photo gallery, a
  **Client Stories** section that shows real approved reviews with star
  ratings once you have any (otherwise an honest "coming soon" state) plus a
  public star-rating review submission form, and a contact form.
- Floating WhatsApp button (bottom-right).
- Floating, **draggable** notification bell (bottom-left, drag it anywhere —
  position is remembered) that opens a slide-in panel of your **News** items,
  with a red dot when there's something new.
- A "Need to talk to staff urgently?" button that dials your urgent-call
  number directly on mobile (`tel:` link).

## Managing the Hot Plots marketplace

In `/admin`:

- **Sellers** — add a seller/company once (name, company, registration no.,
  contact info, bio, avatar). **Tags** and **document types** are just
  comma-separated free text — type "Verified, Premium, Recommended" or
  invent your own; there's no fixed list to be limited by. Never fill in a
  company registration number you can't actually verify.
- **Hot Plots** — add a plot, optionally linking it to a seller from the
  dropdown, with up to 3 photos, price, size, location, nearest landmark,
  description, status, and a "Mark as Hot" checkbox for featured listings.
- **Reviews** — every review submitted on the homepage lands here as
  "Pending". Click **Approve** to make it public instantly (or **Unapprove**
  to hide it again, or delete it outright).

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
Supabase, so banners/stats/clients/plots/news/contact info won't populate
until the site is served over http(s). Deploying takes about 2 minutes and is
the real target anyway:

1. Push this repo to GitHub (already done if you're reading this from the repo).
2. In Netlify: **Add new site → Import an existing project → GitHub** → pick
   this repo. Build command: empty. Publish directory: `/`. Deploy.
3. Point `landbankghana.com` at the Netlify site (Netlify → Domain settings →
   Add custom domain, then update your domain's DNS as instructed).

Once deployed, everything — contact info, social icons, WhatsApp button,
urgent call button, news bell, client popovers, Hot Plots, reviews — will
populate from the database automatically.

## What still needs your input

- **The seller "Verified"/"Premium" tags on Trulander Jsf Limited** are a
  placeholder default — please confirm in **Sellers** that's accurate, or
  change it.
- **Office address** — phone, WhatsApp, and email are set; office address is
  still blank until filled in under **Contact Info**.
- **Stats numbers** — years of experience, acres secured, client count, etc.
  are placeholder figures. Edit anytime under **Stats**.
- **Actual plot listings** — the Hot Plots section is wired up and ready but
  starts empty; add your first real listings under **Hot Plots** in the admin
  dashboard.
- **Client stories / testimonials** — starts empty by design rather than
  invented quotes; real ones will appear automatically as you approve
  submitted reviews, or you can add one yourself directly in Supabase if you
  already have references collected elsewhere.
