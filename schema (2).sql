-- ============================================================
-- DEAD DROP — Multiplayer schema for Supabase (Postgres)
-- Run this ENTIRE file once in your Supabase project's SQL editor
-- (Dashboard → SQL Editor → New query → paste → Run).
-- ============================================================

-- 1. PROFILES ----------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null check (char_length(username) between 3 and 20),
  created_at timestamptz not null default now(),
  season_year int not null default extract(year from (now() at time zone 'utc'))::int,
  season_points numeric not null default 0,
  season_rank text not null default 'Silver I'
);

-- if you already ran an earlier version of this schema, this safely adds the new columns
alter table public.profiles add column if not exists season_year int not null default extract(year from (now() at time zone 'utc'))::int;
alter table public.profiles add column if not exists season_points numeric not null default 0;
alter table public.profiles add column if not exists season_rank text not null default 'Silver I';

alter table public.profiles enable row level security;

drop policy if exists "profiles are publicly readable" on public.profiles;
create policy "profiles are publicly readable"
  on public.profiles for select
  using (true);

drop policy if exists "users can insert their own profile" on public.profiles;
create policy "users can insert their own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

drop policy if exists "users can update their own profile" on public.profiles;
create policy "users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- 2. CASE ITEM POOL (reference data — edit/add rows any time) ----
create table if not exists public.case_items (
  id serial primary key,
  tier_key text not null,       -- milspec | restricted | classified | covert | rare
  weapon text not null,
  skin text not null,
  pattern_type text              -- casehardened | doppler | fade | marblefade | null
);

insert into public.case_items (tier_key, weapon, skin, pattern_type) values
  -- Mil-Spec (blue)
  ('milspec','MP9','Sand Dashed', null),
  ('milspec','P250','Sand Dune', null),
  ('milspec','Nova','Predator', null),
  ('milspec','MAC-10','Toybox', null),
  ('milspec','Five-SeveN','Copper Galaxy', null),
  ('milspec','UMP-45','Grand Prix', null),
  ('milspec','Negev','Anodized Navy', null),
  ('milspec','MP9','Hot Rod', null),
  ('milspec','MP9','Pandora''s Box', null),
  ('milspec','USP-S','Silent Shot', null),
  ('milspec','MP9','Broken Record', null),
  ('milspec','SG 553','Heavy Metal', null),
  ('milspec','AWP','Acheron', null),
  ('milspec','P250','White Out', null),
  ('milspec','Galil AR','Rocket Pop', null),
  ('milspec','AK-47','Safari Mesh', null),
  ('milspec','USP-S','Forest Leaves', null),
  -- Restricted (purple)
  ('restricted','M4A1-S','Guardian', null),
  ('restricted','Glock-18','Bunsen Burner', null),
  ('restricted','AK-47','Jet Set', null),
  ('restricted','USP-S','Cyrex', null),
  ('restricted','Desert Eagle','Naga', null),
  ('restricted','FAMAS','Roll Cage', null),
  ('restricted','AK-47','Redline', null),
  ('restricted','M4A4','Desolate Space', null),
  ('restricted','Glock-18','Water Elemental', null),
  ('restricted','Galil AR','Crimson Tsunami', null),
  ('restricted','USP-S','Guardian', null),
  ('restricted','AK-47','Orbit Mk01', null),
  ('restricted','AK-47','Slate', null),
  ('restricted','AK-47','Rat Rod', null),
  -- Classified (pink)
  ('classified','AWP','Chromatic Aberration', null),
  ('classified','M4A4','The Emperor', null),
  ('classified','AK-47','Neon Rider', null),
  ('classified','Glock-18','Vogue', null),
  ('classified','P90','Shallow Grave', null),
  ('classified','AK-47','Case Hardened','casehardened'),
  ('classified','AWP','Hyper Beast', null),
  ('classified','Glock-18','Twilight Galaxy', null),
  ('classified','AK-47','Frontside Misty', null),
  ('classified','AK-47','Ice Coaled', null),
  ('classified','Desert Eagle','Mecha Industries', null),
  ('classified','P250','Visions', null),
  ('classified','AK-47','The Outsiders', null),
  ('classified','AK-47','Hydroponic', null),
  -- Covert (red)
  ('covert','AK-47','Bloodsport', null),
  ('covert','M4A1-S','Hyper Beast', null),
  ('covert','AWP','Wildfire', null),
  ('covert','Desert Eagle','Blaze', null),
  ('covert','AK-47','Fire Serpent', null),
  ('covert','AK-47','Wasteland Rebel', null),
  ('covert','AK-47','Jaguar', null),
  ('covert','AK-47','Legion of Anubis', null),
  ('covert','AWP','Chrome Cannon', null),
  ('covert','USP-S','Neo-Noir', null),
  ('covert','AK-47','Consequence of the Jinn', null),
  ('covert','AWP','Queen''s Gambit', null),
  ('covert','Glock-18','Fully Tuned', null),
  ('covert','AWP','Dragon Lore', null),
  -- Rare Special (gold — knives & gloves)
  ('rare','★ Karambit','Doppler','doppler'),
  ('rare','★ Butterfly Knife','Doppler','doppler'),
  ('rare','★ M9 Bayonet','Doppler','doppler'),
  ('rare','★ Karambit','Fade','fade'),
  ('rare','★ Karambit','Marble Fade','marblefade'),
  ('rare','★ Sport Gloves','Vice', null),
  ('rare','★ Bayonet','Tiger Tooth', null),
  ('rare','★ Talon Knife','Tiger Tooth', null),
  ('rare','★ Driver Gloves','King Snake', null),
  ('rare','★ Specialist Gloves','Crimson Kimono', null)
