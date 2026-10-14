-- FriendChat database setup for Supabase
-- In Supabase: SQL Editor > New query > paste this file > Run.
-- This creates profiles, friend requests, private messages, row-level security, and realtime.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (char_length(username) between 3 and 24 and username ~ '^[A-Za-z0-9_]+$'),
  created_at timestamptz not null default now()
);

create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references public.profiles(id) on delete cascade,
  user_b uuid not null references public.profiles(id) on delete cascade,
  requested_by uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted','declined')),
  created_at timestamptz not null default now(),
  constraint friendship_not_self check (user_a <> user_b),
  constraint friendship_ordered check (user_a < user_b),
  constraint friendship_unique unique (user_a,user_b)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  conversation_key text not null,
  body text not null check (char_length(body) between 1 and 4000),
  created_at timestamptz not null default now(),
  constraint message_not_self check (sender_id <> receiver_id)
);

create index if not exists messages_conversation_created_idx
  on public.messages (conversation_key, created_at);

-- Create a profile automatically for each newly registered auth user.
create or replace function public.create_friendchat_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  chosen_username text;
begin
  chosen_username := coalesce(new.raw_user_meta_data ->> 'username', split_part(new.email, '@', 1));
  chosen_username := regexp_replace(chosen_username, '[^A-Za-z0-9_]', '_', 'g');
  chosen_username := left(chosen_username, 24);
  if char_length(chosen_username) < 3 then
    chosen_username := 'user_' || left(replace(new.id::text, '-', ''), 8);
  end if;
  insert into public.profiles (id, username)
  values (new.id, chosen_username);
  return new;
exception when unique_violation then
  insert into public.profiles (id, username)
  values (new.id, 'user_' || left(replace(new.id::text, '-', ''), 12));
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_friendchat on auth.users;
create trigger on_auth_user_created_friendchat
  after insert on auth.users
  for each row execute procedure public.create_friendchat_profile();

alter table public.profiles enable row level security;
alter table public.friendships enable row level security;
alter table public.messages enable row level security;

-- Profiles are visible to signed-in users so they can search usernames.
drop policy if exists "Signed-in users can read profiles" on public.profiles;
create policy "Signed-in users can read profiles"
  on public.profiles for select to authenticated using (true);

-- Users can only update their own profile.
drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile"
  on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- Friendships are visible only to their two participants.
drop policy if exists "Participants read friendships" on public.friendships;
create policy "Participants read friendships"
  on public.friendships for select to authenticated
  using (auth.uid() = user_a or auth.uid() = user_b);

-- Only the requesting user can create a pending request.
drop policy if exists "Users create their own requests" on public.friendships;
create policy "Users create their own requests"
  on public.friendships for insert to authenticated
  with check (
    auth.uid() = requested_by
    and status = 'pending'
    and (auth.uid() = user_a or auth.uid() = user_b)
  );

-- The recipient can accept or decline; the requester may not change the request.
drop policy if exists "Recipient resolves request" on public.friendships;
create policy "Recipient resolves request"
  on public.friendships for update to authenticated
  using (auth.uid() <> requested_by and (auth.uid() = user_a or auth.uid() = user_b))
  with check (auth.uid() <> requested_by and (auth.uid() = user_a or auth.uid() = user_b));

-- Only accepted friends can send/read messages between themselves.
drop policy if exists "Friends read conversation messages" on public.messages;
create policy "Friends read conversation messages"
  on public.messages for select to authenticated
  using (
    (auth.uid() = sender_id or auth.uid() = receiver_id)
    and exists (
      select 1 from public.friendships f
      where f.status = 'accepted'
        and f.user_a = least(messages.sender_id, messages.receiver_id)
        and f.user_b = greatest(messages.sender_id, messages.receiver_id)
    )
  );

drop policy if exists "Friends send messages" on public.messages;
create policy "Friends send messages"
  on public.messages for insert to authenticated
  with check (
    auth.uid() = sender_id
    and sender_id <> receiver_id
    and conversation_key = least(sender_id::text, receiver_id::text) || '_' || greatest(sender_id::text, receiver_id::text)
    and exists (
      select 1 from public.friendships f
      where f.status = 'accepted'
        and f.user_a = least(messages.sender_id, messages.receiver_id)
        and f.user_b = greatest(messages.sender_id, messages.receiver_id)
    )
  );

-- Enable live message updates for the app's realtime subscription.
do $$
begin
  alter publication supabase_realtime add table public.messages;
exception when duplicate_object then null;
when undefined_object then null;
end $$;
