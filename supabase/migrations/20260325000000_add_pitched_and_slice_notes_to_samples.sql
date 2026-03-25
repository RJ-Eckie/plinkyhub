alter table samples add column pitched boolean not null default false;
alter table samples add column slice_notes integer[] not null default '{48,48,48,48,48,48,48,48}';
