import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
            title: const Text(
              'Audio Recorder',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.deepPurple),
        body: const AudioRecorderScreen(),
      ),
    );
  }
}

class AudioRecorderScreen extends StatefulWidget {
  const AudioRecorderScreen({super.key});

  @override
  AudioRecorderScreenState createState() => AudioRecorderScreenState();
}

class AudioRecorderScreenState extends State<AudioRecorderScreen> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _player.openPlayer();
  }

  Future<void> _initializeRecorder() async {
    // Request microphone permission at the start
    var status = await Permission.microphone.request();

    if (!mounted) {
      return; // Check if the widget is still mounted before using context
    }

    if (status.isGranted) {
      // Open the recorder in advance
      await _recorder.openRecorder();
    } else {
      // Show an alert if permission is denied
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Microphone permission is required to record audio.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startRecording() async {
    _filePath = '${Directory.systemTemp.path}/recorded_audio.aac';
    await _recorder.startRecorder(toFile: _filePath!);
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() => _isRecording = false);
  }

  Future<void> _playAudio() async {
    if (_filePath == null || !File(_filePath!).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No recording found. Please record first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _player.startPlayer(
        fromURI: _filePath!,
        whenFinished: () {
          setState(() => _isPlaying = false);
        });
    setState(() => _isPlaying = true);
  }

  Future<void> _stopAudio() async {
    await _player.stopPlayer();
    setState(() => _isPlaying = false);
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(), // Empty space to push elements to the center
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _isRecording ? _stopRecording : _startRecording,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  // color: _isRecording ? Colors.red : Colors.grey[300],
                  color: _isRecording ? Colors.red : Colors.purple[50],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: _isRecording ? Colors.white : Colors.black,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isRecording ? "Click to stop" : "Click to record",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _isPlaying ? _stopAudio : _playAudio,
                icon: Icon(
                  _isPlaying ? Icons.stop : Icons.play_arrow,
                  color: Colors.black,
                ),
                label: Text(
                  _isPlaying ? 'Stop Playback' : 'Play Recording',
                  style: const TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isPlaying ? Colors.red[50] : Colors.grey[300],
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
