-- Bora Jogar beta • Execute em Supabase > SQL Editor, em projeto NOVO.
-- Auth > Providers > Email: habilite login com e-mail/senha e CONFIRMAÇÃO de e-mail.
-- Auth > Providers > Anonymous Sign-ins: pode ficar DESABILITADO.
-- Nunca exponha a chave service_role no app.
create extension if not exists pgcrypto;

create table if not exists public.games (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 3 and 100),
  sport text not null check (sport in ('volei','basquete','futebol')),
  kind text not null check (kind in ('avulsa','recorrente','campeonato')),
  city text not null check (city in ('Praia Grande','Santos','São Vicente','Mongaguá')),
  venue text not null check (char_length(venue) between 2 and 120),
  address text not null check (char_length(address) between 2 and 200),
  date date not null,
  time time not null,
  capacity integer not null check (capacity between 1 and 300),
  lat double precision not null check (lat between -25 and -23),
  lon double precision not null check (lon between -48 and -45),
  approx boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.registrations (
  game_id uuid not null references public.games(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (game_id,user_id)
);

create index if not exists idx_games_date on public.games(date,city);
create index if not exists idx_registrations_user on public.registrations(user_id);

alter table public.games enable row level security;
alter table public.registrations enable row level security;

grant select,insert,delete on public.games to authenticated;
grant select,insert,delete on public.registrations to authenticated;

create policy "games readable by signed in (including anonymous)" on public.games
 for select to authenticated using (true);
create policy "games created by same user" on public.games
 for insert to authenticated with check (creator_id=(select auth.uid()));
create policy "games deleted only by creator" on public.games
 for delete to authenticated using (creator_id=(select auth.uid()));

create policy "registrations readable for counts" on public.registrations
 for select to authenticated using (true);
create policy "registrations inserted for current user" on public.registrations
 for insert to authenticated with check (user_id=(select auth.uid()));
create policy "registrations deleted by attendee" on public.registrations
 for delete to authenticated using (user_id=(select auth.uid()));

-- Limita vagas sem condicoes de corrida: bloqueio da partida durante a inscricao.
-- A funcao privilegiada fica FORA do schema public (API), sem permissao de execucao direta.
create schema if not exists borajogar_private;
revoke all on schema borajogar_private from public, anon, authenticated;

create or replace function borajogar_private.check_capacity()
returns trigger language plpgsql security definer set search_path = '' as $$
declare max_vagas integer; ocupadas integer;
begin
 select capacity into max_vagas from public.games where id=new.game_id for update;
 if max_vagas is null then raise exception 'Evento não encontrado'; end if;
 select count(*) into ocupadas from public.registrations where game_id=new.game_id;
 if ocupadas >= max_vagas then raise exception 'Evento lotado'; end if;
 return new;
end;
$$;
revoke all on function borajogar_private.check_capacity() from public, anon, authenticated;

drop trigger if exists borajogar_capacity on public.registrations;
create trigger borajogar_capacity before insert on public.registrations
 for each row execute function borajogar_private.check_capacity();

-- Contas individuais e perfis de atletas: mesmas politicas aplicadas no Supabase ativo.
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
