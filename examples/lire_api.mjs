// Lecture seule, avec une clé publiable et les politiques du visiteur.
const { SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY } = process.env;
if (!SUPABASE_URL || !SUPABASE_PUBLISHABLE_KEY) {
  throw new Error('Renseigner SUPABASE_URL et SUPABASE_PUBLISHABLE_KEY dans l’environnement.');
}
const response = await fetch(new URL('/rest/v1/atelier_sd_snapshot?select=payload', SUPABASE_URL), {
  headers: { apikey: SUPABASE_PUBLISHABLE_KEY, Accept: 'application/json' },
  signal: AbortSignal.timeout(15000),
});
if (!response.ok) throw new Error(`Lecture impossible : HTTP ${response.status}`);
const rows = await response.json();
if (!rows[0]?.payload) throw new Error('Point de lecture absent ou réponse inattendue.');
console.log(JSON.stringify(rows[0].payload, null, 2));
