/// Timezone data for user selection
/// This provides a list of all common timezones with their country flags

class TimeZoneOption {
  final String id;
  final String displayName;
  final String countryCode;
  final String flag;

  const TimeZoneOption({
    required this.id,
    required this.displayName,
    required this.countryCode,
    required this.flag,
  });
}

/// Get country flag emoji from ISO country code
String getCountryFlag(String countryCode) {
  if (countryCode.length != 2) return '🌍';
  
  // Convert country code to flag emoji
  // Each letter is converted to regional indicator symbol
  final code = countryCode.toUpperCase();
  String flag = '';
  for (int i = 0; i < code.length; i++) {
    final codeUnit = code.codeUnitAt(i);
    if (codeUnit >= 65 && codeUnit <= 90) {
      // Regional Indicator Symbol Letter A starts at 0x1F1E6
      flag += String.fromCharCode(0x1F1E6 + (codeUnit - 65));
    }
  }
  return flag;
}

/// Common timezones grouped by region/country
List<TimeZoneOption> getTimeZoneOptions() {
  return [
    // Africa
    TimeZoneOption(
      id: 'Africa/Cairo',
      displayName: '🇪🇬 Cairo, Egypt (EET)',
      countryCode: 'EG',
      flag: '🇪🇬',
    ),
    TimeZoneOption(
      id: 'Africa/Johannesburg',
      displayName: '🇿🇦 Johannesburg, South Africa (SAST)',
      countryCode: 'ZA',
      flag: '🇿🇦',
    ),
    TimeZoneOption(
      id: 'Africa/Lagos',
      displayName: '🇳🇬 Lagos, Nigeria (WAT)',
      countryCode: 'NG',
      flag: '🇳🇬',
    ),
    TimeZoneOption(
      id: 'Africa/Nairobi',
      displayName: '🇰🇪 Nairobi, Kenya (EAT)',
      countryCode: 'KE',
      flag: '🇰🇪',
    ),
    TimeZoneOption(
      id: 'Africa/Casablanca',
      displayName: '🇲🇦 Casablanca, Morocco (WET)',
      countryCode: 'MA',
      flag: '🇲🇦',
    ),
    
    // Americas
    TimeZoneOption(
      id: 'America/New_York',
      displayName: '🇺🇸 New York, USA (EST)',
      countryCode: 'US',
      flag: '🇺🇸',
    ),
    TimeZoneOption(
      id: 'America/Chicago',
      displayName: '🇺🇸 Chicago, USA (CST)',
      countryCode: 'US',
      flag: '🇺🇸',
    ),
    TimeZoneOption(
      id: 'America/Denver',
      displayName: '🇺🇸 Denver, USA (MST)',
      countryCode: 'US',
      flag: '🇺🇸',
    ),
    TimeZoneOption(
      id: 'America/Los_Angeles',
      displayName: '🇺🇸 Los Angeles, USA (PST)',
      countryCode: 'US',
      flag: '🇺🇸',
    ),
    TimeZoneOption(
      id: 'America/Toronto',
      displayName: '🇨🇦 Toronto, Canada (EST)',
      countryCode: 'CA',
      flag: '🇨🇦',
    ),
    TimeZoneOption(
      id: 'America/Vancouver',
      displayName: '🇨🇦 Vancouver, Canada (PST)',
      countryCode: 'CA',
      flag: '🇨🇦',
    ),
    TimeZoneOption(
      id: 'America/Mexico_City',
      displayName: '🇲🇽 Mexico City, Mexico (CST)',
      countryCode: 'MX',
      flag: '🇲🇽',
    ),
    TimeZoneOption(
      id: 'America/Sao_Paulo',
      displayName: '🇧🇷 São Paulo, Brazil (BRT)',
      countryCode: 'BR',
      flag: '🇧🇷',
    ),
    TimeZoneOption(
      id: 'America/Argentina/Buenos_Aires',
      displayName: '🇦🇷 Buenos Aires, Argentina (ART)',
      countryCode: 'AR',
      flag: '🇦🇷',
    ),
    
    // Asia
    TimeZoneOption(
      id: 'Asia/Dubai',
      displayName: '🇦🇪 Dubai, UAE (GST)',
      countryCode: 'AE',
      flag: '🇦🇪',
    ),
    TimeZoneOption(
      id: 'Asia/Riyadh',
      displayName: '🇸🇦 Riyadh, Saudi Arabia (AST)',
      countryCode: 'SA',
      flag: '🇸🇦',
    ),
    TimeZoneOption(
      id: 'Asia/Kuwait',
      displayName: '🇰🇼 Kuwait City, Kuwait (AST)',
      countryCode: 'KW',
      flag: '🇰🇼',
    ),
    TimeZoneOption(
      id: 'Asia/Qatar',
      displayName: '🇶🇦 Doha, Qatar (AST)',
      countryCode: 'QA',
      flag: '🇶🇦',
    ),
    TimeZoneOption(
      id: 'Asia/Jerusalem',
      displayName: '🇮🇱 Jerusalem, Israel (IST)',
      countryCode: 'IL',
      flag: '🇮🇱',
    ),
    TimeZoneOption(
      id: 'Asia/Istanbul',
      displayName: '🇹🇷 Istanbul, Turkey (TRT)',
      countryCode: 'TR',
      flag: '🇹🇷',
    ),
    TimeZoneOption(
      id: 'Asia/Kolkata',
      displayName: '🇮🇳 Kolkata, India (IST)',
      countryCode: 'IN',
      flag: '🇮🇳',
    ),
    TimeZoneOption(
      id: 'Asia/Karachi',
      displayName: '🇵🇰 Karachi, Pakistan (PKT)',
      countryCode: 'PK',
      flag: '🇵🇰',
    ),
    TimeZoneOption(
      id: 'Asia/Dhaka',
      displayName: '🇧🇩 Dhaka, Bangladesh (BST)',
      countryCode: 'BD',
      flag: '🇧🇩',
    ),
    TimeZoneOption(
      id: 'Asia/Bangkok',
      displayName: '🇹🇭 Bangkok, Thailand (ICT)',
      countryCode: 'TH',
      flag: '🇹🇭',
    ),
    TimeZoneOption(
      id: 'Asia/Singapore',
      displayName: '🇸🇬 Singapore (SGT)',
      countryCode: 'SG',
      flag: '🇸🇬',
    ),
    TimeZoneOption(
      id: 'Asia/Hong_Kong',
      displayName: '🇭🇰 Hong Kong (HKT)',
      countryCode: 'HK',
      flag: '🇭🇰',
    ),
    TimeZoneOption(
      id: 'Asia/Shanghai',
      displayName: '🇨🇳 Shanghai, China (CST)',
      countryCode: 'CN',
      flag: '🇨🇳',
    ),
    TimeZoneOption(
      id: 'Asia/Tokyo',
      displayName: '🇯🇵 Tokyo, Japan (JST)',
      countryCode: 'JP',
      flag: '🇯🇵',
    ),
    TimeZoneOption(
      id: 'Asia/Seoul',
      displayName: '🇰🇷 Seoul, South Korea (KST)',
      countryCode: 'KR',
      flag: '🇰🇷',
    ),
    TimeZoneOption(
      id: 'Asia/Manila',
      displayName: '🇵🇭 Manila, Philippines (PHT)',
      countryCode: 'PH',
      flag: '🇵🇭',
    ),
    TimeZoneOption(
      id: 'Asia/Jakarta',
      displayName: '🇮🇩 Jakarta, Indonesia (WIB)',
      countryCode: 'ID',
      flag: '🇮🇩',
    ),
    
    // Europe
    TimeZoneOption(
      id: 'Europe/London',
      displayName: '🇬🇧 London, UK (GMT)',
      countryCode: 'GB',
      flag: '🇬🇧',
    ),
    TimeZoneOption(
      id: 'Europe/Paris',
      displayName: '🇫🇷 Paris, France (CET)',
      countryCode: 'FR',
      flag: '🇫🇷',
    ),
    TimeZoneOption(
      id: 'Europe/Berlin',
      displayName: '🇩🇪 Berlin, Germany (CET)',
      countryCode: 'DE',
      flag: '🇩🇪',
    ),
    TimeZoneOption(
      id: 'Europe/Rome',
      displayName: '🇮🇹 Rome, Italy (CET)',
      countryCode: 'IT',
      flag: '🇮🇹',
    ),
    TimeZoneOption(
      id: 'Europe/Madrid',
      displayName: '🇪🇸 Madrid, Spain (CET)',
      countryCode: 'ES',
      flag: '🇪🇸',
    ),
    TimeZoneOption(
      id: 'Europe/Amsterdam',
      displayName: '🇳🇱 Amsterdam, Netherlands (CET)',
      countryCode: 'NL',
      flag: '🇳🇱',
    ),
    TimeZoneOption(
      id: 'Europe/Brussels',
      displayName: '🇧🇪 Brussels, Belgium (CET)',
      countryCode: 'BE',
      flag: '🇧🇪',
    ),
    TimeZoneOption(
      id: 'Europe/Zurich',
      displayName: '🇨🇭 Zurich, Switzerland (CET)',
      countryCode: 'CH',
      flag: '🇨🇭',
    ),
    TimeZoneOption(
      id: 'Europe/Stockholm',
      displayName: '🇸🇪 Stockholm, Sweden (CET)',
      countryCode: 'SE',
      flag: '🇸🇪',
    ),
    TimeZoneOption(
      id: 'Europe/Moscow',
      displayName: '🇷🇺 Moscow, Russia (MSK)',
      countryCode: 'RU',
      flag: '🇷🇺',
    ),
    
    // Oceania
    TimeZoneOption(
      id: 'Australia/Sydney',
      displayName: '🇦🇺 Sydney, Australia (AEDT)',
      countryCode: 'AU',
      flag: '🇦🇺',
    ),
    TimeZoneOption(
      id: 'Australia/Melbourne',
      displayName: '🇦🇺 Melbourne, Australia (AEDT)',
      countryCode: 'AU',
      flag: '🇦🇺',
    ),
    TimeZoneOption(
      id: 'Australia/Perth',
      displayName: '🇦🇺 Perth, Australia (AWST)',
      countryCode: 'AU',
      flag: '🇦🇺',
    ),
    TimeZoneOption(
      id: 'Pacific/Auckland',
      displayName: '🇳🇿 Auckland, New Zealand (NZDT)',
      countryCode: 'NZ',
      flag: '🇳🇿',
    ),
    TimeZoneOption(
      id: 'Pacific/Fiji',
      displayName: '🇫🇯 Suva, Fiji (FJT)',
      countryCode: 'FJ',
      flag: '🇫🇯',
    ),
  ]..sort((a, b) => a.displayName.compareTo(b.displayName));
}

