PRAGMA foreign_keys=OFF;

CREATE TABLE IF NOT EXISTS admin_chat_messages (
  id TEXT PRIMARY KEY,
  sender_id TEXT NOT NULL,
  receiver_id TEXT NOT NULL,
  content text NOT NULL,
  is_read INTEGER DEFAULT 0,
  created_at TEXT 
);

CREATE TABLE IF NOT EXISTS arcade_config (
  id INTEGER NOT NULL,
  is_unlocked INTEGER DEFAULT 0,
  updated_at TEXT 
);

CREATE TABLE IF NOT EXISTS exam_results (
  id TEXT PRIMARY KEY,
  student_id TEXT,
  student_name text,
  score INTEGER,
  total_marks INTEGER,
  status text,
  certificate_id text,
  answers_TEXT TEXT,
  questions_TEXT TEXT,
  created_at TEXT 
);

CREATE TABLE IF NOT EXISTS exam_settings (
  id INTEGER NOT NULL,
  is_active INTEGER DEFAULT 0,
  exam_title text,
  duration_minutes INTEGER,
  updated_at TEXT 
);

CREATE TABLE IF NOT EXISTS feedback (
  id TEXT PRIMARY KEY,
  student_id TEXT,
  content text NOT NULL,
  rating INTEGER,
  is_read INTEGER DEFAULT 0,
  submitted_at TEXT 
);

CREATE TABLE IF NOT EXISTS game_scores (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  game text NOT NULL,
  score INTEGER NOT NULL,
  max_score INTEGER,
  played_at TEXT 
);

CREATE TABLE IF NOT EXISTS submissions (
  id TEXT PRIMARY KEY,
  task_id TEXT,
  student_id TEXT,
  content text,
  status text DEFAULT 'pending',
  grade text,
  feedback text,
  submitted_at TEXT ,
  student_name text,
  task_title text
);

CREATE TABLE IF NOT EXISTS notices (
  id TEXT PRIMARY KEY,
  title text NOT NULL,
  content text,
  priority text DEFAULT 'normal',
  created_by TEXT,
  is_active INTEGER DEFAULT 1,
  created_at TEXT 
);

CREATE TABLE IF NOT EXISTS personal_storage (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  name text NOT NULL,
  url text NOT NULL,
  size INTEGER,
  type text,
  created_at TEXT 
);

CREATE TABLE IF NOT EXISTS profiles (
  id TEXT PRIMARY KEY,
  uid TEXT,
  full_name text,
  email text,
  role text DEFAULT 'student',
  avatar_url text,
  status text DEFAULT 'active',
  created_at TEXT 
);

CREATE TABLE IF NOT EXISTS resources (
  id TEXT PRIMARY KEY,
  title text NOT NULL,
  url text NOT NULL,
  description text,
  uploaded_by TEXT,
  created_at TEXT ,
  subtitle text
);

CREATE TABLE IF NOT EXISTS system_settings (
  key TEXT PRIMARY KEY,
  value text NOT NULL,
  updated_at TEXT 
);

CREATE TABLE IF NOT EXISTS tasks (
  id TEXT PRIMARY KEY,
  title text NOT NULL,
  description text,
  deadline TEXT,
  created_by TEXT,
  created_at TEXT ,
  hints text
);

CREATE TABLE IF NOT EXISTS user_achievements (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  badge_key text NOT NULL,
  earned_at TEXT 
);

CREATE TABLE IF NOT EXISTS user_arcade_progress (
  user_id TEXT NOT NULL,
  points INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  last_played TEXT
);