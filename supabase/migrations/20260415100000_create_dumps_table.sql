-- Dumps table
-- Stores metadata for flash dumps captured from a user's Plinky device.
-- Each dump represents a snapshot of the device's internal (1 MB) and
-- external (32 MB) flash memory, saved to the dumps storage bucket.
create table dumps (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  title text not null default '',
  description text not null default '',
  internal_flash_path text not null,
  external_flash_path text not null,
  internal_flash_size bigint not null default 0,
  external_flash_size bigint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index dumps_user_id_idx on dumps (user_id);
create index dumps_created_at_idx on dumps (created_at desc);

alter table dumps enable row level security;

-- A user can read their own dumps.
create policy "Users can read own dumps"
  on dumps for select using (auth.uid() = user_id);

-- A user can insert their own dumps.
create policy "Users can insert own dumps"
  on dumps for insert with check (auth.uid() = user_id);

-- A user can update their own dumps.
create policy "Users can update own dumps"
  on dumps for update using (auth.uid() = user_id);

-- A user can delete their own dumps.
create policy "Users can delete own dumps"
  on dumps for delete using (auth.uid() = user_id);

-- Dumps storage bucket (private - user data).
insert into storage.buckets (id, name, public)
  values ('dumps', 'dumps', false);

-- A user can read files inside their own folder.
-- Paths are structured as <user_id>/<dump_id>_int.bin and
-- <user_id>/<dump_id>_ext.bin.
create policy "Users can read own dump files"
  on storage.objects for select
  using (
    bucket_id = 'dumps'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- A user can upload files inside their own folder.
create policy "Users can upload own dump files"
  on storage.objects for insert
  with check (
    bucket_id = 'dumps'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- A user can delete files inside their own folder.
create policy "Users can delete own dump files"
  on storage.objects for delete
  using (
    bucket_id = 'dumps'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- Updated at trigger
create trigger set_updated_at_on_dumps
  before update on dumps
  for each row execute function set_updated_at();
