-- Bora Jogar: nomes e cidades dos inscritos por partida
-- Somente usuários autenticados (não-anônimos) podem consultar.
-- Não retorna e-mails, senhas, telefones ou foto local do atleta.
create or replace function public.game_participants(p_game_id uuid)
returns table (
  athlete_id uuid,
  display_name text,
  city text,
  registered_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select r.user_id,
         coalesce(p.display_name, 'Atleta'),
         coalesce(p.city, 'Cidade não informada'),
         r.created_at
  from public.registrations as r
  left join public.profiles as p on p.id = r.user_id
  where r.game_id = p_game_id
    and (select auth.uid()) is not null
    and coalesce(((select auth.jwt()) ->> 'is_anonymous')::boolean, false) = false
    and exists (select 1 from public.games as g where g.id = p_game_id)
  order by r.created_at asc, r.user_id asc
  limit 300;
$$;

revoke all on function public.game_participants(uuid) from public, anon;
grant execute on function public.game_participants(uuid) to authenticated;

comment on function public.game_participants(uuid) is
'Lista nominal dos inscritos em um jogo; retorna somente nome, cidade, ID e horário de inscrição para atletas autenticados.';
