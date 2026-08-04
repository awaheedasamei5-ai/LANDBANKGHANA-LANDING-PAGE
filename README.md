# Trulander JSF Limited — Landing Page

Public commerce site for Trulander JSF Limited — a GREDA-registered real
estate company and home of **Royal Palm Enclave, Tsopoli** — plus an admin
dashboard for managing every piece of content on it (banners, photos, stats,
clients, social links, news, contact details, staff accounts, plot listings,
sellers, reviews, and the buyer/seller/remote-sales inboxes below).

landbankghana.com is credited as the site's marketing partner in the footer
("Marketed by") — this project itself is standalone, separate from the
internal PEP Landbank sales portal repo, with its own Supabase backend.

## Structure

- `index.html` — the public landing page (single file, no build step).
- `admin/index.html` — password-protected content admin dashboard.
- `assets/trulander-logo.png` — Trulander JSF Limited's real logo — the
  primary site logo (nav, footer, favicon).
- `assets/logo.png` — the LandBank Ghana logo, used only for the "Marketed
  by landbankghana.com" footer credit.
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
- `buyer_inquiries` — the "Yes, help me buy" form: existing land needing due
  diligence, desired acquisition location, whether they want plot options
  shown, budget, preferred contact. Reviewed in **Buyer Inquiries** in admin.
- `seller_submissions` — the "Yes, help me sell" form: full land details,
  documents held, whether a search result exists, description. Reviewed in
  **Seller Submissions** in admin; approving one publishes it to Hot Plots.
- `seller_submission_files` — the land photos and supporting documents
  attached to a seller submission.
- `remote_sales_applications` — the "Refer & Earn" remote sales force
  applications. Reviewed in **Remote Sales Force** in admin. The referral
  bonus amount itself is admin-editable under **Contact Info** and hidden
  on the site until you set it.
- `service_requests` — requests from the **Services** hub (Surveyor, Land
  Issue, Legal, Land Documentation). Reviewed in **Service Requests**
  in admin.
- `site_visit_requests` — "Book a Free Site Visit" submissions for Royal
  Palm Enclave, matching Trulander's real printed Site Visit Request Form.
  Reviewed in **Site Visit Requests** in admin, grouped by date, with a
  CSV export and a one-tap WhatsApp button (booking confirmation or a
  visit reminder that auto-calculates days-away) per request.
- `plots.listing_type` — `'company'` (Trulander's own Royal Palm Enclave
  listings, shown with a "Trulander" badge) or `'third_party'` (verified
  seller submissions — the default).

Two Storage buckets back all file uploads: `media` (public — banners,
gallery, plots, clients, avatars, news, seller-submitted land photos) and
`documents` (private, admin-only — seller-submitted supporting documents
like title deeds and search results, accessed via short-lived signed links).
Files here persist permanently and don't expire.

Anyone can **read** public content and anyone can **submit** the contact
form or a review. Only signed-in admins can add/edit/delete content, approve
reviews, or view leads — enforced by Postgres Row Level Security, not just
the frontend.

## Navigation

Clicking Home/Royal Palm/About/Services/Contact in the nav (or the Hot Plots
"View All Plots" / Refer & Earn "Free Site Visit" CTAs) opens that section as
its own standalone page — everything else fades out — instead of scrolling
the shared homepage. It's all still one file with client-side routing
(`#/royal-palm`, `#/services/legal`, `#/plots`, `#/site-visit`, etc.), so
there's no separate page to deploy or keep in sync. Home itself keeps its
normal single-scroll layout; Hot Plots shows a lightweight preview there
that links through to the full `/plots` page with search/filter/sort.

## What's on the homepage now

- Sticky nav (Home/Royal Palm/About/Services/Contact), a hero with a real
  photo of a team member, "Trusted by" clients strip with clickable social
  popovers, an animated promo banner carousel with your ad creatives, and
  the buyer/seller qualifier questions.
