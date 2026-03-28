-- Patterns table
create table patterns (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id),
  name text not null default '',
  description text not null default '',
  is_public boolean not null default false,
  file_path text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table patterns enable row level security;

create policy "Users can read own patterns"
  on patterns for select using (auth.uid() = user_id);

create policy "Anyone can read public patterns"
  on patterns for select using (is_public = true);

create policy "Users can insert own patterns"
  on patterns for insert with check (auth.uid() = user_id);

create policy "Users can update own patterns"
  on patterns for update using (auth.uid() = user_id);

create policy "Users can delete own patterns"
  on patterns for delete using (auth.uid() = user_id);

-- Pattern stars table
create table pattern_stars (
  id uuid primary key default gen_random_uuid(),
  pattern_id uuid not null references patterns(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (pattern_id, user_id)
);

alter table pattern_stars enable row level security;

create policy "Anyone can read pattern stars" on pattern_stars for select using (true);
create policy "Users can insert own pattern stars" on pattern_stars for insert with check (auth.uid() = user_id);
create policy "Users can delete own pattern stars" on pattern_stars for delete using (auth.uid() = user_id);

-- Patterns storage bucket
insert into storage.buckets (id, name, public)
  values ('patterns', 'patterns', false);

create policy "Users can upload own patterns"
  on storage.objects for insert
  with check (
    bucket_id = 'patterns'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can read own pattern files"
  on storage.objects for select
  using (
    bucket_id = 'patterns'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Anyone can read public pattern files"
  on storage.objects for select
  using (
    bucket_id = 'patterns'
    and exists (
      select 1 from patterns
      where patterns.file_path = name
        and patterns.is_public = true
    )
  );

create policy "Users can delete own pattern files"
  on storage.objects for delete
  using (
    bucket_id = 'patterns'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- Updated at trigger
create trigger set_updated_at_on_patterns
  before update on patterns
  for each row execute function set_updated_at();
