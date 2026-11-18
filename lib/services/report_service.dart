import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../db/app_database.dart';
import '../models.dart';

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Builds and shares a doctor-ready PDF report and CSV exports.
/// Files are written to the app's temporary directory and shared locally
/// via the system share sheet — nothing is uploaded anywhere.
class ReportService {
  ReportService._();
  static final ReportService instance = ReportService._();
  static const _disclaimer =
      'VitalKin is a personal health log, not a medical device. '
      'Readings are user-entered and are not a diagnosis. '
      'Please verify important values with a clinician.';

  Future<File> buildPdf(Member member) async {
    final db = AppDatabase.instance;
    final readings = await db.getReadings(member.id!);
    final medicines = await db.getMedicines(member.id!);
    final recent = readings.take(30).toList();

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Text('VitalKin — Health Report',
            style: pw.TextStyle(
                fontSize: 18, fontWeight: pw.FontWeight.bold)),
        footer: (context) => pw.Text(_disclaimer,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        build: (context) => [
          pw.SizedBox(height: 8),
          pw.Text('Member: ${member.name}',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Text('Age: ${member.age}  •  Relation: ${member.relation}'
              '${member.heightCm != null ? '  •  Height: ${member.heightCm!.toStringAsFixed(0)} cm' : ''}'),
          pw.Text('Generated: ${_fmtDate(DateTime.now())}'),
          pw.SizedBox(height: 16),
          pw.Text('Medicines',
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold)),
          if (medicines.isEmpty)
            pw.Text('No medicines recorded.')
          else
            ...medicines.map((m) => pw.Text(
                '• ${m.name} — ${m.dose} at ${m.times.join(', ')}'
                '${m.note != null && m.note!.isNotEmpty ? ' (${m.note})' : ''}')),
          pw.SizedBox(height: 16),
          pw.Text('Recent readings (latest ${recent.length})',
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold)),
          if (recent.isEmpty)
            pw.Text('No readings recorded yet.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Type', 'Value', 'Note'],
              data: recent
                  .map((r) => [
                        _fmtDate(r.timestamp),
                        r.type.toUpperCase(),
                        r.displayValue,
                        r.note ?? '',
                      ])
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 10),
            ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/vitalkin-${member.name.replaceAll(' ', '_')}-report.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  Future<void> sharePdf(Member member) async {
    final file = await buildPdf(member);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Health report for ${member.name}'),
    );
  }

  Future<File> buildCsv(Member member) async {
    final readings = await AppDatabase.instance.getReadings(member.id!);
    final rows = <List<dynamic>>[
      ['date', 'type', 'value1', 'value2', 'sugar_type', 'note'],
      ...readings.map((r) => [
            r.timestamp.toIso8601String(),
            r.type,
            r.value1,
            r.value2 ?? '',
            r.sugarType ?? '',
            r.note ?? '',
          ]),
    ];
    final csvText = csv.encode(rows);
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/vitalkin-${member.name.replaceAll(' ', '_')}-readings.csv');
    await file.writeAsString(csvText);
    return file;
  }

  Future<void> shareCsv(Member member) async {
    final file = await buildCsv(member);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Readings for ${member.name}'),
    );
  }
}
