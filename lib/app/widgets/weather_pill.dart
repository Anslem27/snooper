import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/weathery_models.dart';

class WeatherPill extends StatefulWidget {
  const WeatherPill({super.key});

  @override
  State<WeatherPill> createState() => _WeatherPillState();
}

class _WeatherPillState extends State<WeatherPill> {
  WeatherData? _weatherData;
  String? _city;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCity();
  }

  Future<void> _loadSavedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString('saved_city');
    if (savedCity != null) {
      setState(() {
        _city = savedCity;
      });
      _fetchWeatherData(savedCity);
    }
  }

  Future<void> _saveCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_city', city);
  }

  Future<void> _fetchWeatherData(String city) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://goweather.herokuapp.com/weather/$city'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _weatherData = WeatherData.fromJson(data);
          _city = city;
          _isLoading = false;
        });
        _saveCity(city);
      } else {
        _handleError('Failed to load weather data');
      }
    } catch (e) {
      _handleError('Error: $e');
    }
  }

  void _handleError(String message) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showCitySearchDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search City'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'City Name',
            hintText: 'e.g., London, New York, Tokyo',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_city),
          ),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _fetchWeatherData(value);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _fetchWeatherData(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('SEARCH'),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String? description) {
    if (description == null) return Icons.cloud_outlined;

    final desc = description.toLowerCase();
    if (desc.contains('sunny') || desc.contains('clear')) {
      return Icons.wb_sunny;
    } else if (desc.contains('partly cloudy')) {
      return Icons.wb_cloudy;
    } else if (desc.contains('cloudy')) {
      return Icons.cloud;
    } else if (desc.contains('rain')) {
      return Icons.umbrella;
    } else if (desc.contains('storm') || desc.contains('thunder')) {
      return Icons.thunderstorm;
    } else if (desc.contains('snow')) {
      return Icons.ac_unit;
    } else if (desc.contains('wind') || desc.contains('breezy')) {
      return Icons.air;
    } else {
      return Icons.cloud_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _showCitySearchDialog,
      child: Material(
        elevation: 3,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 56,
          width: _weatherData == null ? 160 : 240,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: _weatherData == null
                ? colorScheme.surfaceContainerHighest
                : colorScheme.secondaryContainer,
          ),
          child: _isLoading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _weatherData == null
                  ? _buildEmptyPill(colorScheme)
                  : _buildWeatherPill(colorScheme),
        ),
      ),
    );
  }

  Widget _buildEmptyPill(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_location_alt_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          'Add City',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherPill(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              _getWeatherIcon(_weatherData?.description),
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Text(
              _city ?? '',
              style: TextStyle(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          _weatherData?.temperature ?? '',
          style: TextStyle(
            color: colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
