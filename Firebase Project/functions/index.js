// similar to import function in Swift
const functions = require('firebase-functions');

// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase-admin');
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions

// listening for activity and messenging events; trigger push notifications
exports.observeMessaging = functions.database.ref('/messages/{messageID}/')
    .onCreate(snapshot => {

    	var payload = {};

    	var messageSnapshot = snapshot.val();

    	var fromId = messageSnapshot.fromId;
    	var toId = messageSnapshot.toId;

    	console.log('fromId: '+ fromId + ' toId: ' + toId);

    	return admin.database().ref('/users/' + fromId).once('value', snapshot => {

			var userSendingMessage = snapshot.val();

			return admin.database().ref('/groupChats/'+toId+'/metaData/').once('value', snapshot => {

				var chatSnapshot = snapshot.val();

				console.log('chatSnapshot: '+ chatSnapshot);

				var chatParticipants = chatSnapshot.chatParticipantsIDs;

				for (ID in chatParticipants) {

					console.log('Chat Participants: '+ chatParticipants + 'ID: ' + ID + 'user ID: ' + chatParticipants[ID]);
					
					var chatParticipantID = chatParticipants[ID];

					if (chatParticipantID !== fromId) {

						admin.database().ref('/users/'+ chatParticipantID).once('value', snapshot => {

							var userReceivingMessage = snapshot.val();

							var badge = userReceivingMessage.badge
							
							console.log('User fcmToken:' + userReceivingMessage.fcmToken);

							if (chatSnapshot.chatName !== null) {

								var chatName = chatSnapshot.chatName;

								payload = {
									apns: {
										payload: {
											aps: {
												alert: {
													title: userSendingMessage.name,
													subtitle: chatName,
													body: 'New Message',
												},
												badge: badge,
												category: 'CHAT_CATEGORY'
											},
										},
									},
									data: {
										chatID: toId,
									},
									token: userReceivingMessage.fcmToken
								};
							}

							else {

								payload = {
									apns: {
										payload: {
											aps: {
												alert: {
													title: userSendingMessage.name,
													body: 'New Message',
												},
												badge: badge,
												category: 'CHAT_CATEGORY',
											},
										},
									},
									data: {
										chatID: toId,
									},
									token: userReceivingMessage.fcmToken
								};
							}

							// // Send a message to the device corresponding to the provided
							// // registration token.
							admin.messaging().send(payload)
							  .then((response) => {
							    // Response is a message ID string.
							    console.log('Successfully sent message:', response);
							    return null;
							  }).catch((error) => {
							    console.log('Error sending message:', error);
							});
						})
					}
				}
			})
		})
	});

exports.observeActivityCreated = functions.database.ref('/activities/{activityID}/')
    .onCreate((snapshot, context) => {

    	var userIDThatCreatedActivity = context.auth.uid;

    	var activityID = context.params.activityID;

    	return admin.database().ref('/users/' + userIDThatCreatedActivity).once('value', snapshot => {

			var userThatCreatedActivity = snapshot.val();

			return admin.database().ref('/activities/'+activityID+'/metaData/').once('value', snapshot => {

				var activitySnapshot = snapshot.val();

				var activityParticipants = activitySnapshot.participantsIDs;

				console.log('activityParticipants: '+ activityParticipants);

				for (ID in activityParticipants) {

					console.log('Activity Participants: '+ activityParticipants + 'ID: ' + ID + 'user ID: ' + activityParticipants[ID]);
					
					var activityParticipantID = activityParticipants[ID];

					if (activityParticipantID !== userIDThatCreatedActivity) {

						admin.database().ref('/users/'+ activityParticipantID).once('value', snapshot => {

							var activityUser = snapshot.val();

							var badge = activityUser.badge
							
							console.log('User fcmToken:' + activityUser.fcmToken);

								var activityName = activitySnapshot.name;

								var payload = {
									apns: {
										payload: {
											aps: {
												alert: {
													title: userThatCreatedActivity.name,
													subtitle: activityName,
													body: 'New Activity',
												},
												badge: badge,
												category: 'ACTIVITY_CATEGORY'
											},
										},
									},
									data: {
										activityID: activityID,
									},
									token: activityUser.fcmToken
								};


							// // Send a message to the device corresponding to the provided
							// // registration token.
							admin.messaging().send(payload)
							  .then((response) => {
							    // Response is a message ID string.
							    console.log('Successfully sent message:', response);
							    return null;
							  }).catch((error) => {
							    console.log('Error sending message:', error);
							});
						})
					}
				}
			})
		})
    });

