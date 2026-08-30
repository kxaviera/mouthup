import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/listing_types.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/nav_back.dart';
import '../../utils/post_text.dart';
import '../../widgets/screen_wrapper.dart';

enum _AttachmentKind { image, video }

class _PostAttachment {
  const _PostAttachment({required this.bytes, required this.kind});

  final Uint8List bytes;
  final _AttachmentKind kind;
}

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _price = TextEditingController();
  final _swapFor = TextEditingController();
  final _location = TextEditingController();
  final _picker = ImagePicker();
  final List<_PostAttachment> _attachments = [];
  bool _publishing = false;
  bool _acceptedTerms = true;
  ListingTypeOption? _listingType;
  RentPeriodId? _rentPeriod;

  static const _maxAttachments = 4;

  @override
  void initState() {
    super.initState();
    final city = context.read<AppState>().userCity;
    if (city != null) _location.text = city;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _price.dispose();
    _swapFor.dispose();
    _location.dispose();
    super.dispose();
  }

  int get _wordCount => countWords('${_title.text}\n${_content.text}');

  void _onTextChanged() {
    final combined = '${_title.text}\n${_content.text}';
    if (countWords(combined) > PostLimits.maxWords) {
      final clamped = clampToWordLimit(combined);
      final parts = clamped.split('\n');
      _title.text = parts.first;
      _content.text = parts.length > 1 ? parts.sublist(1).join('\n') : '';
    }
    setState(() {});
  }

  Future<void> _pickImage() async {
    if (_attachments.length >= _maxAttachments) return;
    final file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _attachments.add(_PostAttachment(bytes: bytes, kind: _AttachmentKind.image)));
    }
  }

  Future<void> _pickVideo() async {
    if (_attachments.length >= _maxAttachments) return;
    final file = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 2));
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _attachments.add(_PostAttachment(bytes: bytes, kind: _AttachmentKind.video)));
    }
  }

  void _removeAttachment(int index) => setState(() => _attachments.removeAt(index));

  double? _parsedPrice() {
    final raw = _price.text.trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  Future<void> _publish() async {
    if (_publishing || _listingType == null) return;
    final app = context.read<AppState>();
    final title = _title.text.trim();
    final content = _content.text.trim();
    if (!_acceptedTerms || title.length < 3) return;

    setState(() => _publishing = true);

    final images = _attachments.where((a) => a.kind == _AttachmentKind.image).map((a) => a.bytes).toList();
    final videos = _attachments.where((a) => a.kind == _AttachmentKind.video).map((a) => a.bytes).toList();

    final blocked = await app.addListing(
      title: title,
      content: content,
      listingType: _listingType!,
      price: _listingType!.id == ListingTypeId.giveaway ? null : _parsedPrice(),
      rentPeriod: _listingType!.id == ListingTypeId.rent ? _rentPeriod : null,
      swapFor: _listingType!.id == ListingTypeId.swap ? _swapFor.text.trim() : null,
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      images: images,
      videos: videos,
    );

    if (!mounted) return;
    setState(() => _publishing = false);

    if (blocked != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(blocked.userMessage), backgroundColor: AppColors.danger.withValues(alpha: 0.9)),
      );
      return;
    }

    await app.refreshFeed();
    if (mounted) context.go('/home');
  }

  bool get _canPublish {
    if (!_acceptedTerms || _listingType == null || _title.text.trim().length < 3) return false;
    if (_listingType!.id == ListingTypeId.swap && _swapFor.text.trim().isEmpty) return false;
    return _content.text.trim().isNotEmpty || _attachments.isNotEmpty;
  }

  bool get _atWordLimit => _wordCount >= PostLimits.maxWords;

  bool get _showPrice =>
      _listingType != null && _listingType!.id != ListingTypeId.giveaway;

  bool get _showRentPeriod => _listingType?.id == ListingTypeId.rent;

  bool get _showSwapFor => _listingType?.id == ListingTypeId.swap;

  @override
  Widget build(BuildContext context) {
    final types = marketplaceListingTypes;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) popOrGo(context, '/home');
      },
      child: ScreenWrapper(
        padding: false,
        bottomSafe: false,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _sectionLabel('Listing type'),
                  const SizedBox(height: 10),
                  _typeGrid(types),
                  const SizedBox(height: 24),
                  _sectionLabel('Details'),
                  const SizedBox(height: 10),
                  _fieldCard(
                    children: [
                      _styledField(
                        controller: _title,
                        hint: 'Title — e.g. iPhone 13, 2BHK flat',
                        onChanged: _onTextChanged,
                        style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      _divider(),
                      _styledField(
                        controller: _content,
                        hint: 'Description, condition, pickup details…',
                        onChanged: _onTextChanged,
                        maxLines: 5,
                        minLines: 4,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '$_wordCount / ${PostLimits.maxWords} words',
                            style: TextStyle(
                              color: _atWordLimit ? AppColors.danger : AppColors.textDim,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_showPrice || _showRentPeriod || _showSwapFor) ...[
                    const SizedBox(height: 16),
                    _sectionLabel('Pricing'),
                    const SizedBox(height: 10),
                    _fieldCard(
                      children: [
                        if (_showPrice)
                          _styledField(
                            controller: _price,
                            hint: 'Price in ₹ (optional)',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            prefix: const Padding(
                              padding: EdgeInsets.only(left: 16, right: 4),
                              child: Text('₹', style: TextStyle(color: AppColors.textMuted, fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        if (_showPrice && (_showRentPeriod || _showSwapFor)) _divider(),
                        if (_showRentPeriod) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text('Rent period', style: TextStyle(color: AppColors.textDim.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: rentPeriodOptions.map((opt) {
                                final selected = _rentPeriod == opt.id;
                                return _miniChip(label: opt.label, selected: selected, onTap: () => setState(() => _rentPeriod = opt.id));
                              }).toList(),
                            ),
                          ),
                        ],
                        if (_showSwapFor)
                          _styledField(
                            controller: _swapFor,
                            hint: 'What do you want in exchange?',
                            onChanged: () => setState(() {}),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  _sectionLabel('Location'),
                  const SizedBox(height: 10),
                  _fieldCard(
                    children: [
                      _styledField(
                        controller: _location,
                        hint: 'City or area',
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 14, right: 6),
                          child: Icon(Icons.location_on_outlined, size: 20, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _sectionLabel('Photos & videos'),
                      const Spacer(),
                      Text('${_attachments.length}/$_maxAttachments', style: const TextStyle(color: AppColors.textDim, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _mediaSection(),
                ],
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => popOrGo(context, '/home'),
            icon: const Icon(Icons.close_rounded, color: AppColors.text),
          ),
          const Expanded(
            child: Column(
              children: [
                Text('New listing', style: TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                SizedBox(height: 2),
                Text('Reach buyers near you', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(color: AppColors.textDim, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
    );
  }

  Widget _fieldCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _divider() => const Divider(height: 1, thickness: 1, color: AppColors.border);

  Widget _styledField({
    required TextEditingController controller,
    required String hint,
    VoidCallback? onChanged,
    int maxLines = 1,
    int minLines = 1,
    TextInputType? keyboardType,
    TextStyle? style,
    Widget? prefix,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged != null ? (_) => onChanged() : null,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      style: style ?? const TextStyle(color: AppColors.text, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textDim),
        prefix: prefix,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.fromLTRB(prefix == null ? 16 : 4, 14, 16, 14),
      ),
    );
  }

  Widget _typeGrid(List<ListingTypeOption> types) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: types.map((type) {
            final selected = _listingType?.id == type.id;
            return SizedBox(
              width: width,
              child: Material(
                color: selected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => setState(() => _listingType = type),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
                    ),
                    child: Row(
                      children: [
                        Text(type.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            type.label,
                            style: TextStyle(
                              color: selected ? AppColors.text : AppColors.textMuted,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _miniChip({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: TextStyle(color: selected ? AppColors.text : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _mediaSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_attachments.isNotEmpty) ...[
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _attachments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _attachmentThumb(i),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_attachments.length < _maxAttachments)
            Row(
              children: [
                Expanded(child: _mediaButton(icon: Icons.add_photo_alternate_outlined, label: 'Add photo', onTap: _pickImage)),
                const SizedBox(width: 10),
                Expanded(child: _mediaButton(icon: Icons.videocam_outlined, label: 'Add video', onTap: _pickVideo)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _attachmentThumb(int index) {
    final item = _attachments[index];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: item.kind == _AttachmentKind.image
              ? Image.memory(item.bytes, width: 108, height: 108, fit: BoxFit.cover)
              : Container(
                  width: 108,
                  height: 108,
                  color: AppColors.bgElevated,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_outline, color: AppColors.text, size: 32),
                      SizedBox(height: 4),
                      Text('Video', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    ],
                  ),
                ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _removeAttachment(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppColors.text, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: AppColors.onPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _mediaButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: AppColors.bgElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.text, size: 26),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottom),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _acceptedTerms,
                  onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                  activeColor: AppColors.primary,
                  checkColor: AppColors.onPrimary,
                  side: const BorderSide(color: AppColors.border),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('I accept the ', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      GestureDetector(
                        onTap: () => context.push('/profile/terms'),
                        child: const Text('Terms & Conditions', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 13, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _canPublish && !_publishing ? _publish : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                disabledBackgroundColor: AppColors.bgElevated,
                disabledForegroundColor: AppColors.textDim,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _publishing ? 'Publishing…' : 'Publish listing',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2),
              ),
            ),
          ),
          if (_listingType == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Select a listing type to continue', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
            ),
        ],
      ),
    );
  }
}
