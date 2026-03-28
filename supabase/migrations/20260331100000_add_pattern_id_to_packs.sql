-- Add pattern_id foreign key to packs table
alter table packs
  add column pattern_id uuid references patterns(id) on delete set null;
