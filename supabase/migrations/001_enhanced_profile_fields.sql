-- =====================================================
-- Digital Saver Enhanced Profile Schema
-- Adds fields for Smart AI and Health Calculations
-- =====================================================

-- Add new columns to digital_saver_user_profiles
ALTER TABLE digital_saver_user_profiles
ADD COLUMN IF NOT EXISTS height_cm DECIMAL(5,2),
ADD COLUMN IF NOT EXISTS weight_kg DECIMAL(5,2),
ADD COLUMN IF NOT EXISTS blood_type VARCHAR(5),
ADD COLUMN IF NOT EXISTS medical_conditions TEXT[],
ADD COLUMN IF NOT EXISTS allergies TEXT[],
ADD COLUMN IF NOT EXISTS medications TEXT[],
ADD COLUMN IF NOT EXISTS emergency_contact_name VARCHAR(100),
ADD COLUMN IF NOT EXISTS emergency_contact_phone VARCHAR(20),
ADD COLUMN IF NOT EXISTS emergency_contact_relationship VARCHAR(50),
ADD COLUMN IF NOT EXISTS insurance_provider VARCHAR(100),
ADD COLUMN IF NOT EXISTS insurance_policy_number VARCHAR(100),
ADD COLUMN IF NOT EXISTS has_heart_condition BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS has_diabetes BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS has_hypertension BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS has_asthma BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS profile_completeness_score INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_health_check TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS preferred_language VARCHAR(10) DEFAULT 'en',
ADD COLUMN IF NOT EXISTS timezone VARCHAR(50) DEFAULT 'UTC';

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_profiles_blood_type ON digital_saver_user_profiles(blood_type);
CREATE INDEX IF NOT EXISTS idx_profiles_completeness ON digital_saver_user_profiles(profile_completeness_score);

-- Function to calculate profile completeness
CREATE OR REPLACE FUNCTION calculate_profile_completeness()
RETURNS TRIGGER AS $$
DECLARE
    score INTEGER := 0;
BEGIN
    -- Base fields (required for all)
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
    
    -- Emergency contact (critical for health app)
    IF NEW.emergency_contact_name IS NOT NULL AND NEW.emergency_contact_name != '' THEN score := score + 10; END IF;
    IF NEW.emergency_contact_phone IS NOT NULL AND NEW.emergency_contact_phone != '' THEN score := score + 10; END IF;
    IF NEW.emergency_contact_relationship IS NOT NULL AND NEW.emergency_contact_relationship != '' THEN score := score + 5; END IF;
    
    -- Insurance (optional but helpful)
    IF NEW.insurance_provider IS NOT NULL AND NEW.insurance_provider != '' THEN score := score + 5; END IF;
    IF NEW.insurance_policy_number IS NOT NULL AND NEW.insurance_policy_number != '' THEN score := score + 5; END IF;
    
    NEW.profile_completeness_score := score;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-calculate completeness
DROP TRIGGER IF EXISTS trg_profile_completeness ON digital_saver_user_profiles;
CREATE TRIGGER trg_profile_completeness
    BEFORE INSERT OR UPDATE ON digital_saver_user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION calculate_profile_completeness();

-- Create function to get missing profile fields
CREATE OR REPLACE FUNCTION get_missing_profile_fields(user_id UUID)
RETURNS TABLE(field_name TEXT, display_name TEXT, priority INTEGER) AS $$
DECLARE
    profile RECORD;
