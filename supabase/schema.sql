-- =====================================================================
--  LANDBANK GHANA — public landing page + admin backend
--  Supabase project: landbankghana-website (ref: azweseaslsymvuilungg)
--  This file is a record of the schema already applied to that project
--  via the Supabase migration "landing_page_content_schema".
-- =====================================================================

create extension if not exists pgcrypto;

-- ---- ADMIN GATE ----
-- One row per invited admin email. An invited (unclaimed) email can
-- "activate" an account once from /admin — after that, user_id is set
-- and claimed becomes true. Only claimed admins can write site content.
create table public.admins (
  email      text primary key,
  user_id    uuid unique references auth.users(id) on delete set null,
  claimed    boolean not null default false,
  created_at timestamptz not null default now()
);
alter table public.admins enable row level security;
create policy admins_none on public.admins for all using (false) with check (false);

create or replace function public.is_admin() returns boolean
  language sql security definer stable set search_path = public as
$$ select exists (select 1 from public.admins where user_id = auth.uid() and claimed = true) $$;

create or replace function public.email_is_invited_admin(check_email text) returns boolean
  language sql security definer stable set search_path = public as
$$ select exists (select 1 from public.admins where lower(email) = lower(check_email) and claimed = false) $$;

-- Requires an authenticated caller whose own auth email matches check_email —
-- otherwise an anonymous visitor could pre-claim an invited email (with a
-- null user_id) and permanently lock the real admin out of activation.
create or replace function public.claim_admin(check_email text) returns void
  language plpgsql security definer set search_path = public as
$$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  update public.admins
     set user_id = auth.uid(), claimed = true
   where lower(email) = lower(check_email)
     and claimed = false
     and user_id is null
     and lower(email) = lower(coalesce((select email from auth.users where id = auth.uid()), ''));
end;
$$;

-- ---- BANNERS (hero / promo content) ----
create table public.banners (
  id           uuid primary key default gen_random_uuid(),
  kind         text not null default 'hero' check (kind in ('hero','promo')),
  headline     text,
  subheadline  text,
  image_url    text,
  badge_text   text,
  cta_label    text,
  cta_href     text,
  sort_order   int not null default 0,
  active       boolean not null default true,
  created_at   timestamptz not null default now()
);
alter table public.banners enable row level security;
create policy banners_read on public.banners for select using (true);
create policy banners_write on public.banners for all using (public.is_admin()) with check (public.is_admin());

-- ---- STATS STRIP ----
create table public.stats (
  id         uuid primary key default gen_random_uuid(),
  label      text not null,
  value      text not null,
  sort_order int not null default 0,
  active     boolean not null default true
);
alter table public.stats enable row level security;
create policy stats_read on public.stats for select using (true);
create policy stats_write on public.stats for all using (public.is_admin()) with check (public.is_admin());

-- ---- CLIENTS ----
create table public.clients (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  logo_url    text,
  website_url text,
  sort_order  int not null default 0,
  active      boolean not null default true,
  created_at  timestamptz not null default now()
);
alter table public.clients enable row level security;
create policy clients_read on public.clients for select using (true);
create policy clients_write on public.clients for all using (public.is_admin()) with check (public.is_admin());

-- ---- SOCIAL LINKS ----
create table public.social_links (
  id         uuid primary key default gen_random_uuid(),
  platform   text not null,
  url        text not null,
  sort_order int not null default 0,
  active     boolean not null default true
);
alter table public.social_links enable row level security;
create policy social_read on public.social_links for select using (true);
create policy social_write on public.social_links for all using (public.is_admin()) with check (public.is_admin());

-- ---- SITE SETTINGS (singleton row) ----
create table public.site_settings (
  id         int primary key default 1 check (id = 1),
  phone      text,
  whatsapp   text,
  email      text,
  address    text,
  updated_at timestamptz not null default now()
);
alter table public.site_settings enable row level security;
create policy settings_read on public.site_settings for select using (true);
create policy settings_write on public.site_settings for all using (public.is_admin()) with check (public.is_admin());
insert into public.site_settings (id) values (1) on conflict do nothing;

