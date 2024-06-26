import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void showSpeakRequestsDialog(BuildContext context, String roomId) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Speak Requests'),
        content: Container(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rooms')
                .doc(roomId)
                .collection('speakRequests')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              var speakRequests = snapshot.data!.docs;

              if (speakRequests.isEmpty) {
                return Text('No speak requests');
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: speakRequests.length,
                itemBuilder: (context, index) {
                  var request = speakRequests[index];
                  var userId = request.id;
                  var userName = request['name'];
                  var userImage = request['image'];

                  return SizedBox(
                   // height: 300,
                    child: ListTile(
                      
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(userImage),
                      ),
                     title: Text(userName),
                      trailing: Row(
                       mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            
                            onPressed: () async {
                              await acceptRequest(roomId, userId);
                          //    Navigator.of(context).pop();
                            },
                            child:Icon(Icons.check),
                             style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              await rejectRequest(roomId, userId);
                              Navigator.of(context).pop();
                            },
                            child: Icon(Icons.close),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Close'),
          ),
        ],
      );
    },
  );
}

Future<void> acceptRequest(String roomId, String userId) async {
  var firestore = FirebaseFirestore.instance;

  // Update the role of the user in the joinedUsers collection to 'Moderator'
  await firestore
      .collection('rooms')
      .doc(roomId)
      .collection('joinedUsers')
      .doc(userId)
      .update({'role': 'Moderator'});

  // Optionally, remove the request from the speakRequests collection
  await firestore
      .collection('rooms')
      .doc(roomId)
      .collection('speakRequests')
      .doc(userId)
      .delete();
}

Future<void> rejectRequest(String roomId, String userId) async {
  var firestore = FirebaseFirestore.instance;

  // Remove the request from the speakRequests collection
  await firestore
      .collection('rooms')
      .doc(roomId)
      .collection('speakRequests')
      .doc(userId)
      .delete();
}
