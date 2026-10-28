create extension if not exists pgcrypto;

create table if not exists projects(
 id uuid primary key default gen_random_uuid(), name text not null, image_url text, description text,
 features jsonb default '[]', registration_fee numeric(12,2) not null default 0,
 active boolean not null default true, sort_order int not null default 0, created_at timestamptz default now()
);
create table if not exists pricing_plans(
 id uuid primary key default gen_random_uuid(), name text not null, price numeric(12,2) not null default 0,
 registration_fee numeric(12,2) not null default 0, description text, features jsonb default '[]',
 active boolean not null default true, sort_order int not null default 0, created_at timestamptz default now()
);
create table if not exists customers(
 id uuid primary key default gen_random_uuid(), user_id uuid unique references auth.users(id) on delete cascade,
 customer_code text unique, full_name text not null, mobile text not null, email text not null,
 created_at timestamptz default now()
);
create table if not exists registrations(
 id uuid primary key default gen_random_uuid(), registration_code text unique,
 user_id uuid references auth.users(id) on delete cascade,
 project_id uuid references projects(id), plan_id uuid references pricing_plans(id),
 registration_fee numeric(12,2) not null default 0, status text not null default 'Submitted',
 created_at timestamptz default now()
);
create table if not exists addresses(
 id uuid primary key default gen_random_uuid(), user_id uuid references auth.users(id) on delete cascade,
 registration_id uuid references registrations(id) on delete cascade, full_name text, mobile text,
 house text, area text, city text, district text, state text, pin text, whatsapp text,
 created_at timestamptz default now()
);
create table if not exists admin_users(
 user_id uuid primary key references auth.users(id) on delete cascade,
 role text not null default 'support', permissions jsonb default '{}', created_at timestamptz default now()
);
create table if not exists audit_logs(
 id bigint generated always as identity primary key, actor_user_id uuid, action text not null,
 entity_type text, entity_id text, metadata jsonb default '{}', created_at timestamptz default now()
);

create or replace function next_customer_code() returns text language plpgsql as $$
declare n bigint;
begin select count(*)+1 into n from customers; return 'CUST-'||to_char(current_date,'YYYY')||'-'||lpad(n::text,5,'0'); end $$;
create or replace function next_registration_code() returns text language plpgsql as $$
declare n bigint;
begin select count(*)+1 into n from registrations; return 'REG-'||to_char(current_date,'YYYY')||'-'||lpad(n::text,5,'0'); end $$;

create or replace function set_codes() returns trigger language plpgsql as $$
begin
 if new.customer_code is null then new.customer_code:=next_customer_code(); end if;
 return new;
end $$;
drop trigger if exists customers_codes on customers;
create trigger customers_codes before insert on customers for each row execute function set_codes();

create or replace function set_reg_code() returns trigger language plpgsql as $$
begin if new.registration_code is null then new.registration_code:=next_registration_code(); end if; return new; end $$;
drop trigger if exists registrations_codes on registrations;
create trigger registrations_codes before insert on registrations for each row execute function set_reg_code();

alter table projects enable row level security;
alter table pricing_plans enable row level security;
alter table customers enable row level security;
alter table registrations enable row level security;
alter table addresses enable row level security;
alter table admin_users enable row level security;
alter table audit_logs enable row level security;

create policy "public active projects" on projects for select using (active=true);
create policy "public active plans" on pricing_plans for select using (active=true);
create policy "customer own profile" on customers for select using (auth.uid()=user_id);
create policy "customer create own profile" on customers for insert with check (auth.uid()=user_id);
create policy "customer own registrations" on registrations for select using (auth.uid()=user_id);
create policy "customer create own registrations" on registrations for insert with check (auth.uid()=user_id);
create policy "customer own addresses" on addresses for select using (auth.uid()=user_id);
create policy "customer create own addresses" on addresses for insert with check (auth.uid()=user_id);

create or replace function is_admin() returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from admin_users where user_id=auth.uid());
$$;

create policy "admins manage projects" on projects for all using (is_admin()) with check (is_admin());
create policy "admins manage plans" on pricing_plans for all using (is_admin()) with check (is_admin());
create policy "admins read customers" on customers for select using (is_admin() or auth.uid()=user_id);
create policy "admins manage registrations" on registrations for all using (is_admin() or auth.uid()=user_id) with check (is_admin() or auth.uid()=user_id);
create policy "admins manage addresses" on addresses for all using (is_admin() or auth.uid()=user_id) with check (is_admin() or auth.uid()=user_id);
create policy "admins read admin users" on admin_users for select using (is_admin() or auth.uid()=user_id);
create policy "admins audit logs" on audit_logs for select using (is_admin());
