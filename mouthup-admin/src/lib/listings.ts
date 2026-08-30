const listingLabels: Record<string, string> = {
  SALE: 'For sale',
  RENT: 'For rent',
  SWAP: 'Swap',
  GIVEAWAY: 'Giveaway',
  SERVICE: 'Service offer',
  SERVICE_REQUEST: 'Need service',
};

const rentLabels: Record<string, string> = {
  DAY: '/day',
  WEEK: '/week',
  MONTH: '/month',
};

export function listingTypeLabel(value: string | null | undefined): string | null {
  if (!value) return null;
  return listingLabels[value.toUpperCase()] ?? value;
}

export function formatListingPrice(
  price: string | number | null | undefined,
  currency: string | null | undefined,
  rentPeriod: string | null | undefined,
  listingType: string | null | undefined,
): string | null {
  if (price == null || price === '') return listingType === 'SWAP' ? 'Swap' : listingType === 'GIVEAWAY' ? 'Free' : null;
  const num = typeof price === 'string' ? Number(price) : price;
  if (!Number.isFinite(num)) return null;
  const cur = currency ?? 'INR';
  const formatted = new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: cur,
    maximumFractionDigits: 0,
  }).format(num);
  if (listingType === 'RENT' && rentPeriod) {
    return `${formatted}${rentLabels[rentPeriod] ?? ''}`;
  }
  return formatted;
}

export function accountTypeLabel(value: string | null | undefined): string {
  switch (value) {
    case 'BUYER':
      return 'Buyer';
    case 'SELLER':
      return 'Seller';
    case 'BOTH':
      return 'Buyer & seller';
    case 'SERVICE_PROVIDER':
      return 'Service provider';
    default:
      return '—';
  }
}
