import 'package:flutter/material.dart';
import 'package:mazale/assets/app.colors.dart';

// Country code data structure
class CountryCode {
  final String code;
  final String name;
  final String flag;
  final String dialCode;

  const CountryCode({
    required this.code,
    required this.name,
    required this.flag,
    required this.dialCode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryCode && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}

// List of all country codes
class CountryCodes {
  static final List<CountryCode> all = [
    CountryCode(code: 'US', name: 'United States', flag: '🇺🇸', dialCode: '+1'),
    CountryCode(code: 'KE', name: 'Kenya', flag: '🇰🇪', dialCode: '+254'),
    CountryCode(code: 'UG', name: 'Uganda', flag: '🇺🇬', dialCode: '+256'),
    CountryCode(code: 'TZ', name: 'Tanzania', flag: '🇹🇿', dialCode: '+255'),
    CountryCode(code: 'RW', name: 'Rwanda', flag: '🇷🇼', dialCode: '+250'),
    CountryCode(code: 'NG', name: 'Nigeria', flag: '🇳🇬', dialCode: '+234'),
    CountryCode(code: 'GH', name: 'Ghana', flag: '🇬🇭', dialCode: '+233'),
    CountryCode(code: 'ZA', name: 'South Africa', flag: '🇿🇦', dialCode: '+27'),
    CountryCode(code: 'EG', name: 'Egypt', flag: '🇪🇬', dialCode: '+20'),
    CountryCode(code: 'MA', name: 'Morocco', flag: '🇲🇦', dialCode: '+212'),
    CountryCode(code: 'IN', name: 'India', flag: '🇮🇳', dialCode: '+91'),
    CountryCode(code: 'GB', name: 'United Kingdom', flag: '🇬🇧', dialCode: '+44'),
    CountryCode(code: 'DE', name: 'Germany', flag: '🇩🇪', dialCode: '+49'),
    CountryCode(code: 'FR', name: 'France', flag: '🇫🇷', dialCode: '+33'),
    CountryCode(code: 'IT', name: 'Italy', flag: '🇮🇹', dialCode: '+39'),
    CountryCode(code: 'ES', name: 'Spain', flag: '🇪🇸', dialCode: '+34'),
    CountryCode(code: 'BR', name: 'Brazil', flag: '🇧🇷', dialCode: '+55'),
    CountryCode(code: 'MX', name: 'Mexico', flag: '🇲🇽', dialCode: '+52'),
    CountryCode(code: 'CA', name: 'Canada', flag: '🇨🇦', dialCode: '+1'),
    CountryCode(code: 'AU', name: 'Australia', flag: '🇦🇺', dialCode: '+61'),
  ];
}

class CountryCodeDropdown extends StatefulWidget {
  final CountryCode? initialValue;
  final Function(CountryCode) onChanged;
  final String? labelText;
  final String? hintText;

  const CountryCodeDropdown({
    Key? key,
    this.initialValue,
    required this.onChanged,
    this.labelText,
    this.hintText,
  }) : super(key: key);

  // Static method to get default country
  static CountryCode getDefaultCountry() {
    return CountryCodes.all[1]; // Kenya as default
  }

  @override
  State<CountryCodeDropdown> createState() => _CountryCodeDropdownState();
}

class _CountryCodeDropdownState extends State<CountryCodeDropdown> {
  late CountryCode _selectedCountryCode;

  @override
  void initState() {
    super.initState();
    _selectedCountryCode = widget.initialValue ?? CountryCodes.all[1]; // Default to Kenya
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: AppColors.lighter,
      ),
      child: DropdownButtonFormField<CountryCode>(
        value: _selectedCountryCode,
        decoration: InputDecoration(
          icon: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.public),
          ),
          filled: true,
          fillColor: AppColors.lighter,
          labelText: widget.labelText ?? "Country",
          hintText: widget.hintText,
          border: InputBorder.none,
        ),
        items: CountryCodes.all.map((country) {
          return DropdownMenuItem<CountryCode>(
            value: country,
            child: Row(
              children: [
                Text(country.flag, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${country.dialCode} - ${country.name}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (CountryCode? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedCountryCode = newValue;
            });
            widget.onChanged(newValue);
          }
        },
      ),
    );
  }
}