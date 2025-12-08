-- Create 'playbook' bucket
insert into storage.buckets (id, name, public)
values ('playbook', 'playbook', true)
on conflict (id) do nothing;

-- Create 'timeline' bucket
insert into storage.buckets (id, name, public)
values ('timeline', 'timeline', true)
on conflict (id) do nothing;

-- Policy: Public Access for Playbook
create policy "Public Access Playbook"
  on storage.objects for select
  using ( bucket_id = 'playbook' );

-- Policy: Authenticated users can upload to Playbook
create policy "Authenticated Upload Playbook"
  on storage.objects for insert
  with check ( bucket_id = 'playbook' and auth.role() = 'authenticated' );

-- Policy: Users can update their own files in Playbook
create policy "Owner Update Playbook"
  on storage.objects for update
  using ( bucket_id = 'playbook' and auth.uid() = owner );

-- Policy: Users can delete their own files in Playbook
create policy "Owner Delete Playbook"
  on storage.objects for delete
  using ( bucket_id = 'playbook' and auth.uid() = owner );

-- Policy: Public Access for Timeline
create policy "Public Access Timeline"
  on storage.objects for select
  using ( bucket_id = 'timeline' );

-- Policy: Authenticated users can upload to Timeline
create policy "Authenticated Upload Timeline"
  on storage.objects for insert
  with check ( bucket_id = 'timeline' and auth.role() = 'authenticated' );

-- Policy: Users can update their own files in Timeline
create policy "Owner Update Timeline"
  on storage.objects for update
  using ( bucket_id = 'timeline' and auth.uid() = owner );

-- Policy: Users can delete their own files in Timeline
create policy "Owner Delete Timeline"
  on storage.objects for delete
  using ( bucket_id = 'timeline' and auth.uid() = owner );
