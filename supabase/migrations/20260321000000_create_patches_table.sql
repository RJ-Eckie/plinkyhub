create table patches (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) not null,
  name text not null default '',
  category text not null default '',
  patch_data text not null,
  description text not null default '',
  is_public boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table patches enable row level security;

create policy "Users can read own patches"
  on patches for select using (auth.uid() = user_id);

create policy "Anyone can read public patches"
  on patches for select using (is_public = true);

create policy "Users can insert own patches"
  on patches for insert with check (auth.uid() = user_id);

create policy "Users can update own patches"
  on patches for update using (auth.uid() = user_id);

create policy "Users can delete own patches"
  on patches for delete using (auth.uid() = user_id);
