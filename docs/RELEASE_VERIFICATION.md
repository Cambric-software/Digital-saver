# Digital Saver Release Verification Guide

## Overview
This guide ensures all releases are properly verified before deployment.

---

## Pre-Release Checklist

### 1. Code Quality ✅
- [ ] No `!` null assertions without proper guards
- [ ] No empty catch blocks (all must log errors)
- [ ] All async functions properly awaited
- [ ] No hardcoded credentials or secrets
- [ ] Code passes `flutter analyze`

### 2. Database Schema ✅
- [ ] All tables have proper RLS policies
- [ ] No touching other apps' tables (Atlas, Frame)
- [ ] Indexes in place for performance
- [ ] Migrations tested

### 3. Security ✅
- [ ] Auth flows tested (sign up, sign in, sign out)
- [ ] RLS policies verified
- [ ] No sensitive data in logs
- [ ] API keys not exposed

### 4. Functionality ✅
- [ ] Sign up / Sign in flow works
- [ ] Profile creation completes
- [ ] BLE device connection works
- [ ] Health data syncs correctly
- [ ] Emergency alerts trigger properly

### 5. Build Verification ✅
- [ ] Android APK builds successfully
- [ ] Windows build completes (manual for now)
- [ ] Linux build completes
- [ ] All download links work

---

## Release Testing Procedure

### Android Testing
1. Install APK on test device
2. Clear app data
3. Sign up with test account
4. Complete profile
5. Connect to watch simulator
6. Verify health data appears
7. Test emergency contact flow

### Cross-Platform Testing
1. Test sign-in on web version
2. Verify email sync works
3. Check cached email feature

---

## Bug Hunt Integration

The Bug Hunt automation runs daily at 8:00 AM UTC. It checks:
- GitHub issues for bugs
- Supabase logs for errors
- Codebase for common issues
- Empty catch blocks
- Null assertions

If CRITICAL/HIGH issues found, it creates a PR for review.

---

## Emergency Contacts
- Development Lead: Cambric Team
- Supabase Project: Cambric
- GitHub: Cambric-software/Digital-saver
