-- ============================================================================
-- DIGITAL SAVER - COMPLETE SUPABASE DATABASE SETUP
-- ============================================================================
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/cambric-sql/editor
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- TABLE 1: User Profiles (extended user data)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.digital_saver_user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    email TEXT,
    avatar_url TEXT,
    phone TEXT,
    date_of_birth DATE,
    gender TEXT CHECK (gender IN ('male', 'female', 'other')),
    age INTEGER GENERATED ALWAYS AS (
        CASE 
            WHEN date_of_birth IS NOT NULL 
            THEN EXTRACT(YEAR FROM AGE(date_of_birth))
            ELSE NULL 
        END
    ) STORED,
    weight_kg REAL,
    height_cm REAL,
    blood_type TEXT,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    medical_conditions TEXT[],
    allergies TEXT[],
    medications TEXT[],
    insurance_provider TEXT,
    insurance_policy_number TEXT,
    preferred_language TEXT DEFAULT 'en',
    timezone TEXT DEFAULT 'UTC',
    notification_enabled BOOLEAN DEFAULT true,
    email_notifications BOOLEAN DEFAULT true,
    push_notifications BOOLEAN DEFAULT true,
    sms_alerts BOOLEAN DEFAULT false,
    data_sharing_consent BOOLEAN DEFAULT false,
    research_consent BOOLEAN DEFAULT false,
    last_sync_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.digital_saver_user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON public.digital_saver_user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.digital_saver_user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.digital_saver_user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can delete own profile" ON public.digital_saver_user_profiles
    FOR DELETE USING (auth.uid() = id);

-- ============================================================================
-- TABLE 2: Health Devices
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.digital_saver_devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_name TEXT NOT NULL,
    device_type TEXT NOT NULL CHECK (device_type IN ('smartwatch', 'fitness_tracker', 'blood_pressure_monitor', 'glucose_meter', 'scale', 'thermometer', 'pulse_oximeter', 'ecg', 'other')),
    manufacturer TEXT,
    model TEXT,
    serial_number TEXT,
    firmware_version TEXT,
    mac_address TEXT,
    battery_level INTEGER CHECK (battery_level >= 0 AND battery_level <= 100),
    last_sync_at TIMESTAMPTZ,
    is_primary BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    settings JSONB DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.digital_saver_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own devices" ON public.digital_saver_devices
    FOR ALL USING (auth.uid() = user_id);

-- ============================================================================
-- TABLE 3: Health Logs (main data table)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.digital_saver_health_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id UUID REFERENCES public.digital_saver_devices(id) ON DELETE SET NULL,
    data_type TEXT NOT NULL CHECK (data_type IN ('heart_rate', 'blood_pressure', 'oxygen', 'activity', 'sleep', 'hrv', 'stress', 'temperature', 'respiratory', 'weight', 'glucose', 'ecg', 'steps', 'calories', 'distance', 'floors', 'active_minutes')),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    source TEXT DEFAULT 'device' CHECK (source IN ('device', 'manual', 'imported', 'calculated')),
    quality_score INTEGER CHECK (quality_score >= 0 AND quality_score <= 100) DEFAULT 100,
    heart_rate INTEGER CHECK (heart_rate >= 20 AND heart_rate <= 300),
    heart_rate_min INTEGER,
    heart_rate_max INTEGER,
    hrv_rmssd REAL,
    hrv_sdnn REAL,
    systolic_bp INTEGER CHECK (systolic_bp >= 60 AND systolic_bp <= 250),
    diastolic_bp INTEGER CHECK (diastolic_bp >= 40 AND diastolic_bp <= 150),
    mean_arterial_pressure REAL,
    spo2 REAL CHECK (spo2 >= 70 AND spo2 <= 100),
    spo2_min REAL,
    steps INTEGER DEFAULT 0,
    distance_km REAL,
    calories_burned REAL,
    active_minutes INTEGER DEFAULT 0,
    moderate_minutes INTEGER DEFAULT 0,
    vigorous_minutes INTEGER DEFAULT 0,
    floors_climbed INTEGER DEFAULT 0,
    sleep_minutes INTEGER DEFAULT 0,
    deep_sleep_minutes INTEGER DEFAULT 0,
    light_sleep_minutes INTEGER DEFAULT 0,
    rem_sleep_minutes INTEGER DEFAULT 0,
    awake_minutes INTEGER DEFAULT 0,
    sleep_efficiency REAL,
    sleep_score INTEGER CHECK (sleep_score >= 0 AND sleep_score <= 100),
    stress_level INTEGER CHECK (stress_level >= 1 AND stress_level <= 10),
    body_temperature REAL,
    respiratory_rate INTEGER,
    weight_kg REAL,
    bmi REAL,
    glucose_mg_dl INTEGER,
    ecg_data JSONB,
    afib_detected BOOLEAN,
    notes TEXT,
    tags TEXT[],
    metadata JSONB DEFAULT '{}',
    is_anomaly BOOLEAN DEFAULT false,
    anomaly_type TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.digital_saver_health_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own health logs" ON public.digital_saver_health_logs
    FOR ALL USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_health_logs_user_recorded ON public.digital_saver_health_logs(user_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_health_logs_data_type ON public.digital_saver_health_logs(data_type);
CREATE INDEX IF NOT EXISTS idx_health_logs_device ON public.digital_saver_health_logs(device_id);

-- ============================================================================
-- TABLE 4: Daily Aggregates
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.digital_saver_daily_aggregates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    data_type TEXT NOT NULL,
    record_count INTEGER DEFAULT 0,
    anomaly_count INTEGER DEFAULT 0,
    hr_avg REAL,
    hr_min REAL,
    hr_max REAL,
    hrv_avg REAL,
    bp_systolic_avg REAL,
    bp_diastolic_avg REAL,
    spo2_avg REAL,
    spo2_min REAL,
    steps_total INTEGER DEFAULT 0,
    calories_burned_total REAL,
    active_minutes_total INTEGER DEFAULT 0,
    sleep_minutes_total INTEGER DEFAULT 0,
    avg_sleep_score REAL,
    avg_quality_score REAL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, date, data_type)
);

