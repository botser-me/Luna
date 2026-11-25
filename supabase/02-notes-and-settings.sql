-- מטיילים עם לונה – עדכון 2: הערות לארוחות + הגדרות משפחה (רק להורים)
-- להריץ פעם אחת ב-Supabase → SQL Editor → New query → Run
-- קוד ההורים כבר מוגדר. פשוט להריץ.

-- 1) הערה לארוחה ("מה קיבלה")
alter table public.feedings add column if not exists note text;

-- 2) הגדרות משפחה משותפות
create table if not exists public.app_settings (
  key         text primary key,
  value       jsonb not null,
  updated_by  text,
  updated_at  timestamptz not null default now()
);

create or replace function public.is_parent()
returns boolean language sql stable as $$
  select public.is_family()
     and lower(coalesce(current_setting('request.headers', true)::json ->> 'x-parent-key', '')) = lower('***');
$$;
grant execute on function public.is_parent() to anon, authenticated;

alter table public.app_settings enable row level security;
drop policy if exists "family read"   on public.app_settings;
drop policy if exists "parents write" on public.app_settings;
drop policy if exists "parents update" on public.app_settings;
drop policy if exists "parents delete" on public.app_settings;
create policy "family read"    on public.app_settings for select to anon, authenticated using (public.is_family());
create policy "parents write"  on public.app_settings for insert to anon, authenticated with check (public.is_parent());
create policy "parents update" on public.app_settings for update to anon, authenticated using (public.is_parent()) with check (public.is_parent());
create policy "parents delete" on public.app_settings for delete to anon, authenticated using (public.is_parent());
