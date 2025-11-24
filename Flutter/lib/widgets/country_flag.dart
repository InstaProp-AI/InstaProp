import 'package:flutter/material.dart';

/// Widget to display country flag emoji from ISO 3166-1 alpha-2 country code
class CountryFlag extends StatelessWidget {
  final String? countryCode; // ISO 3166-1 alpha-2 (e.g., "US", "AE", "SA")
  final double size;

  const CountryFlag({
    super.key,
    this.countryCode,
    this.size = 20,
  });

  /// Convert ISO 3166-1 alpha-2 country code to flag emoji
  static String getFlagEmoji(String? countryCode) {
    if (countryCode == null || countryCode.isEmpty) {
      return '🌍'; // Default globe emoji
    }

    // Convert to uppercase for consistency
    final code = countryCode.toUpperCase().trim();

    // Handle 2-letter ISO codes
    if (code.length == 2) {
      try {
        // Convert country code to flag emoji
        // Each flag emoji is made of two regional indicator symbols
        // A = U+1F1E6, B = U+1F1E7, etc.
        // These are in the range 0x1F1E6 to 0x1F1FF
        final firstChar = code.codeUnitAt(0);
        final secondChar = code.codeUnitAt(1);
        
        // Validate that characters are A-Z
        if (firstChar < 0x41 || firstChar > 0x5A || 
            secondChar < 0x41 || secondChar > 0x5A) {
          return '🌍';
        }
        
        // Convert to regional indicator symbols (surrogate pairs)
        final firstIndicator = firstChar - 0x41 + 0x1F1E6;
        final secondIndicator = secondChar - 0x41 + 0x1F1E6;
        
        // Create flag emoji using Runes for proper Unicode handling
        return String.fromCharCodes([firstIndicator, secondIndicator]);
      } catch (e) {
        return '🌍';
      }
    }

    // Fallback for invalid codes
    return '🌍';
  }

  /// Extract country code from location string (e.g., "New York, United States" -> "US")
  static String? extractCountryCodeFromLocation(String? location) {
    if (location == null || location.isEmpty) return null;

    // Common country names to codes mapping
    final countryMap = {
      'united states': 'US',
      'usa': 'US',
      'u.s.': 'US',
      'u.s.a.': 'US',
      'united arab emirates': 'AE',
      'uae': 'AE',
      'saudi arabia': 'SA',
      'canada': 'CA',
      'united kingdom': 'GB',
      'uk': 'GB',
      'germany': 'DE',
      'france': 'FR',
      'spain': 'ES',
      'italy': 'IT',
      'netherlands': 'NL',
      'qatar': 'QA',
      'bahrain': 'BH',
      'egypt': 'EG',
    };

    final lowerLocation = location.toLowerCase();
    
    // Check for country names in location string
    for (final entry in countryMap.entries) {
      if (lowerLocation.contains(entry.key)) {
        return entry.value;
      }
    }

    // Try to extract from end of location (common pattern: "City, Country")
    final parts = location.split(',');
    if (parts.length > 1) {
      final lastPart = parts.last.trim().toLowerCase();
      for (final entry in countryMap.entries) {
        if (lastPart.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final flagEmoji = getFlagEmoji(countryCode);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      child: Text(
        flagEmoji,
        style: TextStyle(fontSize: size * 0.9),
      ),
    );
  }
}