ALTER TABLE public.digital_saver_daily_aggregates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own aggregates" ON public.digital_saver_daily_aggregates
    FOR ALL USING (auth.uid() = user_id);

-- ============================================================================
-- TABLE 5: Emergency Contacts
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.digital_saver_emergency_contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT,
    relationship TEXT,
    priority INTEGER DEFAULT 1,
    is_primary BOOLEAN DEFAULT false,
    notify_in_emergency BOOLEAN DEFAULT true,
    can_view_health_data BOOLEAN DEFAULT false,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.digital_saver_emergency_contacts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own emergency contacts" ON public.digital_saver_emergency_contacts
    FOR ALL USING (auth.uid() = user_id);

-- ============================================================================
-- TABLE 6: Health Goals
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.digital_saver_health_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    goal_type TEXT NOT NULL CHECK (goal_type IN ('steps', 'sleep', 'weight', 'hr', 'bp', 'activity', 'calories', 'water', 'medication')),
    target_value REAL NOT NULL,
    current_value REAL DEFAULT 0,
    unit TEXT,
    start_date DATE,
    target_date DATE,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'paused', 'cancelled')),
    progress_percentage REAL DEFAULT 0,
    reminder_enabled BOOLEAN DEFAULT true,
    notes TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.digital_saver_health_goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own goals" ON public.digital_saver_health_goals
    FOR ALL USING (auth.uid() = user_id);

-- ============================================================================
-- TABLE 7: Health Alerts
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.digital_saver_health_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    alert_type TEXT NOT NULL CHECK (alert_type IN ('high_hr', 'low_hr', 'high_bp', 'low_bp', 'low_spo2', 'irregular_rhythm', 'afib', 'anomaly', 'trend_alert', 'goal_achieved', 'reminder')),
    severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    title TEXT NOT NULL,
    message TEXT,
    health_log_id UUID REFERENCES public.digital_saver_health_logs(id) ON DELETE SET NULL,
    value_at_alert REAL,
    threshold_value REAL,
    is_read BOOLEAN DEFAULT false,
    is_acknowledged BOOLEAN DEFAULT false,
    acknowledged_at TIMESTAMPTZ,
    notify_contacts BOOLEAN DEFAULT false,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.digital_saver_health_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own alerts" ON public.digital_saver_health_alerts
    FOR ALL USING (auth.uid() = user_id);

-- ============================================================================
-- TABLE 8: Sync History
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.digital_saver_sync_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id UUID REFERENCES public.digital_saver_devices(id) ON DELETE SET NULL,
    sync_type TEXT NOT NULL CHECK (sync_type IN ('full', 'incremental', 'manual', 'scheduled')),
    records_synced INTEGER DEFAULT 0,
    data_types TEXT[],
    sync_status TEXT DEFAULT 'completed' CHECK (sync_status IN ('pending', 'in_progress', 'completed', 'failed', 'partial')),
    error_message TEXT,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    duration_ms INTEGER,
    metadata JSONB DEFAULT '{}'
);

ALTER TABLE public.digital_saver_sync_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own sync history" ON public.digital_saver_sync_history
    FOR ALL USING (auth.uid() = user_id);

-- ============================================================================
-- TABLE 9: Storage Statistics
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.digital_saver_storage_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    total_records INTEGER DEFAULT 0,
    total_storage_bytes BIGINT DEFAULT 0,
    records_by_type JSONB DEFAULT '{}',
    last_cleanup_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.digital_saver_storage_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own storage stats" ON public.digital_saver_storage_stats
    FOR ALL USING (auth.uid() = user_id);

-- ============================================================================
-- FUNCTION: Auto-update timestamp
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.digital_saver_user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_devices_updated_at BEFORE UPDATE ON public.digital_saver_devices
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_aggregates_updated_at BEFORE UPDATE ON public.digital_saver_daily_aggregates
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_contacts_updated_at BEFORE UPDATE ON public.digital_saver_emergency_contacts
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_goals_updated_at BEFORE UPDATE ON public.digital_saver_health_goals
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_storage_updated_at BEFORE UPDATE ON public.digital_saver_storage_stats
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- FUNCTION: Auto-create user profile on signup
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.digital_saver_user_profiles (id, email, display_name, created_at)
    VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'display_name', NOW());
    
    INSERT INTO public.digital_saver_storage_stats (user_id)
    VALUES (NEW.id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;
