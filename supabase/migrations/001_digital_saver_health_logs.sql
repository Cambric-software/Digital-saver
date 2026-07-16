-- Digital Saver: Health Logs Table
-- Stores user health measurements from smartwatch
-- Version: 1.0.0
-- Created: 2024

CREATE TABLE IF NOT EXISTS public.digital_saver_health_logs (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id TEXT,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    heart_rate INTEGER,
    heart_rate_confidence INTEGER,
    hrv_rmssd INTEGER,
    hrv_sdnn INTEGER,
    hrv_pnn50 INTEGER,
    afib_probability INTEGER,
    systolic_bp INTEGER,
    diastolic_bp INTEGER,
    map_bp INTEGER,
    spo2 INTEGER,
    perfusion_index INTEGER,
    respiration_rate INTEGER,
    steps INTEGER,
    calories_burned DOUBLE PRECISION,
    active_minutes INTEGER,
    sleep_minutes INTEGER,
    deep_sleep_minutes INTEGER,
    rem_sleep_minutes INTEGER,
    battery_level INTEGER,
    fall_detected BOOLEAN DEFAULT FALSE,
    location_lat DOUBLE PRECISION,
    location_lng DOUBLE PRECISION,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS digital_saver_health_logs_user_id_idx ON public.digital_saver_health_logs(user_id);
CREATE INDEX IF NOT EXISTS digital_saver_health_logs_recorded_at_idx ON public.digital_saver_health_logs(recorded_at);

-- Enable Row Level Security
ALTER TABLE public.digital_saver_health_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only see their own health logs
DROP POLICY IF EXISTS "digital_saver_users_can_view_own_health_logs" ON public.digital_saver_health_logs;
CREATE POLICY "digital_saver_users_can_view_own_health_logs" ON public.digital_saver_health_logs
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "digital_saver_users_can_insert_own_health_logs" ON public.digital_saver_health_logs;
CREATE POLICY "digital_saver_users_can_insert_own_health_logs" ON public.digital_saver_health_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "digital_saver_users_can_update_own_health_logs" ON public.digital_saver_health_logs;
CREATE POLICY "digital_saver_users_can_update_own_health_logs" ON public.digital_saver_health_logs
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "digital_saver_users_can_delete_own_health_logs" ON public.digital_saver_health_logs;
CREATE POLICY "digital_saver_users_can_delete_own_health_logs" ON public.digital_saver_health_logs
    FOR DELETE USING (auth.uid() = user_id);

COMMENT ON TABLE public.digital_saver_health_logs IS 'Digital Saver health measurement logs - stores heart rate, blood pressure, SpO2, activity and sleep data';