-- ---- CLIENT SOCIAL HANDLES (popover on click, e.g. Trulander) ----
alter table public.clients add column if not exists facebook_url text;
alter table public.clients add column if not exists instagram_url text;
alter table public.clients add column if not exists tiktok_url text;

-- ---- STAFF PROFILE FIELDS + TEAM MANAGEMENT ----
alter table public.admins add column if not exists display_name text;
alter table public.admins add column if not exists avatar_url text;
alter table public.admins add column if not exists role text not null default 'staff';
alter table public.admins add column if not exists invited_by text;

-- A signed-in admin can update their own display_name/avatar (not email/claim state).
create or replace function public.update_my_profile(new_display_name text, new_avatar_url text) returns void
  language plpgsql security definer set search_path = public as
$$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  update public.admins
     set display_name = new_display_name,
         avatar_url = new_avatar_url
   where user_id = auth.uid() and claimed = true;
end;
$$;

-- Read-only team listing for the admin "Team" panel. This was originally a
-- view, but Postgres/Supabase's linter flags any non-security_invoker view
-- as an error-level risk regardless of an internal access gate — so it's a
-- SECURITY DEFINER function instead (the same accepted pattern used by
-- invite_admin/remove_admin below), explicitly checking is_admin() itself.
create or replace function public.get_team()
returns table (email text, display_name text, avatar_url text, role text, claimed boolean, created_at timestamptz)
  language plpgsql security definer set search_path = public as
$$
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;
  return query
    select a.email, a.display_name, a.avatar_url, a.role, a.claimed, a.created_at
    from public.admins a
    order by a.created_at;
end;
$$;

-- Invite/remove teammates — only an existing claimed admin can call these.
create or replace function public.invite_admin(new_email text) returns void
  language plpgsql security definer set search_path = public as
$$
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;
  insert into public.admins(email) values (lower(new_email))
  on conflict (email) do nothing;
end;
$$;

create or replace function public.remove_admin(target_email text) returns void
  language plpgsql security definer set search_path = public as
$$
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;
  if lower(target_email) = lower(coalesce((select email from auth.users where id = auth.uid()), '')) then
    raise exception 'cannot remove your own access';
  end if;
  delete from public.admins where lower(email) = lower(target_email);
end;
$$;

-- ---- NEWS / ANNOUNCEMENTS (site notification bell) ----
create table public.news (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  body         text,
  image_url    text,
  published_at timestamptz not null default now(),
  active       boolean not null default true,
  created_at   timestamptz not null default now()
);
alter table public.news enable row level security;
create policy news_read on public.news for select using (true);
create policy news_write on public.news for all using (public.is_admin()) with check (public.is_admin());

-- ---- URGENT/EMERGENCY CALL NUMBER (separate from the general display phone) ----
alter table public.site_settings add column if not exists urgent_phone text;

-- ---- CONTENT BLOCKS (flexible photo placements) ----
-- "slot" = a named, fixed spot the frontend already knows how to render
-- (hero / about / process), or 'gallery' for free-form extra images that
-- automatically show up in the homepage's open-ended gallery section —
-- this is how new photos can be added without any code changes.
create table public.content_blocks (
  key         text primary key,
  slot        text not null check (slot in ('hero','about','help_diligence','help_litigation','help_buyer','help_seller','process','gallery')),
  label       text not null,
  image_url   text,
  alt_text    text,
  sort_order  int not null default 0,
  active      boolean not null default true,
  created_at  timestamptz not null default now()
);
alter table public.content_blocks enable row level security;
create policy content_blocks_read on public.content_blocks for select using (true);
create policy content_blocks_write on public.content_blocks for all using (public.is_admin()) with check (public.is_admin());

