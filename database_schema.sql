-- ==========================================
-- NAVTTC LMS v2.0 - Database Schema & RLS
-- ==========================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. profiles
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    uid UUID,
    full_name TEXT,
    email TEXT UNIQUE,
    role TEXT DEFAULT 'student' CHECK (role IN ('student', 'teacher', 'admin')),
    avatar_url TEXT,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. exam_settings
CREATE TABLE public.exam_settings (
    id SERIAL PRIMARY KEY,
    is_active BOOLEAN DEFAULT false,
    exam_title TEXT,
    duration_minutes INTEGER,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. exam_results
CREATE TABLE public.exam_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    student_name TEXT,
    score INTEGER,
    total_marks INTEGER,
    status TEXT,
    certificate_id TEXT UNIQUE,
    answers_json JSONB,
    questions_json JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. notices
CREATE TABLE public.notices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    content TEXT,
    priority TEXT DEFAULT 'normal',
    created_by UUID REFERENCES public.profiles(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. user_achievements
CREATE TABLE public.user_achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    badge_key TEXT NOT NULL,
    earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, badge_key)
);

-- 6. tasks
CREATE TABLE public.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    deadline TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. submissions
CREATE TABLE public.submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE,
    student_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT,
    status TEXT DEFAULT 'pending',
    grade TEXT,
    feedback TEXT,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(task_id, student_id)
);

-- 8. user_arcade_progress
CREATE TABLE public.user_arcade_progress (
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
    points INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    last_played TIMESTAMP WITH TIME ZONE
);

-- 9. feedback
CREATE TABLE public.feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    is_read BOOLEAN DEFAULT false,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. arcade_config
CREATE TABLE public.arcade_config (
    id SERIAL PRIMARY KEY,
    is_unlocked BOOLEAN DEFAULT false,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 11. personal_storage
CREATE TABLE public.personal_storage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    url TEXT NOT NULL,
    size INTEGER,
    type TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 12. resources
CREATE TABLE public.resources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    url TEXT NOT NULL,
    description TEXT,
    uploaded_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 13. task_comments
CREATE TABLE public.task_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 14. game_scores
CREATE TABLE public.game_scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    game TEXT NOT NULL,
    score INTEGER NOT NULL,
    max_score INTEGER,
    played_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


-- ==========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==========================================

-- Enable RLS for all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_arcade_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.arcade_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.personal_storage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_scores ENABLE ROW LEVEL SECURITY;

-- Utility Function to check if user is admin or teacher
CREATE OR REPLACE FUNCTION public.is_admin() RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'teacher')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Profiles
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Exam Settings
CREATE POLICY "Exam settings visible to everyone" ON public.exam_settings FOR SELECT USING (true);
CREATE POLICY "Only admins can update exam settings" ON public.exam_settings FOR ALL USING (public.is_admin());

-- Exam Results
CREATE POLICY "Students can view their own exam results" ON public.exam_results FOR SELECT USING (auth.uid() = student_id OR public.is_admin());
CREATE POLICY "Students can insert their own exam results" ON public.exam_results FOR INSERT WITH CHECK (auth.uid() = student_id);
CREATE POLICY "Only admins can update/delete exam results" ON public.exam_results FOR UPDATE USING (public.is_admin());
CREATE POLICY "Only admins can delete exam results" ON public.exam_results FOR DELETE USING (public.is_admin());

-- Notices
CREATE POLICY "Active notices are viewable by everyone" ON public.notices FOR SELECT USING (is_active = true OR public.is_admin());
CREATE POLICY "Admins can manage notices" ON public.notices FOR ALL USING (public.is_admin());

-- User Achievements
CREATE POLICY "Achievements viewable by everyone" ON public.user_achievements FOR SELECT USING (true);
CREATE POLICY "Users can insert their own achievements" ON public.user_achievements FOR INSERT WITH CHECK (auth.uid() = user_id OR public.is_admin());

-- Tasks
CREATE POLICY "Tasks viewable by everyone" ON public.tasks FOR SELECT USING (true);
CREATE POLICY "Admins can manage tasks" ON public.tasks FOR ALL USING (public.is_admin());

-- Submissions
CREATE POLICY "Users can view their own submissions" ON public.submissions FOR SELECT USING (auth.uid() = student_id OR public.is_admin());
CREATE POLICY "Users can create their own submissions" ON public.submissions FOR INSERT WITH CHECK (auth.uid() = student_id);
CREATE POLICY "Users can update their own pending submissions" ON public.submissions FOR UPDATE USING (auth.uid() = student_id AND status = 'pending' OR public.is_admin());
CREATE POLICY "Only admins can delete submissions" ON public.submissions FOR DELETE USING (public.is_admin());

-- User Arcade Progress
CREATE POLICY "Arcade progress viewable by everyone" ON public.user_arcade_progress FOR SELECT USING (true);
CREATE POLICY "Users can update their own arcade progress" ON public.user_arcade_progress FOR ALL USING (auth.uid() = user_id OR public.is_admin());

-- Feedback
CREATE POLICY "Admins can view feedback" ON public.feedback FOR SELECT USING (public.is_admin() OR auth.uid() = student_id);
CREATE POLICY "Users can submit feedback" ON public.feedback FOR INSERT WITH CHECK (auth.uid() = student_id);
CREATE POLICY "Admins can manage feedback" ON public.feedback FOR UPDATE USING (public.is_admin());
CREATE POLICY "Admins can delete feedback" ON public.feedback FOR DELETE USING (public.is_admin());

-- Arcade Config
CREATE POLICY "Arcade config visible to everyone" ON public.arcade_config FOR SELECT USING (true);
CREATE POLICY "Admins can manage arcade config" ON public.arcade_config FOR ALL USING (public.is_admin());

-- Personal Storage
CREATE POLICY "Users can view their own storage" ON public.personal_storage FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert to their own storage" ON public.personal_storage FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own storage" ON public.personal_storage FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own storage" ON public.personal_storage FOR DELETE USING (auth.uid() = user_id);

-- Resources
CREATE POLICY "Resources viewable by everyone" ON public.resources FOR SELECT USING (true);
CREATE POLICY "Admins can manage resources" ON public.resources FOR ALL USING (public.is_admin());

-- Task Comments
CREATE POLICY "Comments viewable by everyone" ON public.task_comments FOR SELECT USING (true);
CREATE POLICY "Users can insert own comments" ON public.task_comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own comments" ON public.task_comments FOR UPDATE USING (auth.uid() = user_id OR public.is_admin());
CREATE POLICY "Users can delete own comments" ON public.task_comments FOR DELETE USING (auth.uid() = user_id OR public.is_admin());

-- Game Scores
CREATE POLICY "Game scores viewable by everyone" ON public.game_scores FOR SELECT USING (true);
CREATE POLICY "Users can manage own game scores" ON public.game_scores FOR ALL USING (auth.uid() = user_id OR public.is_admin());
