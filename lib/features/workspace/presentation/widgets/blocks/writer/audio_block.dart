import 'dart:io';
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';

import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/audio_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/audio/audio_player_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/audio/audio_trimming_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/audio/audio_appearance_widget.dart';
import 'package:barruu/features/workspace/presentation/services/audio_file_service.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/utils/debouncer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as path;

/// Audio block widget for displaying audio files
/// Supports local audio files with playback controls
/// Extends BaseEditableBlock for consistent behavior.
class AudioBlock extends BaseEditableBlock {
  const AudioBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<AudioBlock> createState() => _AudioBlockState();
}

class _AudioBlockState extends BaseEditableBlockState<AudioBlock> {
  String _fileName = '';
  String _customTitle = '';
  String _caption = '';
  Color _backgroundColor = Colors.grey;
  double? _width;
  double? _height;
  late TextEditingController _titleController;
  late TextEditingController _captionController;
  late Debouncer _saveDebouncer;

  // Audio player state for trimming
  AudioPlayer? _audioPlayer;
  bool _isAudioInitialized = false;
  double _audioDuration = 0;

  @override
  Map<String, dynamic> getDefaultContent() => {
    'path': '',
    'customTitle': '',
    'caption': '',
    'fileName': '',
    'startTime': 0.0,
    'endTime': 0.0,
  };

  @override
  void initializeBlockSpecifics() {
    // Load styling properties from block style
    final styleUtils = ref.read(styleUtilsProvider);
    _width = widget.block.style.width;
    _height = widget.block.style.height;
    _backgroundColor =
        styleUtils.parseHex(widget.block.style.background) ?? Colors.grey;

    // Ensure startTime and endTime exist in content
    content['startTime'] = content['startTime'] ?? 0.0;
    content['endTime'] = content['endTime'] ?? 0.0;

    // Extract file name
    try {
      final relativePath = content['path'] as String;
      final absolutePath = relativePath.isNotEmpty
          ? '${widget.docDir.path}/$relativePath'
          : '';
      final file = File(absolutePath);
      if (file.existsSync()) {
        _fileName = path.basename(file.path);
      } else {
        _fileName = path.basename(relativePath);
      }
      content['fileName'] = _fileName;
    } catch (e) {
      _fileName = 'Audio file';
      content['fileName'] = _fileName;
    }

    // Set title and caption
    _customTitle = content['customTitle']?.isNotEmpty == true
        ? content['customTitle']
        : '';
    _caption = content['caption'] ?? '';
    _titleController = TextEditingController(text: _customTitle);
    _captionController = TextEditingController(text: _caption);
    _saveDebouncer = Debouncer(delay: const Duration(milliseconds: 500));

    // Initialize audio player if path exists
    final audioPath = content['path'] as String? ?? '';
    if (audioPath.isNotEmpty) {
      _initializeAudioController();
    }
  }

  @override
  void disposeBlockSpecifics() {
    _saveDebouncer.dispose();
    _titleController.dispose();
    _captionController.dispose();
    _audioPlayer?.dispose();
  }

  @override
  void onContentChanged() {
    final customTitle = content['customTitle'] ?? '';
    if (_titleController.text != customTitle) {
      _titleController.text = customTitle;
    }
    if (_customTitle != customTitle) {
      _customTitle = customTitle;
    }

    final caption = content['caption'] ?? '';
    if (_captionController.text != caption) {
      _captionController.text = caption;
    }
    if (_caption != caption) {
      _caption = caption;
    }
  }

  void _saveAudioContent() {
    content['customTitle'] = _customTitle;
    content['caption'] = _caption;
    _saveDebouncer.call(() => saveContent());
  }

