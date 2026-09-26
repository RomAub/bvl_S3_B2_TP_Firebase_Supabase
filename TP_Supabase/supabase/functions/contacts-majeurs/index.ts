// Niveau 5 : Edge Function qui compte les contacts majeurs de l'utilisateur connecte
import { createClient } from "npm:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  // On reprend le token de l'utilisateur pour que les regles RLS s'appliquent
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY") ?? req.headers.get("apikey")!,
    { global: { headers: { Authorization: req.headers.get("Authorization")! } } },
  );

  const { count: total } = await supabase
    .from("contacts")
    .select("*", { count: "exact", head: true });

  const { count: majeurs } = await supabase
    .from("contacts")
    .select("*", { count: "exact", head: true })
    .gte("age", 18);

  return new Response(JSON.stringify({ total, majeurs }), {
    headers: { "Content-Type": "application/json" },
  });
});
