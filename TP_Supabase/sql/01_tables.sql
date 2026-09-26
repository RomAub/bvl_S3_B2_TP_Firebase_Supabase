-- Niveau 1 et 2 : tables contacts et groupes (cle etrangere)
create table groupes (
  id bigint generated always as identity primary key,
  nom text not null,
  proprietaire uuid references auth.users(id) default auth.uid()
);

create table contacts (
  id uuid primary key default gen_random_uuid(),
  nom text not null,
  telephone text,
  age int,
  groupe_id bigint references groupes(id) on delete set null,
  proprietaire uuid references auth.users(id) default auth.uid(),
  date_creation timestamp default now()
);

-- Profil pour la photo (partie Storage)
create table profils (
  id uuid primary key references auth.users(id),
  pseudo text,
  photo_url text
);
