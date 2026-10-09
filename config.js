// Planning Redhouse — connexion à la base Supabase.
// La clé "anon public" est faite pour être publique : la sécurité vient des
// règles d'accès définies dans schema.sql, pas du secret de cette clé.
// Ne mets JAMAIS ici la clé "service_role".
window.REDHOUSE_CONFIG = {
  url: "https://weijpqergukdrbkwfvtg.supabase.co",
  anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndlaWpwcWVyZ3VrZHJia3dmdnRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE1NTE2NzcsImV4cCI6MjEwNzEyNzY3N30.X1XRJ49UQlSmTAvjpTIc5zZPJG4ahFdS5_ZEqd4McOQ"
};
