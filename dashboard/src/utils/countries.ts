// Egypt-only market — InstaProp is focused on Egyptian real estate
export interface Country {
  code: string;
  name: string;
  flag: string;
}

export const COUNTRIES: Country[] = [
  { code: 'EG', name: 'Egypt', flag: '🇪🇬' },
];

export const DEFAULT_COUNTRY_CODE = 'EG';

export const getCountryFlag = (countryCode: string): string => {
  if (!countryCode || countryCode.length !== 2) return '🇪🇬';
  const country = COUNTRIES.find(c => c.code === countryCode.toUpperCase());
  return country?.flag ?? '🇪🇬';
};

export const getCountryName = (code: string): string => {
  const country = COUNTRIES.find(c => c.code === code);
  return country ? country.name : 'Egypt';
};

export const getCountryDisplay = (code: string): string => {
  const country = COUNTRIES.find(c => c.code === code);
  return country ? `${country.flag} ${country.name}` : '🇪🇬 Egypt';
};
