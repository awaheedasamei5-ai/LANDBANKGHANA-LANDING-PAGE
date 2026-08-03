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

-- Read-only team listing for the admin "Team" panel. Views run as their
-- owner by default (bypassing admins' own "always false" RLS), so the
-- `where public.is_admin()` clause is the access gate: is_admin() is a
-- single boolean, so it acts as an all-or-nothing filter on the view.
create or replace view public.team_directory as
  select email, display_name, avatar_url, role, claimed, created_at
  from public.admins
  where public.is_admin();

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
  logo_url = '/assets/trulander-logo.svg',
  facebook_url = 'https://www.facebook.com/trulanderjsf?mibextid=wwXIfr&mibextid=wwXIfr',
  instagram_url = 'https://www.instagram.com/trulanderjsf?igsh=ZTVyN3ZramdwYmpx&utm_source=qr',
  tiktok_url = 'https://www.tiktok.com/@trulander?_r=1&_t=ZS-98a3MdYO9pN'
where lower(name) = lower('Trulander Jsf Limited');
