import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/professions.dart';
import '../../constants/service_form_templates.dart';
import '../../constants/service_pricing.dart';
import '../../models/service_catalog_item.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/nav_back.dart';

class AddServiceCatalogScreen extends StatefulWidget {
  const AddServiceCatalogScreen({super.key, this.existing});

  final ServiceCatalogItem? existing;

  @override
  State<AddServiceCatalogScreen> createState() => _AddServiceCatalogScreenState();
}

class _AddServiceCatalogScreenState extends State<AddServiceCatalogScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _cityController = TextEditingController();
  final _fieldControllers = <String, TextEditingController>{};

  String? _profession;
  String _pricingType = 'ON_CHAT';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _profession = existing.profession;
      _titleController.text = existing.title;
      _descriptionController.text = existing.description ?? '';
      _pricingType = existing.pricingType;
      if (existing.price != null) _priceController.text = existing.price!.toString();
      _cityController.text = existing.city ?? '';
      for (final entry in existing.metadata.entries) {
        _fieldControllers[entry.key] = TextEditingController(text: '${entry.value}');
      }
    } else {
      final app = context.read<AppState>();
      _profession = app.profession;
      _cityController.text = app.userCity ?? '';
    }
    _ensureFieldControllers();
  }

  void _ensureFieldControllers() {
    if (_profession == null) return;
    final fields = formFieldsForProfession(_profession!);
    for (final field in fields) {
      _fieldControllers.putIfAbsent(field.key, () => TextEditingController());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _cityController.dispose();
    for (final c in _fieldControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_profession == null) {
      _showError('Pick a profession');
      return;
    }
    if (_titleController.text.trim().length < 2) {
      _showError('Enter a service title');
      return;
    }

    final pricing = pricingFromApi(_pricingType);
    double? price;
    if (pricing?.needsPrice == true) {
      price = double.tryParse(_priceController.text.trim());
      if (price == null) {
        _showError('Enter a valid price');
        return;
      }
    }

    final metadata = <String, dynamic>{};
    for (final field in formFieldsForProfession(_profession!)) {
      final value = _fieldControllers[field.key]?.text.trim() ?? '';
      if (value.isNotEmpty) metadata[field.key] = value;
    }

    setState(() => _saving = true);
    final app = context.read<AppState>();
    final item = ServiceCatalogItem(
      id: widget.existing?.id ?? '',
      profession: _profession!,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      pricingType: _pricingType,
      price: price,
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      metadata: metadata,
    );

    final error = widget.existing == null
        ? await app.createServiceCatalog(item)
        : await app.updateServiceCatalog(widget.existing!.id, item);

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      _showError(error);
      return;
    }

    context.pop(true);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final pricing = pricingFromApi(_pricingType);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        title: Text(isEdit ? 'Edit service' : 'Add to catalog'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => popOrGo(context, '/profile'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          DropdownButtonFormField<String>(
            value: _profession,
            decoration: _inputDecoration('Profession'),
            items: professionOptions
                .map((opt) => DropdownMenuItem(value: opt.apiValue, child: Text('${opt.emoji} ${opt.label}')))
                .toList(),
            onChanged: (value) {
              setState(() {
                _profession = value;
                _ensureFieldControllers();
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: _inputDecoration('Service title', hint: 'e.g. Kitchen leak repair'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: _inputDecoration('Description (optional)'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _pricingType,
            decoration: _inputDecoration('Pricing'),
            items: servicePricingOptions
                .map((opt) => DropdownMenuItem(value: opt.apiValue, child: Text(opt.label)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _pricingType = value);
            },
          ),
          if (pricing?.needsPrice == true) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDecoration('Price (INR)'),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _cityController,
            decoration: _inputDecoration('City', hint: 'Where you offer this'),
          ),
          if (_profession != null) ...[
            const SizedBox(height: 20),
            const Text('Details', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...formFieldsForProfession(_profession!).map((field) {
              final controller = _fieldControllers[field.key]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: controller,
                  maxLines: field.multiline ? 3 : 1,
                  decoration: _inputDecoration(field.label, hint: field.hint),
                ),
              );
            }),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                  )
                : Text(isEdit ? 'Save changes' : 'Add service'),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.bgCard,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
    );
  }
}