  Future<void> _initializeAudioController() async {
    if (!mounted) return;

    final relativePath = content['path'] as String? ?? '';
    if (relativePath.isEmpty) return;

    final absolutePath = '${widget.docDir.path}/$relativePath';
    final file = File(absolutePath);

    if (!file.existsSync()) {
      if (mounted) {
        setState(() {
          _isAudioInitialized = false;
          _audioDuration = 0;
        });
      }
      return;
    }

    try {
      // Dispose existing player if any
      if (_audioPlayer != null) {
        await _audioPlayer!.dispose();
        _audioPlayer = null;
      }

      _audioPlayer = AudioPlayer();

      // Add timeout to prevent indefinite hanging
      await _audioPlayer!
          .setFilePath(file.path)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Audio initialization timed out after 30 seconds',
              );
            },
          );

      if (!mounted) {
        _audioPlayer?.dispose();
        return;
      }

      final duration = _audioPlayer!.duration;
      if (duration != null) {
        setState(() {
          _isAudioInitialized = true;
          _audioDuration = duration.inMilliseconds / 1000.0;

          // Validate and fix trim times
          final startTime = content['startTime'] as double? ?? 0.0;
          final endTime = content['endTime'] as double? ?? 0.0;

          // If endTime is 0 or greater than duration, set it to duration
          if (endTime == 0.0 || endTime > _audioDuration) {
            content['endTime'] = _audioDuration;
          }

          // If startTime is invalid, reset to 0
          if (startTime < 0 || startTime >= _audioDuration) {
            content['startTime'] = 0.0;
          }

          // Ensure startTime < endTime
          if ((content['startTime'] as double) >=
              (content['endTime'] as double)) {
            content['startTime'] = 0.0;
            content['endTime'] = _audioDuration;
          }

          _saveAudioContent();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAudioInitialized = false;
          _audioDuration = 0;
        });
        showError('Error loading audio: ${e.toString()}');
      }
    }
  }

  /// Handles audio file selection and upload using the AudioFileService
  Future<void> _changeAudio() async {
    // Show dialog to choose between recording and file selection
    await AudioFileService.showAudioSourceDialog(
      context: context,
      onRecordAudio: _recordAudio,
      onFileSelected: _selectAudioFile,
    );
  }

  /// Processes audio result and updates the block content
  Future<void> _processAudioResult(Map<String, dynamic>? result) async {
    if (result != null && mounted) {
      setState(() {
        content['path'] = result['path'];
        content['fileName'] = result['fileName'];
        _fileName = result['fileName'];
        content['startTime'] = 0.0;
        content['endTime'] = result['duration'] ?? 0.0;
      });
      _saveAudioContent();

      // Initialize audio controller to get duration
      await _initializeAudioController();
    }
  }

  /// Handles audio recording
  Future<void> _recordAudio() async {
    final result = await AudioFileService.recordAndSaveAudio(
      context: context,
      ref: ref,
      docDir: widget.docDir,
      currentContent: content,
      currentBlock: widget.block,
      showSuccess: showSuccess,
      showError: showError,
    );
    await _processAudioResult(result);
  }

  /// Handles audio file selection from device
  Future<void> _selectAudioFile() async {
    final result = await AudioFileService.selectAndUploadAudioFile(
      context: context,
      ref: ref,
      docDir: widget.docDir,
      currentContent: content,
      currentBlock: widget.block,
      showSuccess: showSuccess,
      showError: showError,
    );
    await _processAudioResult(result);
  }

  void _updateStyle() {
    final controller = ref.read(
      editDocumentControllerProvider(widget.docDir).notifier,
    );
    final styleUtils = ref.read(styleUtilsProvider);

    // Convert Color to hex string
    final String hexColor = styleUtils.toHex(_backgroundColor);

    // Update the block's style with the new values
    final updatedStyle = widget.block.style.copyWith(
      width: _width,
      height: _height,
      background: hexColor,
    );

    final updatedBlock = widget.block.copyWith(style: updatedStyle);
    controller.saveBlock(updatedBlock);
  }

  @override
  Widget buildReader(BuildContext context) {
    return AudioReaderBlock(block: widget.block, docDir: widget.docDir);
  }

  @override
  Widget buildEditor(BuildContext context) {
    final relativePath = content['path'] as String? ?? '';
    final absolutePath = relativePath.isNotEmpty
        ? '${widget.docDir.path}/$relativePath'
        : '';

    return Column(
      children: [
        Toolbar(block: widget.block, docDir: widget.docDir),
        _buildEditor(ref: ref, audioPath: absolutePath),
      ],
    );
  }

  Widget _buildEditor({required WidgetRef ref, required String audioPath}) {
    final theme = Theme.of(context);
    final styleUtils = ref.read(styleUtilsProvider);
    final color =
        styleUtils.parseHex(widget.block.style.color) ??
        theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.audio_file, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _fileName.isEmpty
                        ? 'No audio selected'
                        : 'Audio: $_fileName',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _fileName.isEmpty ? Colors.grey : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ElevatedButton.icon(
                  icon: Icon(
                    _fileName.isEmpty ? Icons.add : Icons.change_circle,
                  ),
                  label: Text(_fileName.isEmpty ? 'Select Audio' : 'Change'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  onPressed: _changeAudio,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Audio Player Widget - maintains state during edits
            AudioPlayerWidget(audioPath: audioPath),

            // Audio trimming controls
            if (_isAudioInitialized &&
                _audioDuration > 0 &&
                _audioPlayer != null) ...[
              const SizedBox(height: 16),
              AudioTrimmingWidget(
                audioPlayer: _audioPlayer!,
                audioDuration: _audioDuration,
                content: content,
                block: widget.block,
                docDir: widget.docDir,
                onContentChanged: _saveAudioContent,
                onError: showError,
                onSuccess: showSuccess,
              ),
            ],
            const SizedBox(height: 16),

            // Title and caption editing (won't affect audio playback)
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter a custom title for this audio',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onChanged: (value) {
                setState(() {
                  _customTitle = value;
                  _saveAudioContent();
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Add a description or caption for this audio',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              maxLines: 1,
              onChanged: (value) {
                setState(() {
                  _caption = value;
                  _saveAudioContent();
                });
              },
            ),
            const SizedBox(height: 16),

            // Appearance controls
            AudioAppearanceWidget(
              width: _width,
              height: _height,
              onWidthChanged: (value) {
                setState(() {
                  _width = value;
                  _updateStyle();
                });
              },
              onHeightChanged: (value) {
                setState(() {
                  _height = value;
                  _updateStyle();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
