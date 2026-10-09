# Planning Redhouse

Calendrier de réservation du studio, accessible depuis n'importe quel navigateur.

- Chaque personne crée son compte avec son e-mail et un mot de passe.
- L'admin valide chaque nouveau compte.
- Chaque participant a sa couleur et ne peut créer, déplacer ou supprimer que ses propres créneaux.
- Deux créneaux ne peuvent jamais se chevaucher. La base de données le refuse, même si deux personnes réservent à la même seconde.

La page est hébergée gratuitement sur **GitHub Pages**. Les comptes et les créneaux sont stockés sur **Supabase**, une base de données avec offre gratuite.

Compte environ 20 minutes pour l'installation.

---

## 1. Créer la base de données (Supabase)

1. Crée un compte sur [supabase.com](https://supabase.com), puis clique sur **New project**.
   - Nom : `planning-redhouse`
   - Région : **West EU (Paris)**
   - Mot de passe de la base : génère-le et garde-le dans ton gestionnaire de mots de passe.
2. Une fois le projet prêt, ouvre **SQL Editor**, puis **New query**.
3. Colle tout le contenu du fichier `schema.sql` et clique sur **Run**.
   - Le message attendu est « Success. No rows returned ».
4. Va dans **Project Settings**, puis **API**, et note deux valeurs :
   - **Project URL**, de la forme `https://xxxx.supabase.co`
   - la clé **anon public**
5. Ouvre `config.js` et remplace les deux valeurs d'exemple par celles-ci.

> La clé `anon public` est conçue pour être visible dans une page web publique. C'est le fichier `schema.sql` qui protège les données.
> Ne mets **jamais** la clé `service_role` dans ce dossier.

## 2. Mettre la page en ligne (GitHub Pages)

1. Sur [github.com](https://github.com), clique sur **New repository**.
   - Nom : `planning-redhouse`
   - Visibilité : **Public**, obligatoire pour GitHub Pages avec un compte gratuit.
2. Clique sur **uploading an existing file** et glisse le contenu du dossier, c'est-à-dire :
   - `index.html`
   - `config.js`
   - `studio.jpg`
   - `README.md`
   - `schema.sql`

   Puis clique sur **Commit changes**.
3. Va dans **Settings**, puis **Pages**. Dans « Build and deployment » :
   - Source : **Deploy from a branch**
   - Branche : `main`, dossier `/ (root)`

   Puis **Save**.
4. Après une à deux minutes, la page est en ligne à l'adresse `https://TON-PSEUDO.github.io/planning-redhouse/`.

## 3. Relier les deux

Dans Supabase, va dans **Authentication**, puis **URL Configuration** :

- **Site URL** : `https://TON-PSEUDO.github.io/planning-redhouse/`
- **Redirect URLs** : ajoute la même adresse.

Sans ce réglage, les liens de confirmation d'inscription et de « mot de passe oublié » renverraient vers une mauvaise adresse.

## 4. Devenir admin

1. Ouvre la page et crée ton compte avec **Créer un compte**.
2. Confirme ton adresse avec le lien reçu par e-mail.
3. Dans Supabase, ouvre **SQL Editor** et lance la requête suivante, en remplaçant l'e-mail :

```sql
update public.profiles
set status = 'approved', is_admin = true
where id = (select id from auth.users where email = 'ton@email.fr');
```

4. Recharge la page : le planning s'ouvre et le bouton **Participants** apparaît.

## 5. Inviter les participants

Envoie simplement le lien de la page. Chaque personne :

1. crée son compte avec son nom, son e-mail, son mot de passe et sa couleur préférée ;
2. confirme son e-mail ;
3. attend ta validation.

Sa demande apparaît dans **Participants**, avec une pastille rouge sur le bouton. Tu y fais trois choses :

- valider la demande, en ajustant la couleur si besoin, ou la refuser ;
- changer la couleur d'un participant ;
- retirer un accès. Ses créneaux à venir sont alors libérés.

## Utilisation

| Action | Ordinateur | Téléphone |
|---|---|---|
| Créer un créneau | Glisser sur la grille | Toucher la grille |
| Déplacer son créneau | Glisser le créneau | Ouvrir le créneau, changer l'heure |
| Changer la durée | Tirer le bord bas du créneau | Ouvrir le créneau, changer la fin |
| Copier un créneau | **⌥ Option + glisser** vers un horaire libre, ou **⌥ Option + clic** pour une copie juste après | Ouvrir le créneau, puis **Dupliquer** ou **Copier à mon nom** |
| Supprimer | Ouvrir le créneau, **Supprimer**, puis **Confirmer** | Pareil |

Les modifications apparaissent en direct chez tout le monde.

## Bon à savoir

- **Offre gratuite Supabase.** Un projet gratuit inactif pendant environ une semaine peut être mis en pause. On le relance d'un clic depuis le tableau de bord Supabase.
- **E-mails de confirmation.** Le service d'e-mail intégré à Supabase est limité à un petit nombre d'envois par heure. Pour inscrire beaucoup de monde d'un coup, configure un SMTP dans **Authentication**, puis **SMTP Settings**.
- **Ce qui est public.** Le dépôt GitHub est public : le code, la photo du studio et la clé publique sont visibles. Les créneaux, les noms et les e-mails ne sont lisibles qu'après connexion avec un compte validé. Les participants ne voient jamais l'e-mail des autres : seul l'admin les voit.
- **Changer la photo de fond.** Remplace `studio.jpg` par une autre image portant le même nom.
