import joblib
import numpy as np
from pathlib import Path
from typing import Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import func
import models

class MLService:
    def __init__(self):
        self.model = None
        self.scaler = None
        self.model_path = Path(__file__).parent.parent / "ml_models" / "best_model.pkl"
        self.scaler_path = Path(__file__).parent.parent / "ml_models" / "feature_scaler.pkl"
        self.load_model()
    
    def load_model(self):
        """Load the trained model and scaler"""
        try:
            if self.model_path.exists():
                self.model = joblib.load(self.model_path)
                print("ML model loaded successfully")
            else:
                print("Warning: ML model not found. Please train the model first.")
            
            if self.scaler_path.exists():
                self.scaler = joblib.load(self.scaler_path)
                print("Feature scaler loaded successfully")
        except Exception as e:
            print(f"Error loading model: {e}")
    
    def extract_features(self, db: Session, student_id: int) -> Dict[str, float]:
        """Extract features for a student"""
        # Get attendance percentage
        avg_attendance = db.query(func.avg(models.Attendance.attendance_percentage)).filter(
            models.Attendance.student_id == student_id
        ).scalar() or 0
        
        # Get internal marks average
        internal_avg = db.query(func.avg(models.Mark.internal_marks)).filter(
            models.Mark.student_id == student_id
        ).scalar() or 0
        
        # Calculate external GPA (simplified: average of external marks / 10)
        external_avg = db.query(func.avg(models.Mark.external_marks)).filter(
            models.Mark.student_id == student_id,
            models.Mark.external_marks.isnot(None)
        ).scalar() or 0
        external_gpa = external_avg / 10 if external_avg > 0 else 0
        
        # Count activities
        activity_count = db.query(func.count(models.ActivityParticipation.participation_id)).filter(
            models.ActivityParticipation.student_id == student_id
        ).scalar() or 0
        
        # Count backlogs (marks with grade F)
        backlog_count = db.query(func.count(models.Mark.mark_id)).filter(
            models.Mark.student_id == student_id,
            models.Mark.grade == 'F'
        ).scalar() or 0
        
        return {
            'attendance_percentage': avg_attendance,
            'internal_avg': internal_avg,
            'external_gpa': external_gpa,
            'activity_count': activity_count,
            'backlog_count': backlog_count
        }
    
    def predict_risk(self, db: Session, student_id: int) -> Dict[str, Any]:
        """Predict academic risk for a student"""
        # Extract features
        features = self.extract_features(db, student_id)
        
        # Create feature array
        feature_array = np.array([[
            features['attendance_percentage'],
            features['internal_avg'],
            features['external_gpa'],
            features['activity_count'],
            features['backlog_count']
        ]])
        
        # If model is not loaded, use rule-based prediction
        if self.model is None or self.scaler is None:
            return self._rule_based_prediction(features)
        
        # Scale features
        feature_scaled = self.scaler.transform(feature_array)
        
        # Predict
        prediction = self.model.predict(feature_scaled)[0]
        probability = self.model.predict_proba(feature_scaled)[0]
        
        # Map prediction to risk level
        risk_level_map = {0: "Low", 1: "Medium", 2: "High"}
        risk_level = risk_level_map.get(prediction, "Medium")
        
        # Calculate risk score (0-100)
        risk_score = probability[prediction] * 100
        
        # Generate reasons
        reasons = self._generate_reasons(features)
        
        return {
            'risk_level': risk_level,
            'risk_score': risk_score,
            'reasons': reasons,
            **features
        }
    
    def _rule_based_prediction(self, features: Dict[str, float]) -> Dict[str, Any]:
        """Fallback rule-based prediction when model is not available"""
        risk_score = 0
        reasons = []
        
        # Attendance check
        if features['attendance_percentage'] < 75:
            risk_score += 30
            reasons.append(f"Low attendance: {features['attendance_percentage']:.1f}%")
        elif features['attendance_percentage'] < 85:
            risk_score += 15
        
        # Internal marks check
        if features['internal_avg'] < 50:
            risk_score += 25
            reasons.append(f"Low internal marks: {features['internal_avg']:.1f}")
        elif features['internal_avg'] < 70:
            risk_score += 10
        
        # External GPA check
        if features['external_gpa'] < 5:
            risk_score += 25
            reasons.append(f"Low GPA: {features['external_gpa']:.1f}")
        elif features['external_gpa'] < 7:
            risk_score += 10
        
        # Activity participation
        if features['activity_count'] == 0:
            risk_score += 10
            reasons.append("No extracurricular activities")
        
        # Backlogs
        if features['backlog_count'] > 0:
            risk_score += features['backlog_count'] * 10
            reasons.append(f"{features['backlog_count']} backlog(s)")
        
        # Determine risk level
        if risk_score >= 60:
            risk_level = "High"
        elif risk_score >= 30:
            risk_level = "Medium"
        else:
            risk_level = "Low"
            if not reasons:
                reasons.append("Good academic performance")
        
        return {
            'risk_level': risk_level,
            'risk_score': min(risk_score, 100),
            'reasons': "; ".join(reasons) if reasons else "Good performance",
            **features
        }
    
    def _generate_reasons(self, features: Dict[str, float]) -> str:
        """Generate human-readable reasons for the prediction"""
        reasons = []
        
        if features['attendance_percentage'] < 75:
            reasons.append(f"Low attendance ({features['attendance_percentage']:.1f}%)")
        if features['internal_avg'] < 60:
            reasons.append(f"Low internal marks ({features['internal_avg']:.1f})")
        if features['external_gpa'] < 6:
            reasons.append(f"Low GPA ({features['external_gpa']:.1f})")
        if features['activity_count'] == 0:
            reasons.append("No extracurricular activities")
        if features['backlog_count'] > 0:
            reasons.append(f"{features['backlog_count']} backlog(s)")
        
        if not reasons:
            reasons.append("Good overall performance")
        
        return "; ".join(reasons)

# Singleton instance
ml_service = MLService()
