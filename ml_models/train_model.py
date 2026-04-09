import pandas as pd
import numpy as np
import joblib
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from xgboost import XGBClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, f1_score
try:
    import matplotlib.pyplot as plt
    import seaborn as sns
    PLOTTING_AVAILABLE = True
except ImportError:
    PLOTTING_AVAILABLE = False

def load_data(filepath='training_data.csv'):
    """Load training data"""
    df = pd.read_csv(filepath)
    X = df.drop('risk_level', axis=1)
    y = df['risk_level']
    return X, y

def train_and_evaluate_models(X_train, X_test, y_train, y_test):
    """Train and compare multiple models"""
    
    models = {
        'Logistic Regression': LogisticRegression(max_iter=1000, random_state=42),
        'Random Forest': RandomForestClassifier(n_estimators=100, random_state=42),
        'XGBoost': XGBClassifier(n_estimators=100, random_state=42, eval_metric='mlogloss')
    }
    
    results = {}
    
    print("=" * 80)
    print("MODEL TRAINING AND EVALUATION")
    print("=" * 80)
    
    for name, model in models.items():
        print(f"\n{'='*80}")
        print(f"Training {name}...")
        print(f"{'='*80}")
        
        # Train model
        model.fit(X_train, y_train)
        
        # Predictions
        y_pred = model.predict(X_test)
        
        # Metrics
        accuracy = accuracy_score(y_test, y_pred)
        f1 = f1_score(y_test, y_pred, average='weighted')
        
        # Cross-validation score
        cv_scores = cross_val_score(model, X_train, y_train, cv=5)
        
        results[name] = {
            'model': model,
            'accuracy': accuracy,
            'f1_score': f1,
            'cv_mean': cv_scores.mean(),
            'cv_std': cv_scores.std(),
            'predictions': y_pred
        }
        
        print(f"\nAccuracy: {accuracy:.4f}")
        print(f"F1 Score: {f1:.4f}")
        print(f"Cross-validation Score: {cv_scores.mean():.4f} (+/- {cv_scores.std():.4f})")
        
        print(f"\nClassification Report:")
        print(classification_report(y_test, y_pred, target_names=['Low Risk', 'Medium Risk', 'High Risk']))
        
        print(f"\nConfusion Matrix:")
        cm = confusion_matrix(y_test, y_pred)
        print(cm)
        
        if PLOTTING_AVAILABLE:
            # Plot confusion matrix
            plt.figure(figsize=(8, 6))
            sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', 
                        xticklabels=['Low', 'Medium', 'High'],
                        yticklabels=['Low', 'Medium', 'High'])
            plt.title(f'Confusion Matrix - {name}')
            plt.ylabel('True Label')
            plt.xlabel('Predicted Label')
            plt.tight_layout()
            plt.savefig(f'confusion_matrix_{name.replace(" ", "_").lower()}.png')
            print(f"Confusion matrix saved as confusion_matrix_{name.replace(' ', '_').lower()}.png")
    
    return results

def select_best_model(results):
    """Select the best model based on F1 score"""
    best_name = max(results, key=lambda x: results[x]['f1_score'])
    best_model = results[best_name]['model']
    
    print(f"\n{'='*80}")
    print(f"BEST MODEL: {best_name}")
    print(f"F1 Score: {results[best_name]['f1_score']:.4f}")
    print(f"Accuracy: {results[best_name]['accuracy']:.4f}")
    print(f"{'='*80}")
    
    return best_name, best_model

def save_model(model, scaler, model_path='best_model.pkl', scaler_path='feature_scaler.pkl'):
    """Save the best model and scaler"""
    joblib.dump(model, model_path)
    joblib.dump(scaler, scaler_path)
    print(f"\nModel saved to {model_path}")
    print(f"Scaler saved to {scaler_path}")

def plot_feature_importance(model, feature_names, model_name):
    if PLOTTING_AVAILABLE and hasattr(model, 'feature_importances_'):
        importances = model.feature_importances_
        indices = np.argsort(importances)[::-1]
        
        plt.figure(figsize=(10, 6))
        plt.title(f'Feature Importance - {model_name}')
        plt.bar(range(len(importances)), importances[indices])
        plt.xticks(range(len(importances)), [feature_names[i] for i in indices], rotation=45)
        plt.tight_layout()
        plt.savefig(f'feature_importance_{model_name.replace(" ", "_").lower()}.png')
        print(f"Feature importance plot saved as feature_importance_{model_name.replace(' ', '_').lower()}.png")

def main():
    print("EduPulse - ML Model Training Pipeline")
    print("=" * 80)
    
    # Load data
    print("\nLoading data...")
    X, y = load_data()
    
    print(f"Dataset shape: {X.shape}")
    print(f"Features: {list(X.columns)}")
    print(f"\nTarget distribution:")
    print(y.value_counts().sort_index())
    
    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    print(f"\nTraining set size: {X_train.shape[0]}")
    print(f"Test set size: {X_test.shape[0]}")
    
    # Scale features
    print("\nScaling features...")
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    # Train and evaluate models
    results = train_and_evaluate_models(X_train_scaled, X_test_scaled, y_train, y_test)
    
    # Select best model
    best_name, best_model = select_best_model(results)
    
    # Plot feature importance
    plot_feature_importance(best_model, X.columns, best_name)
    
    # Save best model
    save_model(best_model, scaler)
    
    # Model comparison
    print("\n" + "=" * 80)
    print("MODEL COMPARISON SUMMARY")
    print("=" * 80)
    print(f"{'Model':<25} {'Accuracy':<12} {'F1 Score':<12} {'CV Score':<12}")
    print("-" * 80)
    for name, result in results.items():
        print(f"{name:<25} {result['accuracy']:<12.4f} {result['f1_score']:<12.4f} {result['cv_mean']:<12.4f}")
    
    print("\n" + "=" * 80)
    print("Training completed successfully!")
    print("=" * 80)

if __name__ == "__main__":
    main()
