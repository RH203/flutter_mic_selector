import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mic_selector/flutter_mic_selector.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mic Selector Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MicSelectorExamplePage(),
    );
  }
}

class MicSelectorExamplePage extends StatelessWidget {
  const MicSelectorExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mic Selector')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: _MicRoutingDemo(),
        ),
      ),
    );
  }
}

class _MicRoutingDemo extends StatelessWidget {
  const _MicRoutingDemo();

  @override
  Widget build(BuildContext context) {
    return MicSelectorBuilder(
      builder: (context, state, selector) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _SessionPanel(state: state, selector: selector),
            const SizedBox(height: 16),

            // VU meter — only shown while recording
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: state.isActive
                  ? _VuMeter(selector: selector, key: const ValueKey('vu'))
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
            if (state.isActive) const SizedBox(height: 16),

            MicSelectorDropdown(
              selector: selector,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Preferred app microphone',
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _DeviceList(state: state, selector: selector),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Session panel — status chip + control buttons
// ---------------------------------------------------------------------------

class _SessionPanel extends StatelessWidget {
  const _SessionPanel({required this.state, required this.selector});

  final MicSelectorState state;
  final MicSelector selector;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  state.isActive ? Icons.mic : Icons.mic_off,
                  color: state.isActive ? colors.primary : colors.outline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.selectedDevice?.name ?? 'System default microphone',
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(state.isActive ? 'Active' : 'Inactive'),
                  avatar: Icon(
                    state.isActive ? Icons.circle : Icons.circle_outlined,
                    size: 14,
                    color: state.isActive ? colors.primary : colors.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.icon(
                  onPressed:
                      state.isActive ? null : () => _start(context, selector),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      state.isActive ? () => _run(context, selector.stop) : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
                TextButton.icon(
                  onPressed: state.selectedDevice == null
                      ? null
                      : () => _run(context, selector.clearSelectedDevice),
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
                IconButton.outlined(
                  onPressed: () => _run(context, () async {
                    await selector.getDevices();
                  }),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh devices',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _start(BuildContext context, MicSelector selector) async {
    await _run(context, () async {
      final status = await selector.hasPermission();
      final granted = status == MicPermissionStatus.granted ||
          await selector.requestPermission() == MicPermissionStatus.granted;
      if (!granted) {
        throw const MicException(
          MicError(
            code: MicErrorCode.permissionDenied,
            message: 'RECORD_AUDIO permission was denied.',
          ),
        );
      }
      await selector.start();
    });
  }
}

// ---------------------------------------------------------------------------
// VU meter — visualises watchInputLevel() in real time
// ---------------------------------------------------------------------------

class _VuMeter extends StatefulWidget {
  const _VuMeter({required this.selector, super.key});

  final MicSelector selector;

  @override
  State<_VuMeter> createState() => _VuMeterState();
}

class _VuMeterState extends State<_VuMeter> {
  StreamSubscription<MicInputLevel>? _subscription;
  double _rms = 0;
  double _peak = 0;

  @override
  void initState() {
    super.initState();
    _subscription = widget.selector.watchInputLevel().listen((level) {
      if (mounted) {
        setState(() {
          _rms = level.rms;
          _peak = level.peak;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Input level',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 6),
        _LevelBar(
          label: 'RMS',
          value: _rms,
          color: colors.primary,
        ),
        const SizedBox(height: 4),
        _LevelBar(
          label: 'Peak',
          value: _peak,
          color: colors.tertiary,
        ),
      ],
    );
  }
}

class _LevelBar extends StatelessWidget {
  const _LevelBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;

  /// Normalised value between 0.0 and 1.0.
  final double value;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                _colorForLevel(value, color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${(value * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Color _colorForLevel(double v, Color base) {
    if (v > 0.85) return Colors.red.shade600;
    if (v > 0.6) return Colors.orange.shade600;
    return base;
  }
}

// ---------------------------------------------------------------------------
// Device list
// ---------------------------------------------------------------------------

class _DeviceList extends StatelessWidget {
  const _DeviceList({required this.state, required this.selector});

  final MicSelectorState state;
  final MicSelector selector;

  @override
  Widget build(BuildContext context) {
    if (state.devices.isEmpty) {
      return const Center(child: Text('No input devices found'));
    }
    return ListView.separated(
      itemCount: state.devices.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final device = state.devices[index];
        final selected = device.id == state.selectedDevice?.id;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(selected ? Icons.radio_button_checked : Icons.mic),
          title: Text(device.name),
          subtitle: Text(_deviceDetails(device)),
          trailing: FilledButton.tonalIcon(
            onPressed: selected
                ? null
                : () => _run(
                      context,
                      () => selector.selectDevice(device.id),
                    ),
            icon: Icon(selected ? Icons.check : Icons.swap_horiz),
            label: Text(selected ? 'Selected' : 'Use'),
          ),
          onTap: selected
              ? null
              : () => _run(
                    context,
                    () => selector.selectDevice(device.id),
                  ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

String _deviceDetails(MicInputDevice device) {
  final parts = <String>[
    device.effectiveTypeLabel,
    if (device.rawName != null && device.rawName != device.name)
      device.rawName!,
    if (device.address != null && device.address!.isNotEmpty) device.address!,
  ];
  return parts.join(' · ');
}

Future<void> _run(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } on MicException catch (error) {
    if (context.mounted) {
      _showMessage(context, error.error.message);
    }
  } catch (error) {
    if (context.mounted) {
      _showMessage(context, error.toString());
    }
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