BEGIN
    SELECT * INTO profile FROM digital_saver_user_profiles WHERE id = user_id;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT 'name'::TEXT, 'Full Name'::TEXT, 1;
        RETURN QUERY SELECT 'age'::TEXT, 'Age'::TEXT, 2;
        RETURN QUERY SELECT 'height'::TEXT, 'Height'::TEXT, 3;
        RETURN QUERY SELECT 'weight'::TEXT, 'Weight'::TEXT, 4;
        RETURN QUERY SELECT 'bloodType'::TEXT, 'Blood Type'::TEXT, 5;
        RETURN QUERY SELECT 'emergencyContact'::TEXT, 'Emergency Contact'::TEXT, 6;
        RETURN;
    END IF;
    
    -- Check each field
    IF profile.display_name IS NULL OR profile.display_name = '' THEN
        RETURN QUERY SELECT 'name'::TEXT, 'Full Name'::TEXT, 1;
    END IF;
    
    IF profile.age IS NULL OR profile.age = 0 THEN
        RETURN QUERY SELECT 'age'::TEXT, 'Age'::TEXT, 2;
    END IF;
    
    IF profile.height_cm IS NULL OR profile.height_cm = 0 THEN
        RETURN QUERY SELECT 'height'::TEXT, 'Height (cm)'::TEXT, 3;
    END IF;
    
    IF profile.weight_kg IS NULL OR profile.weight_kg = 0 THEN
        RETURN QUERY SELECT 'weight'::TEXT, 'Weight (kg)'::TEXT, 4;
    END IF;
    
    IF profile.blood_type IS NULL OR profile.blood_type = '' THEN
        RETURN QUERY SELECT 'bloodType'::TEXT, 'Blood Type'::TEXT, 5;
    END IF;
    
    IF profile.emergency_contact_name IS NULL OR profile.emergency_contact_name = '' THEN
        RETURN QUERY SELECT 'emergencyContactName'::TEXT, 'Emergency Contact Name'::TEXT, 6;
    END IF;
    
    IF profile.emergency_contact_phone IS NULL OR profile.emergency_contact_phone = '' THEN
        RETURN QUERY SELECT 'emergencyContactPhone'::TEXT, 'Emergency Contact Phone'::TEXT, 7;
    END IF;
    
    IF profile.medical_conditions IS NULL OR array_length(profile.medical_conditions, 1) IS NULL THEN
        RETURN QUERY SELECT 'medicalConditions'::TEXT, 'Medical Conditions'::TEXT, 8;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Create health_ai_insights table for storing AI-generated insights
CREATE TABLE IF NOT EXISTS digital_saver_ai_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES digital_saver_user_profiles(id) ON DELETE CASCADE,
    insight_type VARCHAR(50) NOT NULL, -- 'heart', 'sleep', 'activity', 'general'
    insight_text TEXT NOT NULL,
    confidence_score INTEGER DEFAULT 50, -- 0-100
    created_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ,
    is_dismissed BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_ai_insights_user ON digital_saver_ai_insights(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_insights_type ON digital_saver_ai_insights(insight_type);
CREATE INDEX IF NOT EXISTS idx_ai_insights_created ON digital_saver_ai_insights(created_at DESC);

-- Create health_predictions table for AI predictions
CREATE TABLE IF NOT EXISTS digital_saver_health_predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES digital_saver_user_profiles(id) ON DELETE CASCADE,
    prediction_type VARCHAR(50) NOT NULL, -- 'heart_risk', 'sleep_quality', 'activity_trend'
    predicted_value TEXT NOT NULL, -- JSON string with prediction details
    confidence_score INTEGER DEFAULT 50,
    prediction_date DATE NOT NULL,
    actual_value TEXT, -- After the date passes, the actual value
    is_accurate BOOLEAN, -- User feedback
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_predictions_user ON digital_saver_health_predictions(user_id);
CREATE INDEX IF NOT EXISTS idx_predictions_date ON digital_saver_health_predictions(prediction_date);

-- Create emergency_alerts_log table
CREATE TABLE IF NOT EXISTS digital_saver_emergency_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES digital_saver_user_profiles(id) ON DELETE CASCADE,
    alert_type VARCHAR(50) NOT NULL, -- 'fall', 'sos', 'heart_rate', 'spO2', 'ai'
    severity VARCHAR(20) NOT NULL, -- 'low', 'medium', 'high', 'critical'
    heart_rate INTEGER,
    spO2 INTEGER,
    description TEXT,
    triggered_at TIMESTAMPTZ DEFAULT NOW(),
    responded_at TIMESTAMPTZ,
    was_false_alarm BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_emergency_log_user ON digital_saver_emergency_log(user_id);
CREATE INDEX IF NOT EXISTS idx_emergency_log_date ON digital_saver_emergency_log(triggered_at DESC);

-- Grant permissions (for RLS policies)
-- Note: Adjust based on your RLS configuration

COMMENT ON TABLE digital_saver_user_profiles IS 'User health profiles for Digital Saver app';
COMMENT ON TABLE digital_saver_ai_insights IS 'AI-generated health insights for users';
COMMENT ON TABLE digital_saver_health_predictions IS 'AI health predictions based on user data';
COMMENT ON TABLE digital_saver_emergency_log IS 'Emergency alert history for auditing';
