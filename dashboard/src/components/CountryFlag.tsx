import React from 'react';

interface CountryFlagProps {
  countryCode?: string | null; // ISO 3166-1 alpha-2 (e.g., "US", "AE", "SA")
  size?: number;
  style?: React.CSSProperties;
}

/**
 * Convert ISO 3166-1 alpha-2 country code to flag emoji
 */
const getFlagEmoji = (countryCode?: string | null): string => {
  if (!countryCode || countryCode.trim().length === 0) {
    return '🌍'; // Default globe emoji
  }

  // Convert to uppercase for consistency
  const code = countryCode.toUpperCase().trim();

  // Handle 2-letter ISO codes
  if (code.length === 2) {
    // Convert country code to flag emoji
    // Each flag emoji is made of two regional indicator symbols
    // A = U+1F1E6, B = U+1F1E7, etc.
    const firstChar = code.charCodeAt(0) - 0x41 + 0x1F1E6;
    const secondChar = code.charCodeAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstChar) + String.fromCharCode(secondChar);
  }

  // Fallback for invalid codes
  return '🌍';
};

/**
 * Extract country code from location string (e.g., "New York, United States" -> "US")
 */
export const extractCountryCodeFromLocation = (location?: string | null): string | null => {
  if (!location || location.trim().length === 0) return null;

  // Common country names to codes mapping
  const countryMap: Record<string, string> = {
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
    'kuwait': 'KW',
    'oman': 'OM',
    'jordan': 'JO',
    'lebanon': 'LB',
    'turkey': 'TR',
    'india': 'IN',
    'china': 'CN',
    'japan': 'JP',
    'south korea': 'KR',
    'australia': 'AU',
    'new zealand': 'NZ',
    'brazil': 'BR',
    'mexico': 'MX',
    'argentina': 'AR',
  };

  const lowerLocation = location.toLowerCase();
  
  // Check for country names in location string
  for (const [countryName, code] of Object.entries(countryMap)) {
    if (lowerLocation.includes(countryName)) {
      return code;
    }
  }

  // Try to extract from end of location (common pattern: "City, Country")
  const parts = location.split(',');
  if (parts.length > 1) {
    const lastPart = parts[parts.length - 1].trim().toLowerCase();
    for (const [countryName, code] of Object.entries(countryMap)) {
      if (lastPart.includes(countryName)) {
        return code;
      }
    }
  }

  return null;
};

const CountryFlag: React.FC<CountryFlagProps> = ({ countryCode, size = 20, style }) => {
  const flagEmoji = getFlagEmoji(countryCode);

  return (
    <span
      style={{
        fontSize: `${size * 0.9}px`,
        lineHeight: 1,
        display: 'inline-block',
        ...style
      }}
      role="img"
      aria-label={countryCode ? `Flag of ${countryCode}` : 'World flag'}
    >
      {flagEmoji}
    </span>
  );
};

export default CountryFlag;

