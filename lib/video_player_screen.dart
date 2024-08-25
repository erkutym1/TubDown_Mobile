import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io'; // Import dart:io for File

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;

  VideoPlayerScreen({required this.videoPath});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isSliding = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {
          _totalDuration = _controller.value.duration;
        });
        _controller.addListener(() {
          if (!_isSliding) {
            setState(() {
              _currentPosition = _controller.value.position;
            });
          }
        });
        _controller.play(); // Start playing the video automatically
        setState(() {
          _isPlaying = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _seekTo(Duration position) {
    _controller.seekTo(position);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Player'),
        centerTitle: true,
        backgroundColor: Color(0xFF808080),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_controller.value.isInitialized)
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
          else
            Center(child: CircularProgressIndicator()),
          SizedBox(height: 20),
          if (_controller.value.isInitialized)
            Column(
              children: [
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
        ],
      ),
    );
  }
}