/// Country codes for project creation
const List<Map<String, String>> countryOptions = [
  {'code': 'EG', 'name': 'Egypt', 'flag': '🇪🇬'},
  {'code': 'US', 'name': 'United States', 'flag': '🇺🇸'},
  {'code': 'GB', 'name': 'United Kingdom', 'flag': '🇬🇧'},
  {'code': 'AE', 'name': 'United Arab Emirates', 'flag': '🇦🇪'},
  {'code': 'SA', 'name': 'Saudi Arabia', 'flag': '🇸🇦'},
  {'code': 'KW', 'name': 'Kuwait', 'flag': '🇰🇼'},
  {'code': 'QA', 'name': 'Qatar', 'flag': '🇶🇦'},
  {'code': 'BH', 'name': 'Bahrain', 'flag': '🇧🇭'},
  {'code': 'OM', 'name': 'Oman', 'flag': '🇴🇲'},
  {'code': 'JO', 'name': 'Jordan', 'flag': '🇯🇴'},
  {'code': 'LB', 'name': 'Lebanon', 'flag': '🇱🇧'},
  {'code': 'TR', 'name': 'Turkey', 'flag': '🇹🇷'},
  {'code': 'DE', 'name': 'Germany', 'flag': '🇩🇪'},
  {'code': 'FR', 'name': 'France', 'flag': '🇫🇷'},
  {'code': 'ES', 'name': 'Spain', 'flag': '🇪🇸'},
  {'code': 'IT', 'name': 'Italy', 'flag': '🇮🇹'},
  {'code': 'AU', 'name': 'Australia', 'flag': '🇦🇺'},
  {'code': 'CA', 'name': 'Canada', 'flag': '🇨🇦'},
  {'code': 'CN', 'name': 'China', 'flag': '🇨🇳'},
  {'code': 'IN', 'name': 'India', 'flag': '🇮🇳'},
  {'code': 'JP', 'name': 'Japan', 'flag': '🇯🇵'},
  {'code': 'KR', 'name': 'South Korea', 'flag': '🇰🇷'},
  {'code': 'BR', 'name': 'Brazil', 'flag': '🇧🇷'},
  {'code': 'MX', 'name': 'Mexico', 'flag': '🇲🇽'},
  {'code': 'ZA', 'name': 'South Africa', 'flag': '🇿🇦'},
  {'code': 'NG', 'name': 'Nigeria', 'flag': '🇳🇬'},
];






