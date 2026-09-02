-- Схема БД для Трекера задач (Supabase / PostgreSQL)

-- Участники команды
create table members (
  id text primary key,
  name text not null,
  email text,
  created_at timestamptz default now()
);

-- Проекты
create table projects (
  id text primary key,
  name text not null,
  key text not null unique,
  color text not null default '#444FEF',
  created_at timestamptz default now()
);

-- Счётчики ключей задач (WEB-101, MOB-44, ...)
create table counters (
  project_key text primary key references projects(key),
  seq int not null default 0
);

-- Спринты
create table sprints (
  id text primary key,
  name text not null,
  active boolean not null default false,
  start_date date,
  end_date date,
  created_at timestamptz default now()
);

-- Задачи
create table tasks (
  id text primary key,
  key text not null unique,
  type text not null default 'task' check (type in ('task','bug')),
  title text not null,
  description text default '',
  status text not null default 'todo' check (status in ('todo','in_progress','review','testing','done','closed')),
  priority text not null default 'p3' check (priority in ('p1','p2','p3','p4')),
  assignee_id text references members(id),
  project_id text references projects(id),
  sprint_id text references sprints(id),
  due_date date,
  labels text[] default '{}',
  estimated_time real,
  spent_time real default 0,
  time_exceed_reason text,
  close_reason text,
  -- Поля для багов
  source_task_id text references tasks(id),
  steps_to_reproduce text,
  expected_behavior text,
  actual_behavior text,
  environment text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Подзадачи
create table subtasks (
  id text primary key,
  task_id text not null references tasks(id) on delete cascade,
  text text not null,
  done boolean not null default false,
  sort_order int default 0
);

-- Связи между задачами
create table task_relations (
  task_id text not null references tasks(id) on delete cascade,
  related_id text not null references tasks(id) on delete cascade,
  primary key (task_id, related_id)
);

-- Комментарии
create table comments (
  id text primary key,
  task_id text not null references tasks(id) on delete cascade,
  author_id text references members(id),
  text text not null,
  created_at timestamptz default now()
);

-- Вложения (метаданные, файлы в Supabase Storage)
create table attachments (
  id text primary key,
  task_id text not null references tasks(id) on delete cascade,
  name text not null,
  size int,
  mime text,
  storage_path text not null,
  created_at timestamptz default now()
);

-- История изменений
create table history (
  id text primary key,
  task_id text not null references tasks(id) on delete cascade,
  text text not null,
  created_at timestamptz default now()
);

-- Индексы для быстрых запросов
create index idx_tasks_status on tasks(status);
create index idx_tasks_assignee on tasks(assignee_id);
create index idx_tasks_project on tasks(project_id);
create index idx_tasks_sprint on tasks(sprint_id);
create index idx_tasks_due on tasks(due_date);
create index idx_subtasks_task on subtasks(task_id);
create index idx_comments_task on comments(task_id);
create index idx_history_task on history(task_id);
create index idx_attachments_task on attachments(task_id);

-- Автообновление updated_at
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger tasks_updated_at
  before update on tasks
  for each row execute function update_updated_at();

-- RLS (Row Level Security) — включим позже при настройке авторизации
-- alter table tasks enable row level security;
-- alter table comments enable row level security;
