-- Atualização do Bora Jogar: fotos privadas e perfis resumidos dos participantes.
-- Aplicada ao Supabase de produção em 09/11/2026.
alter table public.profiles add column if not exists avatar_path text;
alter table public.profiles drop constraint if exists profiles_avatar_path_owned;
alter table public.profiles add constraint profiles_avatar_path_owned
  check (avatar_path is null or avatar_path=(id::text||'/avatar.jpg'));
grant update (avatar_path) on public.profiles to authenticated;

insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('bora-avatars','bora-avatars',false,1048576,ARRAY['image/jpeg']::text[])
on conflict (id) do nothing;

drop policy if exists "bora avatars signed-in can view" on storage.objects;
drop policy if exists "bora avatars owner uploads" on storage.objects;
drop policy if exists "bora avatars owner updates" on storage.objects;
drop policy if exists "bora avatars owner deletes" on storage.objects;
create policy "bora avatars signed-in can view" on storage.objects
 for select to authenticated
 using (bucket_id='bora-avatars' and coalesce((auth.jwt()->>'is_anonymous')::boolean,false)=false);
create policy "bora avatars owner uploads" on storage.objects
 for insert to authenticated
 with check (bucket_id='bora-avatars' and name=((select auth.uid())::text||'/avatar.jpg') and coalesce((auth.jwt()->>'is_anonymous')::boolean,false)=false);
create policy "bora avatars owner updates" on storage.objects
 for update to authenticated
 using (bucket_id='bora-avatars' and name=((select auth.uid())::text||'/avatar.jpg'))
 with check (bucket_id='bora-avatars' and name=((select auth.uid())::text||'/avatar.jpg'));
create policy "bora avatars owner deletes" on storage.objects
 for delete to authenticated
 using (bucket_id='bora-avatars' and name=((select auth.uid())::text||'/avatar.jpg'));

create or replace function public.game_participants_with_photo(p_game_id uuid)
returns table (athlete_id uuid, display_name text, city text, favorite text, avatar_path text, registered_at timestamptz)
language sql stable security definer set search_path='' as $$
 select r.user_id,
    coalesce(p.display_name, 'Atleta')::text,
    coalesce(p.city, 'Cidade não informada')::text,
    coalesce(p.favorite,'volei')::text,
    p.avatar_path,
    r.created_at
 from public.registrations r
 left join public.profiles p on p.id=r.user_id
 where r.game_id=p_game_id
   and (select auth.uid()) is not null
   and coalesce(((select auth.jwt())->>'is_anonymous')::boolean,false)=false
   and exists(select 1 from public.games g where g.id=p_game_id)
 order by r.created_at, r.user_id
 limit 300
$$;
revoke all on function public.game_participants_with_photo(uuid) from public, anon;
grant execute on function public.game_participants_with_photo(uuid) to authenticated;