exports.observeActivityUpdated = functions.database.ref('/activities/{activityID}/metaData/{node}')
    .onUpdate((snapshot, context) => {

    	var userIDThatCreatedActivity = context.auth.uid;

    	var activityID = context.params.activityID;

    	var updatedNode = context.params.node;

    	var message = " ";
        
        switch (updatedNode) {
        case "name":
            message = "The activity name was updated";
            break;
        case "activityType":
            message = "The activity type was updated";
            break;
        case "activityDescription":
            message = "The activity description was updated";
            break;
        case "locationName":
            message = "The activity location was updated";
            break;
        case "locationAddress":
            return;
        case "participantsIDs":
            message = "The activity invitees were updated";
            break;
        case "transportation":
            message = "The activity transportation was updated";
            break;
        case "activityOriginalPhotoURL":
            message = "The activity photo was updated";
            break;
        case "activityThumbnailPhotoURL":
            return;
        case "activityPhotos":
            message = "The activity photos were updated";
            break;
        case "allDay":
            message = "The activity time was updated";
            break;
        case "startDateTime":
            message = "The activity start time was updated";
            break;
        case "endDateTime":
            message = "The activity end time was updated";
            break;
        case "reminder":
            return;
        case "notes":
            message = "The activity notes were updated";
            break;
        case "schedule":
            message = "The activity schedule was updated";
            break;
        case "purchases":
            message = "The activity purchases were updated";
            break;
        case "checklist":
            return;
        case "conversation":
            message = "The activity conversation was updated";
            break;
        default:
            message = "The activity was updated";
        }

    	return admin.database().ref('/users/' + userIDThatCreatedActivity).once('value', snapshot => {

			var userThatCreatedActivity = snapshot.val();

			return admin.database().ref('/activities/'+activityID+'/metaData/').once('value', snapshot => {

				var activitySnapshot = snapshot.val();

				var activityParticipants = activitySnapshot.participantsIDs;

				console.log('activityParticipants: '+ activityParticipants);

				for (ID in activityParticipants) {

					console.log('Activity Participants: '+ activityParticipants + 'ID: ' + ID + 'user ID: ' + activityParticipants[ID]);
					
					var activityParticipantID = activityParticipants[ID];

					if (activityParticipantID !== userIDThatCreatedActivity) {

						admin.database().ref('/users/'+ activityParticipantID).once('value', snapshot => {

							var activityUser = snapshot.val();

							var badge = activityUser.badge
							
							console.log('User fcmToken:' + activityUser.fcmToken);

								var activityName = activitySnapshot.name;

								var payload = {
									apns: {
										payload: {
											aps: {
												alert: {
													title: userThatCreatedActivity.name,
													subtitle: activityName,
													body: message
												},
												badge: badge,
												category: 'ACTIVITY_CATEGORY'
											},
										},
									},
									data: {
										activityID: activityID,
									},
									token: activityUser.fcmToken
								};


							// // Send a message to the device corresponding to the provided
							// // registration token.
							admin.messaging().send(payload)
							  .then((response) => {
							    // Response is a message ID string.
							    console.log('Successfully sent message:', response);
							    return null;
							  }).catch((error) => {
							    console.log('Error sending message:', error);
							});
						})
					}
				}
			})
		})
    });










