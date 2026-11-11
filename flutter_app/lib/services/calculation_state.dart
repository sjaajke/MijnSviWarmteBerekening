import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/enclosure.dart';
import '../models/component.dart';
import '../core/iec60890.dart';

class CalculationState extends ChangeNotifier {
  EnclosureInput enclosure = EnclosureInput();
  List<ComponentLoss> components = ComponentLoss.exampleComponents();

  CalculationResult? _result;
  CalculationResult? get result => _result;

  /// Nominaal vermogen — zonder gelijktijdigheid en zonder loading factor
  double get totalPowerNominal =>
      components.fold(0.0, (sum, c) => sum + c.nominalTotalW);

  /// Effectief vermogen = Pv × (Ing/In)² × aantal × RDF
  double get totalPower =>
      components.fold(0.0, (sum, c) => sum + c.effectivePowerW);

  /// Totale gelijktijdigheidsfactor = effectief / nominaal
  double get overallSimultaneityFactor {
    final nominal = totalPowerNominal;
    return nominal > 0 ? totalPower / nominal : 1.0;
  }

  CalculationState() {
    _recalculate();
  }

  void updateEnclosure(void Function(EnclosureInput) updater) {
    updater(enclosure);
    _recalculate();
  }

  void setInstallationType(InstallationType type) {
    enclosure.installationType = type;
    enclosure.applyInstallationDefaults();
    _recalculate();
  }

  void addComponent(ComponentLoss c) {
    components.add(c);
    _recalculate();
  }

  void removeComponent(int index) {
    components.removeAt(index);
    _recalculate();
  }

  void updateComponent(int index, ComponentLoss c) {
    components[index] = c;
    _recalculate();
  }

  // ── Serialisatie ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'version': 1,
        'enclosure': enclosure.toJson(),
        'components': components.map((c) => c.toJson()).toList(),
      };

  void _loadFromJson(Map<String, dynamic> j) {
    enclosure =
        EnclosureInput.fromJson(j['enclosure'] as Map<String, dynamic>);
    components = (j['components'] as List)
        .map((c) => ComponentLoss.fromJson(c as Map<String, dynamic>))
        .toList();
    _recalculate();
  }

  // ── Project opslaan ───────────────────────────────────────────────────────

  Future<void> saveProject() async {
    final json = const JsonEncoder.withIndent('  ').convert(toJson());
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/warmteberekening_project.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(json);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'IEC TR 60890 Warmteberekening project',
    );
  }

  // ── Project laden ─────────────────────────────────────────────────────────

  /// Returns null on success, or an error message string on failure.
  Future<String?> loadProject() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return null; // geannuleerd
      final path = result.files.single.path;
      if (path == null) return 'Geen bestandspad gevonden.';
      final content = await File(path).readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      _loadFromJson(json);
      return null; // succes
    } catch (e) {
      return 'Kan bestand niet laden: $e';
    }
  }

  void _recalculate() {
    _result = calculate(enclosure, totalPower);
    notifyListeners();
  }
}
