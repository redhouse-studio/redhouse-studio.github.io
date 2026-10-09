// Planning Redhouse — connexion à ta base Supabase.
// Remplace les deux valeurs par celles de Supabase > Project Settings > API.
// La clé "anon public" est faite pour être publique : la sécurité vient des
// règles d'accès définies dans schema.sql, pas du secret de cette clé.
// Ne mets JAMAIS ici la clé "service_role".
window.REDHOUSE_CONFIG = {
  url: "https://TON-PROJET.supabase.co",
  anonKey: "TA-CLE-ANON-PUBLIQUE"
};
