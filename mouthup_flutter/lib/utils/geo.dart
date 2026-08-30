import 'dart:math' as math;

class GeoPoint {
  const GeoPoint({required this.lat, required this.lng});
  final double lat;
  final double lng;
}

const _cityCoords = <String, GeoPoint>{
  'mumbai': GeoPoint(lat: 19.076, lng: 72.8777),
  'delhi': GeoPoint(lat: 28.6139, lng: 77.209),
  'new delhi': GeoPoint(lat: 28.6139, lng: 77.209),
  'bangalore': GeoPoint(lat: 12.9716, lng: 77.5946),
  'bengaluru': GeoPoint(lat: 12.9716, lng: 77.5946),
  'hyderabad': GeoPoint(lat: 17.385, lng: 78.4867),
  'chennai': GeoPoint(lat: 13.0827, lng: 80.2707),
  'kolkata': GeoPoint(lat: 22.5726, lng: 88.3639),
  'pune': GeoPoint(lat: 18.5204, lng: 73.8567),
  'ahmedabad': GeoPoint(lat: 23.0225, lng: 72.5714),
  'jaipur': GeoPoint(lat: 26.9124, lng: 75.7873),
  'surat': GeoPoint(lat: 21.1702, lng: 72.8311),
  'lucknow': GeoPoint(lat: 26.8467, lng: 80.9462),
  'kanpur': GeoPoint(lat: 26.4499, lng: 80.3319),
  'nagpur': GeoPoint(lat: 21.1458, lng: 79.0882),
  'indore': GeoPoint(lat: 22.7196, lng: 75.8577),
  'thane': GeoPoint(lat: 19.2183, lng: 72.9781),
  'bhopal': GeoPoint(lat: 23.2599, lng: 77.4126),
  'visakhapatnam': GeoPoint(lat: 17.6868, lng: 83.2185),
  'patna': GeoPoint(lat: 25.5941, lng: 85.1376),
  'vadodara': GeoPoint(lat: 22.3072, lng: 73.1812),
  'ghaziabad': GeoPoint(lat: 28.6692, lng: 77.4538),
  'ludhiana': GeoPoint(lat: 30.901, lng: 75.8573),
  'coimbatore': GeoPoint(lat: 11.0168, lng: 76.9558),
  'kochi': GeoPoint(lat: 9.9312, lng: 76.2673),
  'noida': GeoPoint(lat: 28.5355, lng: 77.391),
  'gurugram': GeoPoint(lat: 28.4595, lng: 77.0266),
  'gurgaon': GeoPoint(lat: 28.4595, lng: 77.0266),
  'chandigarh': GeoPoint(lat: 30.7333, lng: 76.7794),
  'goa': GeoPoint(lat: 15.2993, lng: 74.124),
};

const feedRadiusKm = 50.0;

GeoPoint? geocodePlace(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final normalized = value.toLowerCase().replaceAll('.', '').trim();
  final primary = normalized.split(',').first.trim();

  if (_cityCoords.containsKey(primary)) return _cityCoords[primary];

  for (final entry in _cityCoords.entries) {
    if (primary.contains(entry.key) || entry.key.contains(primary)) return entry.value;
  }
  for (final entry in _cityCoords.entries) {
    if (normalized.contains(entry.key)) return entry.value;
  }
  return null;
}

double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371.0;
  double toRad(double deg) => deg * math.pi / 180;
  final dLat = toRad(lat2 - lat1);
  final dLng = toRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(toRad(lat1)) * math.cos(toRad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double? distanceKmFromUser({
  required GeoPoint? userPoint,
  required GeoPoint? postPoint,
}) {
  if (userPoint == null || postPoint == null) return null;
  return haversineKm(userPoint.lat, userPoint.lng, postPoint.lat, postPoint.lng);
}

bool isWithinFeedRadius(double? distanceKm, {bool userHasGeo = false}) {
  if (distanceKm == null) return !userHasGeo;
  return distanceKm <= feedRadiusKm;
}

String formatPostLocationLabel({
  String? location,
  String? authorCity,
  double? distanceKm,
}) {
  final place = (location?.trim().isNotEmpty == true ? location!.trim() : null) ??
      (authorCity?.trim().isNotEmpty == true ? authorCity!.trim() : null);
  final distance = distanceKm != null ? formatDistanceKm(distanceKm) : null;
  if (place != null && distance != null) return '$place · $distance';
  if (place != null) return place;
  if (distance != null) return distance;
  return '';
}

String formatDistanceKm(double? km) {
  if (km == null) return '';
  if (km < 1) return '${(km * 1000).round()} m away';
  if (km < 10) return '${km.toStringAsFixed(1)} km away';
  return '${km.round()} km away';
}