-- ---- SELLERS (Hot Plots marketplace) ----
create table public.sellers (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,
  company_name    text,
  company_reg_no  text,
  phone           text,
  email           text,
  bio             text,
  avatar_url      text,
  tags            text[] not null default '{}',
  document_types  text[] not null default '{}',
  sort_order      int not null default 0,
  active          boolean not null default true,
  created_at      timestamptz not null default now()
);
alter table public.sellers enable row level security;
create policy sellers_read on public.sellers for select using (true);
create policy sellers_write on public.sellers for all using (public.is_admin()) with check (public.is_admin());

-- ---- PLOTS (the "Hot Plots" marketplace) ----
create table public.plots (
  id               uuid primary key default gen_random_uuid(),
  title            text not null,
  size             text not null,
  price_amount     numeric,
  currency         text not null default 'GHS',
  location         text not null,
  nearest_landmark text,
  description      text,
  image_url        text,
  image_url_2      text,
  image_url_3      text,
  seller_id        uuid references public.sellers(id) on delete set null,
  status           text not null default 'available' check (status in ('available','reserved','sold')),
  featured         boolean not null default false,
  sort_order       int not null default 0,
  active           boolean not null default true,
  created_at       timestamptz not null default now()
);
alter table public.plots enable row level security;
create policy plots_read on public.plots for select using (true);
create policy plots_write on public.plots for all using (public.is_admin()) with check (public.is_admin());

-- ---- REVIEWS (feeds the testimonials section once approved) ----
create table public.reviews (
  id             uuid primary key default gen_random_uuid(),
  reviewer_name  text not null,
  rating         int not null check (rating between 1 and 5),
  comment        text,
  approved       boolean not null default false,
  created_at     timestamptz not null default now()
);
alter table public.reviews enable row level security;
create policy reviews_insert on public.reviews for insert with check (true);
create policy reviews_read_approved on public.reviews for select using (approved = true);
create policy reviews_read_admin on public.reviews for select using (public.is_admin());
create policy reviews_write_admin on public.reviews for update using (public.is_admin()) with check (public.is_admin());
create policy reviews_delete_admin on public.reviews for delete using (public.is_admin());

-- ---- LEADS (contact form submissions) ----
create table public.leads (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  phone      text,
  email      text,
  interest   text check (interest in ('buyer','seller','due_diligence','other')),
  message    text,
  status     text not null default 'new' check (status in ('new','contacted','closed')),
  created_at timestamptz not null default now()
);
alter table public.leads enable row level security;
create policy leads_insert on public.leads for insert with check (true);
create policy leads_read on public.leads for select using (public.is_admin());
create policy leads_update on public.leads for update using (public.is_admin());
create policy leads_delete on public.leads for delete using (public.is_admin());

-- ---- SEED DATA ----
insert into public.admins(email) values ('awaheedasamei5@gmail.com') on conflict do nothing;
insert into public.clients(name, sort_order) values ('Trulander Jsf Limited', 1) on conflict do nothing;
insert into public.stats(label, value, sort_order) values
  ('Years of Experience','7+',1),
  ('Litigation-Free Transfers','100%',2),
  ('Acres Secured','1,200+',3),
  ('Happy Clients','500+',4)
on conflict do nothing;
insert into public.banners(kind, headline, subheadline, badge_text, cta_label, cta_href, sort_order) values
  ('hero','Own Land You Can Trust.','We help you find, verify, and secure litigation-free land in Ghana — from due diligence to documentation, every step of the way.','Verified & Litigation-Free','Start Your Land Search','#contact',1)
on conflict do nothing;

-- ---- SEED: real contact info + social links ----
update public.site_settings
   set whatsapp = '233546416566',
       phone = '+233 54 641 6566',
       email = 'digitalopsofficer@landbankghana.com'
 where id = 1;

insert into public.social_links (platform, url, sort_order) values
  ('whatsapp', 'https://wa.me/233546416566', 1),
  ('instagram', 'https://www.instagram.com/landbankghana_?igsh=MWd2em5vcWs1OG84Mw%3D%3D&utm_source=qr', 2),
  ('facebook', 'https://www.facebook.com/share/18qnRVH4W9/?mibextid=wwXIfr', 3),
  ('tiktok', 'https://www.tiktok.com/@landbankghana.com?_r=1&_t=ZS-98a1seDetRU', 4)
