-- Reports table for flagging content
create table reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  sample_id uuid not null references samples(id) on delete cascade,
  reason text not null check (reason in ('copyright_infringement', 'other')),
  description text not null default '',
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

alter table reports enable row level security;

create policy "Users can insert own reports"
  on reports for insert with check (auth.uid() = reporter_id);

create policy "Users can read own reports"
  on reports for select using (auth.uid() = reporter_id);
