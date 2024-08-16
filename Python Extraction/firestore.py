import json
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

# Initialize Firebase Admin SDK
cred = credentials.Certificate('staybus1-c335c-firebase-adminsdk-tbjha-fc45e5c20f.json')
firebase_admin.initialize_app(cred)

# Get a Firestore client
db = firestore.client()

def import_json_to_firestore(json_file_path, collection_name):
    # Load JSON data
    with open(json_file_path, 'r') as file:
        data = json.load(file)
    
    # Get a reference to the collection
    collection_ref = db.collection(collection_name)
    
    # Import school data
    school_doc = collection_ref.document(data['school'])
    school_doc.set({
        'name': data['school']
    })
    
    # Import routes as a subcollection
    routes_ref = school_doc.collection('routes')
    
    for route in data['routes']:
        route_doc = routes_ref.document(route['id'])
        route_doc.set({
            'name': route['name'],
            'stops': route['stops']
        })
    
    print(f"Data imported successfully for {data['school']}")

# Usage
import_json_to_firestore('jmeus_output.json', 'schools')