-- ============================================================
-- Knight Warriors Club — Schema v2, Part 2 (social layer)
-- Run AFTER schema-v2-part1.sql. Safe to run once; if a statement
-- errors because an object already exists, the rest still applies.
-- Tables: notifications, broadcasts (+ fan-out trigger), squads,
-- squad_members, friendships, push_subscriptions.
-- Reuses Part 1 helpers: my_member_id(), am_committee(), am_president().
-- ============================================================

-- ---------- notifications ----------
create table if not exists public.notifications (
  id bigint generated always as identity primary key,
  member_id bigint not null references public.members(id) on delete cascade,
  type text not null default 'info',  -- info | broadcast | squad_invite | friend_request | system
  title text not null,
  body text,
  link text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

-- ---------- broadcasts (President -> all members) ----------
create table if not exists public.broadcasts (
  id bigint generated always as identity primary key,
  sender_member_id bigint references public.members(id) on delete set null,
  title text not null,
  body text not null,
  created_at timestamptz not null default now()
);

-- Fan-out: every broadcast becomes one notification per member
-- (everyone except the sender), which powers the Inbox, the unread
-- badge, the live pop-up (Realtime) and push notifications.
create or replace function public.fanout_broadcast()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (member_id, type, title, body, link)
  select m.id, 'broadcast', new.title, new.body, 'profile/inbox'
  from public.members m
  where m.id <> coalesce(new.sender_member_id, -1);
  return new;
end;
$$;

drop trigger if exists broadcasts_fanout on public.broadcasts;
create trigger broadcasts_fanout
  after insert on public.broadcasts
  for each row execute function public.fanout_broadcast();

-- ---------- squads ----------
create table if not exists public.squads (
  id bigint generated always as identity primary key,
  name text not null,
  game text not null check (game in ('eFootball', 'PUBG', 'Clash of Clans', 'Call of Duty')),
  captain_member_id bigint not null references public.members(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.squad_members (
  squad_id bigint not null references public.squads(id) on delete cascade,
  member_id bigint not null references public.members(id) on delete cascade,
  role text not null default 'Member',
  joined_at timestamptz not null default now(),
  primary key (squad_id, member_id)
);

-- Who may create a squad: the President, or a member the President
-- has switched on (members.can_create_squad from Part 1).
create or replace function public.can_i_create_squad()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select can_create_squad or role = 'President'
       from public.members
      where id = public.my_member_id()),
    false);
$$;

create or replace function public.am_captain_of(sid bigint)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists(
    select 1 from public.squads s
     where s.id = sid
       and s.captain_member_id = public.my_member_id());
$$;

-- ---------- friendships ----------
create table if not exists public.friendships (
  requester_id bigint not null references public.members(id) on delete cascade,
  addressee_id bigint not null references public.members(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  primary key (requester_id, addressee_id),
  check (requester_id <> addressee_id)
);

-- ---------- push subscriptions (Web Push opt-ins) ----------
create table if not exists public.push_subscriptions (
  id bigint generated always as identity primary key,
  member_id bigint not null references public.members(id) on delete cascade,
  endpoint text not null unique,
  p256dh text not null,
  auth text not null,
  created_at timestamptz not null default now()
);

-- ============================================================
-- Row Level Security
-- ============================================================
alter table public.notifications enable row level security;
alter table public.broadcasts enable row level security;
alter table public.squads enable row level security;
alter table public.squad_members enable row level security;
alter table public.friendships enable row level security;
alter table public.push_subscriptions enable row level security;

-- ---------- notifications policies ----------
drop policy if exists notifications_select on public.notifications;
create policy notifications_select on public.notifications
  for select using (member_id = public.my_member_id() or public.am_president());

drop policy if exists notifications_insert on public.notifications;
create policy notifications_insert on public.notifications
  for insert with check (public.am_president());

drop policy if exists notifications_update on public.notifications;
create policy notifications_update on public.notifications
  for update using (member_id = public.my_member_id() or public.am_president());

drop policy if exists notifications_delete on public.notifications;
create policy notifications_delete on public.notifications
  for delete using (member_id = public.my_member_id() or public.am_president());

-- ---------- broadcasts policies ----------
drop policy if exists broadcasts_select on public.broadcasts;
create policy broadcasts_select on public.broadcasts
  for select using (auth.uid() is not null);

drop policy if exists broadcasts_insert on public.broadcasts;
create policy broadcasts_insert on public.broadcasts
  for insert with check (public.am_president() and sender_member_id = public.my_member_id());

drop policy if exists broadcasts_delete on public.broadcasts;
create policy broadcasts_delete on public.broadcasts
  for delete using (public.am_president());

-- ---------- squads policies ----------
drop policy if exists squads_select on public.squads;
create policy squads_select on public.squads
  for select using (true);

drop policy if exists squads_insert on public.squads;
create policy squads_insert on public.squads
  for insert with check (captain_member_id = public.my_member_id() and public.can_i_create_squad());

drop policy if exists squads_update on public.squads;
create policy squads_update on public.squads
  for update using (captain_member_id = public.my_member_id() or public.am_president());

drop policy if exists squads_delete on public.squads;
create policy squads_delete on public.squads
  for delete using (captain_member_id = public.my_member_id() or public.am_president());

-- ---------- squad_members policies ----------
drop policy if exists squad_members_select on public.squad_members;
create policy squad_members_select on public.squad_members
  for select using (true);

drop policy if exists squad_members_insert on public.squad_members;
create policy squad_members_insert on public.squad_members
  for insert with check (public.am_captain_of(squad_id) or public.am_president());

drop policy if exists squad_members_update on public.squad_members;
create policy squad_members_update on public.squad_members
  for update using (public.am_captain_of(squad_id) or public.am_president());

drop policy if exists squad_members_delete on public.squad_members;
create policy squad_members_delete on public.squad_members
  for delete using (member_id = public.my_member_id() or public.am_captain_of(squad_id) or public.am_president());

-- ---------- friendships policies ----------
drop policy if exists friendships_select on public.friendships;
create policy friendships_select on public.friendships
  for select using (requester_id = public.my_member_id() or addressee_id = public.my_member_id() or public.am_committee());

drop policy if exists friendships_insert on public.friendships;
create policy friendships_insert on public.friendships
  for insert with check (requester_id = public.my_member_id() and status = 'pending');

drop policy if exists friendships_update on public.friendships;
create policy friendships_update on public.friendships
  for update using (addressee_id = public.my_member_id() or requester_id = public.my_member_id() or public.am_president());

drop policy if exists friendships_delete on public.friendships;
create policy friendships_delete on public.friendships
  for delete using (requester_id = public.my_member_id() or addressee_id = public.my_member_id() or public.am_president());

-- ---------- push_subscriptions policies ----------
drop policy if exists push_subs_select on public.push_subscriptions;
create policy push_subs_select on public.push_subscriptions
  for select using (member_id = public.my_member_id() or public.am_president());

drop policy if exists push_subs_insert on public.push_subscriptions;
create policy push_subs_insert on public.push_subscriptions
  for insert with check (member_id = public.my_member_id());

drop policy if exists push_subs_update on public.push_subscriptions;
create policy push_subs_update on public.push_subscriptions
  for update using (member_id = public.my_member_id());

drop policy if exists push_subs_delete on public.push_subscriptions;
create policy push_subs_delete on public.push_subscriptions
  for delete using (member_id = public.my_member_id() or public.am_president());

-- ============================================================
-- Grants (Data API "automatically expose new tables" is OFF)
-- ============================================================
grant select, insert, update, delete on public.notifications to authenticated;
grant select, insert, delete on public.broadcasts to authenticated;
grant select, insert, update, delete on public.squads to authenticated;
grant select, insert, update, delete on public.squad_members to authenticated;
grant select, insert, update, delete on public.friendships to authenticated;
grant select, insert, update, delete on public.push_subscriptions to authenticated;
grant select on public.squads to anon;
grant select on public.squad_members to anon;
grant usage on all sequences in schema public to authenticated;

-- ============================================================
-- Realtime: live pop-ups for new notifications
-- ============================================================
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime'
       and schemaname = 'public'
       and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end;
$$;
