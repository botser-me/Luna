-- מטיילים עם לונה – הקמת מסד הנתונים
-- להדביק ב-Supabase → SQL Editor → Run
-- קוד המשפחה כבר מוגדר (לא רגיש לאותיות גדולות/קטנות). פשוט להריץ.

create table if not exists public.walks (
  id          uuid primary key default gen_random_uuid(),
  walk_date   date not null,
  slot        text not null check (slot in ('morning','noon','afternoon','night')),
  walker      text not null,
  started_at  timestamptz,
  ended_at    timestamptz,
  status      text not null default 'done' check (status in ('live','done')),
  note        text,
  photo       text,                                   -- תמונה דחוסה (JPEG base64, ~60KB)
  has_photo   boolean generated always as (photo is not null) stored,
  created_at  timestamptz not null default now()
);

create index if not exists walks_date_idx  on public.walks (walk_date desc);
create index if not exists walks_photo_idx on public.walks (has_photo) where has_photo;

-- קוד המשפחה נשלח מהאפליקציה בכותרת x-family-key.
-- רק מי שיודע את הקוד יכול לקרוא/לכתוב, גם אם הכתובת של האתר ציבורית.
create or replace function public.is_family()
returns boolean
language sql stable
as $$
  select lower(coalesce(current_setting('request.headers', true)::json ->> 'x-family-key', ''))
         = lower('***');
$$;
grant execute on function public.is_family() to anon, authenticated;

alter table public.walks enable row level security;

drop policy if exists "family only" on public.walks;
create policy "family only" on public.walks
  for all to anon, authenticated
  using (public.is_family())
  with check (public.is_family());

-- להחלפת הקוד בעתיד: להריץ שוב רק את create or replace function עם קוד חדש.

-- ===== האכלות =====
create table if not exists public.feedings (
  id          uuid primary key default gen_random_uuid(),
  feed_date   date not null,
  meal        text not null check (meal in ('lunch','dinner','veggies')),
  fed_by      text not null,
  fed_at      timestamptz,
  created_at  timestamptz not null default now()
);
create index if not exists feedings_date_idx on public.feedings (feed_date desc);

alter table public.feedings enable row level security;
drop policy if exists "family only" on public.feedings;
create policy "family only" on public.feedings
  for all to anon, authenticated
  using (public.is_family())
  with check (public.is_family());
