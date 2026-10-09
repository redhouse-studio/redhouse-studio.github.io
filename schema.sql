-- Planning Redhouse — schéma Supabase
-- À coller tel quel dans Supabase > SQL Editor > New query, puis "Run".
-- Ce script peut être relancé : il ne supprime aucune donnée existante.

create extension if not exists btree_gist;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

-- Un profil par compte. Créé automatiquement à l'inscription, en attente.
create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '' check (char_length(display_name) <= 60),
  color        text not null default '#5ee6c6' check (color ~ '^#[0-9a-fA-F]{6}$'),
  note         text not null default '' check (char_length(note) <= 300),
  status       text not null default 'pending' check (status in ('pending','approved','refused')),
  is_admin     boolean not null default false,
  created_at   timestamptz not null default now()
);

-- Les créneaux. La contrainte no_overlap rend tout chevauchement impossible,
-- même si deux personnes réservent la même heure à la même seconde.
create table if not exists public.slots (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  starts_at  timestamptz not null,
  ends_at    timestamptz not null,
  motif      text not null check (char_length(btrim(motif)) between 1 and 80),
  created_at timestamptz not null default now(),
  constraint slot_order check (ends_at > starts_at),
  constraint slot_max   check (ends_at - starts_at <= interval '24 hours'),
  constraint no_overlap exclude using gist (tstzrange(starts_at, ends_at, '[)') with &&)
);
create index if not exists slots_starts_at_idx on public.slots (starts_at);

-- ---------------------------------------------------------------------------
-- Fonctions utilitaires
-- ---------------------------------------------------------------------------

create or replace function public.is_approved() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and status = 'approved');
$$;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and is_admin and status = 'approved');
$$;

-- Crée le profil "en attente" dès qu'un compte est créé.
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  c text := coalesce(new.raw_user_meta_data->>'color', '');
begin
  insert into public.profiles (id, display_name, color, note)
  values (
    new.id,
    left(coalesce(nullif(btrim(new.raw_user_meta_data->>'display_name'), ''), split_part(new.email, '@', 1)), 60),
    case when c ~ '^#[0-9a-fA-F]{6}$' then c else '#5ee6c6' end,
    left(coalesce(new.raw_user_meta_data->>'note', ''), 300)
  )
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Seul l'admin change le statut, la couleur ou le rôle admin.
-- (auth.uid() est vide quand c'est toi qui lances une requête dans le SQL Editor.)
create or replace function public.guard_profile() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    if new.status   is distinct from old.status
    or new.is_admin is distinct from old.is_admin
    or new.color    is distinct from old.color then
      raise exception 'Seul l''admin peut modifier ce champ' using errcode = '42501';
    end if;
  end if;
  if auth.uid() is not null and new.id = auth.uid() and old.is_admin and not new.is_admin then
    raise exception 'Tu ne peux pas retirer ton propre rôle admin' using errcode = '42501';
  end if;
  return new;
end $$;

drop trigger if exists guard_profile on public.profiles;
create trigger guard_profile
  before update on public.profiles
  for each row execute function public.guard_profile();

-- Quand l'admin retire un accès, les créneaux à venir de la personne sont libérés.
create or replace function public.release_slots_on_refuse() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'refused' and old.status is distinct from 'refused' then
    delete from public.slots where user_id = new.id and ends_at > now();
  end if;
  return new;
end $$;

drop trigger if exists release_slots_on_refuse on public.profiles;
create trigger release_slots_on_refuse
  after update on public.profiles
  for each row execute function public.release_slots_on_refuse();

-- Liste des comptes avec leur e-mail, réservée à l'admin.
-- Les participants ne voient jamais les e-mails des autres.
create or replace function public.admin_users()
returns table (id uuid, email text, created_at timestamptz)
language sql stable security definer set search_path = public, auth as $$
  select u.id, u.email::text, u.created_at
  from auth.users u
  where public.is_admin();
$$;

revoke all on function public.admin_users() from public, anon;
grant execute on function public.admin_users() to authenticated;
revoke all on function public.is_approved() from public, anon;
revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_approved() to authenticated;
grant execute on function public.is_admin() to authenticated;

-- ---------------------------------------------------------------------------
-- Règles d'accès (Row Level Security)
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.slots    enable row level security;

revoke all on public.profiles, public.slots from anon;
grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.slots to authenticated;

drop policy if exists "profiles_read"   on public.profiles;
drop policy if exists "profiles_update" on public.profiles;
-- Chacun voit son profil ; les membres validés voient les autres membres validés ; l'admin voit tout.
create policy "profiles_read" on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_admin() or (status = 'approved' and public.is_approved()));
-- Chacun modifie son nom ; l'admin modifie tout (le trigger guard_profile protège le reste).
create policy "profiles_update" on public.profiles for update to authenticated
  using (id = auth.uid() or public.is_admin())
  with check (id = auth.uid() or public.is_admin());

drop policy if exists "slots_read"   on public.slots;
drop policy if exists "slots_insert" on public.slots;
drop policy if exists "slots_update" on public.slots;
drop policy if exists "slots_delete" on public.slots;
-- Seuls les membres validés voient le planning.
create policy "slots_read" on public.slots for select to authenticated
  using (public.is_approved());
-- Chacun ne crée, déplace ou supprime que ses propres créneaux.
create policy "slots_insert" on public.slots for insert to authenticated
  with check (public.is_approved() and user_id = auth.uid());
create policy "slots_update" on public.slots for update to authenticated
  using (public.is_approved() and user_id = auth.uid())
  with check (user_id = auth.uid());
create policy "slots_delete" on public.slots for delete to authenticated
  using (public.is_approved() and user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Temps réel : le planning se met à jour chez tout le monde sans recharger.
-- ---------------------------------------------------------------------------
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public.slots;
    exception when duplicate_object then null;
    end;
    begin
      alter publication supabase_realtime add table public.profiles;
    exception when duplicate_object then null;
    end;
  end if;
end $$;
