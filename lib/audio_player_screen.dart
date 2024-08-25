import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io'; // Import dart:io for File

class AudioPlayerScreen extends StatefulWidget {
  final String audioPath;

  AudioPlayerScreen({required this.audioPath});

  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isSliding = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        _totalDuration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      if (!_isSliding) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (state == PlayerState.completed) {
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        });
      }
    });
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play(DeviceFileSource(widget.audioPath));
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _seekTo(Duration position) {
    _audioPlayer.seek(position);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String audioTitle = widget.audioPath.split('/').last; // Extract title from path

    return Scaffold(
      appBar: AppBar(
        title: Text('Audio Player'),
        centerTitle: true,
        backgroundColor: Color(0xFF808080),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              size: 100,
              color: Colors.blueGrey,
            ),
            SizedBox(height: 20),
            Text(
              audioTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Slider(
              value: _currentPosition.inSeconds.toDouble(),
              min: 0.0,
              max: _totalDuration.inSeconds.toDouble(),
              onChanged: (value) {
                setState(() {
                  _isSliding = true;
                  _currentPosition = Duration(seconds: value.toInt());
                });
              },
              onChangeEnd: (value) {
                setState(() {
                  _isSliding = false;
                });
                _seekTo(Duration(seconds: value.toInt()));
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _togglePlayPause,
              child: Text(_isPlaying ? 'Pause' : 'Play'),
            ),
          ],
        ),
      ),
    );
  }
}
