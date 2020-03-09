import json

modified = {}

with open('Workouts.json') as json_file:
    data = json.load(json_file)
    for node in data:
    	modified[node["identifier"]] = node

# print(json.dumps(modified, indent=4, sort_keys=True))

with open('WorkoutsModified.json', 'w') as outfile:
    json.dump(modified, outfile, indent=4, sort_keys=True)
