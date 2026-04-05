create or replace function get_user_highscores()
returns table (
  user_id uuid,
  username text,
  total_stars bigint,
  total_uploads bigint
)
language sql
stable
security definer
as $$
  select
    p.id as user_id,
    p.username,
    coalesce(stars.total_stars, 0) as total_stars,
    coalesce(uploads.total_uploads, 0) as total_uploads
  from profiles p
  left join lateral (
    select count(*) as total_stars
    from (
      select ps.id from preset_stars ps join presets pr on ps.preset_id = pr.id where pr.user_id = p.id
      union all
      select ss.id from sample_stars ss join samples s on ss.sample_id = s.id where s.user_id = p.id
      union all
      select pks.id from pack_stars pks join packs pk on pks.pack_id = pk.id where pk.user_id = p.id
      union all
      select ws.id from wavetable_stars ws join wavetables w on ws.wavetable_id = w.id where w.user_id = p.id
      union all
      select pts.id from pattern_stars pts join patterns pt on pts.pattern_id = pt.id where pt.user_id = p.id
    ) all_stars
  ) stars on true
  left join lateral (
    select count(*) as total_uploads
    from (
      select id from presets where user_id = p.id and is_public = true
      union all
      select id from samples where user_id = p.id and is_public = true
      union all
      select id from packs where user_id = p.id and is_public = true
      union all
      select id from wavetables where user_id = p.id and is_public = true
      union all
      select id from patterns where user_id = p.id and is_public = true
    ) all_uploads
  ) uploads on true
  where coalesce(stars.total_stars, 0) > 0 or coalesce(uploads.total_uploads, 0) > 0
  order by coalesce(stars.total_stars, 0) desc, coalesce(uploads.total_uploads, 0) desc;
$$;
