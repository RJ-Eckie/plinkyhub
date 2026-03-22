-- Samples table
create table samples (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) not null,
  name text not null default '',
  description text not null default '',
  is_public boolean not null default false,
  file_path text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table samples enable row level security;

create policy "Users can read own samples"
  on samples for select using (auth.uid() = user_id);

create policy "Anyone can read public samples"
  on samples for select using (is_public = true);

create policy "Users can insert own samples"
  on samples for insert with check (auth.uid() = user_id);

create policy "Users can update own samples"
  on samples for update using (auth.uid() = user_id);

create policy "Users can delete own samples"
  on samples for delete using (auth.uid() = user_id);

-- Banks table
create table banks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) not null,
  name text not null default '',
  description text not null default '',
  is_public boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table banks enable row level security;

create policy "Users can read own banks"
  on banks for select using (auth.uid() = user_id);

create policy "Anyone can read public banks"
  on banks for select using (is_public = true);

create policy "Users can insert own banks"
  on banks for insert with check (auth.uid() = user_id);

create policy "Users can update own banks"
  on banks for update using (auth.uid() = user_id);

create policy "Users can delete own banks"
  on banks for delete using (auth.uid() = user_id);

-- Bank slots table
create table bank_slots (
  id uuid primary key default gen_random_uuid(),
  bank_id uuid references banks(id) on delete cascade not null,
  slot_number integer not null check (slot_number >= 0 and slot_number <= 31),
  patch_id uuid references patches(id) on delete set null,
  sample_id uuid references samples(id) on delete set null,
  unique(bank_id, slot_number)
);

alter table bank_slots enable row level security;

create policy "Users can read own bank slots"
  on bank_slots for select using (
    exists (
      select 1 from banks
      where banks.id = bank_slots.bank_id
        and banks.user_id = auth.uid()
    )
  );

create policy "Anyone can read public bank slots"
  on bank_slots for select using (
    exists (
      select 1 from banks
      where banks.id = bank_slots.bank_id
        and banks.is_public = true
    )
  );

create policy "Users can insert own bank slots"
  on bank_slots for insert with check (
    exists (
      select 1 from banks
      where banks.id = bank_slots.bank_id
        and banks.user_id = auth.uid()
    )
  );

create policy "Users can update own bank slots"
  on bank_slots for update using (
    exists (
      select 1 from banks
      where banks.id = bank_slots.bank_id
        and banks.user_id = auth.uid()
    )
  );

create policy "Users can delete own bank slots"
  on bank_slots for delete using (
    exists (
      select 1 from banks
      where banks.id = bank_slots.bank_id
        and banks.user_id = auth.uid()
    )
  );

-- Samples storage bucket
insert into storage.buckets (id, name, public)
  values ('samples', 'samples', false);

create policy "Users can upload own samples"
  on storage.objects for insert
  with check (
    bucket_id = 'samples'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can read own sample files"
  on storage.objects for select
  using (
    bucket_id = 'samples'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Anyone can read public sample files"
  on storage.objects for select
  using (
    bucket_id = 'samples'
    and exists (
      select 1 from samples
      where samples.file_path = name
        and samples.is_public = true
    )
  );

create policy "Users can delete own sample files"
  on storage.objects for delete
  using (
    bucket_id = 'samples'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
