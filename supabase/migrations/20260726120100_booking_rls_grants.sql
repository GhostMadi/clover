-- Booking module: RLS policies and table grants.

alter table public.booking_staff enable row level security;
alter table public.booking_services enable row level security;
alter table public.booking_service_staff enable row level security;
alter table public.booking_schedule_settings enable row level security;
alter table public.booking_staff_schedule enable row level security;
alter table public.booking_staff_absences enable row level security;
alter table public.booking_blocked_slots enable row level security;
alter table public.bookings enable row level security;
alter table public.booking_history enable row level security;
alter table public.booking_reviews enable row level security;

-- --------------------------------------------------------------------------- booking_staff
drop policy if exists booking_staff_select on public.booking_staff;
create policy booking_staff_select
  on public.booking_staff
  for select
  to authenticated
  using (
    host_id = auth.uid()
    or (
      is_active = true
      and public.booking_host_has_booking_tag(host_id)
    )
  );

drop policy if exists booking_staff_insert_own on public.booking_staff;
create policy booking_staff_insert_own
  on public.booking_staff
  for insert
  to authenticated
  with check (host_id = auth.uid());

drop policy if exists booking_staff_update_own on public.booking_staff;
create policy booking_staff_update_own
  on public.booking_staff
  for update
  to authenticated
  using (host_id = auth.uid())
  with check (host_id = auth.uid());

drop policy if exists booking_staff_delete_own on public.booking_staff;
create policy booking_staff_delete_own
  on public.booking_staff
  for delete
  to authenticated
  using (host_id = auth.uid());

-- --------------------------------------------------------------------------- booking_services
drop policy if exists booking_services_select on public.booking_services;
create policy booking_services_select
  on public.booking_services
  for select
  to authenticated
  using (
    host_id = auth.uid()
    or (
      is_active = true
      and public.booking_host_has_booking_tag(host_id)
    )
  );

drop policy if exists booking_services_insert_own on public.booking_services;
create policy booking_services_insert_own
  on public.booking_services
  for insert
  to authenticated
  with check (host_id = auth.uid());

drop policy if exists booking_services_update_own on public.booking_services;
create policy booking_services_update_own
  on public.booking_services
  for update
  to authenticated
  using (host_id = auth.uid())
  with check (host_id = auth.uid());

drop policy if exists booking_services_delete_own on public.booking_services;
create policy booking_services_delete_own
  on public.booking_services
  for delete
  to authenticated
  using (host_id = auth.uid());

-- --------------------------------------------------------------------------- booking_service_staff
drop policy if exists booking_service_staff_select on public.booking_service_staff;
create policy booking_service_staff_select
  on public.booking_service_staff
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.booking_services s
      where s.id = booking_service_staff.service_id
        and (
          s.host_id = auth.uid()
          or (s.is_active = true and public.booking_host_has_booking_tag(s.host_id))
        )
    )
  );

drop policy if exists booking_service_staff_insert_own on public.booking_service_staff;
create policy booking_service_staff_insert_own
  on public.booking_service_staff
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.booking_services s
      where s.id = service_id
        and s.host_id = auth.uid()
    )
  );

drop policy if exists booking_service_staff_delete_own on public.booking_service_staff;
create policy booking_service_staff_delete_own
  on public.booking_service_staff
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.booking_services s
      where s.id = booking_service_staff.service_id
        and s.host_id = auth.uid()
    )
  );

-- --------------------------------------------------------------------------- booking_schedule_settings
drop policy if exists booking_schedule_settings_select on public.booking_schedule_settings;
create policy booking_schedule_settings_select
  on public.booking_schedule_settings
  for select
  to authenticated
  using (
    host_id = auth.uid()
    or public.booking_host_has_booking_tag(host_id)
  );

drop policy if exists booking_schedule_settings_insert_own on public.booking_schedule_settings;
create policy booking_schedule_settings_insert_own
  on public.booking_schedule_settings
  for insert
  to authenticated
  with check (host_id = auth.uid());

drop policy if exists booking_schedule_settings_update_own on public.booking_schedule_settings;
create policy booking_schedule_settings_update_own
  on public.booking_schedule_settings
  for update
  to authenticated
  using (host_id = auth.uid())
  with check (host_id = auth.uid());

-- --------------------------------------------------------------------------- booking_staff_schedule
drop policy if exists booking_staff_schedule_select on public.booking_staff_schedule;
create policy booking_staff_schedule_select
  on public.booking_staff_schedule
  for select
  to authenticated
  using (
    host_id = auth.uid()
    or public.booking_host_has_booking_tag(host_id)
  );

