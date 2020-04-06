import json
from collections import defaultdict
from numpy import median

with open('WorkoutsModified.json') as json_file:
    data = json.load(json_file)
    i = 0
    finalCardio = []
    finalYoga = []
    finalMuscle_groups = defaultdict(list)
    finalSecondary_muscle_groups = defaultdict(list)
    finalTypes = defaultdict(list)
    workout_durations = defaultdict(list)
    finalExercises = defaultdict(list)
    exercises = []
    exercise_ids = []
    HIIT_list = []



    workouts = data["workouts"]
    for workoutID in workouts:
    	i += 1
    	workout = workouts[workoutID]
    	workout_duration = int(workout["workout_duration"])
    	if workout_duration < 22:
    		workout_durations["short"].append(workoutID)
    	elif workout_duration < 42:
    		workout_durations["medium"].append(workoutID)
    	else:
    		workout_durations["long"].append(workoutID)
        if "HIIT" in workout["title"] or "HIIT" in workout["notes"]:
            HIIT_list.append(workoutID)
    	name = []
    	cardio = []
    	yoga = []
    	muscle_groups = []
    	secondary_muscle_groups = []
    	MG = []
    	SMG = []
    	types = []
    	workout_types = []
    	for exercise in workout["exercises"]:
    		exerciseName = exercise["name"]
    		# exerciseName = exerciseName.replace(" ", "_")
    		# exerciseName = exerciseName.replace("/", "or")
    		# exerciseName = exerciseName.lower()
    		finalExercises[exerciseName].append(workoutID)
    		exercise_id = exercise["exercise_wp_id"]
    		if exercise_id not in exercise_ids:
    			exercise_ids.append(exercise_id)
    			exercises.append(exercise)
    		if exerciseName not in name:
    			name.append(exerciseName)
    		if exercise["is_cardio"] not in cardio:
    			cardio.append(exercise["is_cardio"])
    		if exercise["is_yoga"] not in yoga:
    			yoga.append(exercise["is_yoga"])
    		exerMG = exercise["muscle_groups"]
    		if exerMG not in muscle_groups:
    			muscle_groups.append(exerMG)
    		exerSMG = exercise["muscle_groups_secondary"]
    		if exerSMG not in secondary_muscle_groups:
    			secondary_muscle_groups.append(exerSMG)
    		if exercise["types"] not in types:
    			types.append(exercise["types"])
    	if True in cardio:
    		cardio = True
    		finalCardio.append(workoutID)
    	else:
    		cardio = False
    	if True in yoga:
    		yoga = True
    		finalYoga.append(workoutID)
    	else:
    		yoga = False
    	print("moving on")
    	print(muscle_groups)
    	for muscle in muscle_groups:
    		print(muscle)
    		if "," in muscle:
    			print("found comma")
    			muscleSplit = muscle.split(", ")
    			for subMuscle in muscleSplit:
    				# subMuscle = subMuscle.replace(" ", "_")
    				# subMuscle = subMuscle.replace("/", "&")
    				# subMuscle = subMuscle.lower()
    				print(subMuscle)
    				if subMuscle not in MG and subMuscle != '':
    					MG.append(subMuscle)
    					finalMuscle_groups[subMuscle].append(workoutID)
    					print(finalMuscle_groups)
    		else:
				print("did not find comma")
				# muscle = muscle.replace(" ", "_")
				# muscle = muscle.replace("/", "&")
				# muscle = muscle.lower()
				print(muscle)
				if muscle not in MG and muscle != '':
					print(muscle)
					MG.append(muscle)
					finalMuscle_groups[muscle].append(workoutID)
					print(finalMuscle_groups)
    	for muscle in secondary_muscle_groups:
			if "," in muscle:
				print("found comma")
				muscleSplit = muscle.split(", ")
				for subMuscle in muscleSplit:
					# subMuscle = subMuscle.replace(" ", "_")
					# subMuscle = subMuscle.replace("/", "&")
					# subMuscle = subMuscle.lower()
					if subMuscle not in SMG and subMuscle not in MG and subMuscle != '':
						SMG.append(subMuscle)
						finalSecondary_muscle_groups[subMuscle].append(workoutID)
			else:
				print("did not find comma")
				# muscle = muscle.replace(" ", "_")
				# muscle = muscle.replace("/", "&")
				# muscle = muscle.lower()
				if muscle not in SMG and muscle not in MG and muscle != '':
					SMG.append(muscle)
					finalSecondary_muscle_groups[muscle].append(workoutID)
    	for tpe in types:
			print(tpe)
			if "," in tpe:
				typeSplit = tpe.split(", ")
				for subType in typeSplit:
					# subType = subType.replace(" ", "_")
					# subType = subType.replace("/", "&")
					# subType = subType.lower()
					if subType not in workout_types and subType != '':
						workout_types.append(subType)
						finalTypes[subType].append(workoutID)

			else:
				# tpe = tpe.replace(" ", "_")
				# tpe = tpe.replace("/", "&")
				# tpe = tpe.lower()
				if tpe not in workout_types and tpe != '':
					workout_types.append(tpe)
					finalTypes[tpe].append(workoutID)


		# print("name ",name)
		# print("cardio ",cardio)
		# print("yoga ",yoga)
		# print("muscle_groups ",MG)
		# print("secondary_muscle_groups ",SMG)
		# print("types ",workout_types)

    	workout["cardio"] = cardio
    	workout["yoga"] = yoga
    	workout["muscle_groups"] = MG
    	workout["secondary_muscle_groups"] = SMG
    	workout["types"] = workout_types

data["exercises"] = exercises

finalTypes["hiit"] = HIIT_list

types_of_workouts = data["types_of_workouts"]

# types_of_workouts["has_cardio"] = finalCardio
# types_of_workouts["has_yoga"] = finalYoga
types_of_workouts["exercises"] = finalExercises
# print(finalCardio)
# print(finalYoga)
# for key, value in finalMuscle_groups.items():
	# print("key", key)
	# print("value", value)
	# types_of_workouts["muscle_groups"] = finalMuscle_groups
# for key, value in finalSecondary_muscle_groups.items():
	# print("key", key)
	# print("value", value)
	# types_of_workouts["secondary_muscle_groups"] = finalSecondary_muscle_groups
# for key, value in finalTypes.items():
	# print("key", key)
	# print("value", value)
	# types_of_workouts["type_of_workouts"] = finalTypes
# for key, value in workout_durations.items():
	# print("key", key)
	# print("value", value)
	# types_of_workouts["workout_durations"] = workout_durations
# for key, value in finalExercises.items():
    # print("key", key)
    # print("value", value)
    # types_of_workouts["exercises"] = finalExercises

print(finalMuscle_groups.keys())
print(finalTypes.keys())
print(workout_durations.keys())
print(finalExercises.keys())

# print(i)



# with open('Workouts.json', 'w') as outfile:
#     json.dump(data, outfile, indent=4, sort_keys=True)




