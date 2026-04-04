-- Firmwares table
create table firmwares (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id),
  name text not null default '',
  version text not null default '',
  description text not null default '',
  is_beta boolean not null default false,
  file_path text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table firmwares enable row level security;

-- Anyone can read firmwares (they are always public).
create policy "Anyone can read firmwares"
  on firmwares for select using (true);

-- Only allowed admins can insert/update/delete.
create policy "Admins can insert firmwares"
  on firmwares for insert with check (
    auth.uid() in (
      '1fc66f06-5180-48d6-814d-9cbcdd0980d8',
      'a1248a67-da78-4b23-856f-02fc2c23d4bc',
      '3e60fdc3-fd09-44e1-a211-8c790f69899b'
    )
  );

create policy "Admins can update firmwares"
  on firmwares for update using (
    auth.uid() in (
      '1fc66f06-5180-48d6-814d-9cbcdd0980d8',
      'a1248a67-da78-4b23-856f-02fc2c23d4bc',
      '3e60fdc3-fd09-44e1-a211-8c790f69899b'
    )
  );

create policy "Admins can delete firmwares"
  on firmwares for delete using (
    auth.uid() in (
      '1fc66f06-5180-48d6-814d-9cbcdd0980d8',
      'a1248a67-da78-4b23-856f-02fc2c23d4bc',
      '3e60fdc3-fd09-44e1-a211-8c790f69899b'
    )
  );

-- Firmwares storage bucket
insert into storage.buckets (id, name, public)
  values ('firmwares', 'firmwares', false);

-- Anyone can read firmware files (always public).
create policy "Anyone can read firmware files"
  on storage.objects for select
  using (bucket_id = 'firmwares');

-- Only admins can upload firmware files.
create policy "Admins can upload firmware files"
  on storage.objects for insert
  with check (
    bucket_id = 'firmwares'
    and auth.uid() in (
      '1fc66f06-5180-48d6-814d-9cbcdd0980d8',
      'a1248a67-da78-4b23-856f-02fc2c23d4bc',
      '3e60fdc3-fd09-44e1-a211-8c790f69899b'
    )
  );

-- Only admins can delete firmware files.
create policy "Admins can delete firmware files"
  on storage.objects for delete
  using (
    bucket_id = 'firmwares'
    and auth.uid() in (
      '1fc66f06-5180-48d6-814d-9cbcdd0980d8',
      'a1248a67-da78-4b23-856f-02fc2c23d4bc',
      '3e60fdc3-fd09-44e1-a211-8c790f69899b'
    )
  );

-- Updated at trigger
create trigger set_updated_at_on_firmwares
  before update on firmwares
  for each row execute function set_updated_at();