- **Royal Palm Enclave, Tsopoli** — a dedicated flagship-project section with
  land size/lease/GREDA facts, land features, the real investment growth
  numbers from Trulander's brochure (~638% appreciation 2019–2026), what's
  driving the growth (New Airport City, Tema-Aflao Road, Dawa Industrial
  Zone, Saglemi Housing, etc.), and a "Book a Free Site Visit" CTA.
- **Hot Plots** — a searchable, filterable marketplace grid of available
  plots (search by title/location, filter by status/listing type, sort by
  price or newest, save favorites). Each card shows a photo, size, price,
  status badge, "Hot" tag for featured listings, and a "Trulander" badge for
  the company's own listings vs. verified third-party ones. Clicking one
  opens a detail modal with a photo gallery, full facts, a share button, a
  save-to-favorites heart, and a seller card with tags, company info,
  document types held, and direct call/WhatsApp/email buttons. Shows an
  honest "new plots coming soon" message until you add your first one.
- **"Yes, help me buy" / "Yes, help me sell"** on the qualifier cards open
  detailed forms instead of just jumping to the contact section — see
  "Buyer & seller forms" below.
- **Services hub** (`/services`) — four dedicated request pages (Surveyor
  Help, Land Issue Help, Legal Help, Land Documentation), each with its own
  form and call/WhatsApp shortcuts, landing in **Service Requests** in admin.
- **Book a Free Site Visit** (`/site-visit`) — a form matching Trulander's
  real printed Site Visit Request Form. After submitting, the visitor can
  download a PDF copy, edit and resend it, or share it straight to WhatsApp
  — all from their own device, no login needed.
- **Refer & Earn** — a remote sales force section built around Trulander's
  real referral program (GHS 1,500 per successful referral). Anyone can
  apply with their contact info; every application lands in **Remote Sales
  Force** in admin for you to call and onboard.
- A 6-step process section (with a real photo of the team verifying a site),
  stats, About Us (with a real photo), an animated gallery carousel (one
  large photo at a time with a slow Ken-Burns zoom, captions, and a
  clickable filmstrip), a **Client Stories** section that shows real
  approved reviews with star ratings once you have any (otherwise an honest
  "coming soon" state) plus a public star-rating review submission form, and
  a contact form.
- A mobile/desktop view toggle in the nav — forces the real mobile layout on
  an actual phone's "desktop site" mode, and opens a phone-frame preview of
  the live mobile layout when clicked from a desktop browser.
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
  They show up automatically in the animated gallery carousel — hidden
  until you add at least one.

In `/admin` → **Hero & Banners**, set "Kind" to **Promo** to add a slide to
the advertisement carousel (image + optional click-through link).

Every image field accepts either a pasted URL or a direct file upload. A file
upload opens a **crop tool** first — drag to reposition, use the slider to
zoom, then Apply — before the image is uploaded to Storage and saved.

## Buyer & seller forms

Clicking **"Yes, help me buy"** or **"Yes, help me sell"** on the homepage
opens a detailed form instead of just scrolling to the contact section:

- **Buyer form** asks whether they already have land needing due diligence,
  a location they're interested in acquiring land in, whether they'd like to
  see available plot options, budget range, and preferred contact method.
  Name and phone are required. Every submission lands in **Buyer Inquiries**
  in admin — a Gmail-style inbox (list + detail) with a New/Read/Contacted/
  Closed status you update as you follow up.
- **Seller form** captures full land details (title, size, location, nearest
  landmark), which documents they hold, whether they have a search result,
  a free-text description, and lets them attach any number of land photos
  and supporting documents (PDF, Word, or images). Every submission lands in
  **Seller Submissions** in admin with everything visible for verification —
  photos viewable inline, documents downloadable via a secure link. Hit
  **Approve** once you've checked it out and it automatically creates (or
  reuses) a seller record and publishes a linked Hot Plot; **Reject**
  discards it without publishing anything.

Uploaded files go to real Supabase Storage (not embedded in the database),
so they persist permanently and don't slow down page loads.

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
