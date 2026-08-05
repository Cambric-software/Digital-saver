-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           DIGITAL SAVER - COMPLETE DATABASE SETUP                           ║
-- ║                 Run this ONE file in Supabase SQL Editor                    ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝
-- 
-- Instructions:
-- 1. Go to: https://supabase.com/dashboard → Your Project → SQL Editor
-- 2. Paste this entire file
-- 3. Click "Run"
-- 4. Done!
--

-- ════════════════════════════════════════════════════════════════════════════════
-- PART 1: ENHANCED USER PROFILE COLUMNS
-- ════════════════════════════════════════════════════════════════════════════════

-- Add new columns to digital_saver_user_profiles if they don't exist
ALTER TABLE digital_saver_user_profiles 
ADD COLUMN IF NOT EXISTS height_cm REAL,
ADD COLUMN IF NOT EXISTS weight_kg REAL,
ADD COLUMN IF NOT EXISTS blood_type TEXT,
ADD COLUMN IF NOT EXISTS medical_conditions TEXT[],
ADD COLUMN IF NOT EXISTS allergies TEXT[],
ADD COLUMN IF NOT EXISTS medications TEXT[],
ADD COLUMN IF NOT EXISTS emergency_contact_name TEXT,
ADD COLUMN IF NOT EXISTS emergency_contact_phone TEXT,
ADD COLUMN IF NOT EXISTS emergency_contact_relationship TEXT,
ADD COLUMN IF NOT EXISTS insurance_provider TEXT,
ADD COLUMN IF NOT EXISTS insurance_policy_number TEXT,
ADD COLUMN IF NOT EXISTS has_heart_condition BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS has_diabetes BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS has_hypertension BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS has_asthma BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS profile_completeness_score INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_health_check TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS preferred_language TEXT DEFAULT 'en',
ADD COLUMN IF NOT EXISTS timezone TEXT DEFAULT 'UTC';

