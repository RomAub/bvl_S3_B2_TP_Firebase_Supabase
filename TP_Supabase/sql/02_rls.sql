-- Niveau 3 : Row Level Security, chaque utilisateur ne voit que ses donnees
alter table groupes enable row level security;
alter table contacts enable row level security;
alter table profils enable row level security;

create policy "Lecture de ses propres groupes" on groupes
  for select using (auth.uid() = proprietaire);
create policy "Insertion groupe si connecte" on groupes
  for insert with check (auth.uid() = proprietaire);
create policy "Suppression de ses groupes" on groupes
  for delete using (auth.uid() = proprietaire);

create policy "Lecture de ses propres contacts" on contacts
  for select using (auth.uid() = proprietaire);
create policy "Insertion contact si connecte" on contacts
  for insert with check (auth.uid() = proprietaire);
create policy "Modification de ses contacts" on contacts
  for update using (auth.uid() = proprietaire);
create policy "Suppression de ses contacts" on contacts
  for delete using (auth.uid() = proprietaire);

create policy "Lecture de son profil" on profils
  for select using (auth.uid() = id);
create policy "Creation de son profil" on profils
  for insert with check (auth.uid() = id);
create policy "Modification de son profil" on profils
  for update using (auth.uid() = id);

-- Niveau 4 : activer le temps reel sur la table contacts
alter publication supabase_realtime add table contacts;
