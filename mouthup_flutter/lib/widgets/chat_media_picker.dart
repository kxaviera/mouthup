import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/chat_media.dart';
import '../theme/app_theme.dart';

enum ChatMediaTab { emoji, gif, sticker }

class ChatMediaPicker extends StatelessWidget {
  const ChatMediaPicker({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    required this.onEmojiSelected,
    required this.onGifSelected,
    required this.onStickerSelected,
  });

  final ChatMediaTab activeTab;
  final ValueChanged<ChatMediaTab> onTabChanged;
  final ValueChanged<String> onEmojiSelected;
  final ValueChanged<ChatGif> onGifSelected;
  final ValueChanged<ChatSticker> onStickerSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          _TabBar(activeTab: activeTab, onTabChanged: onTabChanged),
          Expanded(
            child: switch (activeTab) {
              ChatMediaTab.emoji => EmojiPicker(
                  onEmojiSelected: (category, emoji) => onEmojiSelected(emoji.emoji),
                  config: Config(
                    height: 220,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: EmojiViewConfig(
                      backgroundColor: AppColors.bgCard,
                      columns: kIsWeb ? 8 : 7,
                      emojiSizeMax: 28 * (kIsWeb ? 1.2 : 1.0),
                      verticalSpacing: 0,
                      horizontalSpacing: 0,
                      gridPadding: EdgeInsets.zero,
                      recentsLimit: 28,
                      noRecents: const Text('No recent emojis', style: TextStyle(color: AppColors.textDim, fontSize: 14)),
                      loadingIndicator: const SizedBox(),
                      buttonMode: ButtonMode.MATERIAL,
                    ),
                    categoryViewConfig: CategoryViewConfig(
                      backgroundColor: AppColors.bgCard,
                      iconColorSelected: AppColors.primary,
                      iconColor: AppColors.textDim,
                      indicatorColor: AppColors.primary,
                      backspaceColor: AppColors.textMuted,
                    ),
                    bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
                    skinToneConfig: const SkinToneConfig(enabled: true),
                  ),
                ),
              ChatMediaTab.gif => _MediaGrid<ChatGif>(
                  items: chatGifs,
                  itemBuilder: (gif) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      gif.url,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDim)));
                      },
                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.gif_box_outlined, color: AppColors.textDim)),
                    ),
                  ),
                  onTap: onGifSelected,
                ),
              ChatMediaTab.sticker => _MediaGrid<ChatSticker>(
                  items: chatStickers,
                  itemBuilder: (sticker) => Center(
                    child: Text(sticker.emoji ?? '🙂', style: const TextStyle(fontSize: 36)),
                  ),
                  onTap: onStickerSelected,
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.activeTab, required this.onTabChanged});

  final ChatMediaTab activeTab;
  final ValueChanged<ChatMediaTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          _tab('Emoji', ChatMediaTab.emoji, Icons.emoji_emotions_outlined),
          _tab('GIF', ChatMediaTab.gif, Icons.gif_box_outlined),
          _tab('Stickers', ChatMediaTab.sticker, Icons.sticky_note_2_outlined),
        ],
      ),
    );
  }

  Widget _tab(String label, ChatMediaTab tab, IconData icon) {
    final selected = activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.bgElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? AppColors.primary : AppColors.textDim),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: selected ? AppColors.primary : AppColors.textDim, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaGrid<T> extends StatelessWidget {
  const _MediaGrid({required this.items, required this.itemBuilder, required this.onTap});

  final List<T> items;
  final Widget Function(T item) itemBuilder;
  final ValueChanged<T> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return Material(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => onTap(item),
            borderRadius: BorderRadius.circular(10),
            child: itemBuilder(item),
          ),
        );
      },
    );
  }
}
