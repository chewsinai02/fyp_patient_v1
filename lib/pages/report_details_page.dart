import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';

class ReportDetailsPage extends StatelessWidget {
  final int reportId;

  const ReportDetailsPage({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Report Details',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.black),
            onPressed: () => _downloadReport(context),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: DatabaseService.instance.getReportDetails(reportId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Could not load report details',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final report = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildReportHeader(report),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDoctorInfo(report),
                      const SizedBox(height: 16),
                      _buildVitalSigns(report),
                      const SizedBox(height: 16),
                      _buildDiagnosisSection(report),
                      const SizedBox(height: 16),
                      _buildTreatmentSection(report),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportHeader(Map<String, dynamic> report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report['title'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMMM d, yyyy').format(
                  DateTime.parse(report['report_date'].toString()),
                ),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: report['status'] == 'completed'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  report['status'].toString().toUpperCase(),
                  style: TextStyle(
                    color: report['status'] == 'completed'
                        ? Colors.green
                        : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorInfo(Map<String, dynamic> report) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report['doctor_name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Attending Physician',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSigns(Map<String, dynamic> report) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vital Signs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildVitalSignCard(
                    'Height',
                    report['height'] ?? 'N/A',
                    'cm',
                    Icons.height,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildVitalSignCard(
                    'Weight',
                    report['weight'] ?? 'N/A',
                    'kg',
                    Icons.monitor_weight_outlined,
                    Colors.indigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildVitalSignCard(
                    'Blood Pressure',
                    report['blood_pressure'],
                    'mmHg',
                    Icons.favorite,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildVitalSignCard(
                    'Heart Rate',
                    report['heart_rate'],
                    'bpm',
                    Icons.timeline,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildVitalSignCard(
                    'Temperature',
                    report['temperature'],
                    '°C',
                    Icons.thermostat,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildVitalSignCard(
                    'Respiratory Rate',
                    report['respiratory_rate'],
                    '/min',
                    Icons.air,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSignCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$value $unit',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisSection(Map<String, dynamic> report) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.medical_information,
                  color: Colors.deepPurple,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Diagnosis & Symptoms',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDiagnosisCard(
                'Diagnosis', report['diagnosis'], Icons.local_hospital),
            const SizedBox(height: 12),
            _buildDiagnosisCard('Symptoms', report['symptoms'], Icons.sick),
            if (report['lab_results'] != 'No lab results') ...[
              const SizedBox(height: 12),
              _buildDiagnosisCard(
                  'Lab Results', report['lab_results'], Icons.science),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisCard(String title, String content, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentSection(Map<String, dynamic> report) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.healing,
                  color: Colors.green,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Treatment Plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTreatmentCard(
              title: 'Treatment Instructions',
              content: report['treatment_plan'],
              icon: Icons.assignment,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildMedicationsCard(report['medications']),
            const SizedBox(height: 12),
            _buildFollowUpCard(report),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsCard(String medications) {
    final medicationsList =
        medications.split(',').map((med) => med.trim()).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.medication,
                size: 18,
                color: Colors.orange,
              ),
              SizedBox(width: 8),
              Text(
                'Medications',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...medicationsList.map((med) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 8,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        med,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFollowUpCard(Map<String, dynamic> report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.event_available,
              color: Colors.teal,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Follow-up Appointment',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scheduled for ${DateFormat('MMMM d, yyyy').format(
                    DateTime.parse(report['report_date'].toString()),
                  )}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadReport(BuildContext context) async {
    try {
      final report = await DatabaseService.instance.getReportDetails(reportId);
      if (report == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Report data not found')),
          );
        }
        return;
      }

      // Create PDF document
      final pdf = pw.Document();

      // Helper function to handle null or empty values
      String safeString(dynamic value, [String defaultValue = 'Not recorded']) {
        if (value == null) return defaultValue;
        if (value.toString().isEmpty) return defaultValue;
        return value.toString();
      }

      // Convert report data to safe strings
      final safeReport = {
        ...report,
        'height': safeString(report['height']),
        'weight': safeString(report['weight']),
        'blood_pressure': safeString(report['blood_pressure']),
        'heart_rate': safeString(report['heart_rate']),
        'temperature': safeString(report['temperature']),
        'respiratory_rate': safeString(report['respiratory_rate']),
        'diagnosis': safeString(report['diagnosis']),
        'symptoms': safeString(report['symptoms']),
        'treatment_plan': safeString(report['treatment_plan']),
        'medications': safeString(report['medications']),
        'lab_results': safeString(report['lab_results']),
        'examination_findings': safeString(report['examination_findings']),
        'follow_up_instructions': safeString(report['follow_up_instructions']),
      };

      // Add pages to the PDF with safe data
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            _buildPdfHeader(safeReport),
            _buildPdfDoctorInfo(safeReport),
            _buildPdfVitalSigns(safeReport),
            _buildPdfDiagnosis(safeReport),
            _buildPdfTreatment(safeReport),
          ],
        ),
      );

      // Get the directory for saving the file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'medical_report_${safeReport['id']}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');

      // Save the PDF
      await file.writeAsBytes(await pdf.save());

      // Show success message with file path
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved: ${file.path}'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () async {
                try {
                  await OpenFile.open(file.path);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error opening file: $e')),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error generating PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  pw.Widget _buildPdfHeader(Map<String, dynamic> report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'MEDICAL REPORT',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            report['title'],
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Date: ${DateFormat('MMMM d, yyyy').format(DateTime.parse(report['report_date'].toString()))}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          if (report['description'] != null) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Description:',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Text(
              report['description'],
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildPdfDoctorInfo(Map<String, dynamic> report) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ATTENDING PHYSICIAN',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Dr. ${report['doctor_name']}',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfVitalSigns(Map<String, dynamic> report) {
    String formatMeasurement(String value, String unit) {
      return value == 'Not recorded' ? value : '$value $unit';
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'VITAL SIGNS',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      'Height: ${formatMeasurement(report['height'], 'cm')}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      'Weight: ${formatMeasurement(report['weight'], 'kg')}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      'Blood Pressure: ${report['blood_pressure']}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      'Heart Rate: ${formatMeasurement(report['heart_rate'], 'bpm')}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Text(
                    'Temperature: ${formatMeasurement(report['temperature'], '°C')}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Respiratory Rate: ${formatMeasurement(report['respiratory_rate'], '/min')}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfDiagnosis(Map<String, dynamic> report) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DIAGNOSIS & EXAMINATION',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Diagnosis:',
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(report['diagnosis'], style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.Text('Symptoms:',
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(report['symptoms'], style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.Text('Examination Findings:',
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(report['examination_findings'],
              style: const pw.TextStyle(fontSize: 10)),
          if (report['lab_results'] != null) ...[
            pw.SizedBox(height: 8),
            pw.Text('Lab Results:',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.Text(report['lab_results'],
                style: const pw.TextStyle(fontSize: 10)),
          ],
          if (report['notes'] != null) ...[
            pw.SizedBox(height: 8),
            pw.Text('Additional Notes:',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.Text(report['notes'], style: const pw.TextStyle(fontSize: 10)),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildPdfTreatment(Map<String, dynamic> report) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TREATMENT PLAN',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Treatment:',
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(report['treatment_plan'],
              style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.Text('Medications:',
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(report['medications'],
              style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.Text('Follow-up Instructions:',
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(report['follow_up_instructions'] ?? 'None provided',
              style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.Text(
            'Follow-up Date: ${DateFormat('MMMM d, yyyy').format(DateTime.parse(report['follow_up_date']?.toString() ?? report['report_date'].toString()))}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
