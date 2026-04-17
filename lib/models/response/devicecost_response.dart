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
    return DeviceCostResponse(
      success: json['success'] ?? false,
      code: json['code'] ?? 0,
      data: DeviceCostData.fromJson(json['data'] ?? {}),
    );
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
  final int totalUnits;
  final double baseCost;
  final double taxPercentage;
  final double taxAmount;
  final double totalCost;

  DeviceCostData({
    required this.deviceId,
    required this.totalUnits,
    required this.baseCost,
    required this.taxPercentage,
    required this.taxAmount,
    required this.totalCost,
  });

  factory DeviceCostData.fromJson(Map<String, dynamic> json) {
    return DeviceCostData(
      deviceId: json['deviceId'] ?? '',
      totalUnits: json['totalUnits'] ?? 0,
      baseCost: (json['baseCost'] ?? 0).toDouble(),
      taxPercentage: (json['taxPercentage'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      totalCost: (json['totalCost'] ?? 0).toDouble(),
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
    };
  }
}