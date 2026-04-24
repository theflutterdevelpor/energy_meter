class DeviceCostResponse {
  final bool success;
  final int code;
  final DeviceCostData data;

  DeviceCostResponse({
    required this.success,
    required this.code,
    required this.data,
  });

  factory DeviceCostResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];

    if (data is List) {
      return DeviceCostResponse(
        success: json['success'] ?? false,
        code: json['code'] ?? 0,
        data: DeviceCostData.fromJson(data.first),
      );
    } else {
      return DeviceCostResponse(
        success: json['success'] ?? false,
        code: json['code'] ?? 0,
        data: DeviceCostData.fromJson(data),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'code': code,
      'data': data.toJson(),
    };
  }
}

class DeviceCostData {
  final String deviceId;
  final double totalUnits;
  final double baseCost;
  final double taxPercentage;
  final double taxAmount;
  final double totalCost;
  final double? load;

  DeviceCostData({
    required this.deviceId,
    required this.totalUnits,
    required this.baseCost,
    required this.taxPercentage,
    required this.taxAmount,
    required this.totalCost,
    required this.load,
  });

  factory DeviceCostData.fromJson(Map<String, dynamic> json) {
    return DeviceCostData(
      deviceId: json['deviceId'] ?? '',
      totalUnits: (json['totalUnits'] ?? 0).toDouble(),
      baseCost: (json['baseCost'] ?? 0).toDouble(),
      taxPercentage: (json['taxPercentage'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      totalCost: (json['totalCost'] ?? 0).toDouble(),
      load: (json['load'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'totalUnits': totalUnits,
      'baseCost': baseCost,
      'taxPercentage': taxPercentage,
      'taxAmount': taxAmount,
      'totalCost': totalCost,
      'load': load,
    };
  }
}