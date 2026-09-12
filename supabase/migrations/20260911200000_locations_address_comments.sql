-- Locations address column semantics (product: docs/business/locations.md).
-- Align comments with live client contract (web resources + mobile create).

comment on column public.locations.address_primary is
  'Display/primary address: latin if provided, else cyrillic (NOT NULL).';

comment on column public.locations.address_cyrillic is
  'Cyrillic address required by product UI; stored separately from latin primary.';
