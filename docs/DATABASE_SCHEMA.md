# Digital Saver - Complete Database Schema Documentation

> **Document Version:** 1.0.0  
> **Last Updated:** July 2026  
> **Database:** Supabase PostgreSQL  
> **Project:** Digital Saver Health Monitoring System  
> **Company:** Cambric  
> **Copyright:** © 2026 Cambric. All Rights Reserved.

---

## Table of Contents

1. [Database Overview](#1-database-overview)
2. [Schema Architecture](#2-schema-architecture)
3. [User Profiles Table](#3-user-profiles-table)
4. [Health Logs Table](#4-health-logs-table)
5. [Devices Table](#5-devices-table)
6. [Emergency Contacts Table](#6-emergency-contacts-table)
7. [Health Goals Table](#7-health-goals-table)
8. [Health Alerts Table](#8-health-alerts-table)
9. [Sync History Table](#9-sync-history-table)
10. [Storage Stats Table](#10-storage-stats-table)
11. [Row Level Security](#11-row-level-security)
12. [Triggers & Functions](#12-triggers--functions)
13. [Indexes & Optimization](#13-indexes--optimization)
14. [API Queries](#14-api-queries)

---

## 1. Database Overview

### Connection Details

| Property | Value |
|----------|-------|
| **Project ID** | dafgzzkerytjuvxzymnq |
| **Region** | Auto-selected |
| **Database** | PostgreSQL 15.x |
| **Schema** | public |
| **RLS** | Enabled on all tables |

### Supabase Project Reference

```
URL: https://dafgzzkerytjuvxzymnq.supabase.co
Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRhZmd6emtlcnl0anV2eHp5bW5xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM3MTE1MDUsImV4cCI6MjA5OTI4NzUwNX0.bZdxqNuy1ZyHMGzBieq7BzUd6IUEhfHEZxL-YTka3DQ
```

### Database Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         DIGITAL SAVER SCHEMA                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│    ┌─────────────────────┐                                               │
│    │    auth.users       │ (Supabase Built-in)                          │
│    │    (UUID, PK)       │                                               │
│    └──────────┬──────────┘                                               │
│               │ 1:1                                                      │
│    ┌──────────▼──────────┐                                               │
│    │ digital_saver_      │                                               │
│    │ user_profiles       │                                               │
│    │ (UUID, FK → auth)  │                                               │
│    └──────────┬──────────┘                                               │
│               │ 1:N                                                      │
│    ┌──────────▼──────────┐     ┌─────────────────────┐                │
│    │ digital_saver_      │────►│ digital_saver_     │                │
│    │ health_logs         │     │ devices             │                │
│    │                     │     └──────────┬──────────┘                │
│    └──────────┬──────────┘               │ 1:N                        │
│               │                          │                             │
│    ┌──────────▼──────────┐     ┌───────▼───────────────┐            │
│    │ digital_saver_      │     │ digital_saver_       │            │
│    │ daily_aggregates    │     │ emergency_contacts   │            │
│    └─────────────────────┘     └──────────────────────┘            │
│                                                                          │
│    ┌─────────────────────┐     ┌─────────────────────┐                │
│    │ digital_saver_      │     │ digital_saver_      │                │
│    │ health_goals        │     │ health_alerts       │                │
│    └─────────────────────┘     └─────────────────────┘                │
│                                                                          │
│    ┌─────────────────────┐     ┌─────────────────────┐                │
│    │ digital_saver_      │     │ digital_saver_      │                │
│    │ sync_history        │     │ storage_stats      │                │
│    └─────────────────────┘     └─────────────────────┘                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Schema Architecture

### Table Summary

| Table Name | Rows | Purpose | RLS |
|------------|------|---------|-----|
| `digital_saver_user_profiles` | 4 | Extended user data | Enabled |
| `digital_saver_devices` | 0 | Watch device info | Enabled |
| `digital_saver_health_logs` | 1 | Health measurements | Enabled |
| `digital_saver_daily_aggregates` | 0 | Daily summaries | Enabled |
| `digital_saver_emergency_contacts` | 0 | SOS contacts | Enabled |
| `digital_saver_health_goals` | 0 | User goals | Enabled |
| `digital_saver_health_alerts` | 0 | System alerts | Enabled |
| `digital_saver_sync_history` | 0 | Sync records | Enabled |
| `digital_saver_storage_stats` | 4 | Storage metrics | Enabled |

---

## 3. User Profiles Table

### Table Definition

```sql
CREATE TABLE public.digital_saver_user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Basic Info
    display_name TEXT,
    email TEXT,
    avatar_url TEXT,
    phone TEXT,
    
    -- Demographics
    date_of_birth DATE,
    gender TEXT CHECK (gender IN ('male', 'female', 'other')),
    age INTEGER GENERATED ALWAYS AS (
        CASE WHEN date_of_birth IS NOT NULL 
        THEN EXTRACT(YEAR FROM AGE(date_of_birth))
        ELSE NULL END
    ) STORED,
    weight_kg REAL,
    height_cm REAL,
    blood_type TEXT,
    
    -- Emergency Contact
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    
    -- Medical Info
    medical_conditions TEXT[],
    allergies TEXT[],
    medications TEXT[],
    insurance_provider TEXT,
    insurance_policy_number TEXT,
    
    -- Preferences
    preferred_language TEXT DEFAULT 'en',
    timezone TEXT DEFAULT 'UTC',
    
    -- Notifications
    notification_enabled BOOLEAN DEFAULT true,
    email_notifications BOOLEAN DEFAULT true,
    push_notifications BOOLEAN DEFAULT true,
    sms_alerts BOOLEAN DEFAULT false,
    
    -- Consent
    data_sharing_consent BOOLEAN DEFAULT false,
    research_consent BOOLEAN DEFAULT false,
    
    -- Timestamps
    last_sync_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Column Reference

| Column | Type | Nullable | Default | Constraints |
|--------|------|----------|---------|-------------|
| id | UUID | NO | - | PRIMARY KEY, FK → auth.users |
| display_name | TEXT | YES | - | - |
| email | TEXT | YES | - | - |
| avatar_url | TEXT | YES | - | - |
| phone | TEXT | YES | - | - |
| date_of_birth | DATE | YES | - | - |
| gender | TEXT | YES | - | CHECK (male/female/other) |
| age | INTEGER | YES | AUTO | GENERATED from date_of_birth |
| weight_kg | REAL | YES | - | - |
| height_cm | REAL | YES | - | - |
| blood_type | TEXT | YES | - | - |
| emergency_contact_name | TEXT | YES | - | - |
| emergency_contact_phone | TEXT | YES | - | - |
| medical_conditions | TEXT[] | YES | - | - |
| allergies | TEXT[] | YES | - | - |
| medications | TEXT[] | YES | - | - |
| insurance_provider | TEXT | YES | - | - |
| insurance_policy_number | TEXT | YES | - | - |
| preferred_language | TEXT | YES | 'en' | - |
| timezone | TEXT | YES | 'UTC' | - |
| notification_enabled | BOOLEAN | YES | true | - |
| email_notifications | BOOLEAN | YES | true | - |
| push_notifications | BOOLEAN | YES | true | - |
| sms_alerts | BOOLEAN | YES | false | - |
| data_sharing_consent | BOOLEAN | YES | false | - |
| research_consent | BOOLEAN | YES | false | - |
| last_sync_at | TIMESTAMPTZ | YES | - | - |
| created_at | TIMESTAMPTZ | YES | NOW() | - |
| updated_at | TIMESTAMPTZ | YES | NOW() | - |

---

## 4. Health Logs Table

### Table Definition

```sql
CREATE TABLE public.digital_saver_health_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id UUID REFERENCES public.digital_saver_devices(id) ON DELETE SET NULL,
    
    -- Classification
    data_type TEXT NOT NULL CHECK (data_type IN (
        'heart_rate', 'blood_pressure', 'oxygen', 'activity', 
        'sleep', 'hrv', 'stress', 'temperature', 'respiratory',
        'weight', 'glucose', 'ecg', 'steps', 'calories', 
        'distance', 'floors', 'active_minutes'
    )),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    source TEXT DEFAULT 'device' CHECK (source IN ('device', 'manual', 'imported', 'calculated')),
    quality_score INTEGER CHECK (quality_score >= 0 AND quality_score <= 100) DEFAULT 100,
    
    -- Heart Rate
    heart_rate INTEGER CHECK (heart_rate >= 20 AND heart_rate <= 300),
    heart_rate_min INTEGER,
    heart_rate_max INTEGER,
    
    -- HRV
    hrv_rmssd REAL,
    hrv_sdnn REAL,
    
    -- Blood Pressure
    systolic_bp INTEGER CHECK (systolic_bp >= 60 AND systolic_bp <= 250),
    diastolic_bp INTEGER CHECK (diastolic_bp >= 40 AND diastolic_bp <= 150),
    mean_arterial_pressure REAL,
    
    -- Oxygen
    spo2 REAL CHECK (spo2 >= 70 AND spo2 <= 100),
    spo2_min REAL,
    
    -- Activity
    steps INTEGER DEFAULT 0,
    distance_km REAL,
    calories_burned REAL,
    active_minutes INTEGER DEFAULT 0,
    moderate_minutes INTEGER DEFAULT 0,
    vigorous_minutes INTEGER DEFAULT 0,
    floors_climbed INTEGER DEFAULT 0,
    
    -- Sleep
    sleep_minutes INTEGER DEFAULT 0,
    deep_sleep_minutes INTEGER DEFAULT 0,
    light_sleep_minutes INTEGER DEFAULT 0,
    rem_sleep_minutes INTEGER DEFAULT 0,
    awake_minutes INTEGER DEFAULT 0,
    sleep_efficiency REAL,
    sleep_score INTEGER CHECK (sleep_score >= 0 AND sleep_score <= 100),
    
    -- Other Metrics
    stress_level INTEGER CHECK (stress_level >= 1 AND stress_level <= 10),
    body_temperature REAL,
    respiratory_rate INTEGER,
    weight_kg REAL,
    bmi REAL,
    glucose_mg_dl INTEGER,
    
    -- ECG & Analysis
    ecg_data JSONB,
    afib_detected BOOLEAN,
    
    -- Metadata
    notes TEXT,
    tags TEXT[],
    metadata JSONB DEFAULT '{}',
    is_anomaly BOOLEAN DEFAULT false,
    anomaly_type TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Health Log Data Types

| Data Type | Key Columns | Unit |
|-----------|-------------|------|
| heart_rate | heart_rate | BPM |
| blood_pressure | systolic_bp, diastolic_bp | mmHg |
| oxygen | spo2 | % |
| activity | steps, calories, active_minutes | steps/kcal/min |
| sleep | sleep_minutes, deep_sleep, rem_sleep | minutes |
| hrv | hrv_rmssd, hrv_sdnn | ms |
| weight | weight_kg, bmi | kg |
| temperature | body_temperature | °C |

---

## 5. Devices Table

### Table Definition

```sql
CREATE TABLE public.digital_saver_devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_name TEXT NOT NULL,
    device_type TEXT NOT NULL CHECK (device_type IN (
        'smartwatch', 'fitness_tracker', 'blood_pressure_monitor',
        'glucose_meter', 'scale', 'thermometer', 
        'pulse_oximeter', 'ecg', 'other'
    )),
    
    -- Device Info
    manufacturer TEXT,
    model TEXT,
    serial_number TEXT,
    firmware_version TEXT,
    mac_address TEXT,
    
    -- Status
    battery_level INTEGER CHECK (battery_level >= 0 AND battery_level <= 100),
    last_sync_at TIMESTAMPTZ,
    is_primary BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    
    -- Settings
    settings JSONB DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 6. Emergency Contacts Table

### Table Definition

```sql
CREATE TABLE public.digital_saver_emergency_contacts (
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
```

---

## 7. Health Goals Table

### Table Definition

```sql
CREATE TABLE public.digital_saver_health_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    goal_type TEXT NOT NULL CHECK (goal_type IN (
        'steps', 'sleep', 'weight', 'hr', 'bp',
        'activity', 'calories', 'water', 'medication'
    )),
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
```

---

## 8. Health Alerts Table

### Table Definition

```sql
CREATE TABLE public.digital_saver_health_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    alert_type TEXT NOT NULL CHECK (alert_type IN (
        'high_hr', 'low_hr', 'high_bp', 'low_bp', 'low_spo2',
        'irregular_rhythm', 'afib', 'anomaly', 'trend_alert',
        'goal_achieved', 'reminder'
    )),
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
```

---

## 9. Sync History Table

### Table Definition

```sql
CREATE TABLE public.digital_saver_sync_history (
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
```

---

## 10. Storage Stats Table

### Table Definition

```sql
CREATE TABLE public.digital_saver_storage_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    total_records INTEGER DEFAULT 0,
    total_storage_bytes BIGINT DEFAULT 0,
    records_by_type JSONB DEFAULT '{}',
    last_cleanup_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 11. Row Level Security

### RLS Policies

All tables have Row Level Security enabled with the following pattern:

```sql
-- Users can only see their own data
CREATE POLICY "Users can view own profile" ON public.digital_saver_user_profiles
    FOR SELECT USING (auth.uid() = id);

-- Users can only insert their own data
CREATE POLICY "Users can insert own profile" ON public.digital_saver_user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Users can only update their own data
CREATE POLICY "Users can update own profile" ON public.digital_saver_user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- Users can only delete their own data
CREATE POLICY "Users can delete own profile" ON public.digital_saver_user_profiles
    FOR DELETE USING (auth.uid() = id);
```

### RLS for Health Logs

```sql
-- Health logs use user_id column
CREATE POLICY "Users can manage own health logs" ON public.digital_saver_health_logs
    FOR ALL USING (auth.uid() = user_id);
```

---

## 12. Triggers & Functions

### Auto-Update Timestamp Function

```sql
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables
CREATE TRIGGER update_profiles_updated_at 
    BEFORE UPDATE ON public.digital_saver_user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_devices_updated_at 
    BEFORE UPDATE ON public.digital_saver_devices
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_contacts_updated_at 
    BEFORE UPDATE ON public.digital_saver_emergency_contacts
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_goals_updated_at 
    BEFORE UPDATE ON public.digital_saver_health_goals
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
```

### Auto-Create Profile on Signup

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Create user profile
    INSERT INTO public.digital_saver_user_profiles (id, email, display_name, created_at)
    VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'display_name', NOW());
    
    -- Create storage stats
    INSERT INTO public.digital_saver_storage_stats (user_id)
    VALUES (NEW.id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

---

## 13. Indexes & Optimization

### Index Definitions

```sql
-- Health logs indexes
CREATE INDEX idx_health_logs_user_recorded 
    ON public.digital_saver_health_logs(user_id, recorded_at DESC);
CREATE INDEX idx_health_logs_data_type 
    ON public.digital_saver_health_logs(data_type);
CREATE INDEX idx_health_logs_device 
    ON public.digital_saver_health_logs(device_id);
CREATE INDEX idx_health_logs_anomaly 
    ON public.digital_saver_health_logs(is_anomaly) WHERE is_anomaly = true;

-- User profiles index
CREATE INDEX idx_profiles_email 
    ON public.digital_saver_user_profiles(email) WHERE email IS NOT NULL;

-- Emergency contacts index
CREATE INDEX idx_contacts_user 
    ON public.digital_saver_emergency_contacts(user_id, priority);
```

### Query Optimization Examples

```sql
-- Get latest health data for a user
SELECT * FROM digital_saver_health_logs
WHERE user_id = auth.uid()
ORDER BY recorded_at DESC
LIMIT 10;

-- Get daily averages for the past week
SELECT 
    DATE(recorded_at) as date,
    AVG(heart_rate) as avg_hr,
    AVG(steps) as avg_steps,
    AVG(spo2) as avg_spo2
FROM digital_saver_health_logs
WHERE user_id = auth.uid()
  AND recorded_at >= NOW() - INTERVAL '7 days'
GROUP BY DATE(recorded_at)
ORDER BY date DESC;
```

---

## 14. API Queries

### Supabase Client Usage

```dart
// Initialize Supabase
import 'package:supabase_flutter/supabase_flutter.dart';

await Supabase.initialize(
  url: 'https://dafgzzkerytjuvxzymnq.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
);

// Get current user
final user = Supabase.instance.client.auth.currentUser;

// Insert health log
await Supabase.instance.client
    .from('digital_saver_health_logs')
    .insert({
      'user_id': user!.id,
      'data_type': 'heart_rate',
      'heart_rate': 72,
      'recorded_at': DateTime.now().toIso8601String(),
    });

// Query health logs
final logs = await Supabase.instance.client
    .from('digital_saver_health_logs')
    .select()
    .eq('user_id', user!.id)
    .eq('data_type', 'heart_rate')
    .order('recorded_at', ascending: false)
    .limit(100);

// Update user profile
await Supabase.instance.client
    .from('digital_saver_user_profiles')
    .update({
      'display_name': 'John Doe',
      'weight_kg': 75.0,
      'height_cm': 175.0,
    })
    .eq('id', user!.id);

// Delete old health logs (cleanup)
await Supabase.instance.client
    .from('digital_saver_health_logs')
    .delete()
    .eq('user_id', user!.id)
    .lt('recorded_at', DateTime.now().subtract(Duration(days: 365)));
```

---

**Document Version:** 1.0.0  
**Last Updated:** July 2026  
**Author:** Cambric Engineering Team  
**Copyright © 2026 Cambric. All Rights Reserved.**
