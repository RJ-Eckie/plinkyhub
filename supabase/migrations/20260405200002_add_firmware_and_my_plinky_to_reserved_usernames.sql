alter table profiles
  drop constraint username_not_reserved;

alter table profiles
  add constraint username_not_reserved
  check (lower(username) not in (
    'my-plinky',
    'editor',
    'presets',
    'packs',
    'samples',
    'wavetables',
    'patterns',
    'users',
    'profile',
    'firmware',
    'about'
  ));
