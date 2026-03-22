-- Add slice points and pitch settings to samples
alter table samples
  add column slice_points double precision[] not null default '{0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875}',
  add column base_note integer not null default 60,
  add column fine_tune integer not null default 0;
