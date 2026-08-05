/*
 * Configuration Manager
 * Persistent storage using Preferences
 */

#ifndef CONFIG_MANAGER_H
#define CONFIG_MANAGER_H

#include <Arduino.h>
#include <Preferences.h>

class ConfigManager {
private:
    Preferences preferences;
    bool initialized = false;
    
public:
    ConfigManager() {}
    
    void begin();
    
    // Profile
    void loadProfile(char* name, int* age, int* weight, int* height, char* gender, 
                     char* bloodType, bool* hasHeart, bool* hasDiabetes, 
                     bool* hasHypertension, bool* hasAsthma,
                     char* emergencyName, char* emergencyPhone);
    
    void saveProfile(const char* name, int age, int weight, int height, char gender,
                     const char* bloodType, bool hasHeart, bool hasDiabetes,
                     bool hasHypertension, bool hasAsthma,
                     const char* emergencyName, const char* emergencyPhone);
    
    // Settings
    bool getStealthMode();
    void setStealthMode(bool enabled);
    
    unsigned long getSleepTimeout();
    void setSleepTimeout(unsigned long ms);
    
    int getStepGoal();
    void setStepGoal(int goal);
    
    // Reset
    void resetAll();
};

#endif // CONFIG_MANAGER_H
