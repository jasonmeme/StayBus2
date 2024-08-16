import json
import time
import requests

def geocode_address(address, api_key):
    base_url = "https://maps.googleapis.com/maps/api/geocode/json"
    # Append ", Merrimack, NH" to all addresses
    full_address = f"{address}, Merrimack, NH"
    params = {
        "address": full_address,
        "key": api_key
    }
    response = requests.get(base_url, params=params)
    data = response.json()
    
    if data['status'] == 'OK':
        location = data['results'][0]['geometry']['location']
        location['lat'], location['lng']
        print(f"Geocoding successful for address: {full_address}")
        return location['lat'], location['lng']
    else:
        print(f"Geocoding failed for address: {full_address}")
        return None, None

def update_json_structure(input_file, output_file, api_key):
    with open(input_file, 'r') as f:
        data = json.load(f)

    new_data = {
        "school": "James Mastricola Upper Elementary School",
        "routes": []
    }

    for route in data["routes"]:
        new_route = {
            "id": route["name"],
            "name": f"Route {route['name']}",
            "stops": []
        }
        
        for stop in route["stops"]:
            lat, lng = geocode_address(stop['location'], api_key)
            
            new_stop = {
                "id": f"{route['name']}-{stop['stop_number']}",
                "stopNumber": stop["stop_number"],
                "time": stop["time"].zfill(5),  # Ensure time is in HH:MM format
                "location": stop["location"],
                "coordinates": {
                    "latitude": lat,
                    "longitude": lng
                } if lat and lng else None
            }
            new_route["stops"].append(new_stop)
            
            # Sleep to respect Google's rate limits (2.5 requests per second)
            time.sleep(0.5)
        
        new_data["routes"].append(new_route)

    with open(output_file, 'w') as f:
        json.dump(new_data, f, indent=2)

# Usage
api_key = "AIzaSyDMG1atSMaWw9oSLX-fG6IJNg0taGkms58" # Replace with your actual API key
update_json_structure('jmues_route.json', 'jmeus_output.json', api_key)