/*
 * Pattern Analyzer Module
 * Identifies complex health patterns
 */

#ifndef PATTERN_ANALYZER_H
#define PATTERN_ANALYZER_H

#include <Arduino.h>

enum class PatternType {
    NONE,
    TACHYCARDIA,
    BRADYCARDIA,
    HYPERTENSION,
    HYPOTENSION,
    HYPOXIA,
    ARRHYTHMIA,
    STRESS,
    FATIGUE,
    OVEREXERTION
};

struct DetectedPattern {
    PatternType type;
    int severity;
    unsigned long startTime;
    int occurrenceCount;
    char description[50];
};

class PatternAnalyzer {
private:
    bool initialized = false;
    
    DetectedPattern patterns[20];
    int patternCount = 0;
    
    // State tracking
    int consecutiveHighHR = 0;
    int consecutiveLowHR = 0;
    int consecutiveLowSpO2 = 0;
    
public:
    PatternAnalyzer() {}
    
    void begin();
    void update(HealthReading reading, HealthPattern* aiPatterns, int riskScore);
    
    int getPatternCount() { return patternCount; }
    DetectedPattern* getPatterns() { return patterns; }
};

#endif // PATTERN_ANALYZER_H
