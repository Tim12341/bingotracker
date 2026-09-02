-- Эпики
create table epics (
  id text primary key,
  name text not null,
  color text not null default '#444FEF',
  status text not null default 'open' check (status in ('open','closed')),
  description text default '',
  created_at timestamptz default now()
);

-- Добавить epicId к задачам
alter table tasks add column epic_id text references epics(id);
create index idx_tasks_epic on tasks(epic_id);

-- Уведомления (per-user)
create table notifications (
  id text primary key,
  user_id text not null,
  type text not null default 'info',
  text text not null,
  task_id text references tasks(id) on delete cascade,
  read boolean not null default false,
  created_at timestamptz default now()
);
create index idx_notifications_user on notifications(user_id, read);

-- Realtime
alter publication supabase_realtime add table epics;
alter publication supabase_realtime add table notifications;
