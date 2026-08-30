import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/chat_media.dart';
import '../../models/chat_message.dart';
import '../../models/direct_message.dart';
import '../../models/post.dart';
import '../../models/review_request.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/chat_label.dart';
import '../../utils/nav_back.dart';
import '../../utils/user_profile_nav.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/chat_media_picker.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/write_review_sheet.dart';

class DmChatScreen extends StatefulWidget {
  const DmChatScreen({super.key, required this.peer, this.postId});

  final String peer;
  final String? postId;

  @override
  State<DmChatScreen> createState() => _DmChatScreenState();
}

class _DmChatScreenState extends State<DmChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  bool _showMediaPicker = false;
  ChatMediaTab _mediaTab = ChatMediaTab.emoji;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppState>();
      app.markDmRead(widget.peer);
      app.joinDmPeer(widget.peer);
      app.loadDmMessages(widget.peer);
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted) return;
      final app = context.read<AppState>();
      if (app.realtimeConnected) return;
      app.loadDmMessages(widget.peer);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _sendText(AppState app) async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final blocked = await app.sendDirectMessage(widget.peer, text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (blocked != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(blocked.userMessage), backgroundColor: AppColors.danger.withValues(alpha: 0.9)),
      );
      return;
    }
    _controller.clear();
    _scrollToBottom();
  }

  void _openMediaPicker(ChatMediaTab tab) {
    setState(() {
      if (_showMediaPicker && _mediaTab == tab) {
        _showMediaPicker = false;
      } else {
        _showMediaPicker = true;
        _mediaTab = tab;
      }
    });
  }

  void _insertEmoji(String emoji) {
    final text = _controller.text;
    final selection = _controller.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final updated = text.replaceRange(start, end, emoji);
    _controller
      ..text = updated
      ..selection = TextSelection.collapsed(offset: start + emoji.length);
  }

  Future<void> _sendGif(AppState app, ChatGif gif) async {
    await app.sendDirectGif(widget.peer, gif.url, label: gif.label);
    if (!mounted) return;
    setState(() => _showMediaPicker = false);
    _scrollToBottom();
  }

  Future<void> _sendSticker(AppState app, ChatSticker sticker) async {
    await app.sendDirectSticker(widget.peer, sticker);
    if (!mounted) return;
    setState(() => _showMediaPicker = false);
    _scrollToBottom();
  }

  ChatMessage _asChatMessage(DirectMessage dm, String myNickname) {
    final isMe = dm.isFromMe(myNickname);
    return ChatMessage(
      id: dm.id,
      nickname: isMe ? myNickname : widget.peer,
      text: dm.text,
      isMe: isMe,
      type: dm.type,
      mediaUrl: dm.mediaUrl,
      isSystem: dm.type == ChatMessageType.system,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final peer = widget.peer;
    final messages = app.dmMessages(peer);
    final canDm = app.canDm(peer);
    final listingPost = widget.postId != null ? app.getPost(widget.postId!) : null;
    final tip = dmTipForPost(listingPost);
    final reviewRequests = app.reviewRequestsInChat(peer);
    final pendingForMe = app.pendingReviewRequestsFrom(peer);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) popOrGo(context, '/chats');
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => popOrGo(context, '/chats'),
                      icon: const Icon(Icons.arrow_back, color: AppColors.text),
                    ),
                    UserAvatar(name: peer, imageUrl: app.avatarForUser(peer), radius: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(peer, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 16)),
                          const Text('Direct message', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                    if (canDm)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: AppColors.textDim, size: 20),
                        color: AppColors.bgCard,
                        onSelected: (value) async {
                          if (value == 'profile') {
                            openUserProfile(context, app, peer);
                          } else if (value == 'block') {
                            final error = await app.blockUser(peer);
                            if (!context.mounted) return;
                            popOrGo(context, '/chats');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error ?? '$peer blocked')),
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'profile', child: Text('View profile', style: TextStyle(color: AppColors.text))),
                          const PopupMenuItem(value: 'block', child: Text('Block user', style: TextStyle(color: AppColors.danger))),
                        ],
                      ),
                  ],
                ),
              ),
              if (listingPost != null) _dealBar(context, app, listingPost, peer, pendingForMe),
              if (tip != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(tip, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.35)),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_showMediaPicker) setState(() => _showMediaPicker = false);
                  },
                  child: (messages.isEmpty && reviewRequests.isEmpty)
                      ? const Center(child: Text('Say hi 👋', style: TextStyle(color: AppColors.textDim)))
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                          itemCount: reviewRequests.length + messages.length,
                          itemBuilder: (_, i) {
                            if (i < reviewRequests.length) {
                              final req = reviewRequests[i];
                              final post = app.getPost(req.postId);
                              final postTitle = post?.displayTitle ?? 'Listing';
                              final canRespond = req.reviewer == app.nickname && !req.completed;
                              return ReviewRequestCard(
                                request: req,
                                postTitle: postTitle,
                                canRespond: canRespond,
                                alreadyReviewed: app.hasSubmittedReview(req.requester, req.postId),
                                onLeaveReview: canRespond
                                    ? () => WriteReviewSheet.show(
                                          context,
                                          profileUsername: req.requester,
                                          postTitle: postTitle,
                                          onSubmit: (rating, text) => app.submitReview(
                                            profileUsername: req.requester,
                                            postId: req.postId,
                                            rating: rating,
                                            text: text,
                                          ),
                                        )
                                    : null,
                              );
                            }
                            final dm = messages[i - reviewRequests.length];
                            final chat = _asChatMessage(dm, app.nickname);
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              child: ChatBubble(nickname: chat.nickname, message: chat, isMe: chat.isMe),
                            );
                          },
                        ),
                ),
              ),
              if (!canDm)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: AppColors.bgCard,
                  child: Text(
                    app.isBlocked(peer) ? 'You blocked $peer' : 'You cannot message yourself',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                )
              else ...[
                if (_showMediaPicker)
                  ChatMediaPicker(
                    activeTab: _mediaTab,
                    onTabChanged: (tab) => setState(() => _mediaTab = tab),
                    onEmojiSelected: _insertEmoji,
                    onGifSelected: (gif) => _sendGif(app, gif),
                    onStickerSelected: (sticker) => _sendSticker(app, sticker),
                  ),
                Container(
                  padding: EdgeInsets.fromLTRB(8, 10, 12, 10 + MediaQuery.of(context).padding.bottom),
                  decoration: const BoxDecoration(
                    color: AppColors.bgCard,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _inputIcon(
                        icon: Icons.emoji_emotions_outlined,
                        active: _showMediaPicker && _mediaTab == ChatMediaTab.emoji,
                        onTap: () => _openMediaPicker(ChatMediaTab.emoji),
                      ),
                      _inputIcon(
                        icon: Icons.gif_box_outlined,
                        active: _showMediaPicker && _mediaTab == ChatMediaTab.gif,
                        onTap: () => _openMediaPicker(ChatMediaTab.gif),
                      ),
                      _inputIcon(
                        icon: Icons.sticky_note_2_outlined,
                        active: _showMediaPicker && _mediaTab == ChatMediaTab.sticker,
                        onTap: () => _openMediaPicker(ChatMediaTab.sticker),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: AppColors.text),
                          maxLines: 4,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            hintText: 'Message $peer...',
                            hintStyle: const TextStyle(color: AppColors.textDim),
                            filled: true,
                            fillColor: AppColors.bgElevated,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (_) => _sendText(app),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: AppColors.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: _sending ? null : () => _sendText(app),
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: _sending
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                                  )
                                : const Icon(Icons.send_rounded, color: AppColors.onPrimary, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _dealBar(BuildContext context, AppState app, MouthUpPost listingPost, String peer, List<ReviewRequest> pendingForMe) {
    final postId = listingPost.id;
    final canRequest = !app.hasOpenReviewRequest(peer, postId) && !app.hasSubmittedReview(peer, postId);
    final pendingThisPost = pendingForMe.where((r) => r.postId == postId).toList();
    final pendingReq = pendingThisPost.isNotEmpty ? pendingThisPost.first : null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.handshake_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  listingPost.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/post/$postId'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (pendingReq != null) ...[
            const SizedBox(height: 8),
            Text(
              '$peer asked you to leave a review for this deal',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: app.hasSubmittedReview(pendingReq.requester, postId)
                    ? null
                    : () => WriteReviewSheet.show(
                          context,
                          profileUsername: pendingReq.requester,
                          postTitle: listingPost.displayTitle,
                          onSubmit: (rating, text) => app.submitReview(
                            profileUsername: pendingReq.requester,
                            postId: postId,
                            rating: rating,
                            text: text,
                          ),
                        ),
                icon: const Icon(Icons.rate_review_outlined, size: 16),
                label: const Text('Leave review'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: canRequest
                    ? () async {
                        final error = await app.requestReview(peer, postId);
                        if (!context.mounted) return;
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                        }
                      }
                    : null,
                icon: const Icon(Icons.rate_review_outlined, size: 16),
                label: Text(canRequest ? 'Request review' : 'Review requested'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: canRequest ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _inputIcon({required IconData icon, required VoidCallback onTap, bool active = false}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: active ? AppColors.primary : AppColors.textDim, size: 22),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(8),
    );
  }
}
