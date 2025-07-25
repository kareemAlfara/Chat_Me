import 'package:chat_me/src/data/models/messageModel.dart';
import 'package:chat_me/src/presentation/cubits/meesagescubit/messages_cubit.dart';
import 'package:chat_me/src/presentation/widgets/audioWidget.dart';
import 'package:chat_me/src/services/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class chatingWidget extends StatelessWidget {
  const chatingWidget({
    super.key,
    required this.messagemodel,
    required this.receiverId,
  });
  final Messagemodel messagemodel;
  final String receiverId;
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MessagesCubit, MessagesState>(
      listener: (context, state) {
        print("userder : ${messagemodel.Sender_id}");
      },
      builder: (context, state) {
        return GestureDetector(
          onLongPress: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text("Delete Message"),
                content: Text("Are you sure you want to delete this message?"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () async {
                      await MessagesCubit.get(
                        context,
                      ).deleteMessage(messagemodel.id);
                      FocusScope.of(context).unfocus();

                      // assume `id` is in model
                      Navigator.pop(context);
                      await MessagesCubit.get(
                        context,
                      ).fetchMessages(receiverId: receiverId);
                    },
                    child: Text("Delete", style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
          child: Align(
            alignment: messagemodel.Sender_id == uid
                ? Alignment.topLeft
                : Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: messagemodel.Sender_id == uid
                      ? Primarycolor
                      : Colors.grey,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                    bottomRight: messagemodel.Sender_id == uid
                        ? Radius.circular(15)
                        : Radius.circular(0),
                    bottomLeft: messagemodel.Sender_id == uid
                        ? Radius.circular(0)
                        : Radius.circular(15),
                  ),
                ),
                child: buildMessageContent(context),
              ),
            ),
          ),
        );
      },
    );
  }
Widget buildMessageContent(BuildContext context) {
  final fileUrl = messagemodel.image_url ?? '';
  final messageText = messagemodel.message ?? '';

  // If fileUrl is missing AND message has no media => text only
  if (fileUrl.isEmpty && messageText.isNotEmpty) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: defulttext(data: messageText, fSize: 17),
    );
  }

  final uri = Uri.tryParse(fileUrl);
  final fileExtension = uri?.path.split('.').last.toLowerCase() ?? '';

  // --- Audio ---
  if (fileExtension == 'mp3' || fileUrl.contains('.mp3')) {
    return AudioMessageWidget(
      audioUrl: fileUrl,
      isSentByMe: messagemodel.Sender_id == uid,
    );
  }

  // --- PDF ---
  else if (fileExtension == 'pdf') {
    final fileName = fileUrl.split('uploads/').last;
    return GestureDetector(
      onTap: () => MessagesCubit.get(context).openFile(fileUrl, context),
      child: Container(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Text('$fileName'),
          ],
        ),
      ),
    );
  }

  // --- Image ---
  else if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExtension)) {
    return GestureDetector(
      onTap: () => MessagesCubit.get(context).openFile(fileUrl, context),
      child: Image.network(
        fileUrl,
        width: 200,
        height: 130,
        fit: BoxFit.cover,
      ),
    );
  }

  // --- Fallback file ---
  else if (fileUrl.isNotEmpty) {
    return GestureDetector(
      onTap: () => MessagesCubit.get(context).openFile(fileUrl, context),
      child: Container(
        color: Colors.grey[300],
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(Icons.insert_drive_file, color: Colors.blue, size: 30),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                fileUrl.split('/').last,
                style: TextStyle(color: Colors.black),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fallback again if nothing works
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: defulttext(data: messageText, fSize: 17),
  );
}

//   Widget buildMessageContent(BuildContext context) {
//     final fileUrl = messagemodel.image_url;
//     final url = messagemodel.image_url;
//     String fileName = url.split('uploads/').last;
//     if (fileUrl != null && fileUrl.isNotEmpty) {
//       final fileExtension = fileUrl.split('.').last.toLowerCase();

//       if (fileExtension == 'pdf') {
//         // 📄 PDF Section
//         return GestureDetector(
//           onTap: () async {
//             // final url = messagemodel.image_url;

//             await MessagesCubit.get(context).openFile(url, context);
//           },
//           child: Container(
//             // color: Colors.grey[200],
//             padding: EdgeInsets.all(8),
//             child: Row(
//               children: [
//                 Icon(Icons.picture_as_pdf, color: Colors.red, size: 30),
//                 SizedBox(width: 10),
//                 Text('$fileName'),
//               ],
//             ),
//           ),
//         );
//       } else if ([
//         'jpg',
//         'jpeg',
//         'png',
//         'gif',
//         'webp',
//       ].contains(fileExtension)) {
//         // 🖼️ Image Section
//         return GestureDetector(
//           onTap: () async {
//             final url = messagemodel.image_url;

//             await MessagesCubit.get(context).openFile(url, context);
//           },
//           child: Image.network(
//             fileUrl,
//             width: 200,
//             height: 130,
//             fit: BoxFit.cover,
//           ),
//         );
//       }  else if (['mp3'].contains(fileExtension)) {
//   return  AudioMessageWidget(
//     audioUrl: fileUrl,
//     isSentByMe: messagemodel.Sender_id == uid,
//   );
// }else {
//         // 📁 Other File Types Section
//         return GestureDetector(
//           onTap: () async {
//             await MessagesCubit.get(context).openFile(fileUrl, context);
//           },
//           child: Container(
//             color: Colors.grey[300],
//             padding: EdgeInsets.all(8),
//             child: Row(
//               children: [
//                 Icon(Icons.insert_drive_file, color: Colors.blue, size: 30),
//                 SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     fileUrl.split('/').last, // Show only file name
//                     style: TextStyle(color: Colors.black),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }
//     }

//     // 📝 Fallback to text message
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: defulttext(data: messagemodel.message, fSize: 17),
//     );
//   }
}
