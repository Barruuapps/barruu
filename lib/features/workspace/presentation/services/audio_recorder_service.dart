import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

/// Service for handling audio recording operations.
///
/// This service manages:
/// - Microphone permission requests
/// - Audio recording with visual feedback
/// - Recording duration tracking
/// - File storage and cleanup
///
/// The service ensures proper permission handling and
/// provides a user-friendly recording interface.
class AudioRecorderService {
  static const Uuid _uuid = Uuid();

  /// Requests microphone permission from the user.
  ///
  /// Shows appropriate dialogs if permission is denied or permanently denied.
  ///
  /// Returns true if permission is granted, false otherwise.
  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    final status = await Permission.microphone.status;
    
    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showPermissionDeniedDialog(context);
      }
      return false;
    }

    return false;
  }

  /// Shows a dialog informing the user that microphone permission is required.
  static Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission Required'),
        content: const Text(
          'To record audio, please grant microphone permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Records audio with a visual recording dialog.
  ///
  /// Shows a modal dialog with recording controls and duration display.
  /// User can stop recording or cancel.
  ///
  /// [context] is used for showing the recording dialog.
  /// [docDir] is the document directory where audio will be saved.
  ///
  /// Returns a map with 'path' and 'fileName' if successful, or null if cancelled.
  static Future<Map<String, dynamic>?> recordAudio({
    required BuildContext context,
    required Directory docDir,
  }) async {
    // Request permission first
    final hasPermission = await requestMicrophonePermission(context);
    if (!hasPermission) {
      return null;
    }

    // Create recorder instance
    final recorder = AudioRecorder();

    // Create audios directory if it doesn't exist
    final audiosDir = Directory('${docDir.path}/media/audios');
    if (!await audiosDir.exists()) {
      await audiosDir.create(recursive: true);
    }

    // Generate unique filename
    final uniqueName = '${_uuid.v4()}_recording.m4a';
    final filePath = '${audiosDir.path}/$uniqueName';

    // Start recording
    try {
      await recorder.start(
        const RecordConfig(
          
        ),
        path: filePath,
      );
    } catch (e) {
      await recorder.dispose();
      return null;
    }

    // Show recording dialog
    if (!context.mounted) {
      await recorder.stop();
      await recorder.dispose();
      return null;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _RecordingDialog(recorder: recorder),
    );

    // Clean up recorder
    await recorder.dispose();

    // If cancelled, delete the file
    if (result == null) {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      return null;
    }

    // Return the recorded file info
    return {
      'path': 'media/audios/$uniqueName',
      'fileName': uniqueName,
    };
  }
}

/// Dialog widget that displays recording UI with timer and controls.
class _RecordingDialog extends StatefulWidget {
  final AudioRecorder recorder;

  const _RecordingDialog({required this.recorder});

  @override
  State<_RecordingDialog> createState() => _RecordingDialogState();
}

class _RecordingDialogState extends State<_RecordingDialog> {
  int _recordingDuration = 0;
  bool _isRecording = true;
  bool _isStopping = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _stopRecording() async {
    if (_isStopping) return;
    
    _timer?.cancel();
    setState(() {
      _isStopping = true;
      _isRecording = false;
    });

    try {
      final path = await widget.recorder.stop();
      if (mounted && path != null) {
        Navigator.pop(context, {'success': true});
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
    });

    try {
      await widget.recorder.stop();
    } catch (e) {
      // Ignore errors when cancelling
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Recording Audio'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isRecording ? Icons.mic : Icons.mic_off,
              size: 48,
              color: _isRecording ? Colors.red : Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          
          // Duration display
          Text(
            _formatDuration(_recordingDuration),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          
          // Status text
          Text(
            _isStopping 
                ? 'Saving...' 
                : _isRecording 
                    ? 'Recording in progress...' 
                    : 'Recording stopped',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      actions: _isStopping
          ? null
          : [
              TextButton(
                onPressed: _cancelRecording,
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: _stopRecording,
                icon: const Icon(Icons.stop),
                label: const Text('Stop & Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ],
    );
  }
}
