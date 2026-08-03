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
