import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/component.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------
class UserLibraryEntry {
  final String category;
  final String description;
  final double powerLossW;
  final double? nominalCurrentA;
  final double? maxTemperatureC;

  const UserLibraryEntry({
    required this.category,
    required this.description,
    required this.powerLossW,
    this.nominalCurrentA,
    this.maxTemperatureC,
  });

  ComponentLoss toComponent() => ComponentLoss(
        description: description,
        powerLossW: powerLossW,
        nominalCurrentA: nominalCurrentA,
        maxTemperatureC: maxTemperatureC,
      );

  Map<String, dynamic> toJson() => {
        'category': category,
        'description': description,
        'powerLossW': powerLossW,
        if (nominalCurrentA != null) 'nominalCurrentA': nominalCurrentA,
        if (maxTemperatureC != null) 'maxTemperatureC': maxTemperatureC,
      };

  factory UserLibraryEntry.fromJson(Map<String, dynamic> j) => UserLibraryEntry(
        category: j['category'] as String? ?? 'Eigen',
        description: j['description'] as String,
        powerLossW: (j['powerLossW'] as num).toDouble(),
        nominalCurrentA: j['nominalCurrentA'] != null
            ? (j['nominalCurrentA'] as num).toDouble()
            : null,
        maxTemperatureC: j['maxTemperatureC'] != null
            ? (j['maxTemperatureC'] as num).toDouble()
            : null,
      );
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------
class UserLibraryService extends ChangeNotifier {
  final List<UserLibraryEntry> _entries = [];

  List<UserLibraryEntry> get entries => List.unmodifiable(_entries);

  List<String> get categories =>
      _entries.map((e) => e.category).toSet().toList()..sort();

  List<UserLibraryEntry> byCategory(String category) =>
      _entries.where((e) => e.category == category).toList();

  List<UserLibraryEntry> search(String query) {
    final q = query.toLowerCase();
    return _entries
        .where((e) =>
            e.description.toLowerCase().contains(q) ||
            e.category.toLowerCase().contains(q))
        .toList();
  }

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/warmteberekening_user_library.json');
  }

  Future<void> load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as List;
        _entries.clear();
        _entries.addAll(
            data.map((e) => UserLibraryEntry.fromJson(e as Map<String, dynamic>)));
        notifyListeners();
      }
    } catch (_) {
      // Ignore corrupt file
    }
  }

  Future<void> add(UserLibraryEntry entry) async {
    _entries.add(entry);
    notifyListeners();
    await _save();
  }

  Future<void> remove(int index) async {
    _entries.removeAt(index);
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final f = await _file;
    await f.parent.create(recursive: true);
    await f.writeAsString(
        jsonEncode(_entries.map((e) => e.toJson()).toList()));
  }
}
