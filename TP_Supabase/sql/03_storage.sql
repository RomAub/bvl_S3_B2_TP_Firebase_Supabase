-- Bucket "photos" pour les photos de profil (public en lecture)
insert into storage.buckets (id, name, public) values ('photos', 'photos', true);

-- Un utilisateur connecte peut envoyer / remplacer uniquement SA photo (nom = son id)
create policy "Envoi de sa photo" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'photos' and name = auth.uid()::text || '.png');
create policy "Remplacement de sa photo" on storage.objects
  for update to authenticated
  using (bucket_id = 'photos' and name = auth.uid()::text || '.png');
create policy "Lecture des photos" on storage.objects
  for select using (bucket_id = 'photos');
