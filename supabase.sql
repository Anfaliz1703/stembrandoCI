-- STEMbrando Live · esquema mínimo para interacción en Vercel + Supabase
-- Ejecuta este script en Supabase SQL Editor.

create table if not exists public.sessions (
  room text primary key,
  slide_index integer not null default 0,
  active_interaction jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.participants (
  id uuid primary key,
  room text not null,
  name text not null,
  role text,
  sede text,
  avatar text,
  score integer default 0,
  last_seen timestamptz default now(),
  created_at timestamptz default now()
);

create table if not exists public.responses (
  id uuid primary key,
  room text not null,
  participant_id uuid not null,
  interaction_id text not null,
  type text not null,
  response text not null,
  correct boolean,
  ms integer default 0,
  points integer default 0,
  meta jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

create table if not exists public.approvals (
  id uuid primary key,
  room text not null,
  participant_id uuid not null,
  interaction_id text not null,
  approved boolean default true,
  created_at timestamptz default now(),
  unique(room, participant_id, interaction_id)
);

alter table public.sessions enable row level security;
alter table public.participants enable row level security;
alter table public.responses enable row level security;
alter table public.approvals enable row level security;

-- Políticas abiertas para evento escolar con enlace público.
-- Para producción institucional, reemplazar por autenticación o sala con token.
drop policy if exists "public read sessions" on public.sessions;
drop policy if exists "public write sessions" on public.sessions;
drop policy if exists "public read participants" on public.participants;
drop policy if exists "public write participants" on public.participants;
drop policy if exists "public read responses" on public.responses;
drop policy if exists "public write responses" on public.responses;
drop policy if exists "public read approvals" on public.approvals;
drop policy if exists "public write approvals" on public.approvals;

create policy "public read sessions" on public.sessions for select using (true);
create policy "public write sessions" on public.sessions for all using (true) with check (true);
create policy "public read participants" on public.participants for select using (true);
create policy "public write participants" on public.participants for all using (true) with check (true);
create policy "public read responses" on public.responses for select using (true);
create policy "public write responses" on public.responses for all using (true) with check (true);
create policy "public read approvals" on public.approvals for select using (true);
create policy "public write approvals" on public.approvals for all using (true) with check (true);


-- Permisos para clientes web que usan Publishable key (rol anon/authenticated).
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on table public.sessions to anon, authenticated;
grant select, insert, update, delete on table public.participants to anon, authenticated;
grant select, insert, update, delete on table public.responses to anon, authenticated;
grant select, insert, update, delete on table public.approvals to anon, authenticated;

-- Activar Realtime para las tablas (de forma segura si ejecutas el script más de una vez).
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='sessions') then
    execute 'alter publication supabase_realtime add table public.sessions';
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='participants') then
    execute 'alter publication supabase_realtime add table public.participants';
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='responses') then
    execute 'alter publication supabase_realtime add table public.responses';
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='approvals') then
    execute 'alter publication supabase_realtime add table public.approvals';
  end if;
end $$;