-- Fix RLS policies for digital_saver_user_profiles
-- The table uses 'id' column (FK to auth.users), not 'user_id'

-- Drop existing policies that reference user_id
DROP POLICY IF EXISTS "digital_saver_users_can_view_own_profile" ON public.digital_saver_user_profiles;
DROP POLICY IF EXISTS "digital_saver_users_can_insert_own_profile" ON public.digital_saver_user_profiles;
DROP POLICY IF EXISTS "digital_saver_users_can_update_own_profile" ON public.digital_saver_user_profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.digital_saver_user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.digital_saver_user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.digital_saver_user_profiles;
DROP POLICY IF EXISTS "Users can upsert own profile" ON public.digital_saver_user_profiles;

-- Create policy for users to view their own profile (using id, not user_id)
CREATE POLICY "Users can view own profile" ON public.digital_saver_user_profiles
  FOR SELECT USING (auth.uid() = id);

-- Create policy for users to insert their own profile
CREATE POLICY "Users can insert own profile" ON public.digital_saver_user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Create policy for users to update their own profile
CREATE POLICY "Users can update own profile" ON public.digital_saver_user_profiles
  FOR UPDATE USING (auth.uid() = id);

-- Create policy for users to upsert their own profile
CREATE POLICY "Users can upsert own profile" ON public.digital_saver_user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);
