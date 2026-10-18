-- Hourly revalidation of community videos by the `revalidate-videos` Edge
-- Function (deploy it first: supabase functions deploy revalidate-videos
-- --no-verify-jwt).
--
-- The function is public on the network, so it only runs for callers that
-- present a secret. The secret is generated here and kept in Vault: pg_cron
-- reads it to call the function, and the function checks it through
-- verify_revalidation_secret (service role only). Nobody needs to copy it.
--
-- The job also needs the project URL in Vault, once per project:
--   select vault.create_secret('https://<ref>.supabase.co', 'project_url');

create extension if not exists pg_cron;
create extension if not exists pg_net with schema extensions;

select vault.create_secret(
  encode(extensions.gen_random_bytes(32), 'hex'),
  'revalidate_videos_secret',
  'Shared by pg_cron and the revalidate-videos Edge Function'
)
where not exists (
  select 1 from vault.secrets where name = 'revalidate_videos_secret'
);

create function public.verify_revalidation_secret(p_secret text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from vault.decrypted_secrets
    where name = 'revalidate_videos_secret'
      and decrypted_secret = p_secret
      and length(p_secret) > 0
  );
$$;

revoke all on function public.verify_revalidation_secret(text)
  from public, anon, authenticated;
grant execute on function public.verify_revalidation_secret(text)
  to service_role;

select cron.schedule(
  'revalidate-videos',
  '7 * * * *',
  $job$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets
            where name = 'project_url') || '/functions/v1/revalidate-videos',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-revalidation-secret',
      (select decrypted_secret from vault.decrypted_secrets
       where name = 'revalidate_videos_secret')
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 60000
  ) where exists (select 1 from vault.decrypted_secrets where name = 'project_url');
  $job$
);