on conflict do nothing;

update public.site_settings set urgent_phone = '233546416566' where id = 1;

update public.clients set
  logo_url = '/assets/trulander-logo.png',
  facebook_url = 'https://www.facebook.com/trulanderjsf?mibextid=wwXIfr&mibextid=wwXIfr',
  instagram_url = 'https://www.instagram.com/trulanderjsf?igsh=ZTVyN3ZramdwYmpx&utm_source=qr',
  tiktok_url = 'https://www.tiktok.com/@trulander?_r=1&_t=ZS-98a3MdYO9pN'
where lower(name) = lower('Trulander Jsf Limited');

-- ---- SEED: real photos from the client, and the Hot Plots marketplace ----
insert into public.content_blocks (key, slot, label, image_url, alt_text, sort_order, active) values
  ('hero', 'hero', 'Hero photo (homepage top)', '/assets/photos/hero-person.png', 'LandBank Ghana helps you own land safely', 0, true),
  ('about', 'about', 'About section photo', '/assets/photos/about.jpg', 'Handing over the keys to a new landowner', 0, true),
  ('process', 'process', 'Process section photo', '/assets/photos/process.jpg', 'Our team verifying a plot on site', 0, true),
  ('gallery_1', 'gallery', 'Site verification', '/assets/photos/gallery-1.jpg', 'LandBank Ghana team member on a site visit', 1, true),
  ('gallery_2', 'gallery', 'Handover moment', '/assets/photos/gallery-2.png', 'Handing over the keys to a new home', 2, true),
  ('gallery_3', 'gallery', 'On-site support', '/assets/photos/gallery-3.png', 'LandBank Ghana team member ready to help', 3, true),
  ('gallery_4', 'gallery', 'Happy client', '/assets/photos/gallery-4.jpg', 'A happy LandBank Ghana client', 4, true)
on conflict (key) do update set image_url = excluded.image_url, alt_text = excluded.alt_text, active = true;

insert into public.banners (kind, headline, subheadline, image_url, cta_href, sort_order, active) values
  ('promo', 'Own Land The Smart Way', 'Explore our curated list of risk-free lands, each thoroughly vetted through comprehensive due diligence.', '/assets/photos/promo-1.jpg', '#contact', 1, true),
  ('promo', 'Land Acquisition Made Simple', 'A seamless platform for buying and selling risk-free lands across Ghana.', '/assets/photos/promo-2.jpg', '#contact', 2, true),
  ('promo', 'Son of the Land Wey No Get Land', 'What a plot twist! Start your land ownership journey today.', '/assets/photos/promo-3.jpg', '#contact', 3, true);

-- Note: no company registration number is seeded — never fabricate a real
-- company's legal registration details; leave that field for the admin to
-- fill in once they can verify it.
insert into public.sellers (name, company_name, tags, document_types, phone, sort_order) values
  ('Trulander Jsf Limited', 'Trulander Jsf Limited', ARRAY['Verified','Premium'], ARRAY['Title','Certified Site Plan & Indenture'], '233546416566', 1);

-- =====================================================================
--  MIGRATION: add_storage_buckets_buyer_seller_forms
--  Storage buckets for real file uploads (replacing base64-in-Postgres,
--  which was a real driver of "the backend is slow" — every image was
--  being sent whole through every save and every page load), plus the
--  buyer inquiry / seller submission tables behind the qualifier forms.
-- =====================================================================

-- `media` (public): banners, gallery, plots, clients, avatars, news, and
-- seller-submitted land photos — anything meant to be publicly visible.
insert into storage.buckets (id, name, public)
values ('media', 'media', true)
on conflict (id) do nothing;

-- `documents` (private): supporting documents attached to seller
-- submissions (title deeds, search results, indentures) — admin-only read,
-- accessed via short-lived signed URLs, never a public link.
insert into storage.buckets (id, name, public)
values ('documents', 'documents', false)
on conflict (id) do nothing;

