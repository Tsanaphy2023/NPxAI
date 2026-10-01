import 'spectral_signature.dart';

/// ตัวแทนข้อมูลตัวอย่างดินภาคสนาม (Soil Sample Record)
class SoilSample {
  final String id;
  final String plotName;
  final String cropType; // ทุเรียน, มังคุด, สละ, ลำไย, มะม่วง, นาข้าว, พืชไร่, พืชผักสวนครัว
  final String farmingType; // อินทรีย์, เคมี, อินทรีย์เคมี
  final double latitude;
  final double longitude;
  final DateTime measuredAt;
  final SpectralSignature? spectralSignature;
  final String notes;
  final String province;
  final String district;

  const SoilSample({
    required this.id,
    required this.plotName,
    required this.cropType,
    required this.farmingType,
    required this.latitude,
    required this.longitude,
    required this.measuredAt,
    this.spectralSignature,
    this.notes = '',
    this.province = 'จันทบุรี',
    this.district = 'อัตโนมัติ',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'plotName': plotName,
        'cropType': cropType,
        'farmingType': farmingType,
        'latitude': latitude,
        'longitude': longitude,
        'measuredAt': measuredAt.toIso8601String(),
        'spectralSignature': spectralSignature?.toJson(),
        'notes': notes,
        'province': province,
        'district': district,
      };

  factory SoilSample.fromJson(Map<String, dynamic> json) => SoilSample(
        id: json['id'] as String,
        plotName: json['plotName'] as String,
        cropType: json['cropType'] as String,
        farmingType: json['farmingType'] as String? ?? 'อินทรีย์เคมี',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        measuredAt: DateTime.parse(json['measuredAt'] as String),
        spectralSignature: json['spectralSignature'] != null
            ? SpectralSignature.fromJson(
                json['spectralSignature'] as Map<String, dynamic>)
            : null,
        notes: json['notes'] as String? ?? '',
        province: json['province'] as String? ?? 'จันทบุรี',
        district: json['district'] as String? ?? 'อัตโนมัติ',
      );
}