drop policy if exists booking_staff_schedule_insert_own on public.booking_staff_schedule;
create policy booking_staff_schedule_insert_own
  on public.booking_staff_schedule
  for insert
  to authenticated
  with check (host_id = auth.uid());

drop policy if exists booking_staff_schedule_update_own on public.booking_staff_schedule;
create policy booking_staff_schedule_update_own
  on public.booking_staff_schedule
  for update
  to authenticated
  using (host_id = auth.uid())
  with check (host_id = auth.uid());

drop policy if exists booking_staff_schedule_delete_own on public.booking_staff_schedule;
create policy booking_staff_schedule_delete_own
  on public.booking_staff_schedule
  for delete
  to authenticated
  using (host_id = auth.uid());

-- --------------------------------------------------------------------------- booking_staff_absences
drop policy if exists booking_staff_absences_select on public.booking_staff_absences;
create policy booking_staff_absences_select
  on public.booking_staff_absences
  for select
  to authenticated
  using (
    host_id = auth.uid()
    or public.booking_host_has_booking_tag(host_id)
  );

drop policy if exists booking_staff_absences_insert_own on public.booking_staff_absences;
create policy booking_staff_absences_insert_own
  on public.booking_staff_absences
  for insert
  to authenticated
  with check (host_id = auth.uid());

drop policy if exists booking_staff_absences_update_own on public.booking_staff_absences;
create policy booking_staff_absences_update_own
  on public.booking_staff_absences
  for update
  to authenticated
  using (host_id = auth.uid())
  with check (host_id = auth.uid());

drop policy if exists booking_staff_absences_delete_own on public.booking_staff_absences;
create policy booking_staff_absences_delete_own
  on public.booking_staff_absences
  for delete
  to authenticated
  using (host_id = auth.uid());

-- --------------------------------------------------------------------------- booking_blocked_slots
drop policy if exists booking_blocked_slots_select_own on public.booking_blocked_slots;
create policy booking_blocked_slots_select_own
  on public.booking_blocked_slots
  for select
  to authenticated
  using (host_id = auth.uid());

drop policy if exists booking_blocked_slots_insert_own on public.booking_blocked_slots;
create policy booking_blocked_slots_insert_own
  on public.booking_blocked_slots
  for insert
  to authenticated
  with check (host_id = auth.uid());

drop policy if exists booking_blocked_slots_update_own on public.booking_blocked_slots;
create policy booking_blocked_slots_update_own
  on public.booking_blocked_slots
  for update
  to authenticated
  using (host_id = auth.uid())
  with check (host_id = auth.uid());

drop policy if exists booking_blocked_slots_delete_own on public.booking_blocked_slots;
create policy booking_blocked_slots_delete_own
  on public.booking_blocked_slots
  for delete
  to authenticated
  using (host_id = auth.uid());

-- --------------------------------------------------------------------------- bookings (read only; writes via RPC)
drop policy if exists bookings_select_participant on public.bookings;
create policy bookings_select_participant
  on public.bookings
  for select
  to authenticated
  using (host_id = auth.uid() or client_id = auth.uid());

-- --------------------------------------------------------------------------- booking_history
drop policy if exists booking_history_select_participant on public.booking_history;
create policy booking_history_select_participant
  on public.booking_history
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.bookings b
      where b.id = booking_history.booking_id
        and (b.host_id = auth.uid() or b.client_id = auth.uid())
    )
  );

-- --------------------------------------------------------------------------- booking_reviews
drop policy if exists booking_reviews_select on public.booking_reviews;
create policy booking_reviews_select
  on public.booking_reviews
  for select
  to authenticated
  using (
    host_id = auth.uid()
    or client_id = auth.uid()
    or public.booking_host_has_booking_tag(host_id)
  );

-- --------------------------------------------------------------------------- grants
grant select, insert, update, delete on public.booking_staff to authenticated;
grant select, insert, update, delete on public.booking_services to authenticated;
grant select, insert, delete on public.booking_service_staff to authenticated;
grant select, insert, update on public.booking_schedule_settings to authenticated;
grant select, insert, update, delete on public.booking_staff_schedule to authenticated;
grant select, insert, update, delete on public.booking_staff_absences to authenticated;
grant select, insert, update, delete on public.booking_blocked_slots to authenticated;
grant select on public.bookings to authenticated;
grant select on public.booking_history to authenticated;
grant select on public.booking_reviews to authenticated;
