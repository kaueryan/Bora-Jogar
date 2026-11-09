-- Aplicada ao projeto Bora Jogar Beta (jjxqfqejhgteqcqxwzks) em 09/11/2026.
-- Para projetos existentes, rode somente se a migracao ainda nao tiver sido aplicada.
-- Exigir contas por e-mail e senha. A CONFIRMACAO POR E-MAIL
-- e configurada em Supabase > Authentication > Providers > Email.
-- JWT is_anonymous evita que sessao anonima antiga escreva/leia dados protegidos.

create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null check (char_length(btrim(display_name)) between 2 and 45),
 city text not null check (city in ('Praia Grande','Santos','São Vicente','Mongaguá')),
 favorite text not null default 'volei' check (favorite in ('volei','basquete','futebol')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
revoke all on public.profiles from anon, authenticated;
grant select, insert on public.profiles to authenticated;
grant update (display_name,city,favorite) on public.profiles to authenticated;

drop policy if exists "profiles owner read" on public.profiles;
drop policy if exists "profiles owner create" on public.profiles;
drop policy if exists "profiles owner edit" on public.profiles;
create policy "profiles owner read" on public.profiles for select to authenticated
 using (id=(select auth.uid()) and coalesce((auth.jwt()->>'is_anonymous')::boolean,false)=false);
create policy "profiles owner create" on public.profiles for insert to authenticated
 with check (id=(select auth.uid()) and coalesce((auth.jwt()->>'is_anonymous')::boolean,false)=false);
create policy "profiles owner edit" on public.profiles for update to authenticated
 using (id=(select auth.uid()) and coalesce((auth.jwt()->>'is_anonymous')::boolean,false)=false)
 with check (id=(select auth.uid()) and coalesce((auth.jwt()->>'is_anonymous')::boolean,false)=false);

-- Permissoes das partidas sempre respeitam a conta autenticada.
revoke all on public.games,public.registrations from anon,authenticated;
grant select,insert,delete on public.games,public.registrations to authenticated;
drop policy if exists "games created by same user" on public.games;
drop policy if exists "games deleted only by creator" on public.games;
drop policy if exists "games readable by signed in (including anonymous)" on public.games;
drop policy if exists "registrations deleted by attendee" on public.registrations;
drop policy if exists "registrations inserted for current user" on public.registrations;
drop policy if exists "registrations readable for counts" on public.registrations;
create policy "games readable by registered athletes" on public.games for select to authenticated
 using (coalesce((auth.jwt()->>'is_anonymous')::boolean,false)=false);
create policy "games created by owner" on public.games for insert to authenticated
 with check (creator_id=(select auth.uid()) and coalesce((auth.jwt()->>'is_anonymous')::boolean,false)=false);
create policy "games deleted by owner" on public.games for delete to authenticated
 using (creator_id=(select auth.uid()) and coalesce((auth.jwt()->>'is_anonymous')::boolean,false)=false);
create policy "registrations visible to athletes" on public.registrations for select to authenticated
 using (coalesce((auth.jwt()->>'is_anonymous')::boolean,false)=false);
create policy "registrations owner joins" on public.registrations for insert to authenticated
 with check (user_id=(select auth.uid()) and coalesce((auth.jwt()->>'is_anonymous')::boolean,false)=false);
create policy "registrations owner leaves" on public.registrations for delete to authenticated
 using (user_id=(select auth.uid()) and coalesce((auth.jwt()->>'is_anonymous')::boolean,false)=false);