create policy "media public read" on storage.objects for select
  using (bucket_id = 'media');
create policy "media public insert" on storage.objects for insert
  with check (bucket_id = 'media');
create policy "media admin update" on storage.objects for update
  using (bucket_id = 'media' and is_admin());
create policy "media admin delete" on storage.objects for delete
  using (bucket_id = 'media' and is_admin());

create policy "documents public insert" on storage.objects for insert
  with check (bucket_id = 'documents');
create policy "documents admin read" on storage.objects for select
  using (bucket_id = 'documents' and is_admin());
create policy "documents admin delete" on storage.objects for delete
  using (bucket_id = 'documents' and is_admin());

-- Buyer inquiries — the "Gmail kind of chat system" inbox behind the
-- "Yes, help me buy" qualifier form.
create table public.buyer_inquiries (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text not null,
  email text,
  has_existing_land boolean,
  existing_land_details text,
  interested_location text,
  wants_plot_recommendations boolean,
  budget_range text,
  preferred_contact text default 'phone' check (preferred_contact in ('phone','whatsapp','email')),
  message text,
  status text not null default 'new' check (status in ('new','read','contacted','closed')),
  created_at timestamptz not null default now()
);
alter table public.buyer_inquiries enable row level security;
create policy "buyer_inquiries public insert" on public.buyer_inquiries for insert with check (true);
create policy "buyer_inquiries admin read" on public.buyer_inquiries for select using (is_admin());
create policy "buyer_inquiries admin update" on public.buyer_inquiries for update using (is_admin());
create policy "buyer_inquiries admin delete" on public.buyer_inquiries for delete using (is_admin());

-- Seller submissions — behind the "Yes, help me sell" form. Every
-- submission lands in the admin's "Seller Submissions" inbox for review;
-- approving one auto-creates (or reuses) a seller record and publishes a
-- linked row in `plots`, so it appears in the public Hot Plots section.
create table public.seller_submissions (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text not null,
  email text,
  company_name text,
  land_title text not null,
  land_size text,
  land_location text not null,
  nearest_landmark text,
  has_search_result boolean,
  documents_held text[] not null default '{}',
  asking_price_amount numeric,
  currency text default 'GHS',
  description text not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  linked_plot_id uuid references public.plots(id) on delete set null,
  reviewed_by text,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);
alter table public.seller_submissions enable row level security;
create policy "seller_submissions public insert" on public.seller_submissions for insert with check (true);
create policy "seller_submissions admin read" on public.seller_submissions for select using (is_admin());
create policy "seller_submissions admin update" on public.seller_submissions for update using (is_admin());
create policy "seller_submissions admin delete" on public.seller_submissions for delete using (is_admin());

-- Attachments (land photos + supporting documents) for a seller submission.
create table public.seller_submission_files (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null references public.seller_submissions(id) on delete cascade,
  kind text not null check (kind in ('image','document')),
  file_url text not null,
  file_path text not null,
  file_name text not null,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);
alter table public.seller_submission_files enable row level security;
create policy "seller_submission_files public insert" on public.seller_submission_files for insert with check (true);
create policy "seller_submission_files admin read" on public.seller_submission_files for select using (is_admin());
create policy "seller_submission_files admin delete" on public.seller_submission_files for delete using (is_admin());

-- =====================================================================
--  MIGRATION: fix leading-slash image paths (broke on GitHub Pages,
--  which serves this site from a /repo-name/ subpath, not domain root)
-- =====================================================================
update public.content_blocks set image_url = ltrim(image_url, '/') where image_url like '/%';
update public.banners set image_url = ltrim(image_url, '/') where image_url like '/%';
update public.clients set logo_url = ltrim(logo_url, '/') where logo_url like '/%';
update public.sellers set avatar_url = ltrim(avatar_url, '/') where avatar_url like '/%';
update public.plots set image_url = ltrim(image_url, '/') where image_url like '/%';
update public.plots set image_url_2 = ltrim(image_url_2, '/') where image_url_2 like '/%';
update public.plots set image_url_3 = ltrim(image_url_3, '/') where image_url_3 like '/%';
update public.news set image_url = ltrim(image_url, '/') where image_url like '/%';
update public.admins set avatar_url = ltrim(avatar_url, '/') where avatar_url like '/%';

