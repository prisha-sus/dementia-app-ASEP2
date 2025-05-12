import serial
import json
import time
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase Admin SDK
cred = credentials.Certificate("/home/lucifer/Downloads/dementia-app-dc774-firebase-adminsdk-fbsvc-0d7c329e39.json")
firebase_admin.initialize_app(cred)

# Initialize Firestore
db = firestore.client()

# Serial port setup
ser = serial.Serial('/dev/ttyUSB0', 9600)  # Replace with your port if different

def upload_to_firestore(timestamp, message):
    try:
        # Create a new document with auto-generated ID
        doc_ref = db.collection('logs').document()
        # Set the data
        doc_ref.set({
            'timestamp': timestamp,
            'message': message,
            'created_at': firestore.SERVER_TIMESTAMP
        })
        print("Log uploaded to Firestore:", doc_ref.id)
    except Exception as e:
        print(f"Error uploading to Firestore: {e}")
def process_serial_data():
    while True:
        if ser.in_waiting > 0:
            line = ser.readline().decode('utf-8').strip()
            try:
                data = json.loads(line)
                timestamp = data['timestamp']
                message = data['message']
                
                print(f"Received Log: Timestamp={timestamp}, Message={message}")
                
                if "Caution" in message:
                    upload_to_firestore(timestamp, message)
                else:
                    print("No caution, no log uploaded.")
            except json.JSONDecodeError:
                print("Error decoding JSON.")
        time.sleep(1)

if __name__ == "__main__":
    print("Starting to listen for serial data...")
    process_serial_data()
