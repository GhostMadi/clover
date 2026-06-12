-- SECURITY DEFINER не отключает RLS сам по себе: без этого PostgREST может отдавать
-- 500 при update profiles (hibernate) и 403 при delete из storage.objects (reset).
-- См. https://www.postgresql.org/docs/current/ddl-rowsecurity.html (функции definer + RLS)
alter function public.hibernate_account() set row_security to off;

alter function public.wake_up_if_needed() set row_security to off;

alter function public.reset_account() set row_security to off;
