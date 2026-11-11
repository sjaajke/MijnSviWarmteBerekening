// IEC TR 60890:2022 – Enclosure data models

enum InstallationType {
  freeStandingSingle,   // 1 – vrijstaand, enkelvoudig
  freeStandingMulti,    // 2 – vrijstaand, meervoudig
  wallMountedSingle,    // 3 – wandmontage, enkelvoudig
  wallMountedMulti,     // 4 – wandmontage, meervoudig
  builtIn,              // 5 – ingebouwd
}

extension InstallationTypeLabel on InstallationType {
  String get label => switch (this) {
        InstallationType.freeStandingSingle => 'Vrijstaand — enkelvoudig',
        InstallationType.freeStandingMulti => 'Vrijstaand — meervoudig',
        InstallationType.wallMountedSingle => 'Wandmontage — enkelvoudig',
        InstallationType.wallMountedMulti => 'Wandmontage — meervoudig',
        InstallationType.builtIn => 'Ingebouwd',
      };
}

enum VentilationType { none, natural }

extension VentilationTypeLabel on VentilationType {
  String get label => switch (this) {
        VentilationType.none => 'Geen ventilatie',
        VentilationType.natural => 'Natuurlijke ventilatie',
      };
}

enum SolarRadiation { none, light, dark }

extension SolarRadiationLabel on SolarRadiation {
  String get label => switch (this) {
        SolarRadiation.none => 'Geen',
        SolarRadiation.light => 'Licht oppervlak (+10 K)',
        SolarRadiation.dark => 'Donker oppervlak (+25 K)',
      };

  double get deltaT => switch (this) {
        SolarRadiation.none => 0.0,
        SolarRadiation.light => 10.0,
        SolarRadiation.dark => 25.0,
      };
}

class EnclosureInput {
  double heightMm;
  double widthMm;
  double depthMm;
  bool topExposed;
  bool frontExposed;
  bool rearExposed;
  bool leftExposed;
  bool rightExposed;
  InstallationType installationType;
  VentilationType ventilationType;
  double ventilationAreaCm2;
  int numPartitions;
  double ambientTemperatureC;
  SolarRadiation solarRadiation;

  EnclosureInput({
    this.heightMm = 950,
    this.widthMm = 1050,
    this.depthMm = 225,
    this.topExposed = true,
    this.frontExposed = true,
    this.rearExposed = false,
    this.leftExposed = true,
    this.rightExposed = true,
    this.installationType = InstallationType.wallMountedSingle,
    this.ventilationType = VentilationType.none,
    this.ventilationAreaCm2 = 0,
    this.numPartitions = 0,
    this.ambientTemperatureC = 35,
    this.solarRadiation = SolarRadiation.none,
  });

  Map<String, dynamic> toJson() => {
        'heightMm': heightMm,
        'widthMm': widthMm,
        'depthMm': depthMm,
        'topExposed': topExposed,
        'frontExposed': frontExposed,
        'rearExposed': rearExposed,
        'leftExposed': leftExposed,
        'rightExposed': rightExposed,
        'installationType': installationType.name,
        'ventilationType': ventilationType.name,
        'ventilationAreaCm2': ventilationAreaCm2,
        'numPartitions': numPartitions,
        'ambientTemperatureC': ambientTemperatureC,
        'solarRadiation': solarRadiation.name,
      };

  factory EnclosureInput.fromJson(Map<String, dynamic> j) => EnclosureInput(
        heightMm: (j['heightMm'] as num).toDouble(),
        widthMm: (j['widthMm'] as num).toDouble(),
        depthMm: (j['depthMm'] as num).toDouble(),
        topExposed: j['topExposed'] as bool? ?? true,
        frontExposed: j['frontExposed'] as bool? ?? true,
        rearExposed: j['rearExposed'] as bool? ?? false,
        leftExposed: j['leftExposed'] as bool? ?? true,
        rightExposed: j['rightExposed'] as bool? ?? true,
        installationType:
            InstallationType.values.byName(j['installationType'] as String),
        ventilationType:
            VentilationType.values.byName(j['ventilationType'] as String),
        ventilationAreaCm2:
            (j['ventilationAreaCm2'] as num?)?.toDouble() ?? 0,
        numPartitions: (j['numPartitions'] as num?)?.toInt() ?? 0,
        ambientTemperatureC: (j['ambientTemperatureC'] as num).toDouble(),
        solarRadiation: SolarRadiation.values
            .byName(j['solarRadiation'] as String? ?? 'none'),
      );

  /// Auto-set surface exposure based on installation type
  void applyInstallationDefaults() {
    switch (installationType) {
      case InstallationType.freeStandingSingle:
      case InstallationType.freeStandingMulti:
        rearExposed = true;
        leftExposed = true;
        rightExposed = true;
        topExposed = true;
      case InstallationType.wallMountedSingle:
        rearExposed = false;
        leftExposed = true;
        rightExposed = true;
        topExposed = true;
      case InstallationType.wallMountedMulti:
        rearExposed = false;
        leftExposed = false;
        rightExposed = false;
        topExposed = true;
      case InstallationType.builtIn:
        rearExposed = false;
        leftExposed = false;
        rightExposed = false;
        topExposed = false;
    }
  }
}
