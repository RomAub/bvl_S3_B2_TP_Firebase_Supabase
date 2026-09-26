-- Fiche 4, fin : le profil possede maintenant les champs pseudo, bio et location
alter table profils add column if not exists bio text;
alter table profils add column if not exists location text;

-- Mise a jour du profil de l'utilisateur connecte (romain@test.fr)
update profils
set pseudo = 'Romain',
    bio = 'Étudiant en BTS SIO option SLAM',
    location = 'France'
where id = (select id from auth.users where email = 'romain@test.fr');

select * from profils;