-- ════════════════════════════════════════════════════════════════════════════════
-- PART 2: INDEXES FOR PERFORMANCE
-- ════════════════════════════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_profiles_blood_type ON digital_saver_user_profiles(blood_type);
CREATE INDEX IF NOT EXISTS idx_profiles_completeness ON digital_saver_user_profiles(profile_completeness_score);
CREATE INDEX IF NOT EXISTS idx_profiles_age ON digital_saver_user_profiles(age);
CREATE INDEX IF NOT EXISTS idx_health_logs_user_recorded ON digital_saver_health_logs(user_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_health_logs_data_type ON digital_saver_health_logs(data_type);
CREATE INDEX IF NOT EXISTS idx_devices_user ON digital_saver_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_aggregates_user_date ON digital_saver_daily_aggregates(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_health_goals_user ON digital_saver_health_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_user ON digital_saver_emergency_contacts(user_id);

-- ════════════════════════════════════════════════════════════════════════════════
-- PART 3: PROFILE COMPLETENESS FUNCTION
-- ════════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION calculate_profile_completeness()
RETURNS TRIGGER AS $$
DECLARE
    score INTEGER := 0;
BEGIN
    -- Base fields
    IF NEW.display_name IS NOT NULL AND NEW.display_name != '' THEN score := score + 10; END IF;
    IF NEW.age IS NOT NULL AND NEW.age > 0 THEN score := score + 10; END IF;
    IF NEW.gender IS NOT NULL AND NEW.gender != '' THEN score := score + 5; END IF;
    
    -- Health profile fields
    IF NEW.height_cm IS NOT NULL AND NEW.height_cm > 0 THEN score := score + 10; END IF;
    IF NEW.weight_kg IS NOT NULL AND NEW.weight_kg > 0 THEN score := score + 10; END IF;
    IF NEW.blood_type IS NOT NULL AND NEW.blood_type != '' THEN score := score + 10; END IF;
    
    -- Medical info
    IF NEW.medical_conditions IS NOT NULL AND array_length(NEW.medical_conditions, 1) > 0 THEN score := score + 10; END IF;
    IF NEW.allergies IS NOT NULL AND array_length(NEW.allergies, 1) > 0 THEN score := score + 5; END IF;
    IF NEW.medications IS NOT NULL AND array_length(NEW.medications, 1) > 0 THEN score := score + 5; END IF;
    
    -- Emergency contact (critical!)
    IF NEW.emergency_contact_name IS NOT NULL AND NEW.emergency_contact_name != '' THEN score := score + 10; END IF;
    IF NEW.emergency_contact_phone IS NOT NULL AND NEW.emergency_contact_phone != '' THEN score := score + 10; END IF;
    IF NEW.emergency_contact_relationship IS NOT NULL AND NEW.emergency_contact_relationship != '' THEN score := score + 5; END IF;
    
    -- Insurance
    IF NEW.insurance_provider IS NOT NULL AND NEW.insurance_provider != '' THEN score := score + 5; END IF;
    IF NEW.insurance_policy_number IS NOT NULL AND NEW.insurance_policy_number != '' THEN score := score + 5; END IF;
    
    NEW.profile_completeness_score := score;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop old trigger if exists and create new one
DROP TRIGGER IF EXISTS trg_profile_completeness ON digital_saver_user_profiles;
CREATE TRIGGER trg_profile_completeness
    BEFORE INSERT OR UPDATE ON digital_saver_user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION calculate_profile_completeness();

-- ════════════════════════════════════════════════════════════════════════════════
-- PART 4: GET MISSING PROFILE FIELDS FUNCTION
-- ════════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION get_missing_profile_fields(target_user_id UUID)
RETURNS TABLE(field_name TEXT, display_name TEXT, priority INTEGER) AS $$
DECLARE
    profile RECORD;
BEGIN
    SELECT * INTO profile FROM digital_saver_user_profiles WHERE id = target_user_id;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT 'name'::TEXT, 'Full Name'::TEXT, 1::INTEGER;
        RETURN QUERY SELECT 'age'::TEXT, 'Age'::TEXT, 2::INTEGER;
        RETURN QUERY SELECT 'height'::TEXT, 'Height'::TEXT, 3::INTEGER;
        RETURN QUERY SELECT 'weight'::TEXT, 'Weight'::TEXT, 4::INTEGER;
        RETURN QUERY SELECT 'bloodType'::TEXT, 'Blood Type'::TEXT, 5::INTEGER;
        RETURN QUERY SELECT 'emergencyContact'::TEXT, 'Emergency Contact'::TEXT, 6::INTEGER;
        RETURN;
    END IF;
    
    IF profile.display_name IS NULL OR profile.display_name = '' THEN
        RETURN QUERY SELECT 'name'::TEXT, 'Full Name'::TEXT, 1::INTEGER;
    END IF;
    
    IF profile.age IS NULL OR profile.age = 0 THEN
        RETURN QUERY SELECT 'age'::TEXT, 'Age'::TEXT, 2::INTEGER;
    END IF;
    
    IF profile.height_cm IS NULL OR profile.height_cm = 0 THEN
        RETURN QUERY SELECT 'height'::TEXT, 'Height (cm)'::TEXT, 3::INTEGER;
    END IF;
    
    IF profile.weight_kg IS NULL OR profile.weight_kg = 0 THEN
        RETURN QUERY SELECT 'weight'::TEXT, 'Weight (kg)'::TEXT, 4::INTEGER;
    END IF;
    
    IF profile.blood_type IS NULL OR profile.blood_type = '' THEN
        RETURN QUERY SELECT 'bloodType'::TEXT, 'Blood Type'::TEXT, 5::INTEGER;
    END IF;
    
    IF profile.emergency_contact_name IS NULL OR profile.emergency_contact_name = '' THEN
        RETURN QUERY SELECT 'emergencyContactName'::TEXT, 'Emergency Contact Name'::TEXT, 6::INTEGER;
    END IF;
    
    IF profile.emergency_contact_phone IS NULL OR profile.emergency_contact_phone = '' THEN
        RETURN QUERY SELECT 'emergencyContactPhone'::TEXT, 'Emergency Contact Phone'::TEXT, 7::INTEGER;
    END IF;
    
    IF profile.medical_conditions IS NULL OR array_length(profile.medical_conditions, 1) IS NULL THEN
        RETURN QUERY SELECT 'medicalConditions'::TEXT, 'Medical Conditions'::TEXT, 8::INTEGER;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ════════════════════════════════════════════════════════════════════════════════
-- PART 5: AI INSIGHTS TABLE
-- ════════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS digital_saver_ai_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES digital_saver_user_profiles(id) ON DELETE CASCADE,
    insight_type VARCHAR(50) NOT NULL CHECK (insight_type IN ('heart', 'sleep', 'activity', 'general', 'prediction', 'warning')),
    insight_text TEXT NOT NULL,
    confidence_score INTEGER DEFAULT 50 CHECK (confidence_score >= 0 AND confidence_score <= 100),
    severity VARCHAR(20) DEFAULT 'info' CHECK (severity IN ('info', 'low', 'medium', 'high', 'critical')),
    source VARCHAR(50) DEFAULT 'ai' CHECK (source IN ('ai', 'system', 'manual')),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ,
    is_dismissed BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_ai_insights_user ON digital_saver_ai_insights(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_insights_type ON digital_saver_ai_insights(insight_type);
CREATE INDEX IF NOT EXISTS idx_ai_insights_created ON digital_saver_ai_insights(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_insights_unread ON digital_saver_ai_insights(user_id, is_dismissed) WHERE is_dismissed = FALSE;

-- ════════════════════════════════════════════════════════════════════════════════
-- PART 6: HEALTH PREDICTIONS TABLE
-- ════════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS digital_saver_health_predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES digital_saver_user_profiles(id) ON DELETE CASCADE,
    prediction_type VARCHAR(50) NOT NULL CHECK (prediction_type IN ('heart_risk', 'sleep_quality', 'activity_trend', 'health_score', 'emergency_risk')),
    predicted_value JSONB NOT NULL,
    confidence_score INTEGER DEFAULT 50 CHECK (confidence_score >= 0 AND confidence_score <= 100),
    prediction_date DATE NOT NULL,
    actual_value JSONB,
    is_accurate BOOLEAN,
    model_version VARCHAR(20) DEFAULT '1.0',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    validated_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_predictions_user ON digital_saver_health_predictions(user_id);
CREATE INDEX IF NOT EXISTS idx_predictions_date ON digital_saver_health_predictions(prediction_date DESC);
CREATE INDEX IF NOT EXISTS idx_predictions_type ON digital_saver_health_predictions(prediction_type);

-- ════════════════════════════════════════════════════════════════════════════════
-- PART 7: EMERGENCY LOG TABLE
-- ════════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS digital_saver_emergency_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES digital_saver_user_profiles(id) ON DELETE CASCADE,
    alert_type VARCHAR(50) NOT NULL CHECK (alert_type IN ('fall', 'sos', 'heart_rate', 'spO2', 'ai', 'manual', 'low_battery')),
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    heart_rate INTEGER,
    spO2 REAL,
    blood_pressure VARCHAR(20),
    trigger_source VARCHAR(50) DEFAULT 'watch' CHECK (trigger_source IN ('watch', 'app', 'ai', 'manual')),
    description TEXT,
    location JSONB,
    triggered_at TIMESTAMPTZ DEFAULT NOW(),
    notification_sent_at TIMESTAMPTZ,
    contact_notified_at TIMESTAMPTZ,
    responded_at TIMESTAMPTZ,
    response_type VARCHAR(50) CHECK (response_type IN ('none', 'cancelled', 'acknowledged', 'emergency_called')),
    was_false_alarm BOOLEAN DEFAULT FALSE,
    false_alarm_reason TEXT,
    resolution_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_emergency_log_user ON digital_saver_emergency_log(user_id);
CREATE INDEX IF NOT EXISTS idx_emergency_log_date ON digital_saver_emergency_log(triggered_at DESC);
CREATE INDEX IF NOT EXISTS idx_emergency_log_type ON digital_saver_emergency_log(alert_type);
CREATE INDEX IF NOT EXISTS idx_emergency_log_severity ON digital_saver_emergency_log(severity);

-- ════════════════════════════════════════════════════════════════════════════════
-- PART 8: WATCH DEVICE TABLE (for Onyx)
-- ════════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS digital_saver_watch_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES digital_saver_user_profiles(id) ON DELETE CASCADE,
    device_id UUID REFERENCES digital_saver_devices(id) ON DELETE SET NULL,
    firmware_version VARCHAR(20),
    recorded_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Heart data
    heart_rate INTEGER,
    hrv_rmssd REAL,
    hrv_sdnn REAL,
    irregular_beat BOOLEAN DEFAULT FALSE,
    afib_probability INTEGER,
    
    -- Blood oxygen
    spO2 REAL,
    perfusion_index REAL,
    
    -- Blood pressure
    systolic_bp INTEGER,
    diastolic_bp INTEGER,
    
    -- Activity
    steps INTEGER DEFAULT 0,
    calories_burned REAL,
    distance_km REAL,
    active_minutes INTEGER,
    
    -- Motion
    accelerometer_x REAL,
    accelerometer_y REAL,
    accelerometer_z REAL,
    fall_detected BOOLEAN DEFAULT FALSE,
    
    -- Battery
    battery_level INTEGER,
    
    -- AI Analysis
    ai_risk_score INTEGER,
    ai_patterns TEXT[],
    
    -- Raw data for debugging
    raw_sensor_data JSONB,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_watch_user_recorded ON digital_saver_watch_data(user_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_watch_device ON digital_saver_watch_data(device_id);

-- ════════════════════════════════════════════════════════════════════════════════
-- PART 9: SLEEP ANALYTICS TABLE
-- ════════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS digital_saver_sleep_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES digital_saver_user_profiles(id) ON DELETE CASCADE,
    sleep_date DATE NOT NULL,
    
    -- Duration
    total_minutes INTEGER,
    total_hours REAL GENERATED ALWAYS AS (total_minutes / 60.0) STORED,
    
    -- Sleep stages
    deep_sleep_minutes INTEGER,
    light_sleep_minutes INTEGER,
    rem_sleep_minutes INTEGER,
    awake_minutes INTEGER,
    
    -- Quality
    sleep_score INTEGER CHECK (sleep_score >= 0 AND sleep_score <= 100),
    sleep_quality VARCHAR(20) CHECK (sleep_quality IN ('poor', 'fair', 'good', 'excellent')),
    
    -- Timing
    sleep_start TIMESTAMPTZ,
    sleep_end TIMESTAMPTZ,
    time_to_sleep_minutes INTEGER,
    awakenings_count INTEGER DEFAULT 0,
    
    -- Health metrics during sleep
    avg_heart_rate INTEGER,
    min_heart_rate INTEGER,
    max_heart_rate INTEGER,
    avg_spO2 REAL,
    min_spO2 REAL,
    
    -- AI insights
    sleep_insights JSONB DEFAULT '[]',
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, sleep_date)
);

CREATE INDEX IF NOT EXISTS idx_sleep_user_date ON digital_saver_sleep_analytics(user_id, sleep_date DESC);

-- ════════════════════════════════════════════════════════════════════════════════
-- PART 10: HEALTH ACHIEVEMENTS TABLE
-- ════════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS digital_saver_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES digital_saver_user_profiles(id) ON DELETE CASCADE,
    achievement_type VARCHAR(50) NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    points INTEGER DEFAULT 0,
    badge_color VARCHAR(20),
    unlocked_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_achievements_user ON digital_saver_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_achievements_unlocked ON digital_saver_achievements(user_id, unlocked_at DESC);

-- ════════════════════════════════════════════════════════════════════════════════
-- PART 11: BLE PAIRING TOKENS TABLE
-- ════════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS digital_saver_pairing_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES digital_saver_user_profiles(id) ON DELETE CASCADE,
    token VARCHAR(100) NOT NULL UNIQUE,
    device_name VARCHAR(100),
    device_type VARCHAR(50) DEFAULT 'onyx',
    mac_address VARCHAR(17),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '10 minutes'),
    used_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pairing_token ON digital_saver_pairing_tokens(token) WHERE is_active = TRUE;

-- ════════════════════════════════════════════════════════════════════════════════
-- PART 12: SAMPLE DATA FOR TESTING (Optional)
-- ════════════════════════════════════════════════════════════════════════════════

-- Insert sample AI insights (uncomment to add)
-- INSERT INTO digital_saver_ai_insights (user_id, insight_type, insight_text, confidence_score, severity)
-- SELECT id, 'general', 'Welcome to Digital Saver! Complete your profile for personalized health insights.', 100, 'info'
-- FROM digital_saver_user_profiles LIMIT 1;

-- ════════════════════════════════════════════════════════════════════════════════
-- PART 13: COMMENTS FOR DOCUMENTATION
-- ════════════════════════════════════════════════════════════════════════════════

COMMENT ON TABLE digital_saver_ai_insights IS 'AI-generated health insights for users';
COMMENT ON TABLE digital_saver_health_predictions IS 'AI health predictions based on user data';
COMMENT ON TABLE digital_saver_emergency_log IS 'Emergency alert history for auditing';
COMMENT ON TABLE digital_saver_watch_data IS 'Raw data from Onyx watch sensors';
COMMENT ON TABLE digital_saver_sleep_analytics IS 'Detailed sleep analysis and stages';
COMMENT ON TABLE digital_saver_achievements IS 'Health achievements and badges';
COMMENT ON TABLE digital_saver_pairing_tokens IS 'BLE pairing tokens for watch connection';

COMMENT ON COLUMN digital_saver_user_profiles.profile_completeness_score IS '0-100 score based on profile fields filled';
COMMENT ON COLUMN digital_saver_ai_insights.confidence_score IS 'AI confidence 0-100';
COMMENT ON COLUMN digital_saver_emergency_log.location IS 'GPS coordinates if available';

-- ════════════════════════════════════════════════════════════════════════════════
-- PART 14: ROW LEVEL SECURITY POLICIES
-- ════════════════════════════════════════════════════════════════════════════════

-- Enable RLS on new tables
ALTER TABLE digital_saver_ai_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE digital_saver_health_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE digital_saver_emergency_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE digital_saver_watch_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE digital_saver_sleep_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE digital_saver_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE digital_saver_pairing_tokens ENABLE ROW LEVEL SECURITY;

-- Users can only see their own data
CREATE POLICY "Users can view own insights" ON digital_saver_ai_insights
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own insights" ON digital_saver_ai_insights
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own insights" ON digital_saver_ai_insights
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own predictions" ON digital_saver_health_predictions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own predictions" ON digital_saver_health_predictions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own emergency log" ON digital_saver_emergency_log
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own emergency log" ON digital_saver_emergency_log
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own emergency log" ON digital_saver_emergency_log
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own watch data" ON digital_saver_watch_data
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own watch data" ON digital_saver_watch_data
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own sleep analytics" ON digital_saver_sleep_analytics
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sleep analytics" ON digital_saver_sleep_analytics
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own achievements" ON digital_saver_achievements
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own achievements" ON digital_saver_achievements
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own pairing tokens" ON digital_saver_pairing_tokens
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own pairing tokens" ON digital_saver_pairing_tokens
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Anyone can use valid pairing token" ON digital_saver_pairing_tokens
    FOR UPDATE USING (is_active = TRUE);

-- ════════════════════════════════════════════════════════════════════════════════
-- DONE!
-- ════════════════════════════════════════════════════════════════════════════════

-- Verification query - should return table count
SELECT 'Tables created successfully!' as status, 
       (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name LIKE 'digital_saver%') as digital_saver_tables;
