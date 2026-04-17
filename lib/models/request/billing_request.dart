class BillingRequest {
  final String deviceId;
  final String organizationId;
  final int readingDate;
  final List<UnitPriceSlab> unitPriceSlabs;
  final double taxPercentage;
  final double? maxLoad;

  BillingRequest({
    required this.deviceId,
    required this.organizationId,
    required this.readingDate,
    required this.unitPriceSlabs,
    required this.taxPercentage,
    this.maxLoad,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'organizationId': organizationId,
      'readingDate': readingDate,
      'unitPriceSlabs': unitPriceSlabs.map((slab) => slab.toJson()).toList(),
      'taxPercentage': taxPercentage,
      if (maxLoad != null) 'maxLoad': maxLoad,
    };
  }
}

class UnitPriceSlab {
  final int from;
  final int to;
  final double pricePerUnit;

  UnitPriceSlab({
    required this.from,
    required this.to,
    required this.pricePerUnit,
  });

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'pricePerUnit': pricePerUnit,
    };
  }
}