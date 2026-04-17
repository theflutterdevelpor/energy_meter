class TemperatureLatestResponse {
  final bool success;
  final int code;
  final TemperatureLatestData data;

  TemperatureLatestResponse({
    required this.success,
    required this.code,
    required this.data,
  });

  factory TemperatureLatestResponse.fromJson(Map<String, dynamic> json) {
    return TemperatureLatestResponse(
      success: json['success'] ?? false,
      code: json['code'] ?? 0,
      data: TemperatureLatestData.fromJson(json['data'] ?? {}),
    );
  }

  TemperatureLatestResponse copyWith({
    TemperatureLatestData? data,
  }) {
    return TemperatureLatestResponse(
      success: success,
      code: code,
      data: data ?? this.data,
    );
  }
}

class TemperatureLatestData {
  final String id;
  final String gatewayId;
  final String nodeId;
  final DateTime readingTime;
  final double temperature;
  final double humidity;
  final String type;
  final String location;
  final String battery;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime installationDate;
  final DateTime lastCalibration;
  final int v;

  TemperatureLatestData({
    required this.id,
    required this.gatewayId,
    required this.nodeId,
    required this.readingTime,
    required this.temperature,
    required this.humidity,
    required this.type,
    required this.location,
    required this.battery,
    required this.createdAt,
    required this.updatedAt,
    required this.installationDate,
    required this.lastCalibration,
    required this.v,
  });

  factory TemperatureLatestData.fromJson(Map<String, dynamic> json) {
    return TemperatureLatestData(
      id: json['_id'] ?? '',
      gatewayId: json['gatewayId'] ?? '',
      nodeId: json['nodeId'] ?? '',
      readingTime:
      DateTime.tryParse(json['readingTime'] ?? '') ?? DateTime.now(),
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] ?? '',
      location: json['location'] ?? '',
      battery: json['battery'] ?? '',
      createdAt:
      DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt:
      DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      installationDate:
      DateTime.tryParse(json['installationDate'] ?? '') ??
          DateTime.now(),
      lastCalibration:
      DateTime.tryParse(json['lastCalibration'] ?? '') ??
          DateTime.now(),
      v: json['__v'] ?? 0,
    );
  }

  TemperatureLatestData copyWith({
    double? temperature,
    double? humidity,
    DateTime? updatedAt,
  }) {
    return TemperatureLatestData(
      id: id,
      gatewayId: gatewayId,
      nodeId: nodeId,
      readingTime: readingTime,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      type: type,
      location: location,
      battery: battery,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      installationDate: installationDate,
      lastCalibration: lastCalibration,
      v: v,
    );
  }
}
