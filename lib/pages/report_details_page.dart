import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';

class ReportDetailsPage extends StatelessWidget {
  final int reportId;

  const ReportDetailsPage({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    print('\n=== BUILDING REPORT DETAILS PAGE ===');
    print('Report ID: $reportId');

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
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: DatabaseService.instance.getReportDetails(reportId),
          builder: (context, snapshot) {
            print('FutureBuilder state: ${snapshot.connectionState}');
            print('Snapshot data: ${snapshot.data}');
            print('Snapshot error: ${snapshot.error}');

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              print('Error loading report details: ${snapshot.error}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            }

            final report = snapshot.data;
            if (report == null) {
              print('No report data found');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_off_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Report not found',
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

            print('Report data loaded successfully: $report');
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(context, report),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildPatientInfo(report),
                        const SizedBox(height: 16),
                        _buildVitalSigns(report),
                        const SizedBox(height: 16),
                        _buildClinicalInfo(report),
                        const SizedBox(height: 16),
                        _buildDiagnosisTreatment(report),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _downloadReport(context),
        icon: const Icon(Icons.download),
        label: const Text('Download PDF'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> report) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
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
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  report['title'],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Dr. ${report['doctor_name']}',
            style: const TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMMM d, yyyy').format(
              DateTime.parse(report['report_date'].toString()),
            ),
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfo(Map<String, dynamic> report) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Patient Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', report['patient_name']),
            _buildInfoRow('Gender', report['patient_gender']),
            _buildInfoRow('Contact', report['patient_contact']),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSigns(Map<String, dynamic> report) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            _buildInfoRow('Blood Pressure', '${report['blood_pressure']} mmHg'),
            _buildInfoRow('Heart Rate', '${report['heart_rate']} bpm'),
            _buildInfoRow('Temperature', '${report['temperature']}°C'),
            _buildInfoRow(
                'Respiratory Rate', '${report['respiratory_rate']} /min'),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalInfo(Map<String, dynamic> report) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Clinical Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Symptoms', report['symptoms']),
            if (report['lab_results'] != null)
              _buildInfoRow('Lab Results', report['lab_results']),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisTreatment(Map<String, dynamic> report) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Diagnosis & Treatment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Diagnosis', report['diagnosis']),
            _buildInfoRow('Treatment Plan', report['treatment_plan']),
            if (report['medications'] != null)
              _buildInfoRow('Medications', report['medications']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? 'N/A',
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _downloadReport(BuildContext context) {
    // TODO: Implement PDF download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading report...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
