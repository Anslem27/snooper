class WeatherData {
  final String temperature;
  final String wind;
  final String? description;
  final List<ForecastDay> forecast;

  WeatherData({
    required this.temperature,
    required this.wind,
    this.description,
    required this.forecast,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    List<ForecastDay> forecastList = [];
    if (json['forecast'] != null) {
      forecastList = List<ForecastDay>.from(
        json['forecast'].map((x) => ForecastDay.fromJson(x)),
      );
    }

    return WeatherData(
      temperature: json['temperature'] ?? 'N/A',
      wind: json['wind'] ?? 'N/A',
      description: json['description'],
      forecast: forecastList,
    );
  }
}

class ForecastDay {
  final String day;
  final String temperature;
  final String wind;

  ForecastDay({
    required this.day,
    required this.temperature,
    required this.wind,
  });

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    return ForecastDay(
      day: json['day'].toString(),
      temperature: json['temperature'] ?? 'N/A',
      wind: json['wind'] ?? 'N/A',
    );
  }
}
