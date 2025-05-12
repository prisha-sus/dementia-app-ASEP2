
import firebase_admin
from firebase_admin import credentials, firestore
import json

# Initialize Firebase Admin SDK
cred = credentials.Certificate("/home/lucifer/Downloads/dementia-app-dc774-firebase-adminsdk-fbsvc-0d7c329e39.json")  # Replace with your path
firebase_admin.initialize_app(cred)

# Create a Firestore client
db = firestore.client()

# Function to fetch all patient publicIds from Firestore
def fetch_patient_public_ids():
    # Reference to the users collection
    users_ref = db.collection('users')
    
    # Fetch all users (filtering by role if you want to fetch only patients)
    patients_ref = users_ref.where('role', '==', 'patient')
    
    # Get all documents
    docs = patients_ref.stream()
    
    # List to store publicIds
    public_ids = []
    
    for doc in docs:
        user_data = doc.to_dict()
        public_id = user_data.get('publicId')
        
        if public_id:
            public_ids.append(public_id)
        else:
            print(f"User {doc.id} does not have a publicId")
    
    return public_ids

# Save public IDs to a JSON file
def save_public_ids_to_json(public_ids):
    with open('publicIds.json', 'w') as json_file:
        json.dump(public_ids, json_file, indent=4)
    print("Public IDs saved to publicIds.json")

# Main function to execute the script
def main():
    public_ids = fetch_patient_public_ids()
    save_public_ids_to_json(public_ids)

if __name__ == '__main__':
    main()