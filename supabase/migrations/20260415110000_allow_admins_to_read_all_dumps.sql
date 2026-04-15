-- Allow firmware admins to read all dumps from every user so they can
-- help debug devices. Admins still cannot insert, update or delete on
-- behalf of other users; this only grants additional SELECT access.
create policy "Admins can read all dumps"
  on dumps for select using (
    auth.uid() in (
      '1fc66f06-5180-48d6-814d-9cbcdd0980d8',
      'a1248a67-da78-4b23-856f-02fc2c23d4bc',
      '3e60fdc3-fd09-44e1-a211-8c790f69899b'
    )
  );

create policy "Admins can read all dump files"
  on storage.objects for select
  using (
    bucket_id = 'dumps'
    and auth.uid() in (
      '1fc66f06-5180-48d6-814d-9cbcdd0980d8',
      'a1248a67-da78-4b23-856f-02fc2c23d4bc',
      '3e60fdc3-fd09-44e1-a211-8c790f69899b'
    )
  );
