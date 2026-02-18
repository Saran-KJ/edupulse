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
        # ml_service.py is in backend/, models are in backend/ml_models/
        self.model_path = Path(__file__).parent / "ml_models" / "best_model.pkl"
        self.scaler_path = Path(__file__).parent / "ml_models" / "feature_scaler.pkl"
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
    
    def get_student_model(self, dept: str):
        dept = dept.upper()
        if dept == 'CSE': return models.StudentCSE
        elif dept == 'ECE': return models.StudentECE
        elif dept == 'EEE': return models.StudentEEE
        elif dept == 'MECH': return models.StudentMECH
        elif dept == 'CIVIL': return models.StudentCIVIL
        elif dept == 'BIO': return models.StudentBIO
        elif dept == 'AIDS': return models.StudentAIDS
        return None

    def extract_features(self, db: Session, reg_no: str) -> Dict[str, float]:
        """Extract features for a student"""
        # Find student across all dept tables using reg_no
        student = None
        for model in [models.StudentCSE, models.StudentECE, models.StudentEEE, models.StudentMECH, models.StudentCIVIL, models.StudentBIO, models.StudentAIDS]:
            student = db.query(model).filter(model.reg_no == reg_no).first()
            if student:
                break
        
        if not student:
            return {
                'attendance_percentage': 0,
                'internal_avg': 0,
                'external_gpa': 0,
                'activity_count': 0,
                'backlog_count': 0
            }
        
        # reg_no is already available


        # Get attendance percentage
        total_days = db.query(models.Attendance).filter(
            models.Attendance.reg_no == reg_no
        ).count()
        
        present_days = db.query(models.Attendance).filter(
            models.Attendance.reg_no == reg_no,
            models.Attendance.status.in_(['Present', 'P', 'OD'])
        ).count()
        
        avg_attendance = (present_days / total_days * 100) if total_days > 0 else 0
        
        # Get internal marks average (Using all available components)
        # Calculate subject-wise internal marks and then average them
        marks = db.query(models.Mark).filter(
            models.Mark.reg_no == reg_no
        ).all()
        
        total_internal_percentage = 0
        subject_count = 0
        
        for mark in marks:
            # Calculate Internal 1
            st1, st2 = float(mark.slip_test_1 or 0), float(mark.slip_test_2 or 0)
            a1, a2 = float(mark.assignment_1 or 0), float(mark.assignment_2 or 0)
            cia1 = float(mark.cia_1 or 0)
            
            # Check if Internal 1 has any data
            has_int1 = (st1 + st2 + a1 + a2 + cia1) > 0
            int1_score = 0
            if has_int1:
                # Progressive logic: use non-zero averages if needed, but for backend simplicity 
                # we'll stick to the standard formula but only count it if it exists
                st_avg1 = (st1 + st2) / 2
                assign_avg1 = (a1 + a2) / 2
                raw_int1 = (0.3 * st_avg1) + (0.2 * assign_avg1) + (0.5 * cia1)
                # Max raw for Int 1 is 38 (6 + 2 + 30)
                int1_score = (raw_int1 / 38) * 100
            
            # Calculate Internal 2
            st3, st4 = float(mark.slip_test_3 or 0), float(mark.slip_test_4 or 0)
            a3, a4, a5 = float(mark.assignment_3 or 0), float(mark.assignment_4 or 0), float(mark.assignment_5 or 0)
            cia2 = float(mark.cia_2 or 0)
            model = float(mark.model or 0)
            
            has_int2 = (st3 + st4 + a3 + a4 + a5 + cia2 + model) > 0
            int2_score = 0
            if has_int2:
                st_avg2 = (st3 + st4) / 2
                assign_avg2 = (a3 + a4 + a5) / 3
                raw_int2 = (0.25 * st_avg2) + (0.15 * assign_avg2) + (0.3 * cia2) + (0.3 * model)
                # Max raw for Int 2 is 54.5 (5 + 1.5 + 18 + 30)
                int2_score = (raw_int2 / 54.5) * 100
                
            # Final Subject Internal Calculation
            if has_int1 and has_int2:
                final_subject_internal = (0.4 * int1_score) + (0.6 * int2_score)
            elif has_int1:
                final_subject_internal = int1_score
            elif has_int2:
                final_subject_internal = int2_score
            else:
                final_subject_internal = 0
                
            if has_int1 or has_int2:
                total_internal_percentage += final_subject_internal
                subject_count += 1
                
        internal_avg = (total_internal_percentage / subject_count) if subject_count > 0 else 0
        
        # Calculate external GPA (Simplified based on grades)
        # O=10, A+=9, A=8, B+=7, B=6, C=5, F/AREAR=0
        grades = db.query(models.Mark.university_result_grade).filter(
            models.Mark.reg_no == reg_no
        ).all()
        
        total_points = 0
        count = 0
        backlog_count = 0
        
        grade_map = {'O': 10, 'A+': 9, 'A': 8, 'B+': 7, 'B': 6, 'C': 5}
        
        for g in grades:
            grade = g[0]
            if grade in grade_map:
                total_points += grade_map[grade]
                count += 1
            elif grade == 'AREAR' or grade == 'F':
                backlog_count += 1
                count += 1
                
        external_gpa = total_points / count if count > 0 else 0
        
        # Count activities
        # Note: ActivityParticipation.student_id was renamed to reg_no in models.py
        activity_count = db.query(func.count(models.ActivityParticipation.participation_id)).filter(
            models.ActivityParticipation.reg_no == reg_no
        ).scalar() or 0
        
        return {
            'attendance_percentage': avg_attendance,
            'internal_avg': internal_avg,
            'external_gpa': external_gpa,
            'activity_count': activity_count,
            'backlog_count': backlog_count
        }
    
    def predict_risk(self, db: Session, reg_no: str) -> Dict[str, Any]:
        """Predict academic risk for a student"""
        # Extract features
        features = self.extract_features(db, reg_no)
        
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

    def save_prediction(self, db: Session, reg_no: str, prediction_result: Dict[str, Any]):
        """Save prediction result to database"""
        try:
            db_prediction = models.RiskPrediction(
                reg_no=reg_no,
                risk_level=prediction_result['risk_level'],
                risk_score=prediction_result['risk_score'],
                attendance_percentage=prediction_result['attendance_percentage'],
                internal_avg=prediction_result['internal_avg'],
                external_gpa=prediction_result['external_gpa'],
                activity_count=prediction_result['activity_count'],
                backlog_count=prediction_result['backlog_count'],
                reasons=prediction_result['reasons']
            )
            db.add(db_prediction)
            db.commit()
            db.refresh(db_prediction)
            print(f"Saved risk prediction for {reg_no}: {prediction_result['risk_level']} ({prediction_result['risk_score']:.1f}%)")
            return db_prediction
        except Exception as e:
            print(f"Error saving prediction for {reg_no}: {e}")
            db.rollback()
            return None

    def calculate_subject_risk(self, db: Session, reg_no: str, subject_code: str) -> Dict[str, Any]:
        """Calculate risk specifically for a given subject"""
        # Case insensitive match for subject code
        mark = db.query(models.Mark).filter(
            models.Mark.reg_no == reg_no,
            func.lower(models.Mark.subject_code) == subject_code.lower()
        ).first()
        
        if not mark:
            return {'risk_level': 'Unknown', 'score': 0, 'basis': 'No Data'}
            
        # Internal 1
        st1, st2 = float(mark.slip_test_1 or 0), float(mark.slip_test_2 or 0)
        a1, a2 = float(mark.assignment_1 or 0), float(mark.assignment_2 or 0)
        cia1 = float(mark.cia_1 or 0)
        
        has_int1 = (st1 + st2 + a1 + a2 + cia1) > 0
        int1_score = 0
        if has_int1:
            st_avg1 = (st1 + st2) / 2
            assign_avg1 = (a1 + a2) / 2
            raw_int1 = (0.3 * st_avg1) + (0.2 * assign_avg1) + (0.5 * cia1)
            int1_score = (raw_int1 / 38) * 100
        
        # Internal 2
        st3, st4 = float(mark.slip_test_3 or 0), float(mark.slip_test_4 or 0)
        a3, a4, a5 = float(mark.assignment_3 or 0), float(mark.assignment_4 or 0), float(mark.assignment_5 or 0)
        cia2 = float(mark.cia_2 or 0)
        model = float(mark.model or 0)
        
        has_int2 = (st3 + st4 + a3 + a4 + a5 + cia2 + model) > 0
        int2_score = 0
        if has_int2:
            st_avg2 = (st3 + st4) / 2
            assign_avg2 = (a3 + a4 + a5) / 3
            raw_int2 = (0.25 * st_avg2) + (0.15 * assign_avg2) + (0.3 * cia2) + (0.3 * model)
            int2_score = (raw_int2 / 54.5) * 100
            
        # Final Calculation
        if has_int1 and has_int2:
            final_score = (0.4 * int1_score) + (0.6 * int2_score)
            basis = "Full Data"
        elif has_int1:
            final_score = int1_score
            basis = "Internal 1 Only"
        elif has_int2:
            final_score = int2_score
            basis = "Internal 2 Only"
        else:
            final_score = 0
            basis = "No Data"
            
        # Determine Risk Level
        if final_score < 50:
            risk_level = "High"
        elif final_score < 65:
            risk_level = "Medium"
        else:
            risk_level = "Low"
            
        return {
            'risk_level': risk_level,
            'score': final_score,
            'basis': basis
        }

# Singleton instance
ml_service = MLService()
