class BillingResponse {
  final bool success;
  final int code;
  final String? message;
  final BillingData data;

  BillingResponse({
    required this.success,
    required this.code,
     this.message,
    required this.data,
  });

  factory BillingResponse.fromJson(Map<String, dynamic> json) {
    return BillingResponse(
      success: json['success'],
      code: json['code'],
      message: json['message'],
      data: BillingData.fromJson(json['data']),
    );
  }
}

class BillingData {
  final String id;
  final String deviceId;
  final String organizationId;
  final int readingDate;
  final List<UnitPriceSlabResponse> unitPriceSlabs;
  final int maxLoad;
  final int taxPercentage;
  final DateTime createdAt;
  final DateTime updatedAt;

  BillingData({
    required this.id,
    required this.deviceId,
    required this.organizationId,
    required this.readingDate,
    required this.unitPriceSlabs,
    required this.maxLoad,
    required this.taxPercentage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BillingData.fromJson(Map<String, dynamic> json) {
    return BillingData(
      id: json['_id'],
      deviceId: json['deviceId'],
      organizationId: json['organizationId'],
      readingDate: json['readingDate'],
      unitPriceSlabs: (json['unitPriceSlabs'] as List)
          .map((slab) => UnitPriceSlabResponse.fromJson(slab))
          .toList(),
      maxLoad: json['maxLoad'],
      taxPercentage: json['taxPercentage'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class UnitPriceSlabResponse {
  final String id;
  final int from;
  final int to;
  final double pricePerUnit;

  UnitPriceSlabResponse({
    required this.id,
    required this.from,
    required this.to,
    required this.pricePerUnit,
  });

  factory UnitPriceSlabResponse.fromJson(Map<String, dynamic> json) {
    return UnitPriceSlabResponse(
      id: json['_id'],
      from: json['from'],
      to: json['to'],
      pricePerUnit: (json['pricePerUnit'] as num).toDouble(),
    );
  }
}