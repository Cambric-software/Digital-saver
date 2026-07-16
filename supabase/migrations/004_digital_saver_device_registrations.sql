-- Digital Saver: Device Registrations Table
-- Stores registered smartwatch devices
-- Version: 1.0.0
-- Created: 2024

CREATE TABLE IF NOT EXISTS public.digital_saver_device_registrations (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_name TEXT,
    device_type TEXT DEFAULT 'smartwatch' CHECK (device_type IN ('smartwatch', 'fitness_tracker', 'health_monitor', 'other')),
    manufacturer TEXT,
    model TEXT,
    firmware_version TEXT,
    ble_mac_address TEXT,
    ble_device_uuid TEXT,
    battery_capacity_mah INTEGER,
    battery_type TEXT,
    display_type TEXT,
    last_seen_at TIMESTAMP WITH TIME ZONE,
    last_battery_level INTEGER,
    total_connections INTEGER DEFAULT 0,
    total_data_points INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    is_paired BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.digital_saver_device_registrations ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can manage their own devices
DROP POLICY IF EXISTS "digital_saver_users_can_view_own_devices" ON public.digital_saver_device_registrations;
CREATE POLICY "digital_saver_users_can_view_own_devices" ON public.digital_saver_device_registrations
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "digital_saver_users_can_insert_own_devices" ON public.digital_saver_device_registrations;
CREATE POLICY "digital_saver_users_can_insert_own_devices" ON public.digital_saver_device_registrations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "digital_saver_users_can_update_own_devices" ON public.digital_saver_device_registrations;
CREATE POLICY "digital_saver_users_can_update_own_devices" ON public.digital_saver_device_registrations
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "digital_saver_users_can_delete_own_devices" ON public.digital_saver_device_registrations;
CREATE POLICY "digital_saver_users_can_delete_own_devices" ON public.digital_saver_device_registrations
    FOR DELETE USING (auth.uid() = user_id);

-- Trigger to auto-update updated_at
DROP TRIGGER IF EXISTS update_digital_saver_device_registrations_updated_at ON public.digital_saver_device_registrations;
CREATE TRIGGER update_digital_saver_device_registrations_updated_at
    BEFORE UPDATE ON public.digital_saver_device_registrations
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.digital_saver_device_registrations IS 'Digital Saver device registrations - stores paired smartwatch device information';
