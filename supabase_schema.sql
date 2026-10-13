-- ==============================================================================
-- DATA SCIENCE STUDENT LEARNING PORTAL - SUPABASE SQL SCHEMA
-- Run this script in your Supabase SQL Editor (Dashboard -> SQL Editor -> New Query)
-- ==============================================================================

-- 1. Create Profiles Table linked to auth.users
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL,
    register_number TEXT,
    college_id TEXT,
    college_name TEXT DEFAULT 'Institute of Science and Technology',
    department TEXT DEFAULT 'Department of Data Science & Artificial Intelligence',
    course TEXT DEFAULT 'B.Tech in Data Science',
    year_semester TEXT DEFAULT '3rd Year / Semester 6',
    section TEXT DEFAULT 'Section A',
    faculty_name TEXT DEFAULT 'Dr. K. S. Ramanathan, Ph.D.',
    bio TEXT DEFAULT 'Data Science undergraduate passionate about Machine Learning, NLP, and Predictive Analytics.',
    interests TEXT[] DEFAULT ARRAY['Machine Learning', 'Computer Vision', 'Deep Learning', 'SQL Analytics', 'PyTorch'],
    avatar_url TEXT DEFAULT 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    github_url TEXT DEFAULT 'https://github.com',
    linkedin_url TEXT DEFAULT 'https://linkedin.com',
    portfolioUrl TEXT DEFAULT '',
    kaggle_url TEXT DEFAULT 'https://kaggle.com',
    hide_sensitive_ids BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security (RLS) for profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Trigger to automatically create a profile when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (
        id,
        email,
        full_name,
        register_number,
        college_id
    ) VALUES (
        new.id,
        new.email,
        COALESCE(new.raw_user_meta_data->>'full_name', 'Student User'),
        COALESCE(new.raw_user_meta_data->>'register_number', 'REG-' || substring(new.id::text from 1 for 6)),
        COALESCE(new.raw_user_meta_data->>'college_id', 'COL-' || substring(new.id::text from 1 for 5))
    );
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- 2. Modules & Uploaded Files Table
CREATE TABLE IF NOT EXISTS public.modules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_type TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    file_url TEXT NOT NULL,
    subject TEXT NOT NULL,
    semester TEXT NOT NULL,
    module_number INT NOT NULL DEFAULT 1,
    topic TEXT NOT NULL,
    preview_content TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.modules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own modules"
    ON public.modules FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own modules"
    ON public.modules FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own modules"
    ON public.modules FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own modules"
    ON public.modules FOR DELETE
    USING (auth.uid() = user_id);


-- 3. Lab Assignments Table
CREATE TABLE IF NOT EXISTS public.lab_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    subject TEXT NOT NULL,
    language TEXT NOT NULL,
    repo_name TEXT NOT NULL,
    repo_url TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'Not Started',
    experiment_number INT DEFAULT 1,
    due_date DATE DEFAULT CURRENT_DATE + INTERVAL '14 days',
    default_branch TEXT DEFAULT 'main',
    stars INT DEFAULT 0,
    open_issues INT DEFAULT 0,
    readme_content TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.lab_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own assignments"
    ON public.lab_assignments FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own assignments"
    ON public.lab_assignments FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own assignments"
    ON public.lab_assignments FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own assignments"
    ON public.lab_assignments FOR DELETE
    USING (auth.uid() = user_id);


-- 4. Resources and Bookmarks Table
CREATE TABLE IF NOT EXISTS public.resources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    resource_type TEXT NOT NULL,
    url TEXT NOT NULL,
    is_bookmarked BOOLEAN DEFAULT false,
    is_completed BOOLEAN DEFAULT false,
    is_custom BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view resources"
    ON public.resources FOR SELECT
    USING (user_id IS NULL OR auth.uid() = user_id);

CREATE POLICY "Users can insert their custom resources"
    ON public.resources FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own resources"
    ON public.resources FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their custom resources"
    ON public.resources FOR DELETE
    USING (auth.uid() = user_id);


-- 5. Storage Bucket Configuration for Study Materials
INSERT INTO storage.buckets (id, name, public)
VALUES ('module-files', 'module-files', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Public or Authenticated Read Module Files"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'module-files');

CREATE POLICY "Authenticated users can upload module files"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'module-files' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update their uploaded files"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'module-files' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete their uploaded files"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'module-files' AND auth.role() = 'authenticated');
