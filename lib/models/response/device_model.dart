// ================== Main Response Model ==================
class DeviceResponse {
  final bool success;
  final int code;
  final List<Device> data;

  DeviceResponse({
    required this.success,
    required this.code,
    required this.data,
  });

  factory DeviceResponse.fromJson(Map<String, dynamic> json) {
    return DeviceResponse(
      success: json['success'] ?? false,
      code: json['code'] ?? 0,
      data: json['data'] != null
          ? List<Device>.from(json['data'].map((x) => Device.fromJson(x)))
          : [],
    );
  }
}

// ================== Device Model ==================
class Device {
  final String id;
  final String name;
  final String deviceId;
  final String organization;
  final Building building;
  final Floor floor;
  final String room;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;
  final List<String> scheduleIds;
  final List<Sensor> sensors;
  final dynamic space;
  final String status;
  final dynamic lastSeen;
  final int offlineThreshold;

  Device({
    required this.id,
    required this.name,
    required this.deviceId,
    required this.organization,
    required this.building,
    required this.floor,
    required this.room,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
    required this.scheduleIds,
    required this.sensors,
    this.space,
    required this.status,
    this.lastSeen,
    required this.offlineThreshold,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      deviceId: json['deviceId'] ?? '',
      organization: json['organization'] ?? '',
      building: json['building'] != null
          ? Building.fromJson(json['building'])
          : Building.empty(),
      floor: json['floor'] != null
          ? Floor.fromJson(json['floor'])
          : Floor.empty(),
      room: json['room'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      v: json['__v'] ?? 0,
      scheduleIds: json['scheduleIds'] != null
          ? List<String>.from(json['scheduleIds'])
          : [],
      sensors: json['sensors'] != null
          ? List<Sensor>.from(json['sensors'].map((x) => Sensor.fromJson(x)))
          : [],
      space: json['space'],
      status: json['status']?.toString().toLowerCase() ?? 'offline',
      lastSeen: json['lastSeen'],
      offlineThreshold: json['offlineThreshold'] ?? 1800000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'deviceId': deviceId,
      'organization': organization,
      'building': building.toJson(),
      'floor': floor.toJson(),
      'room': room,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': v,
      'scheduleIds': scheduleIds,
      'sensors': sensors.map((e) => e.toJson()).toList(),
      'space': space,
      'status': status,
      'lastSeen': lastSeen,
      'offlineThreshold': offlineThreshold,
    };
  }

  // Helper getters (already good, but made safer)
  bool get isOnline => status.toLowerCase() == 'online';
  bool get isOffline => status.toLowerCase() == 'offline';
}

// ================== Building Model ==================
class Building {
  final String id;
  final String organization;
  final String name;
  final Location locations;
  final List<String> floors;
  final int v;

  Building({
    required this.id,
    required this.organization,
    required this.name,
    required this.locations,
    required this.floors,
    required this.v,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['_id'] ?? '',
      organization: json['organization'] ?? '',
      name: json['name'] ?? '',
      locations: json['locations'] != null
          ? Location.fromJson(json['locations'])
          : Location.empty(),
      floors: json['floors'] != null
          ? List<String>.from(json['floors'])
          : [],
      v: json['__v'] ?? 0,
    );
  }

  factory Building.empty() => Building(
    id: '', organization: '', name: '',
    locations: Location.empty(), floors: [], v: 0,
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'organization': organization,
    'name': name,
    'locations': locations.toJson(),
    'floors': floors,
    '__v': v,
  };
}

// ================== Location Model ==================
class Location {
  final String address;
  final dynamic suite;
  final dynamic flat;
  final String city;
  final String state;
  final String country;
  final dynamic postalCode;        // Changed to dynamic (can be int or string)
  final String id;

  Location({
    required this.address,
    this.suite,
    this.flat,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.id,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      address: json['address'] ?? '',
      suite: json['suite'],
      flat: json['flat'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      postalCode: json['postalCode'],
      id: json['_id'] ?? '',
    );
  }

  factory Location.empty() => Location(
    address: '', suite: null, flat: null, city: '',
    state: '', country: '', postalCode: '', id: '',
  );

  Map<String, dynamic> toJson() => {
    'address': address,
    'suite': suite,
    'flat': flat,
    'city': city,
    'state': state,
    'country': country,
    'postalCode': postalCode,
    '_id': id,
  };
}

// ================== Floor Model ==================
class Floor {
  final String id;
  final String label;
  final List<String> rooms;
  final String building;
  final int number;
  final int v;

  Floor({
    required this.id,
    required this.label,
    required this.rooms,
    required this.building,
    required this.number,
    required this.v,
  });

  factory Floor.fromJson(Map<String, dynamic> json) {
    return Floor(
      id: json['_id'] ?? '',
      label: json['label'] ?? '',
      rooms: json['rooms'] != null ? List<String>.from(json['rooms']) : [],
      building: json['building'] ?? '',
      number: (json['number'] as num?)?.toInt() ?? 0,
      v: json['__v'] ?? 0,
    );
  }

  factory Floor.empty() => Floor(
    id: '', label: '', rooms: [], building: '', number: 0, v: 0,
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'label': label,
    'rooms': rooms,
    'building': building,
    'number': number,
    '__v': v,
  };
}

// ================== Sensor Model ==================
class Sensor {
  final String name;
  final String unit;
  final double minThreshold;
  final double maxThreshold;
  final String id;

  Sensor({
    required this.name,
    required this.unit,
    required this.minThreshold,
    required this.maxThreshold,
    required this.id,
  });

  factory Sensor.fromJson(Map<String, dynamic> json) {
    return Sensor(
      name: json['name'] ?? '',
      unit: json['unit'] ?? '',
      minThreshold: (json['minThreshold'] as num?)?.toDouble() ?? 0.0,
      maxThreshold: (json['maxThreshold'] as num?)?.toDouble() ?? 0.0,
      id: json['_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'unit': unit,
    'minThreshold': minThreshold,
    'maxThreshold': maxThreshold,
    '_id': id,
  };

  String get displayName => name.split('-')
      .map((e) => e.isNotEmpty ? e[0].toUpperCase() + e.substring(1) : '')
      .join(' ');
}

// ================== Extension (Good) ==================
extension DeviceExtension on Device {
  bool get isOnline => status.toLowerCase() == 'online';
  bool get isOffline => status.toLowerCase() == 'offline';

  String get formattedOfflineThreshold {
    final minutes = offlineThreshold / 60000;
    return '${minutes.toInt()} minutes';
  }

  List<Sensor> getSensorsByType(String type) {
    return sensors.where((sensor) => sensor.name.toLowerCase().contains(type.toLowerCase())).toList();
  }

  String get fullAddress {
    final loc = building.locations;
    return '${loc.address}, ${loc.city}, ${loc.state}, ${loc.country} ${loc.postalCode}';
  }
}