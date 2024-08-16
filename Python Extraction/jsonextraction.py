import json
import re
import os

def parse_routes(filename):
    routes = []
    current_route = None
    current_stop = None

    def add_stop_to_route():
        nonlocal current_route, current_stop
        if current_stop and all(key in current_stop for key in ["stop_number", "time", "location"]):
            current_route["stops"].append(current_stop)
            current_stop = None

    time_pattern = re.compile(r'^\d{1,2}:\d{2}$')

    with open(filename, 'r') as file:
        for line in file:
            line = line.strip()
            if line == "ROUTE:":
                add_stop_to_route()  # Add last stop of previous route
                if current_route:
                    routes.append(current_route)
                current_route = {"stops": []}
            elif current_route is not None:
                if "name" not in current_route:
                    current_route["name"] = line
                elif line.isdigit():
                    add_stop_to_route()  # Add previous stop before starting a new one
                    current_stop = {"stop_number": int(line)}
                elif time_pattern.match(line):  # Flexible time format check
                    if current_stop:
                        current_stop["time"] = line
                else:
                    if current_stop:
                        current_stop["location"] = line

    # Add the last stop and route
    add_stop_to_route()
    if current_route:
        routes.append(current_route)

    return routes

def main():
    while True:
        input_filename = input("Enter the name of the input text file (including .txt extension): ")
        if os.path.exists(input_filename):
            break
        else:
            print(f"File '{input_filename}' not found. Please try again.")

    # Generate output filename
    output_filename = os.path.splitext(input_filename)[0] + ".json"

    routes = parse_routes(input_filename)

    # Save to JSON file
    with open(output_filename, 'w') as json_file:
        json.dump({"routes": routes}, json_file, indent=2)

    print(f"Parsing complete. Data saved to {output_filename}")

    # Print the first route as a sample
    if routes:
        print("\nSample (First Route):")
        print(json.dumps(routes[0], indent=2))
    else:
        print("No routes were parsed.")

if __name__ == "__main__":
    main()