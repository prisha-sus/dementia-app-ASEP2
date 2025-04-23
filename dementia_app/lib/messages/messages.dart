import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  TextEditingController _messageController = TextEditingController();
  late FirebaseFirestore _firestore;
  late FirebaseAuth _auth;
  String _userType = ""; // Initially empty, no default role
  bool _hasSentFirstMessage = false;
  String _roleGreeting = "loading...";

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
    _fetchUserRole(); // Fetch user role from Firestore
  }

  // Fetch user role from Firestore
  Future<void> _fetchUserRole() async {
    String userId = _auth.currentUser?.uid ?? ''; // Get the current user's UID
    if (userId.isNotEmpty) {
      try {
        // Fetch user document from Firestore using the UID
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          var userRole = userDoc['role']; // Fetch the role directly from the DB
          if (userRole != null) {
            setState(() {
              _userType = userRole; // Update user role state
              _roleGreeting = 'Hey $userRole, how can we help today?'; // Update greeting with user role
            });
            print("User role: $_userType"); // Debugging: Print user role
          } else {
            print("User role not found in Firestore.");
          }
        } else {
          print("User document not found.");
        }
      } catch (e) {
        print('Error fetching user role: $e'); // Handle errors
      }
    } else {
      print("User not authenticated.");
    }
  }

  // Function to send a message to Firestore
  Future<void> sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      try {
        // Check if it's the first message and update state to hide greeting
        if (!_hasSentFirstMessage) {
          setState(() {
            _hasSentFirstMessage = true;
          });
        }

        // Print message details before sending it
        print("Sending message: ${_messageController.text} from $_userType");

        // Send message to Firestore
        await _firestore.collection('messages').add({
          'sender': _userType, // Store the user role (caregiver, patient, etc.)
          'message': _messageController.text, // Store message text
          'timestamp': FieldValue.serverTimestamp(), // Store timestamp
        });
        _messageController.clear(); // Clear the text input after sending
      } catch (e) {
        print("Error sending message: $e"); // Handle errors
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Display greeting if no messages have been sent yet
          if (!_hasSentFirstMessage)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _roleGreeting, // Show greeting message with the role
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('messages')
                  .orderBy('timestamp', descending: true) // Order messages by timestamp
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator()); // Show loading spinner while waiting
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}')); // Show error if there's an issue
                }

                final messages = snapshot.data?.docs ?? [];

                return ListView.builder(
                  reverse: true, // Reverse list to show most recent messages at the bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var messageData = messages[index];
                    var message = messageData['message'];
                    var sender = messageData['sender'];
                    var timestamp = messageData['timestamp'];

                    // Determine message alignment based on sender's role
                    bool isSentByUser = sender == _userType;

                    return ListTile(
                      title: Align(
                        alignment: isSentByUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSentByUser ? Colors.blue[100] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          child: Text(
                            message,
                            style: TextStyle(fontSize: 16, color: Colors.black), // Set message text color to black
                          ),
                        ),
                      ),
                      subtitle: Text(
                        timestamp != null
                            ? DateTime.parse(timestamp.toDate().toString()).toString() // Format timestamp
                            : '',
                        style: TextStyle(fontSize: 12),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage, // Call sendMessage when button is pressed
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}