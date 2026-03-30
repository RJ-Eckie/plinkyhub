-- Enforce that each user can only have one item with a given name per type.
ALTER TABLE samples
  ADD CONSTRAINT samples_user_id_name_unique UNIQUE (user_id, name);

ALTER TABLE presets
  ADD CONSTRAINT presets_user_id_name_unique UNIQUE (user_id, name);

ALTER TABLE packs
  ADD CONSTRAINT packs_user_id_name_unique UNIQUE (user_id, name);

ALTER TABLE wavetables
  ADD CONSTRAINT wavetables_user_id_name_unique UNIQUE (user_id, name);

ALTER TABLE patterns
  ADD CONSTRAINT patterns_user_id_name_unique UNIQUE (user_id, name);
