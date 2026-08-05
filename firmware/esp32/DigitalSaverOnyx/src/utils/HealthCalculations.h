/*
 * Health Calculations Utility
 * Various health-related calculations
 */

#ifndef HEALTH_CALCULATIONS_H
#define HEALTH_CALCULATIONS_H

#include <Arduino.h>

struct BloodPressureEstimate {
    int systolic;
    int diastolic;
    int confidence;
};

class HealthCalculations {
public:
    // Calculate BMR using Mifflin-St Jeor Equation
    static double calculateBMR(int weightKg, int heightCm, int age, char gender);
    
    // Calculate daily calorie needs
    static double calculateDailyCalories(double bmr, int activityLevel);
    
    // Estimate blood pressure using PTT (Pulse Transit Time) approximation
    static BloodPressureEstimate estimateBloodPressure(int heartRate, int hrv, int age, bool hasHypertension);
    
    // Calculate Mean Arterial Pressure
    static int getMAP(int systolic, int diastolic);
    
    // Calculate step distance
    static float calculateDistance(int steps, int heightCm);
    
    // Calculate calorie burn from steps
    static float calculateCaloriesFromSteps(int steps, int weightKg, int heightCm);
    
    // Calculate target heart rate zones
    static void getHeartRateZones(int age, int* zones);
    
    // Calculate BMI
    static float calculateBMI(int weightKg, int heightCm);
};

#endif // HEALTH_CALCULATIONS_H
