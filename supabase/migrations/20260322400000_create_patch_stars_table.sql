create table patch_stars (
  id uuid primary key default gen_random_uuid(),
  patch_id uuid references patches(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  created_at timestamptz not null default now(),
  unique (patch_id, user_id)
);

alter table patch_stars enable row level security;

create policy "Anyone can read stars"
  on patch_stars for select using (true);

create policy "Users can insert own stars"
  on patch_stars for insert with check (auth.uid() = user_id);

create policy "Users can delete own stars"
  on patch_stars for delete using (auth.uid() = user_id);
