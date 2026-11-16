-- 保險單追蹤系統：Supabase 一次性設定
-- 在 Supabase 專案 → SQL Editor → New query，貼上全部內容後按 Run。
-- 可重複執行。

-- 1. 資料表（工程案保單與團險保單都存在這裡，內容放在 data 欄位）
create table if not exists public.records (
  id         text primary key,
  kind       text not null check (kind in ('policy', 'group')),
  data       jsonb not null,
  updated_at timestamptz not null default now()
);

-- 2. 允許「知道網址的人」不登入就能讀寫
alter table public.records enable row level security;
drop policy if exists "public read"   on public.records;
drop policy if exists "public insert" on public.records;
drop policy if exists "public update" on public.records;
drop policy if exists "public delete" on public.records;
create policy "public read"   on public.records for select to anon using (true);
create policy "public insert" on public.records for insert to anon with check (true);
create policy "public update" on public.records for update to anon using (true) with check (true);
create policy "public delete" on public.records for delete to anon using (true);

-- 3. 即時同步（別人修改後，頁面自動更新）
do $$ begin
  alter publication supabase_realtime add table public.records;
exception when duplicate_object then null; end $$;

-- 4. 附件空間（單檔上限 50 MB）
insert into storage.buckets (id, name, public, file_size_limit)
values ('attachments', 'attachments', true, 52428800)
on conflict (id) do update set public = true, file_size_limit = 52428800;

drop policy if exists "public upload attachments" on storage.objects;
drop policy if exists "public read attachments"   on storage.objects;
drop policy if exists "public delete attachments" on storage.objects;
create policy "public upload attachments" on storage.objects for insert to anon with check (bucket_id = 'attachments');
create policy "public read attachments"   on storage.objects for select to anon using (bucket_id = 'attachments');
create policy "public delete attachments" on storage.objects for delete to anon using (bucket_id = 'attachments');
