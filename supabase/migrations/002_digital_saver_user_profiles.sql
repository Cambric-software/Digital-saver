-- Digital Saver: User Profiles Table
-- Stores additional user profile information for health tracking
-- Version: 1.0.0
-- Created: 2024

CREATE TABLE IF NOT EXISTS public.digital_saver_user_profiles (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    date_of_birth DATE,
    gender TEXT CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
    height_cm INTEGER,
    weight_kg DOUBLE PRECISION,
    blood_type TEXT CHECK (blood_type IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'unknown')),
    medical_conditions TEXT[],
    allergies TEXT[],
    medications TEXT[],
    emergency_notes TEXT,
    preferred_language TEXT DEFAULT 'en',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.digital_saver_user_profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only see and edit their own profile
DROP POLICY IF EXISTS "digital_saver_users_can_view_own_profile" ON public.digital_saver_user_profiles;
CREATE POLICY "digital_saver_users_can_view_own_profile" ON public.digital_saver_user_profiles
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "digital_saver_users_can_insert_own_profile" ON public.digital_saver_user_profiles;
CREATE POLICY "digital_saver_users_can_insert_own_profile" ON public.digital_saver_user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "digital_saver_users_can_update_own_profile" ON public.digital_saver_user_profiles;
CREATE POLICY "digital_saver_users_can_update_own_profile" ON public.digital_saver_user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

-- Function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
DROP TRIGGER IF EXISTS update_digital_saver_user_profiles_updated_at ON public.digital_saver_user_profiles;
CREATE TRIGGER update_digital_saver_user_profiles_updated_at
    BEFORE UPDATE ON public.digital_saver_user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.digital_saver_user_profiles IS 'Digital Saver user profiles - stores medical info, preferences, and emergency details';
