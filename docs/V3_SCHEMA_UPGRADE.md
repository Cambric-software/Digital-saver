# Digital Saver v3.0 Schema Upgrade Plan

## Overview
Preparing the Supabase schema for v3.0 major features.

---

## Current Schema (v2.x)

### Existing Tables
- `digital_saver_user_profiles` - User profile data
- `digital_saver_devices` - Watch device registration
- `digital_saver_health_logs` - Raw health readings
- `digital_saver_daily_aggregates` - Daily summaries
- `digital_saver_emergency_contacts` - Emergency contacts
- `digital_saver_health_goals` - User goals
- `digital_saver_health_alerts` - Alert history
- `digital_saver_sync_history` - Sync tracking
- `digital_saver_storage_stats` - Storage metrics

---

## v3.0 New Features Requiring Schema Changes

### 1. AI Health Predictions
**New Tables Needed:**
```sql
-- AI model predictions cache
CREATE TABLE digital_saver_ai_predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES digital_saver_user_profiles(id),
    prediction_type TEXT NOT NULL, -- 'health_trend', 'risk_score', 'anomaly'
    prediction_data JSONB NOT NULL, -- {'score': 0.85, 'confidence': 0.92, 'factors': [...]}
    model_version TEXT NOT NULL,
    prediction_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days')
);

-- Health trend analysis
CREATE TABLE digital_saver_health_trends (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES digital_saver_user_profiles(id),
    metric_type TEXT NOT NULL, -- 'heart_rate', 'spo2', 'sleep_quality'
    trend_direction TEXT NOT NULL, -- 'improving', 'stable', 'declining'
    confidence_score DECIMAL(3,2),
    period_days INTEGER DEFAULT 30,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2. Multi-Device Support (Onyx Pro)
**Schema Changes:**
```sql
-- Enhanced device table
ALTER TABLE digital_saver_devices ADD COLUMN device_type TEXT DEFAULT 'onyx';
ALTER TABLE digital_saver_devices ADD COLUMN firmware_version TEXT;
ALTER TABLE digital_saver_devices ADD COLUMN last_heartbeat TIMESTAMPTZ;
ALTER TABLE digital_saver_devices ADD COLUMN battery_level INTEGER;
ALTER TABLE digital_saver_devices ADD COLUMN is_primary BOOLEAN DEFAULT true;

-- Multi-device health sync
CREATE TABLE digital_saver_device_sync (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID REFERENCES digital_saver_devices(id),
    sync_type TEXT NOT NULL, -- 'full', 'incremental', 'conflict_resolution'
    records_synced INTEGER,
    sync_duration_ms INTEGER,
    sync_status TEXT DEFAULT 'success',
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 3. Family Sharing
**New Tables:**
```sql
-- Family groups
CREATE TABLE digital_saver_family_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_name TEXT NOT NULL,
    owner_id UUID REFERENCES digital_saver_user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    invite_code TEXT UNIQUE
);

-- Family members
CREATE TABLE digital_saver_family_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES digital_saver_family_groups(id),
    user_id UUID REFERENCES digital_saver_user_profiles(id),
    role TEXT DEFAULT 'member', -- 'owner', 'admin', 'member', 'viewer'
    permissions JSONB DEFAULT '{}', -- {'view_health': true, 'receive_alerts': false}
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(group_id, user_id)
);

-- Shared health view permissions
CREATE TABLE digital_saver_health_sharing (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES digital_saver_user_profiles(id),
    viewer_id UUID REFERENCES digital_saver_user_profiles(id),
    shared_metrics TEXT[] DEFAULT '{}', -- ['heart_rate', 'location', 'alerts']
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 4. Advanced Analytics Dashboard
**New Tables:**
```sql
-- Weekly/Monthly reports
CREATE TABLE digital_saver_health_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES digital_saver_user_profiles(id),
    report_type TEXT NOT NULL, -- 'weekly', 'monthly', 'custom'
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    summary_data JSONB NOT NULL, -- Aggregated health metrics
    insights JSONB DEFAULT '[]', -- AI-generated insights
    report_url TEXT, -- Stored report file
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Activity achievements
CREATE TABLE digital_saver_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES digital_saver_user_profiles(id),
    achievement_type TEXT NOT NULL,
    achievement_data JSONB,
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, achievement_type)
);
```

---

## Migration Priority

### Phase 1: Multi-Device Support (v3.1)
- [ ] Enhance `digital_saver_devices` table
- [ ] Create `digital_saver_device_sync` table
- [ ] Add RLS policies for device access

### Phase 2: Family Sharing (v3.2)
- [ ] Create family tables
- [ ] Implement sharing permissions
- [ ] Add notification for shared alerts

### Phase 3: AI Predictions (v3.3)
- [ ] Create prediction tables
- [ ] Integrate ML model API
- [ ] Add prediction display to app

### Phase 4: Advanced Analytics (v3.4)
- [ ] Create report generation tables
- [ ] Build automated reporting
- [ ] Add achievements system

---

## Backwards Compatibility
All v3.0 changes must:
- Work with existing v2.x app versions
- Use feature flags for new functionality
- Provide graceful degradation

---

## Testing Requirements
- [ ] Test migrations on staging
- [ ] Verify RLS policies
- [ ] Check performance with indexes
- [ ] Cross-app compatibility (Atlas, Frame)
