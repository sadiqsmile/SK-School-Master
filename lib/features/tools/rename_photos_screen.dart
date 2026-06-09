import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class RenamePhotosScreen extends StatelessWidget {
  const RenamePhotosScreen({super.key});

  static const _sampleCsv = 'Old File Name,Admission No\n'
      'IMG_001.jpg,2023001\n'
      'IMG_002.jpg,2023002\n'
      'IMG_003.jpg,2023003\n';

  static const _pythonScript = r'''import os
import csv

folder_path = input("Enter your photo folder path: ")
csv_file = input("Enter CSV file path: ")

with open(csv_file, newline='') as file:
    reader = csv.DictReader(file)

    for row in reader:
        old_name = os.path.join(folder_path, row['Old File Name'])
        new_name = os.path.join(folder_path, row['Admission No'] + ".jpg")

        if os.path.exists(old_name):
            os.rename(old_name, new_name)
            print(f"Renamed: {old_name} → {new_name}")
        else:
            print(f"File not found: {old_name}")

print("Done!")
''';

  Future<void> _downloadSampleCsv(BuildContext context) async {
    final bytes = Uint8List.fromList(_sampleCsv.codeUnits);
    final path = await FilePicker.platform.saveFile(
      fileName: 'rename_sample.csv',
      bytes: bytes,
    );
    if (path != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sample CSV saved')),
      );
    }
  }

  Future<void> _downloadPythonScript(BuildContext context) async {
    final bytes = Uint8List.fromList(_pythonScript.codeUnits);
    final path = await FilePicker.platform.saveFile(
      fileName: 'rename_photos.py',
      bytes: bytes,
    );
    if (path != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Python script saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rename Photos Tool'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Bulk Rename Student Photos',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Rename your photo files to match Admission Numbers '
              'before uploading them to the system.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // Warning banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange.shade800, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Photos must be renamed BEFORE uploading.\n'
                      'The system matches photos using Admission Number.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Steps
            _StepCard(
              number: '1',
              title: 'Prepare Excel / CSV File',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Create a file with 2 columns:'),
                  const SizedBox(height: 8),
                  _CodeBlock(
                    text: 'Old File Name  |  Admission No\n'
                        'IMG_001.jpg    |  2023001\n'
                        'IMG_002.jpg    |  2023002',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _StepCard(
              number: '2',
              title: 'Save as CSV',
              content: const Text(
                'File → Save As → CSV (Comma delimited) .csv',
              ),
            ),
            const SizedBox(height: 12),
            _StepCard(
              number: '3',
              title: 'Run the Python Script',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Download the script below and run it in a terminal:',
                  ),
                  const SizedBox(height: 8),
                  _CodeBlock(text: 'python rename_photos.py'),
                  const SizedBox(height: 8),
                  const Text(
                    'The script will ask for your photo folder path and '
                    'the CSV file path, then rename all matching files.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _StepCard(
              number: '4',
              title: 'Upload Photos',
              content: const Text(
                'Go to Students → ⋮ menu → Upload Photos and select '
                'all renamed files at once.',
              ),
            ),
            const SizedBox(height: 28),

            // Rules
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Important Rules',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...[
                    'File names must match the Admission Number exactly',
                    'Use .jpg format only',
                    'Admission number must exist in the system',
                    'No duplicate file names',
                  ].map(
                    (rule) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(child: Text(rule)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Download buttons
            Text(
              'Downloads',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('Sample CSV'),
                    onPressed: () => _downloadSampleCsv(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.code),
                    label: const Text('Python Script'),
                    onPressed: () => _downloadPythonScript(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final Widget content;

  const _StepCard({
    required this.number,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                content,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String text;
  const _CodeBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: Color(0xFFCDD6F4),
          height: 1.6,
        ),
      ),
    );
  }
}
