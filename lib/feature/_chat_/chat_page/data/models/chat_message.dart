import 'package:clover/feature/_chat_/chat_page/data/models/chat_attendance_card.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_booking_staff_card.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message_attachment.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message_post_ref.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message_reaction.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message_reply_preview.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.isMine,
    this.isRead = false,
    this.kind = 'text',
    this.clientMessageId,
    this.isPending = false,
    this.postRef,
    this.attendanceCard,
    this.bookingStaffCard,
    this.attachments = const [],
    this.reactions = const [],
    this.myReactions = const [],
    this.replyPreview,
    this.editedAt,
  });

  final String id;
  final String text;
  final DateTime sentAt;
  final bool isMine;
  final bool isRead;
  final String kind;
  final String? clientMessageId;
  final bool isPending;
  final ChatMessagePostRef? postRef;
  final ChatAttendanceCard? attendanceCard;
  final ChatBookingStaffCard? bookingStaffCard;
  final List<ChatMessageAttachment> attachments;
  final List<ChatMessageReaction> reactions;
  final List<String> myReactions;
  final ChatMessageReplyPreview? replyPreview;
  final DateTime? editedAt;

  bool get isPostShare => kind == 'post_ref';

  bool get isAttendanceCard => attendanceCard != null;

  bool get isBookingStaffCard => bookingStaffCard != null;

  /// Kind hints when payload was dropped from an old cache entry.
  bool get isAttendanceCardKind =>
      isAttendanceCard || kind == 'attendance_invite' || kind == 'attendance_rules';

  bool get isBookingStaffCardKind => isBookingStaffCard || kind == 'booking_staff_invite';

  bool get needsStructuredCardRepair =>
      !isPending &&
      ((isAttendanceCardKind && attendanceCard == null) ||
          (isBookingStaffCardKind && bookingStaffCard == null) ||
          (isPostShare && !hasPostPreview));

  bool get isMedia => kind == 'media';

  bool get isFile => kind == 'file';

  bool get hasAttachments => attachments.isNotEmpty;

  bool get hasPostPreview => postRef != null && postRef!.postId.isNotEmpty;

  bool get hasReactions => reactions.isNotEmpty;

  bool get hasReply => replyPreview != null && replyPreview!.id.isNotEmpty;

  bool get isEdited => editedAt != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'sent_at': sentAt.toUtc().toIso8601String(),
      'is_mine': isMine,
      'is_read': isRead,
      'kind': kind,
      if (clientMessageId != null) 'client_message_id': clientMessageId,
      'is_pending': isPending,
      if (postRef != null) 'post_ref': postRef!.toJson(),
      if (attendanceCard != null) 'attendance_card': attendanceCard!.toJson(),
      if (bookingStaffCard != null) 'booking_card': bookingStaffCard!.toJson(),
      'attachments': attachments.map((item) => item.toJson()).toList(growable: false),
      'reactions': reactions.map((item) => item.toJson()).toList(growable: false),
      'my_reactions': myReactions,
      if (replyPreview != null) 'reply_preview': replyPreview!.toJson(),
      if (editedAt != null) 'edited_at': editedAt!.toUtc().toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final postRefRaw = json['post_ref'];
    ChatMessagePostRef? postRef;
    if (postRefRaw is Map) {
      final parsed = ChatMessagePostRef.fromJson(Map<String, dynamic>.from(postRefRaw));
      if (parsed.postId.isNotEmpty) postRef = parsed;
    }

    ChatAttendanceCard? attendanceCard;
    final attendanceRaw = json['attendance_card'];
    if (attendanceRaw is Map) {
      attendanceCard = ChatAttendanceCard.fromRef(Map<String, dynamic>.from(attendanceRaw));
    }
    attendanceCard ??= ChatAttendanceCard.tryParse((json['text'] as String?)?.trim());

    ChatBookingStaffCard? bookingStaffCard;
    final bookingRaw = json['booking_card'];
    if (bookingRaw is Map) {
      bookingStaffCard = ChatBookingStaffCard.fromRef(Map<String, dynamic>.from(bookingRaw));
    }

    ChatMessageReplyPreview? replyPreview;
    final replyRaw = json['reply_preview'];
    if (replyRaw is Map) {
      final parsed = ChatMessageReplyPreview.fromJson(Map<String, dynamic>.from(replyRaw));
      if (parsed.id.isNotEmpty) replyPreview = parsed;
    }

    final attachmentsRaw = json['attachments'];
    final attachments = <ChatMessageAttachment>[];
    if (attachmentsRaw is List) {
      for (final raw in attachmentsRaw) {
        if (raw is! Map) continue;
        final item = ChatMessageAttachment.fromJson(Map<String, dynamic>.from(raw));
        if (item.path.isNotEmpty) attachments.add(item);
      }
    }

    final reactionsRaw = json['reactions'];
    final reactions = <ChatMessageReaction>[];
    if (reactionsRaw is List) {
      for (final raw in reactionsRaw) {
        if (raw is! Map) continue;
        final item = ChatMessageReaction.fromJson(Map<String, dynamic>.from(raw));
        if (item.emoji.isNotEmpty) reactions.add(item);
      }
    }

    final myReactionsRaw = json['my_reactions'];
    final myReactions = <String>[];
    if (myReactionsRaw is List) {
      for (final raw in myReactionsRaw) {
        final emoji = raw?.toString().trim();
        if (emoji != null && emoji.isNotEmpty) myReactions.add(emoji);
      }
    }

    return ChatMessage(
      id: (json['id'] as String?)?.trim() ?? '',
      text: (json['text'] as String?)?.trim() ?? '',
      sentAt: DateTime.tryParse(json['sent_at']?.toString() ?? '')?.toUtc() ?? DateTime.now().toUtc(),
      isMine: json['is_mine'] == true,
      isRead: json['is_read'] == true,
      kind: (json['kind'] as String?)?.trim().isNotEmpty == true ? json['kind'] as String : 'text',
      clientMessageId: (json['client_message_id'] as String?)?.trim(),
      isPending: json['is_pending'] == true,
      postRef: postRef,
      attendanceCard: attendanceCard,
      bookingStaffCard: bookingStaffCard,
      attachments: attachments,
      reactions: reactions,
      myReactions: myReactions,
      replyPreview: replyPreview,
      editedAt: DateTime.tryParse(json['edited_at']?.toString() ?? '')?.toUtc(),
    );
  }

  ChatMessage copyWith({
    String? id,
    String? text,
    DateTime? sentAt,
    bool? isMine,
    bool? isRead,
    String? kind,
    String? clientMessageId,
    bool? isPending,
    ChatMessagePostRef? postRef,
    ChatAttendanceCard? attendanceCard,
    ChatBookingStaffCard? bookingStaffCard,
    List<ChatMessageAttachment>? attachments,
    List<ChatMessageReaction>? reactions,
    List<String>? myReactions,
    ChatMessageReplyPreview? replyPreview,
    DateTime? editedAt,
    bool clearReplyPreview = false,
    bool clearEditedAt = false,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sentAt: sentAt ?? this.sentAt,
      isMine: isMine ?? this.isMine,
      isRead: isRead ?? this.isRead,
      kind: kind ?? this.kind,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      isPending: isPending ?? this.isPending,
      postRef: postRef ?? this.postRef,
      attendanceCard: attendanceCard ?? this.attendanceCard,
      bookingStaffCard: bookingStaffCard ?? this.bookingStaffCard,
      attachments: attachments ?? this.attachments,
      reactions: reactions ?? this.reactions,
      myReactions: myReactions ?? this.myReactions,
      replyPreview: clearReplyPreview ? null : (replyPreview ?? this.replyPreview),
      editedAt: clearEditedAt ? null : (editedAt ?? this.editedAt),
    );
  }
}