-- =====================================================================
--  MIGRATION: trulander_rebrand_backend
--  The site pivoted from a "LandBank Ghana" agency brand to being
--  Trulander JSF Limited's own commerce site (a GREDA-registered real
--  estate company), with landbankghana.com credited as the "marketed by"
--  partner in the footer instead of being the primary brand. Content
--  facts below (mission, vision, Royal Palm Enclave details, referral
--  program terms) are taken directly from Trulander's own printed
--  brochure — nothing here is invented.
-- =====================================================================

-- "Refer & Earn" remote sales force applications — GHS 1,500 per
-- successful referral, per Trulander's real Tsopoli Referral Program.
create table public.remote_sales_applications (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text not null,
  email text,
  location text,
  experience text,
  message text,
  status text not null default 'new' check (status in ('new','read','contacted','onboarded','closed')),
  created_at timestamptz not null default now()
);
alter table public.remote_sales_applications enable row level security;
create policy "remote_sales_applications public insert" on public.remote_sales_applications for insert with check (true);
create policy "remote_sales_applications admin read" on public.remote_sales_applications for select using (is_admin());
create policy "remote_sales_applications admin update" on public.remote_sales_applications for update using (is_admin());
create policy "remote_sales_applications admin delete" on public.remote_sales_applications for delete using (is_admin());

-- Distinguish Trulander's own Royal Palm Enclave listings from
-- third-party seller submissions in the Hot Plots marketplace.
alter table public.plots add column if not exists listing_type text not null default 'third_party' check (listing_type in ('company','third_party'));

-- Real Trulander contact info, from their own printed brochure.
update public.site_settings set
  phone = '+233 302 956 795',
  whatsapp = '233546416566',
  email = 'info@trulander.com',
  address = 'Nungua Nautical Last Stop, Alex Nerda Building, Accra'
where id = 1;

-- Hero copy: Trulander / Royal Palm Enclave focused.
update public.banners set
  headline = 'Own Royal Palm Enclave, Risk-Free.',
  subheadline = 'Trulander JSF Limited makes genuine land accessible for all — GREDA-registered, fully documented, and backed by real due diligence on every plot we sell.',
  badge_text = 'GREDA Registered · Verified Title',
  cta_label = 'Explore Royal Palm Enclave',
  cta_href = '#royal-palm'
where kind = 'hero';

-- social_links becomes the primary brand's own (Trulander) social icons.
update public.social_links set url = 'https://www.facebook.com/trulanderjsf?mibextid=wwXIfr&mibextid=wwXIfr' where platform = 'facebook';
update public.social_links set url = 'https://www.instagram.com/trulanderjsf?igsh=ZTVyN3ZramdwYmpx&utm_source=qr' where platform = 'instagram';
update public.social_links set url = 'https://www.tiktok.com/@trulander?_r=1&_t=ZS-98a3MdYO9pN' where platform = 'tiktok';

-- The former "Trulander" client-tile row becomes the "Marketed by
-- LandBankGhana.com" footer credit, carrying LandBank's own real handles
-- (previously in social_links, before Trulander became the primary brand).
update public.clients set
  name = 'LandBankGhana.com',
  logo_url = 'assets/logo.png',
  facebook_url = 'https://www.facebook.com/share/18qnRVH4W9/?mibextid=wwXIfr',
  instagram_url = 'https://www.instagram.com/landbankghana_?igsh=MWd2em5vcWs1OG84Mw%3D%3D&utm_source=qr',
  tiktok_url = 'https://www.tiktok.com/@landbankghana.com?_r=1&_t=ZS-98a1seDetRU',
  website_url = null
where name = 'Trulander Jsf Limited';

insert into public.clients (name, sort_order) values ('Hollard Insurance', 2) on conflict do nothing;
