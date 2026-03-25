alter table packs
  add constraint packs_user_id_profiles_fkey
  foreign key (user_id) references profiles(id);

alter table samples
  add constraint samples_user_id_profiles_fkey
  foreign key (user_id) references profiles(id);
