-- 오르락 미션 빙고 · Supabase 초기 설정
-- Supabase 대시보드 > SQL Editor 에 통째로 붙여넣고 Run 한 번.
-- 그다음 index.html 맨 위 CONFIG 에 Project URL 과 anon public key 를 넣으면 됩니다.

-- 1) 모든 데이터(참가자·미션·빙고 칸·설정)를 담는 테이블
create table if not exists public.docs (
  col        text        not null,
  id         text        not null,
  data       jsonb       not null,
  updated_at timestamptz not null default now(),
  primary key (col, id)
);

alter table public.docs enable row level security;

-- 프로젝트를 만들 때 "Grant API access to new tables automatically"를 껐어도 동작하도록 직접 권한을 줍니다.
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.docs to anon, authenticated;

-- 로그인 없이 이름 + 0000 으로 들어오는 행사용 페이지라 누구나 읽고 쓸 수 있게 엽니다.
-- (권한 구분은 페이지 안에서만 합니다. 행사가 끝나면 프로젝트를 일시정지하거나 지우세요.)
drop policy if exists "docs open" on public.docs;
create policy "docs open" on public.docs for all to anon, authenticated using (true) with check (true);

-- 다른 사람이 바꾼 내용이 바로 보이도록 실시간 전송 켜기
do $$ begin
  alter publication supabase_realtime add table public.docs;
exception when duplicate_object then null; end $$;

-- 2) 인증 사진·영상 저장소
insert into storage.buckets (id, name, public)
values ('media', 'media', true)
on conflict (id) do update set public = true;

drop policy if exists "media read"   on storage.objects;
drop policy if exists "media upload" on storage.objects;
drop policy if exists "media delete" on storage.objects;
create policy "media read"   on storage.objects for select to anon, authenticated using (bucket_id = 'media');
create policy "media upload" on storage.objects for insert to anon, authenticated with check (bucket_id = 'media');
create policy "media delete" on storage.objects for delete to anon, authenticated using (bucket_id = 'media');