on conflict do nothing;
-- case_items is non-sensitive reference data, intentionally left without RLS.

-- 3. DROPS ---------------------------------------------------------
create table if not exists public.drops (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  day_key date not null,
  tier_key text not null,
  weapon text not null,
  skin text not null,
  pattern_type text,
  float numeric(6,4) not null,
  seed int not null,
  special_label text,
  rank_score numeric not null,
  points_earned int not null default 0,
  created_at timestamptz not null default now(),
  unique (user_id, day_key)      -- hard guarantee: one drop per user per day
);

alter table public.drops add column if not exists points_earned int not null default 0;

create index if not exists drops_day_key_idx on public.drops(day_key);
create index if not exists drops_rank_score_idx on public.drops(rank_score desc);
create index if not exists drops_user_id_idx on public.drops(user_id);

alter table public.drops enable row level security;

drop policy if exists "drops are publicly readable" on public.drops;
create policy "drops are publicly readable"
  on public.drops for select
  using (true);

drop policy if exists "users can insert their own drop" on public.drops;
create policy "users can insert their own drop"
  on public.drops for insert
  with check (auth.uid() = user_id);

-- 4. RANK SYSTEM ----------------------------------------------------
-- 18 competitive-style ranks, gained by season points earned from drops.
-- Season resets every calendar year (profiles.season_year is checked lazily
-- on each open — no cron job needed).
create or replace function public.rank_for_points(p numeric)
returns text
language sql
immutable
as $$
  select case
    when p >= 1000 then 'Global Elite'
    when p >= 850  then 'Supreme Master First Class'
    when p >= 730  then 'Legendary Eagle Master'
    when p >= 630  then 'Legendary Eagle'
    when p >= 540  then 'Distinguished Master Guardian'
    when p >= 460  then 'Master Guardian Elite'
    when p >= 390  then 'Master Guardian II'
    when p >= 330  then 'Master Guardian I'
    when p >= 275  then 'Gold Nova Master'
    when p >= 225  then 'Gold Nova III'
    when p >= 180  then 'Gold Nova II'
    when p >= 140  then 'Gold Nova I'
    when p >= 105  then 'Silver Elite Master'
    when p >= 75   then 'Silver Elite'
    when p >= 50   then 'Silver IV'
    when p >= 30   then 'Silver III'
    when p >= 15   then 'Silver II'
    else 'Silver I'
  end;
$$;

-- 5. DAILY OPEN FUNCTION -------------------------------------------
-- This is the whole point: the roll happens here, server-side, where a
-- player can't reach it with devtools. The client only ever gets the result.
create or replace function public.open_daily_case()
returns setof public.drops
language plpgsql
security invoker
as $$
declare
  v_uid uuid := auth.uid();
  v_day date;
  v_r numeric := random();
  v_tier text;
  v_tier_rank int;
  v_weapon text;
  v_skin text;
  v_pattern text;
  v_float numeric;
  v_seed int;
  v_special text;
  v_rank_score numeric;
  v_phase_r numeric;
  v_fade_pct numeric;
  v_points int;
  v_this_year int := extract(year from (now() at time zone 'utc'))::int;
  v_cur_season_year int;
  v_cur_season_points numeric;
  v_new_season_points numeric;
  v_new_season_rank text;
  ch_tier0 int[] := array[661];
  ch_tier1 int[] := array[151,955,321,387,670,179];
  ch_tier2 int[] := array[592,4,905,13,168,429];
  ch_tier3 int[] := array[555,442,978,139,828,969,750,695,103,112,733,844,228,868,434,698,74,996,760,375,708,823,690,791,278,917,463,711,849,92,82,450,512,310,713,11,721,236,172,950,147,782,322,363,189,961,497,430,887,426,862];
