import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mic_selector/flutter_mic_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mic Selector',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MicSelectorExamplePage(),
    );
  }
}

class MicSelectorExamplePage extends StatefulWidget {
  const MicSelectorExamplePage({super.key});

  @override
  State<MicSelectorExamplePage> createState() => _MicSelectorExamplePageState();
}

class _MicSelectorExamplePageState extends State<MicSelectorExamplePage> {
  final _micSelector = FlutterMicSelector.instance;
  final _audioRecorder = AudioRecorder();

  List<MicrophoneDevice> _microphones = [];
  MicrophoneDevice? _selectedMicrophone;
  bool _isLoading = false;
  bool _isRecording = false;
  String? _outputPath;
  String? _errorMessage;
  bool _micPermission = false;

  StreamSubscription<List<MicrophoneDevice>>? _deviceSubscription;

  @override
  void initState() {
    super.initState();
    _deviceSubscription = _micSelector.microphoneDevicesChanged.listen(
      _onDevicesChanged,
    );
    _checkPermission();
  }

  @override
  void dispose() {
    _deviceSubscription?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.microphone.status;
    setState(() => _micPermission = status.isGranted);
  }

  Future<void> _requestPermission() async {
    final status = await Permission.microphone.request();
    setState(() => _micPermission = status.isGranted);
  }

  Future<void> _loadMicrophones() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final devices = await _micSelector.getAvailableMicrophones();
      final selected = await _micSelector.getSelectedMicrophone();
      setState(() {
        _microphones = devices;
        _selectedMicrophone = selected;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectMicrophone(MicrophoneDevice device) async {
    try {
      await _micSelector.selectMicrophone(device);
      setState(() {
        _selectedMicrophone = device;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  Future<void> _clearSelection() async {
    try {
      await _micSelector.clearSelectedMicrophone();
      setState(() {
        _selectedMicrophone = null;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  Future<void> _startRecording() async {
    if (!await _micSelector.hasPermission()) {
      setState(() => _errorMessage = 'RECORD_AUDIO permission is required.');
      return;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      setState(() {
        _isRecording = true;
        _outputPath = path;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Recording failed: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        if (path != null) _outputPath = path;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Stop failed: $e');
    }
  }

  void _onDevicesChanged(List<MicrophoneDevice> devices) {
    if (!mounted) return;
    setState(() {
      _microphones = devices;
      // Clear selection if selected device disappeared
      if (_selectedMicrophone != null &&
          !devices.any((d) => d.id == _selectedMicrophone!.id)) {
        _selectedMicrophone = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mic Selector')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PermissionSection(
              granted: _micPermission,
              onRequest: _requestPermission,
            ),
            const SizedBox(height: 16),
            _DeviceSection(
              microphones: _microphones,
              selectedMicrophone: _selectedMicrophone,
              isLoading: _isLoading,
              onLoad: _loadMicrophones,
              onSelect: _selectMicrophone,
              onClear: _clearSelection,
            ),
            if (_selectedMicrophone != null) ...[
              const SizedBox(height: 16),
              _SelectedDeviceCard(device: _selectedMicrophone!),
            ],
            const SizedBox(height: 16),
            _RecordingSection(
              isRecording: _isRecording,
              outputPath: _outputPath,
              onStart: _startRecording,
              onStop: _stopRecording,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _ErrorCard(message: _errorMessage!),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Permission section
// ---------------------------------------------------------------------------

class _PermissionSection extends StatelessWidget {
  const _PermissionSection({required this.granted, required this.onRequest});

  final bool granted;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              granted ? Icons.check_circle : Icons.warning,
              color: granted ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                granted
                    ? 'Microphone permission granted'
                    : 'Microphone permission required',
              ),
            ),
            if (!granted)
              FilledButton.tonal(
                onPressed: onRequest,
                child: const Text('Grant'),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Device section
// ---------------------------------------------------------------------------

class _DeviceSection extends StatelessWidget {
  const _DeviceSection({
    required this.microphones,
    required this.selectedMicrophone,
    required this.isLoading,
    required this.onLoad,
    required this.onSelect,
    required this.onClear,
  });

  final List<MicrophoneDevice> microphones;
  final MicrophoneDevice? selectedMicrophone;
  final bool isLoading;
  final VoidCallback onLoad;
  final void Function(MicrophoneDevice) onSelect;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Microphones',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (selectedMicrophone != null)
                  TextButton(onPressed: onClear, child: const Text('Clear')),
                IconButton(
                  onPressed: isLoading ? null : onLoad,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (microphones.isEmpty)
              const Text(
                'No microphones found. Tap refresh to scan.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...microphones.map((device) {
                final isSelected = device.id == selectedMicrophone?.id;
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(device.name),
                  subtitle: Text(device.type.label),
                  onTap: () => onSelect(device),
                  contentPadding: EdgeInsets.zero,
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Selected device info card
// ---------------------------------------------------------------------------

class _SelectedDeviceCard extends StatelessWidget {
  const _SelectedDeviceCard({required this.device});

  final MicrophoneDevice device;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selected Microphone',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _InfoRow(label: 'Name', value: device.name),
            _InfoRow(label: 'Type', value: device.type.label),
            _InfoRow(label: 'Device ID', value: device.id),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recording section
// ---------------------------------------------------------------------------

class _RecordingSection extends StatelessWidget {
  const _RecordingSection({
    required this.isRecording,
    required this.outputPath,
    required this.onStart,
    required this.onStop,
  });

  final bool isRecording;
  final String? outputPath;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isRecording ? Icons.mic : Icons.mic_none,
                  color: isRecording ? Colors.red : null,
                ),
                const SizedBox(width: 8),
                Text(
                  isRecording ? 'Recording...' : 'Audio Recording',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: isRecording ? null : onStart,
                  icon: const Icon(Icons.fiber_manual_record),
                  label: const Text('Record'),
                  style: FilledButton.styleFrom(
                    backgroundColor: isRecording ? null : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: isRecording ? onStop : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ],
            ),
            if (outputPath != null) ...[
              const SizedBox(height: 8),
              Text(
                'File: $outputPath',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error card
// ---------------------------------------------------------------------------

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
