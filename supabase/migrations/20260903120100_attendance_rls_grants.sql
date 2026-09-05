-- Attendance module: RLS policies and table grants.

alter table public.attendance_folders enable row level security;
alter table public.attendance_workplaces enable row level security;
alter table public.attendance_punch_type_defs enable row level security;
alter table public.attendance_memberships enable row level security;
alter table public.attendance_punches enable row level security;
alter table public.attendance_absences enable row level security;

-- --------------------------------------------------------------------------- attendance_folders
drop policy if exists attendance_folders_select_own on public.attendance_folders;
create policy attendance_folders_select_own
  on public.attendance_folders for select to authenticated
  using (owner_id = auth.uid());

drop policy if exists attendance_folders_insert_own on public.attendance_folders;
create policy attendance_folders_insert_own
  on public.attendance_folders for insert to authenticated
  with check (owner_id = auth.uid());

drop policy if exists attendance_folders_update_own on public.attendance_folders;
create policy attendance_folders_update_own
  on public.attendance_folders for update to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

drop policy if exists attendance_folders_delete_own on public.attendance_folders;
create policy attendance_folders_delete_own
  on public.attendance_folders for delete to authenticated
  using (owner_id = auth.uid());

-- --------------------------------------------------------------------------- attendance_workplaces
drop policy if exists attendance_workplaces_select on public.attendance_workplaces;
create policy attendance_workplaces_select
  on public.attendance_workplaces for select to authenticated
  using (public.attendance_can_view_workplace(id, auth.uid()));

drop policy if exists attendance_workplaces_insert_own on public.attendance_workplaces;
create policy attendance_workplaces_insert_own
  on public.attendance_workplaces for insert to authenticated
  with check (owner_id = auth.uid());

drop policy if exists attendance_workplaces_update_own on public.attendance_workplaces;
create policy attendance_workplaces_update_own
  on public.attendance_workplaces for update to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

drop policy if exists attendance_workplaces_delete_own on public.attendance_workplaces;
create policy attendance_workplaces_delete_own
  on public.attendance_workplaces for delete to authenticated
  using (owner_id = auth.uid());

-- --------------------------------------------------------------------------- attendance_punch_type_defs
drop policy if exists attendance_punch_type_defs_select on public.attendance_punch_type_defs;
create policy attendance_punch_type_defs_select
  on public.attendance_punch_type_defs for select to authenticated
  using (public.attendance_can_view_workplace(workplace_id, auth.uid()));

drop policy if exists attendance_punch_type_defs_insert_owner on public.attendance_punch_type_defs;
create policy attendance_punch_type_defs_insert_owner
  on public.attendance_punch_type_defs for insert to authenticated
  with check (public.attendance_is_workplace_owner(workplace_id, auth.uid()));

drop policy if exists attendance_punch_type_defs_update_owner on public.attendance_punch_type_defs;
create policy attendance_punch_type_defs_update_owner
  on public.attendance_punch_type_defs for update to authenticated
  using (public.attendance_is_workplace_owner(workplace_id, auth.uid()))
  with check (public.attendance_is_workplace_owner(workplace_id, auth.uid()));

drop policy if exists attendance_punch_type_defs_delete_owner on public.attendance_punch_type_defs;
create policy attendance_punch_type_defs_delete_owner
  on public.attendance_punch_type_defs for delete to authenticated
  using (public.attendance_is_workplace_owner(workplace_id, auth.uid()));

-- --------------------------------------------------------------------------- attendance_memberships
-- SELECT: owner or self. Mutations for invite lifecycle go through RPC (security definer).
drop policy if exists attendance_memberships_select on public.attendance_memberships;
create policy attendance_memberships_select
  on public.attendance_memberships for select to authenticated
  using (
    profile_id = auth.uid()
    or public.attendance_is_workplace_owner(workplace_id, auth.uid())
  );

-- Owner may insert pending invites via PostgREST (also available via RPC).
drop policy if exists attendance_memberships_insert_owner on public.attendance_memberships;
create policy attendance_memberships_insert_owner
  on public.attendance_memberships for insert to authenticated
  with check (
    public.attendance_is_workplace_owner(workplace_id, auth.uid())
    and status = 'pending'::public.attendance_membership_status
  );

-- No direct UPDATE/DELETE for clients — status changes via RPC.
revoke insert, update, delete on public.attendance_memberships from anon;
-- Keep insert for owner policy; revoke update/delete from authenticated default then grant select only extras below.

drop policy if exists attendance_memberships_update_none on public.attendance_memberships;
-- intentionally no update/delete policies for authenticated

-- --------------------------------------------------------------------------- attendance_punches
-- SELECT only; all writes via RPC.
drop policy if exists attendance_punches_select on public.attendance_punches;
create policy attendance_punches_select
  on public.attendance_punches for select to authenticated
  using (
    profile_id = auth.uid()
    or public.attendance_is_workplace_owner(workplace_id, auth.uid())
  );

-- --------------------------------------------------------------------------- attendance_absences
drop policy if exists attendance_absences_select on public.attendance_absences;
create policy attendance_absences_select
  on public.attendance_absences for select to authenticated
  using (
    profile_id = auth.uid()
    or public.attendance_is_workplace_owner(workplace_id, auth.uid())
  );

drop policy if exists attendance_absences_insert_owner on public.attendance_absences;
create policy attendance_absences_insert_owner
  on public.attendance_absences for insert to authenticated
  with check (public.attendance_is_workplace_owner(workplace_id, auth.uid()));

drop policy if exists attendance_absences_update_owner on public.attendance_absences;
create policy attendance_absences_update_owner
  on public.attendance_absences for update to authenticated
  using (public.attendance_is_workplace_owner(workplace_id, auth.uid()))
  with check (public.attendance_is_workplace_owner(workplace_id, auth.uid()));

drop policy if exists attendance_absences_delete_owner on public.attendance_absences;
create policy attendance_absences_delete_owner
  on public.attendance_absences for delete to authenticated
  using (public.attendance_is_workplace_owner(workplace_id, auth.uid()));

-- --------------------------------------------------------------------------- GRANTs
grant select, insert, update, delete on public.attendance_folders to authenticated;
grant select, insert, update, delete on public.attendance_workplaces to authenticated;
grant select, insert, update, delete on public.attendance_punch_type_defs to authenticated;
grant select, insert on public.attendance_memberships to authenticated;
grant select on public.attendance_punches to authenticated;
grant select, insert, update, delete on public.attendance_absences to authenticated;

grant execute on function public.attendance_is_workplace_owner(uuid, uuid) to authenticated;
grant execute on function public.attendance_is_active_member(uuid, uuid) to authenticated;
grant execute on function public.attendance_can_view_workplace(uuid, uuid) to authenticated;
grant execute on function public.attendance_shift_is_open(uuid) to authenticated;
