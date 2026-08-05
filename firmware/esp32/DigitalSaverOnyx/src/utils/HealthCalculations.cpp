/*
 * Health Calculations Implementation
 */

#include "HealthCalculations.h"
#include <math.h>

double HealthCalculations::calculateBMR(int weightKg, int heightCm, int age, char gender) {
    if (gender == 'F' || gender == 'f' || gender == 'f') {
        return (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age) - 161.0;
    } else {
        return (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age) + 5.0;
    }
}

double HealthCalculations::calculateDailyCalories(double bmr, int activityLevel) {
    // Activity multipliers
    static const double multipliers[] = {1.2, 1.375, 1.55, 1.725, 1.9};
    activityLevel = constrain(activityLevel, 0, 4);
    return bmr * multipliers[activityLevel];
}

BloodPressureEstimate HealthCalculations::estimateBloodPressure(int heartRate, int hrv, int age, bool hasHypertension) {
    BloodPressureEstimate result;
    
    // Base systolic (simplified formula)
    int baseSystolic = 100 + (age / 2);
    
    // Adjust based on heart rate
    if (heartRate > 100) {
        baseSystolic += 10;
    } else if (heartRate < 60) {
        baseSystolic -= 10;
    }
    
    // Adjust based on HRV (higher HRV = generally better cardiovascular health)
    if (hrv > 60) {
        baseSystolic -= 10;
    } else if (hrv > 0 && hrv < 30) {
        baseSystolic += 10;
    }
    
    // Hypertension modifier
    if (hasHypertension) {
        baseSystolic += 20;
    }
    
    // Calculate diastolic (roughly 60-70% of systolic)
    result.systolic = constrain(baseSystolic, 80, 200);
    result.diastolic = (result.systolic * 60) / 100;
    
    // Confidence based on available data
    if (hrv > 0) {
        result.confidence = 70;
    } else {
        result.confidence = 50;
    }
    
    return result;
}

int HealthCalculations::getMAP(int systolic, int diastolic) {
    // MAP = DBP + (SBP - DBP) / 3
    return diastolic + (systolic - diastolic) / 3;
}

float HealthCalculations::calculateDistance(int steps, int heightCm) {
    // Average stride length = height * 0.415 (men) or 0.413 (women)
    float strideLength = heightCm * 0.414 / 100; // in meters
    return (steps * strideLength) / 1000.0; // in km
}

float HealthCalculations::calculateCaloriesFromSteps(int steps, int weightKg, int heightCm) {
    // Calories per km walked = weight (kg) * 0.5 (approximate)
    float distanceKm = calculateDistance(steps, heightCm);
    return distanceKm * weightKg * 0.5;
}

void HealthCalculations::getHeartRateZones(int age, int* zones) {
    int maxHR = 220 - age;
    
    zones[0] = maxHR * 50 / 100;  // Resting (50%)
    zones[1] = maxHR * 60 / 100;  // Fat burn (60%)
    zones[2] = maxHR * 70 / 100;  // Cardio (70%)
    zones[3] = maxHR * 85 / 100;  // Peak (85%)
    zones[4] = maxHR;              // Maximum
}

float HealthCalculations::calculateBMI(int weightKg, int heightCm) {
    if (heightCm <= 0) return 0;
    float heightM = heightCm / 100.0;
    return weightKg / (heightM * heightM);
}
