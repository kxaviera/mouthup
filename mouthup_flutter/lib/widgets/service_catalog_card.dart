import 'package:flutter/material.dart';
import '../constants/professions.dart';
import '../constants/service_pricing.dart';
import '../models/service_catalog_item.dart';
import '../theme/app_theme.dart';
import '../utils/display_name.dart';
import 'verified_badge.dart';

class ServiceCatalogCard extends StatelessWidget {
  const ServiceCatalogCard({
    super.key,
    required this.item,
    this.onTap,
    this.onProviderTap,
    this.compact = false,
  });

  final ServiceCatalogItem item;
  final VoidCallback? onTap;
  final VoidCallback? onProviderTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final profession = professionFromApi(item.profession);
    final priceLabel = formatServicePrice(
      pricingType: item.pricingType,
      price: item.price,
      currency: item.currency,
    );
    final providerName = displayNameFor(
      screenName: item.providerScreenName,
      username: item.providerUsername ?? '',
    );

    return Material(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${profession?.emoji ?? '✨'} ${profession?.label ?? item.profession}${item.city != null ? ' · ${item.city}' : ''}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      priceLabel,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (!compact && item.description != null && item.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  item.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.text, fontSize: 13, height: 1.35),
                ),
              ],
              if (item.providerUsername != null) ...[
                const SizedBox(height: 10),
                InkWell(
                  onTap: onProviderTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Text(
                        providerName,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.providerVerified) ...[
                        const SizedBox(width: 4),
                        const VerifiedBadge(size: 14),
                      ],
                      const Spacer(),
                      const Icon(Icons.chevron_right, size: 18, color: AppColors.textDim),
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
}
