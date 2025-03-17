import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import 'loading_overlay.dart';
import 'package:lottie/lottie.dart';

class ChatScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  ChatScreen({required this.toggleTheme});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  Map<String, String> _userNames = {};
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottomButton = false;
  bool _isNearBottom = true;
  String? _lastMessageId;
  Stream<QuerySnapshot>? _messagesStream;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadUserNames();
    
    // Configure scroll controller to detect when user has scrolled away from bottom
    _scrollController.addListener(_onScroll);
    
    // Subscribe to chat room topic
    _notificationService.subscribeToTopic('chatroom');
    
    // Initialize messages stream
    _messagesStream = _firestore
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
        
    // Listen for new messages to show notifications when app is in foreground but user is not looking at chat
    _listenForNewMessages();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // Listen for new messages to show notifications
  void _listenForNewMessages() {
    _messagesStream?.listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final lastDoc = snapshot.docs.last;
        final lastMessageId = lastDoc.id;
        
        // If this is not the first load and we have a new message
        if (_lastMessageId != null && _lastMessageId != lastMessageId) {
          final data = lastDoc.data() as Map<String, dynamic>;
          final sender = data['sender'] ?? 'Unknown';
          final text = data['text'] ?? '';
          
          // Only show notification if the message is not from the current user
          if (sender != _auth.currentUser?.email) {
            String senderName = _getDisplayName(sender);
            
            // Show local notification
            _notificationService.showLocalNotification(
              id: lastMessageId.hashCode,
              title: senderName,
              body: text,
              payload: 'chat',
            );
          }
        }
        
        // Update the last message ID
        _lastMessageId = lastMessageId;
      }
    });
  }

  // Load user names from Firestore
  void _loadUserNames() async {
    QuerySnapshot usersSnapshot = await _firestore.collection('users').get();

    Map<String, String> userNames = {};
    for (var doc in usersSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('email') && data.containsKey('name')) {
        userNames[data['email']] = data['name'];
      }
    }

    setState(() {
      _userNames = userNames;
    });
  }

  // Get display name for a user
  String _getDisplayName(String email) {
    return _userNames[email] ?? email.split('@')[0];
  }

  // Get initials for a user
  String _getInitials(String name) {
    List<String> nameParts = name.split(' ');
    if (nameParts.isEmpty) return '';
    if (nameParts.length == 1) return nameParts[0][0].toUpperCase();
    return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    _firestore.collection('messages').add({
      'text': _messageController.text,
      'sender': _auth.currentUser?.email,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
    // Only scroll to bottom if already near bottom
    if (_isNearBottom) {
      _scrollToBottom();
    }
  }

  // Scroll to the bottom of the ListView
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  // Handle scroll events
  void _onScroll() {
    if (_scrollController.hasClients) {
      // Check if we're near the bottom
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      
      // Only update state if the nearBottom status changed to avoid unnecessary rebuilds
      final isNearBottom = currentScroll >= maxScroll - 100;
      if (isNearBottom != _isNearBottom || _showScrollToBottomButton != !isNearBottom) {
        setState(() {
          _isNearBottom = isNearBottom;
          _showScrollToBottomButton = !isNearBottom;
        });
      }
    }
  }
  
  // Method to send a test notification
  void _sendTestNotification() {
    // Show a local notification for testing
    _notificationService.showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'Test Notification',
      body: 'This is a test notification from GTCS Chat!',
      payload: 'test',
    );
  }

  // Method to handle logout with loading overlay
  Future<void> _handleLogout() async {
    setState(() {
      _isLoggingOut = true;
    });

    // Ensure the loading animation shows for at least 3 seconds
    await Future.delayed(Duration(seconds: 2));
    await AuthService().logout();
    
    // No need to set _isLoggingOut to false since this widget will be disposed
  }

  @override
  Widget build(BuildContext context) {
    final String currentUser = _auth.currentUser?.email ?? "";
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return LoadingOverlay(
      isLoading: _isLoggingOut,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: isDarkMode ? Colors.grey[900] : null,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: isDarkMode
                  ? null
                  : LinearGradient(
                      colors: [Colors.purple, Colors.blue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            ),
          ),
          title: Text(
            'GTCS Chat',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.notifications, color: Colors.white),
              onPressed: _sendTestNotification,
              tooltip: 'Test Notification',
            ),
            IconButton(
              icon: Icon(Icons.brightness_6, color: Colors.white),
              onPressed: widget.toggleTheme,
            ),
            IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: _handleLogout,
            ),
          ],
          elevation: 5,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _messagesStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        var messages = snapshot.data!.docs;
                        String? previousSender;
                        
                        // Only auto-scroll for new messages if user is already near bottom
                        if (snapshot.connectionState == ConnectionState.active && 
                            snapshot.hasData && 
                            _isNearBottom) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_scrollController.hasClients) {
                              _scrollToBottom();
                            }
                          });
                        }

                        return NotificationListener<ScrollNotification>(
                          // This additional notification listener ensures we catch all scroll events
                          onNotification: (notification) {
                            if (notification is ScrollEndNotification) {
                              _onScroll();
                            }
                            return false; // Return false to allow the notification to continue propagating
                          },
                          child: messages.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Lottie.asset(
                                      'assets/animation.json',
                                      width: 150,
                                      height: 150,
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      'No messages yet.\nBe the first to say hello!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white70 : Colors.black54,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(), // Ensure scrolling works even with few items
                                controller: _scrollController,
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  var message = messages[index];
                                  String messageText = message['text'];
                                  String messageSender = message['sender'] ?? "Unknown";
                                  String displayName = _getDisplayName(messageSender);
                                  String initials = _getInitials(displayName);

                                  bool isMe = messageSender == currentUser;
                                  bool showProfilePicture = previousSender != messageSender;
                                  previousSender = messageSender;
                                  
                                  return Container(
                                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                      children: [
                                        if (!isMe && showProfilePicture)
                                          Container(
                                            margin: EdgeInsets.only(right: 8),
                                            child: CircleAvatar(
                                              radius: 12,
                                              backgroundColor: isDarkMode ? Colors.blue[800] : Colors.blue,
                                              child: Text(
                                                initials,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        Column(
                                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                          children: [
                                            if (!isMe && showProfilePicture)
                                              Text(
                                                displayName,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            Container(
                                              constraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                                              ),
                                              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                              decoration: BoxDecoration(
                                                gradient: isMe
                                                    ? (isDarkMode
                                                        ? LinearGradient(
                                                            colors: [Color(0xFFFF5ACD), Color(0xFFB429FF)],
                                                            begin: Alignment.topLeft,
                                                            end: Alignment.bottomRight,
                                                          )
                                                        : LinearGradient(
                                                            colors: [Colors.blue, Colors.green],
                                                            begin: Alignment.topLeft,
                                                            end: Alignment.bottomRight,
                                                          ))
                                                    : (isDarkMode
                                                        ? LinearGradient(
                                                            colors: [Color(0xFF2B5EE0), Color(0xFF45C7FF)],
                                                            begin: Alignment.topLeft,
                                                            end: Alignment.bottomRight,
                                                          )
                                                        : LinearGradient(
                                                            colors: [Colors.grey[300]!, Colors.grey[400]!],
                                                            begin: Alignment.topLeft,
                                                            end: Alignment.bottomRight,
                                                          )),
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(20),
                                                  topRight: Radius.circular(20),
                                                  bottomLeft: isMe ? Radius.circular(20) : Radius.circular(5),
                                                  bottomRight: isMe ? Radius.circular(5) : Radius.circular(20),
                                                ),
                                              ),
                                              child: Text(
                                                messageText,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: isMe ? Colors.white : (isDarkMode ? Colors.white : Colors.black),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: TextField(
                                controller: _messageController,
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Enter message",
                                  hintStyle: TextStyle(
                                    color: isDarkMode ? Colors.white70 : Colors.black54,
                                  ),
                                  border: InputBorder.none,
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: isDarkMode ? Colors.deepPurple : Colors.blue,
                          radius: 25,
                          child: IconButton(
                            icon: Icon(Icons.send, color: Colors.white),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_showScrollToBottomButton)
                Positioned(
                  bottom: 80,
                  right: 20,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: isDarkMode ? Colors.deepPurple : Colors.blue,
                    onPressed: _scrollToBottom,
                    child: Icon(Icons.arrow_downward, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}