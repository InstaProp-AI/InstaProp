using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;

namespace InstapropAPI.Helpers
{
    /// <summary>
    /// Helper class to provide timezone and country information for user selection
    /// </summary>
    public static class TimeZoneHelper
    {
        private static List<TimeZoneInfo>? _cachedTimeZones;
        private static List<CountryTimezoneData>? _cachedCountryTimezones;

        /// <summary>
        /// Gets all system timezones sorted alphabetically by display name
        /// </summary>
        public static List<TimeZoneInfo> GetAllTimeZones()
        {
            if (_cachedTimeZones == null)
            {
                _cachedTimeZones = TimeZoneInfo.GetSystemTimeZones()
                    .OrderBy(tz => tz.DisplayName)
                    .ToList();
            }
            return _cachedTimeZones;
        }

        /// <summary>
        /// Gets timezone-country mappings from JSON file
        /// </summary>
        public static List<CountryTimezoneData> GetCountryTimezones()
        {
            if (_cachedCountryTimezones == null)
            {
                try
                {
                    var jsonPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Data", "timezone-country-mapping.json");
                    var jsonString = File.ReadAllText(jsonPath);
                    _cachedCountryTimezones = JsonSerializer.Deserialize<List<CountryTimezoneData>>(jsonString) ?? new List<CountryTimezoneData>();
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error loading timezone-country mapping: {ex.Message}");
                    _cachedCountryTimezones = new List<CountryTimezoneData>();
                }
            }
            return _cachedCountryTimezones;
        }

        /// <summary>
        /// Gets a flattened list of all timezones with their country information, sorted alphabetically
        /// </summary>
        public static List<TimeZoneOption> GetTimeZoneOptions()
        {
            var countryTimezones = GetCountryTimezones();
            var options = new List<TimeZoneOption>();

            foreach (var country in countryTimezones.OrderBy(c => c.Country))
            {
                foreach (var timezone in country.Timezones.OrderBy(tz => tz))
                {
                    var flag = GetCountryFlag(country.CountryCode);
                    options.Add(new TimeZoneOption
                    {
                        TimeZoneId = timezone,
                        DisplayName = $"{flag} {timezone.Replace("_", " ")} - {country.Country}",
                        CountryCode = country.CountryCode,
                        CountryName = country.Country,
                        Flag = flag
                    });
                }
            }

            return options.OrderBy(o => o.TimeZoneId).ToList();
        }

        /// <summary>
        /// Gets country flag emoji from country code
        /// </summary>
        public static string GetCountryFlag(string countryCode)
        {
            if (string.IsNullOrEmpty(countryCode) || countryCode.Length != 2)
                return "🌍";

            // Convert country code to flag emoji
            // Each letter is converted to regional indicator symbol
            var code = countryCode.ToUpper();
            var flag = string.Empty;
            foreach (var c in code)
            {
                if (c >= 'A' && c <= 'Z')
                {
                    // Regional Indicator Symbol Letter A starts at 0x1F1E6
                    flag += char.ConvertFromUtf32(0x1F1E6 + (c - 'A'));
                }
            }
            return flag;
        }

        /// <summary>
        /// Gets country information from country code
        /// </summary>
        public static CountryTimezoneData? GetCountryByCode(string countryCode)
        {
            var countryTimezones = GetCountryTimezones();
            return countryTimezones.FirstOrDefault(c => c.CountryCode.Equals(countryCode, StringComparison.OrdinalIgnoreCase));
        }

        /// <summary>
        /// Validates if a timezone ID is valid
        /// </summary>
        public static bool IsValidTimeZone(string timeZoneId)
        {
            if (string.IsNullOrWhiteSpace(timeZoneId))
                return false;

            try
            {
                TimeZoneInfo.FindSystemTimeZoneById(timeZoneId);
                return true;
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Validates if a country code is valid
        /// </summary>
        public static bool IsValidCountryCode(string countryCode)
        {
            if (string.IsNullOrWhiteSpace(countryCode) || countryCode.Length != 2)
                return false;

            var countryTimezones = GetCountryTimezones();
            return countryTimezones.Any(c => c.CountryCode.Equals(countryCode, StringComparison.OrdinalIgnoreCase));
        }
    }

    /// <summary>
    /// Represents country-timezone mapping data
    /// </summary>
    public class CountryTimezoneData
    {
        public string Country { get; set; } = string.Empty;
        public string CountryCode { get; set; } = string.Empty;
        public List<string> Timezones { get; set; } = new List<string>();
    }

    /// <summary>
    /// Represents a timezone option for dropdown selection
    /// </summary>
    public class TimeZoneOption
    {
        public string TimeZoneId { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public string CountryCode { get; set; } = string.Empty;
        public string CountryName { get; set; } = string.Empty;
        public string Flag { get; set; } = string.Empty;
    }
}