begin
  if v_uid is null then
    raise exception 'You must be signed in to open a case.';
  end if;

  -- day boundary: resets 02:00 CET (fixed UTC+1 — swap to interval '2 hours'
  -- for the summer months if you want to track real CEST)
  v_day := ((now() at time zone 'utc') - interval '1 hour')::date;

  if exists (select 1 from public.drops where user_id = v_uid and day_key = v_day) then
    raise exception 'You already opened today''s case. Come back after the reset.';
  end if;

  -- weighted rarity tier roll — mirrors Valve's official case odds
  if v_r <= 0.7992 then v_tier := 'milspec'; v_tier_rank := 0;
  elsif v_r <= 0.9590 then v_tier := 'restricted'; v_tier_rank := 1;
  elsif v_r <= 0.9910 then v_tier := 'classified'; v_tier_rank := 2;
  elsif v_r <= 0.9974 then v_tier := 'covert'; v_tier_rank := 3;
  else v_tier := 'rare'; v_tier_rank := 4;
  end if;

  select weapon, skin, pattern_type into v_weapon, v_skin, v_pattern
  from public.case_items where tier_key = v_tier
  order by random() limit 1;

  v_float := round((random()*0.98)::numeric, 4);
  v_seed := floor(random()*1000)::int + 1;

  v_special := null;
  v_rank_score := v_tier_rank * 1000;

  if v_pattern = 'casehardened' then
    if v_seed = any(ch_tier0) then v_special := '★ Blue Gem — "The Scar"'; v_rank_score := v_rank_score + 100;
    elsif v_seed = any(ch_tier1) then v_special := 'Blue Gem — Tier 1'; v_rank_score := v_rank_score + 85;
    elsif v_seed = any(ch_tier2) then v_special := 'Blue Gem — Tier 2'; v_rank_score := v_rank_score + 70;
    elsif v_seed = any(ch_tier3) then v_special := 'Blue Gem — Tier 3'; v_rank_score := v_rank_score + 55;
    end if;

  elsif v_pattern = 'doppler' then
    v_phase_r := random();
    if v_phase_r <= 0.245 then v_special := 'Phase 1'; v_rank_score := v_rank_score + 20;
    elsif v_phase_r <= 0.490 then v_special := 'Phase 2'; v_rank_score := v_rank_score + 35;
    elsif v_phase_r <= 0.735 then v_special := 'Phase 3'; v_rank_score := v_rank_score + 15;
    elsif v_phase_r <= 0.980 then v_special := 'Phase 4'; v_rank_score := v_rank_score + 30;
    elsif v_phase_r <= 0.987 then v_special := 'Ruby'; v_rank_score := v_rank_score + 90;
    elsif v_phase_r <= 0.994 then v_special := 'Sapphire'; v_rank_score := v_rank_score + 90;
    else v_special := 'Black Pearl'; v_rank_score := v_rank_score + 100;
    end if;

  elsif v_pattern = 'fade' then
    v_fade_pct := round((100 - (v_seed::numeric/1000)*100)::numeric, 1);
    if v_fade_pct >= 95 then
      v_special := v_fade_pct::text || '% Fade — Full Fade';
    else
      v_special := v_fade_pct::text || '% Fade';
    end if;
    v_rank_score := v_rank_score + v_fade_pct;

  elsif v_pattern = 'marblefade' then
    if v_seed % 137 = 0 then v_special := 'Fire & Ice — legendary split';
    elsif v_seed < 150 then v_special := 'Fire-dominant';
    elsif v_seed > 850 then v_special := 'Ice-dominant';
    else v_special := 'Balanced marble';
    end if;
    v_rank_score := v_rank_score + 20;
  end if;

  v_rank_score := v_rank_score + (1 - v_float) * 5;

  -- rank points awarded for this pull, by tier
  v_points := case v_tier
    when 'milspec' then 1
    when 'restricted' then 3
    when 'classified' then 8
    when 'covert' then 20
    when 'rare' then 50
    else 0
  end;

  -- season points: lazily reset when the calendar year has rolled over
  select season_year, season_points into v_cur_season_year, v_cur_season_points
  from public.profiles where id = v_uid for update;

  if v_cur_season_year is distinct from v_this_year then
    v_cur_season_points := 0;
  end if;
  v_new_season_points := v_cur_season_points + v_points;
  v_new_season_rank := public.rank_for_points(v_new_season_points);

  update public.profiles
  set season_year = v_this_year,
      season_points = v_new_season_points,
      season_rank = v_new_season_rank
  where id = v_uid;

  return query
    insert into public.drops
      (user_id, day_key, tier_key, weapon, skin, pattern_type, float, seed, special_label, rank_score, points_earned)
    values
      (v_uid, v_day, v_tier, v_weapon, v_skin, v_pattern, v_float, v_seed, v_special, v_rank_score, v_points)
    returning *;
exception
  when unique_violation then
    raise exception 'You already opened today''s case. Come back after the reset.';
end;
$$;

grant execute on function public.open_daily_case() to authenticated;
