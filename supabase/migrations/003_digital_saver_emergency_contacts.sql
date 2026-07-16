-- Digital Saver: Emergency Contacts Table
-- Stores emergency contacts for health alerts
-- Version: 1.0.0
-- Created: 2024

CREATE TABLE IF NOT EXISTS public.digital_saver_emergency_contacts (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    relation TEXT CHECK (relation IN ('spouse', 'parent', 'child', 'sibling', 'friend', 'doctor', 'caregiver', 'other')),
    email TEXT,
    is_primary BOOLEAN DEFAULT FALSE,
    notify_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.digital_saver_emergency_contacts ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can manage their own emergency contacts
DROP POLICY IF EXISTS "digital_saver_users_can_view_own_contacts" ON public.digital_saver_emergency_contacts;
CREATE POLICY "digital_saver_users_can_view_own_contacts" ON public.digital_saver_emergency_contacts
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "digital_saver_users_can_insert_own_contacts" ON public.digital_saver_emergency_contacts;
CREATE POLICY "digital_saver_users_can_insert_own_contacts" ON public.digital_saver_emergency_contacts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "digital_saver_users_can_update_own_contacts" ON public.digital_saver_emergency_contacts;
CREATE POLICY "digital_saver_users_can_update_own_contacts" ON public.digital_saver_emergency_contacts
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "digital_saver_users_can_delete_own_contacts" ON public.digital_saver_emergency_contacts;
CREATE POLICY "digital_saver_users_can_delete_own_contacts" ON public.digital_saver_emergency_contacts
    FOR DELETE USING (auth.uid() = user_id);

-- Trigger to auto-update updated_at
DROP TRIGGER IF EXISTS update_digital_saver_emergency_contacts_updated_at ON public.digital_saver_emergency_contacts;
CREATE TRIGGER update_digital_saver_emergency_contacts_updated_at
    BEFORE UPDATE ON public.digital_saver_emergency_contacts
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.digital_saver_emergency_contacts IS 'Digital Saver emergency contacts - stores contacts to notify during health emergencies';
