import os
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import make_pipeline
from tqdm import tqdm

class PhishingChecker:
    def __init__(self):
        # AI Model Pipeline: Text-ke numbers-e convert korbe (TF-IDF) ebong predict korbe (Naive Bayes)
        self.model = make_pipeline(TfidfVectorizer(stop_words='english', lowercase=True), MultinomialNB())
        self.is_trained = False

    def train_model(self, csv_path):
        """
        Model target data diye train korar jonno. 
        CSV file-e 'text' (email content) ebong 'label' (1 for phishing, 0 for safe) thakte hobe.
        """
        if not os.path.exists(csv_path):
            print(f"[-] Error: Training file '{csv_path}' paoya jayni!")
            return False
        
        print("[+] Model train hocche, ektu opekkha korun...")
        df = pd.read_csv(csv_path)
        
        # Train text and labels
        self.model.fit(df['text'], df['label'])
        self.is_trained = True
        print("[+] Model successfully trained ebong automated check er jonno ready!")
        return True

    def check_email(self, email_text):
        """Single ekta email test korar jonno"""
        if not self.is_trained:
            return "Model train kora nai. Age train_model() run korun."
        
        # Prediction (0 = Safe, 1 = Phishing)
        prediction = self.model.predict([email_text])[0]
        confidence = max(self.model.predict_proba([email_text])[0]) * 100
        
        if prediction == 1:
            return f"🚨 WARNING: Phishing Email detected! (Confidence: {confidence:.2f}%)"
        else:
            return f"✅ SAFE: Eta ekta normal email. (Confidence: {confidence:.2f}%)"

# =====================================================================
# SYSTEM AUTOMATION & USAGE EXAMPLE
# =====================================================================
if __name__ == "__main__":
    checker = PhishingChecker()
    
    # 1. Dummy Dataset to build the model quickly (Real project-e boro CSV use korbe)
    # create a mock csv file for demonstration
    mock_data = {
        'text': [
            "Urgent: Update your bank account details now! Click here to login.",
            "Dear customer, your netflix password has expired. Reset link inside.",
            "Hey, are we still meeting today at 4 PM for the project discussion?",
            "Get free $1000 amazon gift card now by entering your credit card details.",
            "Attached is the invoice for last month's cloud hosting service. Please review."
        ],
        'label': [1, 1, 0, 1, 0] # 1 = Phishing, 0 = Safe
    }
    pd.DataFrame(mock_data).to_csv('dataset.csv', index=False)
    
    # 2. Model Train kora (Eta automated workflow te shudhu ekbar-i kora lagbe)
    checker.train_model('dataset.csv')
    
    print("\n--- Testing Live Emails ---")
    
    # Test Email 1 (Suspicious)
    incoming_mail_1 = "URGENT: Your PayPal account is locked. Please login via http://fake-paypal.com to verify."
    print(f"Email 1 Result: {checker.check_email(incoming_mail_1)}")
    
    # Test Email 2 (Normal)
    incoming_mail_2 = "Hi team, please submit your weekly updates by Friday afternoon. Thanks!"
    print(f"Email 2 Result: {checker.check_email(incoming_mail_2)}")
