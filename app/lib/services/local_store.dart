import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/health_models.dart';
import 'veyro_protocol.dart';

class WatchSample {
  final int unix;
  final int hr;
  final int spo2;
  final int bps;
  final int bpd;
  final int hrv;
  final int steps;
  final bool fall;
  final int bat;

  WatchSample({
    required this.unix,
    this.hr = 0,
    this.spo2 = 0,
    this.bps = 0,
    this.bpd = 0,
    this.hrv = 0,
    this.steps = 0,
    this.fall = false,
    this.bat = 0,
  });

  DateTime get at => DateTime.fromMillisecondsSinceEpoch(unix * 1000, isUtc: true).toLocal();

  String toCsv() => '$unix,$hr,$spo2,$bps,$bpd,$hrv,$steps,${fall ? 1 : 0},$bat';

  static WatchSample? parseCsv(String line) {
    final p = line.trim().split(',');
    if (p.length < 8) return null;
    return WatchSample(
      unix: int.tryParse(p[0]) ?? 0,
      hr: int.tryParse(p[1]) ?? 0,
      spo2: int.tryParse(p[2]) ?? 0,
      bps: int.tryParse(p[3]) ?? 0,
      bpd: int.tryParse(p[4]) ?? 0,
      hrv: int.tryParse(p[5]) ?? 0,
      steps: int.tryParse(p[6]) ?? 0,
      fall: p[7] == '1',
      bat: p.length > 8 ? int.tryParse(p[8]) ?? 0 : 0,
    );
  }
}

/// Everything stays on this phone. Nothing is uploaded.
class LocalStore {
  static Future<Directory> _root() async {
    final dir = await getApplicationSupportDirectory();
    final root = Directory('${dir.path}/veyro');
    if (!await root.exists()) await root.create(recursive: true);
    final days = Directory('${root.path}/days');
    if (!await days.exists()) await days.create(recursive: true);
    return root;
  }

  static Future<void> pruneOlderThanTwoMonths() async {
    if (kIsWeb) return;
    final cut = DateTime.now().subtract(const Duration(days: VeyroProtocol.retainDays));
    final root = await _root();
    final days = Directory('${root.path}/days');
    if (!await days.exists()) return;
    await for (final f in days.list()) {
      if (f is! File) continue;
      final name = f.uri.pathSegments.last;
      if (name.length < 8) continue;
      final y = int.tryParse(name.substring(0, 4));
      final m = int.tryParse(name.substring(4, 6));
      final d = int.tryParse(name.substring(6, 8));
      if (y == null || m == null || d == null) continue;
      final date = DateTime(y, m, d);
      if (date.isBefore(DateTime(cut.year, cut.month, cut.day))) {
        await f.delete();
      }
    }
  }

  static Future<void> ingestCsvRow(String row) async {
    final sample = WatchSample.parseCsv(row);
    if (sample == null || sample.unix <= 0) return;
    await ingestSample(sample);
  }

  static Future<void> ingestSample(WatchSample sample) async {
    if (kIsWeb) return;
    await pruneOlderThanTwoMonths();
    final t = sample.at;
    final name =
        '${t.year.toString().padLeft(4, '0')}${t.month.toString().padLeft(2, '0')}${t.day.toString().padLeft(2, '0')}.csv';
    final root = await _root();
    final file = File('${root.path}/days/$name');
    await file.writeAsString('${sample.toCsv()}\n', mode: FileMode.append);
  }

  static Future<List<WatchSample>> loadAll() async {
    if (kIsWeb) return [];
    await pruneOlderThanTwoMonths();
    final root = await _root();
    final days = Directory('${root.path}/days');
    final samples = <WatchSample>[];
    if (!await days.exists()) return samples;
    final files = await days.list().where((e) => e is File).cast<File>().toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    for (final f in files) {
      final text = await f.readAsString();
      for (final line in text.split('\n')) {
        final s = WatchSample.parseCsv(line);
        if (s != null) samples.add(s);
      }
    }
    return samples;
  }

  static Future<UserProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('veyro_profile');
    if (raw == null) return UserProfile();
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfile(
        name: m['name'] ?? '',
        age: m['age'] ?? 16,
        weightKg: (m['weightKg'] ?? 70).toDouble(),
        heightCm: (m['heightCm'] ?? 170).toDouble(),
        gender: m['gender'] ?? 'male',
        language: m['language'] ?? 'en',
        emergencyContactName: m['emergencyName'],
        emergencyContactPhone: m['emergencyPhone'],
      );
    } catch (_) {
      return UserProfile();
    }
  }

  static Future<void> saveProfile(UserProfile p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'veyro_profile',
      jsonEncode({
        'name': p.name,
        'age': p.age,
        'weightKg': p.weightKg,
        'heightCm': p.heightCm,
        'gender': p.gender,
        'language': p.language,
        'emergencyName': p.emergencyContactName,
        'emergencyPhone': p.emergencyContactPhone,
      }),
    );
  }

  static Future<List<EmergencyContact>> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('veyro_contacts');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => EmergencyContact.fromMap(Map<String, String>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveContacts(List<EmergencyContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'veyro_contacts',
      jsonEncode(contacts.map((c) => c.toMap()).toList()),
    );
  }
}
