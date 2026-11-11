// Component power loss model

class ComponentLoss {
  String description;
  int count;                    // Aantal stuks
  double powerLossW;            // Pv nominaal per stuk [W] — bij In
  double? nominalCurrentA;      // In [A] — nominale stroom apparaat
  double? designCurrentA;       // Ing [A] — ontwerpstroom stroomkring
  double? maxTemperatureC;      // Tmax [°C]
  double simultaneityFactor;    // Gelijktijdigheidsfactor RDF (0.0–1.0)
  // Conductor-specific (set when added from conductor library)
  double? crossSectionMm2;      // Doorsnede [mm²]
  double? ithMaxA;              // Ith max [A] — stroombelastbaarheid

  ComponentLoss({
    required this.description,
    required this.powerLossW,
    this.count = 1,
    this.nominalCurrentA,
    this.designCurrentA,
    this.maxTemperatureC,
    this.simultaneityFactor = 1.0,
    this.crossSectionMm2,
    this.ithMaxA,
  });

  /// Loading factor: (Ing/In)² when both currents known, else 1.0
  double get loadingFactor {
    final ing = designCurrentA;
    final inn = nominalCurrentA;
    if (ing != null && inn != null && inn > 0) {
      return (ing / inn) * (ing / inn);
    }
    return 1.0;
  }

  /// Pv per device at actual current = Pv_rated × (Ing/In)²
  double get pvPerDeviceActual => powerLossW * loadingFactor;

  /// Total effective power = Pv_actual × count × RDF
  double get effectivePowerW => pvPerDeviceActual * count * simultaneityFactor;

  /// Total nominal power (at In, count, no RDF)
  double get nominalTotalW => powerLossW * count;

  Map<String, dynamic> toJson() => {
        'description': description,
        'count': count,
        'powerLossW': powerLossW,
        'nominalCurrentA': nominalCurrentA,
        'designCurrentA': designCurrentA,
        'maxTemperatureC': maxTemperatureC,
        'simultaneityFactor': simultaneityFactor,
        'crossSectionMm2': crossSectionMm2,
        'ithMaxA': ithMaxA,
      };

  factory ComponentLoss.fromJson(Map<String, dynamic> j) => ComponentLoss(
        description: j['description'] as String,
        powerLossW: (j['powerLossW'] as num).toDouble(),
        count: (j['count'] as num?)?.toInt() ?? 1,
        nominalCurrentA: j['nominalCurrentA'] != null
            ? (j['nominalCurrentA'] as num).toDouble()
            : null,
        designCurrentA: j['designCurrentA'] != null
            ? (j['designCurrentA'] as num).toDouble()
            : null,
        maxTemperatureC: j['maxTemperatureC'] != null
            ? (j['maxTemperatureC'] as num).toDouble()
            : null,
        simultaneityFactor: j['simultaneityFactor'] != null
            ? (j['simultaneityFactor'] as num).toDouble()
            : 1.0,
        crossSectionMm2: j['crossSectionMm2'] != null
            ? (j['crossSectionMm2'] as num).toDouble()
            : null,
        ithMaxA: j['ithMaxA'] != null
            ? (j['ithMaxA'] as num).toDouble()
            : null,
      );

  static List<ComponentLoss> exampleComponents() => [
        ComponentLoss(
            description: 'MCB 3P 25A (PKZM)',
            powerLossW: 18.0,
            count: 1,
            nominalCurrentA: 25,
            designCurrentA: 20,
            maxTemperatureC: 70),
        ComponentLoss(
            description: 'RCBO 1P+N 16A',
            powerLossW: 6.5,
            count: 2,
            nominalCurrentA: 16,
            designCurrentA: 16,
            maxTemperatureC: 70),
        ComponentLoss(
            description: 'RCBO 1P+N 10A',
            powerLossW: 4.5,
            count: 1,
            nominalCurrentA: 10,
            designCurrentA: 8,
            maxTemperatureC: 70),
        ComponentLoss(description: 'Rijgklemmen', powerLossW: 0.6, count: 20),
        ComponentLoss(description: 'Kabels en bedrading', powerLossW: 80.0),
      ];
}
