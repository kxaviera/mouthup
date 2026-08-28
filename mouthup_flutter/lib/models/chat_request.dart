import 'user_gender.dart';

enum ChatRequestStatus { pending, accepted, rejected }

class ChatJoinRequest {
  ChatJoinRequest({
    required this.id,
    required this.postId,
    required this.requesterName,
    required this.requesterCity,
    required this.requesterGender,
    this.status = ChatRequestStatus.pending,
  });

  final String id;
  final String postId;
  final String requesterName;
  final String requesterCity;
  final UserGender requesterGender;
  final ChatRequestStatus status;

  ChatJoinRequest copyWith({ChatRequestStatus? status}) {
    return ChatJoinRequest(
      id: id,
      postId: postId,
      requesterName: requesterName,
      requesterCity: requesterCity,
      requesterGender: requesterGender,
      status: status ?? this.status,
    );
  }
}
