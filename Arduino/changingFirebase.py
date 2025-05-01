import random
import time
import datetime
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase Admin SDK
cred = credentials.Certificate("/home/lucifer/Downloads/dementia-app-dc774-firebase-adminsdk-fbsvc-0d7c329e39.json")
firebase_admin.initialize_app(cred)

# Initialize Firestore
db = firestore.client()

# Cache for user publicIds
public_ids = []

def get_random_public_id():
    global public_ids
    
    # Fetch publicIds only once and cache them
    if not public_ids:
        try:
            users_ref = db.collection('users').stream()
            for user in users_ref:
                user_data = user.to_dict()
                if 'publicId' in user_data and user_data['publicId']:
                    public_ids.append(user_data['publicId'])
            
            print(f"Found {len(public_ids)} users with public IDs")
            
            if not public_ids:
                print("Warning: No publicIds found in the usersdb collection")
                return None
        except Exception as e:
            print(f"Error fetching publicIds: {e}")
            return None
    
    # Return a random publicId from the cache
    return random.choice(public_ids)

def upload_to_firestore(timestamp, message):
    try:
        # Get a random publicId
        public_id = get_random_public_id()
        if not public_id:
            print("Error: No publicId available")
            return
        
        # Create a new document with auto-generated ID in the logs/public_id/realLogs collection
        doc_ref = db.collection('logs').document(public_id).collection('realLogs').document()
        
        # Set the data
        doc_ref.set({
            'timestamp': timestamp,
            'message': message,
            'created_at': firestore.SERVER_TIMESTAMP
        })
        print(f"Log uploaded to Firestore: logs/public_id/realLogs/{doc_ref.id}")
    except Exception as e:
        print(f"Error uploading to Firestore: {e}")

def upload_caution_logs():
    logs_count = 0
    max_logs = 100
    message = "Caution:You cryin?"
    
    print(f"Will upload {max_logs} logs with message '{message}' to random publicIds...")
    
    while logs_count < max_logs:
        # Generate timestamp (current time in ISO format)
        timestamp = datetime.datetime.now().isoformat()
        
        # Upload the log
        upload_to_firestore(timestamp, message)
        
        logs_count += 1
        print(f"Uploaded {logs_count}/{max_logs} logs")
        
        # Add a small delay to avoid rate limiting
        time.sleep(0.2)
    
    print(f"Successfully uploaded {max_logs} logs!")

if __name__ == "__main__":
    print("Starting to upload caution logs...")
    upload_caution_logs()