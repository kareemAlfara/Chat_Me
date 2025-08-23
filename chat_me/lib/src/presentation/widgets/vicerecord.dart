import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
// Import your existing message model and services
// import 'your_message_model.dart';
// import 'your_supabase_service.dart';

class VoiceRecordingWidget extends StatefulWidget {
  final Function(File audioFile) onAudioRecorded;
  final VoidCallback? onCancel;

  const VoiceRecordingWidget({
    super.key,
    required this.onAudioRecorded,
    this.onCancel,
  });

  @override
  State<VoiceRecordingWidget> createState() => _VoiceRecordingWidgetState();
}

class _VoiceRecordingWidgetState extends State<VoiceRecordingWidget>
    with TickerProviderStateMixin {
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  bool _isPaused = false;
  Duration _recordingDuration = Duration.zero;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  String? _recordingPath;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  Future<void> _initializeRecorder() async {
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _recorder?.closeRecorder();
    _recorder = null;
    super.dispose();
  }

  Future<bool> _checkPermissions() async {
    final microphoneStatus = await Permission.microphone.status;
    if (microphoneStatus != PermissionStatus.granted) {
      final result = await Permission.microphone.request();
      return result == PermissionStatus.granted;
    }
    return true;
  }

  Future<void> _startRecording() async {
    if (!_isInitialized || _recorder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recorder not initialized. Please try again.'),
        ),
      );
      return;
    }

    try {
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required to record audio'),
          ),
        );
        return;
      }

      final directory = await getTemporaryDirectory();
      final fileName =
          'voice_message_${DateTime.now().millisecondsSinceEpoch}.mp4';
      _recordingPath = '${directory.path}/$fileName';

      await _recorder!.startRecorder(
        toFile: _recordingPath,
        codec: Codec.aacMP4, // ✅ هذا الترميز يفضل امتداد .mp4 أو .m4a
        bitRate: 128000,
        sampleRate: 44100,
      );
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _startTimer();
    } catch (e) {
      print('Error starting recording: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to start recording: $e')));
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      if (!_isRecording || _isPaused) return false;

      await Future.delayed(const Duration(seconds: 1));

      if (mounted && _isRecording && !_isPaused) {
        setState(() {
          _recordingDuration = Duration(
            seconds: _recordingDuration.inSeconds + 1,
          );
        });
        return true;
      }
      return false;
    });
  }

  Future<void> _pauseRecording() async {
    if (_recorder == null) return;

    try {
      await _recorder!.pauseRecorder();
      setState(() {
        _isPaused = true;
      });
    } catch (e) {
      print('Error pausing recording: $e');
    }
  }

  Future<void> _resumeRecording() async {
    if (_recorder == null) return;

    try {
      await _recorder!.resumeRecorder();
      setState(() {
        _isPaused = false;
      });
      _startTimer();
    } catch (e) {
      print('Error resuming recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (_recorder == null) return;

    try {
      await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });

      if (_recordingPath != null) {
        final audioFile = File(_recordingPath!);
        if (await audioFile.exists()) {
          widget.onAudioRecorded(audioFile);
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to stop recording: $e')));
    }
  }

  Future<void> _cancelRecording() async {
    if (_recorder == null) return;

    try {
      await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _recordingDuration = Duration.zero;
      });

      // Delete the recorded file
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      widget.onCancel?.call();
    } catch (e) {
      print('Error canceling recording: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Initializing recorder...'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          if (!_isRecording) ...[
            // Record button
            GestureDetector(
              onTap: _startRecording,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 24),
              ),
            ),
          ] else ...[
            // Recording controls
            Expanded(
              child: Row(
                children: [
                  // Cancel button
                  GestureDetector(
                    onTap: _cancelRecording,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red[400],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Pause/Resume button
                  GestureDetector(
                    onTap: _isPaused ? _resumeRecording : _pauseRecording,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.orange[400],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPaused ? Icons.play_arrow : Icons.pause,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Recording indicator with animation
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isPaused ? 1.0 : _scaleAnimation.value,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _isPaused ? Colors.orange : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),

                  // Duration
                  Text(
                    _formatDuration(_recordingDuration),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const Spacer(),

                  // Recording bars animation
                  Row(
                    children: List.generate(5, (index) {
                      return AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Container(
                            width: 3,
                            height: 8 + (index * 4) * _scaleAnimation.value,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Send button
            GestureDetector(
              onTap: _stopRecording,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 24),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// class ChatInputWidget extends StatefulWidget {
//   final Function(String message) onSendMessage;
//   final Function(File audioFile) onSendAudio;
//   final TextEditingController? controller;

//   const ChatInputWidget({
//     super.key,
//     required this.onSendMessage,
//     required this.onSendAudio,
//     this.controller,
//   });

//   @override
//   State<ChatInputWidget> createState() => _ChatInputWidgetState();
// }

// class _ChatInputWidgetState extends State<ChatInputWidget> {
//   late TextEditingController _controller;
//   bool _showVoiceRecorder = false;

//   @override
//   void initState() {
//     super.initState();
//     _controller = widget.controller ?? TextEditingController();
//     _controller.addListener(_onTextChanged);
//   }

//   @override
//   void dispose() {
//     if (widget.controller == null) {
//       _controller.dispose();
//     }
//     super.dispose();
//   }

//   void _onTextChanged() {
//     setState(() {});
//   }

//   void _sendMessage() {
//     final message = _controller.text.trim();
//     if (message.isNotEmpty) {
//       widget.onSendMessage(message);
//       _controller.clear();
//     }
//   }

//   void _onAudioRecorded(File audioFile) {
//     widget.onSendAudio(audioFile);
//     setState(() {
//       _showVoiceRecorder = false;
//     });
//   }

//   void _onCancelRecording() {
//     setState(() {
//       _showVoiceRecorder = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.2),
//             spreadRadius: 1,
//             blurRadius: 3,
//             offset: const Offset(0, -1),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           if (_showVoiceRecorder) ...[
//             VoiceRecordingWidget(
//               onAudioRecorded: _onAudioRecorded,
//               onCancel: _onCancelRecording,
//             ),
//             const SizedBox(height: 8),
//           ],
          
//           Row(
//             children: [
//               Expanded(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.grey[100],
//                     borderRadius: BorderRadius.circular(25),
//                   ),
//                   child: TextField(
//                     controller: _controller,
//                     decoration: const InputDecoration(
//                       hintText: 'Type anything here...',
//                       border: InputBorder.none,
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                     ),
//                     maxLines: null,
//                     textCapitalization: TextCapitalization.sentences,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
              
//               // Voice/Send button
//               GestureDetector(
//                 onTap: () {
//                   if (_controller.text.trim().isNotEmpty) {
//                     _sendMessage();
//                   } else {
//                     setState(() {
//                       _showVoiceRecorder = !_showVoiceRecorder;
//                     });
//                   }
//                 },
//                 child: Container(
//                   width: 48,
//                   height: 48,
//                   decoration: const BoxDecoration(
//                     color: Colors.green,
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     _controller.text.trim().isNotEmpty 
//                         ? Icons.send 
//                         : Icons.mic,
//                     color: Colors.white,
//                     size: 24,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class ChatingScreen extends StatefulWidget {
//   final String receiverId;
//   final String receiverName;
//   final String receiverImage;
  
//   const ChatingScreen({
//     super.key,
//     required this.receiverId,
//     required this.receiverName,
//     required this.receiverImage,
//   });

//   @override
//   State<ChatingScreen> createState() => _ChatingScreenState();
// }

// class _ChatingScreenState extends State<ChatingScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
  
//   // Replace these with your actual variables
//   List<dynamic> messages = []; // Your message list
//   String uid = ""; // Your current user ID
//   bool isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     // Initialize your data
//     _loadInitialData();
//   }

//   void _loadInitialData() async {
//     // Replace with your actual initialization logic
//     setState(() {
//       isLoading = true;
//     });
    
//     try {
//       // await fetchMessages(receiverId: widget.receiverId);
//       // uid = await getCurrentUserId();
//     } catch (e) {
//       print('Error loading initial data: $e');
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   // Safe method to scroll to bottom
//   void _scrollToBottom() {
//     if (mounted && _scrollController.hasClients) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (mounted && _scrollController.hasClients) {
//           try {
//             _scrollController.animateTo(
//               _scrollController.position.maxScrollExtent,
//               duration: const Duration(milliseconds: 300),
//               curve: Curves.easeOut,
//             );
//           } catch (e) {
//             print('Error scrolling: $e');
//           }
//         }
//       });
//     }
//   }

//   // Alternative safe scroll method
//   void _scrollToBottomSafe() {
//     Future.delayed(const Duration(milliseconds: 100), () {
//       if (mounted && _scrollController.hasClients) {
//         try {
//           _scrollController.animateTo(
//             _scrollController.position.maxScrollExtent,
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeOut,
//           );
//         } catch (e) {
//           print('Error scrolling: $e');
//         }
//       }
//     });
//   }

//   void _sendTextMessage(String message) async {
//     try {
//       // Replace with your actual message sending logic
//       // await insterMessage(
//       //   receiver_id: widget.receiverId,
//       //   message: message,
//       //   imageUrl: '',
//       // );
      
//       print('Sending text message: $message');
      
//       // Update UI immediately (optimistic update)
//       setState(() {
//         // Add message to your messages list
//         // messages.add(your_message_object);
//       });
      
//       // Scroll to bottom after sending
//       _scrollToBottomSafe();
      
//       // Refresh messages from server
//       // await fetchMessages(receiverId: widget.receiverId);
      
//     } catch (e) {
//       print('Error sending text message: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to send message: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   void _sendAudioMessage(File audioFile) async {
//     try {
//       // Show loading indicator
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Row(
//             children: [
//               SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               ),
//               SizedBox(width: 12),
//               Text('Sending voice message...'),
//             ],
//           ),
//           duration: Duration(seconds: 2),
//         ),
//       );

//       // Use your existing sendAudioMessage method
//       await sendAudioMessage(
//         audioFile: audioFile,
//         receiverId: widget.receiverId,
//       );
      
//       // Update UI
//       setState(() {
//         // Update your messages list if needed
//       });
      
//       // Scroll to bottom after sending
//       _scrollToBottomSafe();
      
//       // Show success message
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Voice message sent successfully!'),
//           backgroundColor: Colors.green,
//           duration: Duration(seconds: 2),
//         ),
//       );
      
//     } catch (e) {
//       print('Error sending audio message: $e');
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to send voice message: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // Your existing sendAudioMessage method
//   Future<void> sendAudioMessage({
//     required File audioFile,
//     required String receiverId,
//   }) async {
//     try {
//       // Replace with your actual Supabase instance
//       // final supabase = Supabase.instance.client;
      
//       final fileExtension = audioFile.path.split('.').last;
//       final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
//       final fileName = '$uniqueId.$fileExtension';
//       final fileBytes = await audioFile.readAsBytes();
      
//       // Upload audio to Supabase
//       // await supabase.storage
//       //     .from('chat-files')
//       //     .uploadBinary('uploads/$fileName', fileBytes);
      
//       // Get public URL
//       // final publicUrl = supabase.storage
//       //     .from('chat-files')
//       //     .getPublicUrl('uploads/$fileName');
      
//       // Send message with audio URL
//       // await insterMessage(
//       //   receiver_id: receiverId,
//       //   imageUrl: publicUrl,
//       //   message: '',
//       // );
      
//       // Refresh messages
//       // await fetchMessages(receiverId: receiverId);
      
//       print('✅ Audio message sent successfully');
//     } catch (e) {
//       print('❌ Failed to send audio: $e');
//       rethrow;
//     }
//   }

//   Widget _buildMessageItem(dynamic message, int index) {
//     // Replace this with your actual message building logic
//     // This is just a placeholder
    
//     // Check if it's an audio message
//     // final isAudioMessage = message.imageUrl?.contains('.aac') == true ||
//     //                        message.imageUrl?.contains('.mp3') == true;
    
//     // if (isAudioMessage) {
//     //   return AudioMessageWidget(
//     //     audioUrl: message.imageUrl!,
//     //     isSentByMe: message.senderId == uid,
//     //   );
//     // }
    
//     // Regular text message
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center, // Replace with your logic
//         children: [
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             decoration: BoxDecoration(
//               color: Colors.blue, // Replace with your color logic
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Text(
//               'Message $index', // Replace with actual message text
//               style: const TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.green,
//         foregroundColor: Colors.white,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Row(
//           children: [
//             CircleAvatar(
//               radius: 18,
//               backgroundImage: widget.receiverImage.isNotEmpty
//                   ? NetworkImage(widget.receiverImage)
//                   : null,
//               child: widget.receiverImage.isEmpty
//                   ? Text(
//                       widget.receiverName.isNotEmpty 
//                           ? widget.receiverName[0].toUpperCase()
//                           : 'U',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     )
//                   : null,
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.receiverName,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   Text(
//                     'Online', // Replace with actual online status
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.white.withOpacity(0.8),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.videocam),
//             onPressed: () {
//               // Implement video call
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.call),
//             onPressed: () {
//               // Implement voice call
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.more_vert),
//             onPressed: () {
//               // Show more options
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Messages List
//           Expanded(
//             child: isLoading
//                 ? const Center(
//                     child: CircularProgressIndicator(
//                       color: Colors.green,
//                     ),
//                   )
//                 : ListView.builder(
//                     controller: _scrollController,
//                     padding: const EdgeInsets.symmetric(vertical: 8),
//                     itemCount: messages.length,
//                     itemBuilder: (context, index) {
//                       return _buildMessageItem(messages[index], index);
//                     },
//                   ),
//           ),
          
//           // Chat Input
//           ChatInputWidget(
//             controller: _messageController,
//             onSendMessage: _sendTextMessage,
//             onSendAudio: _sendAudioMessage,
//           ),
//         ],
//       ),
//     );
//   }
// }