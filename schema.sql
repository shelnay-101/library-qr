-- Run this whole file once in Supabase > SQL Editor.
create extension if not exists pgcrypto;

create table boxes (
  id uuid primary key default gen_random_uuid(),
  box_number varchar not null unique,
  box_name varchar not null,
  category varchar,
  shelf_location varchar,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table books (
  id uuid primary key default gen_random_uuid(),
  book_number varchar not null unique,
  title varchar not null,
  author varchar,
  isbn varchar,
  publisher varchar,
  publication_year integer,
  category varchar,
  classification varchar,
  cutter_number varchar,
  copy_number varchar,
  description text,
  status varchar not null default 'available' check (status in ('available','borrowed','missing','repair')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table box_books (
  id uuid primary key default gen_random_uuid(),
  box_id uuid not null references boxes(id) on delete cascade,
  book_id uuid not null unique references books(id) on delete cascade,  -- one box per book
  assigned_at timestamptz not null default now()
);
create index on box_books(box_id);

create table admin_users (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null unique references auth.users(id) on delete cascade,
  full_name varchar,
  role varchar not null default 'admin',
  created_at timestamptz not null default now()
);

create table activity_log (
  id bigserial primary key,
  action text not null,
  actor uuid default auth.uid(),
  created_at timestamptz not null default now()
);

-- Search view: each book with its box (respects RLS of the caller)
create view book_locations with (security_invoker = true) as
select b.*, bx.id as box_id, bx.box_number, bx.box_name, bx.shelf_location
from books b
left join box_books bb on bb.book_id = b.id
left join boxes bx on bx.id = bb.box_id;

create function is_admin() returns boolean
language sql stable security definer set search_path = public as
$$ select exists (select 1 from admin_users where auth_user_id = auth.uid()) $$;

create function touch_updated_at() returns trigger language plpgsql as
$$ begin new.updated_at = now(); return new; end $$;
create trigger t_boxes before update on boxes for each row execute function touch_updated_at();
create trigger t_books before update on books for each row execute function touch_updated_at();

-- Row Level Security
alter table boxes enable row level security;
alter table books enable row level security;
alter table box_books enable row level security;
alter table admin_users enable row level security;
alter table activity_log enable row level security;

create policy "public read" on boxes for select using (true);
create policy "public read" on books for select using (true);
create policy "public read" on box_books for select using (true);
create policy "admin write" on boxes for all using (is_admin()) with check (is_admin());
create policy "admin write" on books for all using (is_admin()) with check (is_admin());
create policy "admin write" on box_books for all using (is_admin()) with check (is_admin());
create policy "read own row" on admin_users for select using (auth_user_id = auth.uid());
create policy "admin read log" on activity_log for select using (is_admin());
create policy "admin add log" on activity_log for insert with check (is_admin());
-- admin_users has no write policy: admins are added only via SQL Editor (see README).
