import json

def restructure_json(input_file, output_file):
    # Read the input JSON file
    with open(input_file, 'r') as f:
        data = json.load(f)
    
    # Extract school information
    school = {
        "name": data["school"],
        "routes": []
    }
    
    # Restructure routes
    for route in data["routes"]:
        restructured_route = {
            "id": route["id"],
            "name": route["name"],
            "stops": []
        }
        
        for stop in route["stops"]:
            restructured_stop = {
                "id": stop["id"],
                "stopNumber": stop["stopNumber"],
                "time": stop["time"],
                "location": stop["location"],
                "latitude": stop["coordinates"]["latitude"],
                "longitude": stop["coordinates"]["longitude"]
            }
            restructured_route["stops"].append(restructured_stop)
        
        school["routes"].append(restructured_route)
    
    # Create the final structure
    restructured_data = [school]
    
    # Write the restructured data to the output file
    with open(output_file, 'w') as f:
        json.dump(restructured_data, f, indent=2)

# Usage
input_file = 'output.json'
output_file = 'restructured_output.json'
restructure_json(input_file, output_file)
print(f"Restructured JSON has been written to {output_file}")