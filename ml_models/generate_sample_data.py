import pandas as pd
import numpy as np
from datetime import datetime, timedelta

np.random.seed(42)

def generate_sample_data(n_samples=500):
    """Generate synthetic student data for training"""
    
    data = []
    
    for i in range(n_samples):
        # Generate features with realistic correlations
        attendance = np.random.uniform(40, 100)
        
        # Internal marks correlate with attendance
        internal_base = attendance * 0.6 + np.random.normal(10, 10)
        internal_avg = np.clip(internal_base, 0, 100)
        
        # External GPA (0-10 scale)
        external_base = (attendance * 0.05 + internal_avg * 0.05) + np.random.normal(0, 1.5)
        external_gpa = np.clip(external_base, 0, 10)
        
        # Activity count (students with better performance tend to participate more)
        activity_prob = (attendance + internal_avg) / 200
        activity_count = np.random.poisson(activity_prob * 5)
        
        # Backlogs (inversely correlated with performance)
        backlog_prob = max(0, (100 - attendance) / 100 * (100 - internal_avg) / 100)
        backlog_count = np.random.binomial(5, backlog_prob)
        
        # Determine risk level based on rules
        risk_score = 0
        
        if attendance < 75:
            risk_score += 30
        elif attendance < 85:
            risk_score += 15
            
        if internal_avg < 50:
            risk_score += 25
        elif internal_avg < 70:
            risk_score += 10
            
        if external_gpa < 5:
            risk_score += 25
        elif external_gpa < 7:
            risk_score += 10
            
        if activity_count == 0:
            risk_score += 10
            
        risk_score += backlog_count * 10
        
        # Classify risk level
        if risk_score >= 60:
            risk_level = 2  # High
        elif risk_score >= 30:
            risk_level = 1  # Medium
        else:
            risk_level = 0  # Low
        
        data.append({
            'attendance_percentage': round(attendance, 2),
            'internal_avg': round(internal_avg, 2),
            'external_gpa': round(external_gpa, 2),
            'activity_count': activity_count,
            'backlog_count': backlog_count,
            'risk_level': risk_level
        })
    
    df = pd.DataFrame(data)
    return df

if __name__ == "__main__":
    # Generate training data
    df = generate_sample_data(500)
    
    # Save to CSV
    df.to_csv('training_data.csv', index=False)
    
    print("Sample data generated successfully!")
    print(f"\nDataset shape: {df.shape}")
    print(f"\nRisk level distribution:")
    print(df['risk_level'].value_counts().sort_index())
    print(f"\n0 = Low Risk, 1 = Medium Risk, 2 = High Risk")
    print(f"\nFirst few rows:")
    print(df.head(10))
    print(f"\nData saved to training_data.csv")
