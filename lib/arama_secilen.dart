import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'video_player_screen.dart';
import 'audio_player_screen.dart';

class AramaSecilenPage extends StatefulWidget {
  final Video video;

  AramaSecilenPage({required this.video});

  @override
  _AramaSecilenPageState createState() => _AramaSecilenPageState();
}

class _AramaSecilenPageState extends State<AramaSecilenPage> {
  String _selectedFormat = 'Video';
  String? _selectedResolution;
  String? _selectedBitrate;
  List<String> _availableResolutions = [];
  List<String> _availableBitrates = [];
  late YoutubeExplode _youtubeExplode;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();
  bool _isDownloading = false;
  bool _showPlayButton = false;
  String? _downloadedFilePath;

  @override
  void initState() {
    super.initState();
    _youtubeExplode = YoutubeExplode();
    _initializeNotifications();
    _fetchAvailableResolutions();
    _fetchAvailableBitrates();
  }

  Future<void> _initializeNotifications() async {
    final AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _fetchAvailableResolutions() async {
    try {
      final manifest = await _youtubeExplode.videos.streamsClient.getManifest(widget.video.url);
      final videoStreams = manifest.videoOnly;
      setState(() {
        _availableResolutions = videoStreams.map((e) => e.videoQualityLabel).toSet().toList();
      });
    } catch (e) {
      print('Çözünürlükler alınırken bir hata oluştu: $e');
    }
  }

  Future<void> _fetchAvailableBitrates() async {
    try {
      final manifest = await _youtubeExplode.videos.streamsClient.getManifest(widget.video.url);
      final audioStreams = manifest.audioOnly;
      setState(() {
        _availableBitrates = audioStreams.map((e) => '${e.bitrate.kiloBitsPerSecond} kbps').toSet().toList();
      });
    } catch (e) {
      print('Bitrate’ler alınırken bir hata oluştu: $e');
    }
  }

  Future<void> _requestPermissions() async {
    await [Permission.storage].request();
  }

  Future<void> _downloadFile() async {
    setState(() {
      _isDownloading = true;
      _showPlayButton = false;
    });

    try {
      await _showNotification('Download Started', 'Downloading ${widget.video.title} as $_selectedFormat', 0);

      final url = widget.video.url;
      final filename = '${widget.video.title}_${DateTime.now().millisecondsSinceEpoch}.${_selectedFormat == 'Video' ? 'mp4' : 'mp3'}';

      await _requestPermissions();
      await _downloadFileFromUrl(url, filename);

      await _showNotification('Download Complete', 'File saved successfully', 100);
    } catch (e) {
      print('Bir hata oluştu: $e');
      await _showNotification('Download Failed', 'An error occurred: $e', 0);
    } finally {
      setState(() {
        _isDownloading = false;
        _showPlayButton = true;
      });
    }
  }

  Future<void> _downloadFileFromUrl(String url, String filename) async {
    final manifest = await _youtubeExplode.videos.streamsClient.getManifest(url);
    StreamInfo? videoStreamInfo;
    StreamInfo? audioStreamInfo;

    if (_selectedFormat == 'Video') {
      audioStreamInfo = manifest.audioOnly.reduce((a, b) => a.bitrate.kiloBitsPerSecond > b.bitrate.kiloBitsPerSecond ? a : b);

      videoStreamInfo = manifest.videoOnly.firstWhere(
            (e) => e.videoQualityLabel == _selectedResolution,
        orElse: () => throw Exception('Uygun video akışı bulunamadı.'),
      );

      final videoStream = _youtubeExplode.videos.streamsClient.get(videoStreamInfo);
      final audioStream = _youtubeExplode.videos.streamsClient.get(audioStreamInfo);

      final tempVideoPath = '${(await _getDownloadsDirectory('Videos')).path}/temp_video.mp4';
      final tempAudioPath = '${(await _getDownloadsDirectory('Videos')).path}/temp_audio.mp3';

      final videoFile = File(tempVideoPath);
      final audioFile = File(tempAudioPath);

      final videoOutput = videoFile.openWrite();
      await videoStream.pipe(videoOutput);
      await videoOutput.close();

      final audioOutput = audioFile.openWrite();
      await audioStream.pipe(audioOutput);
      await audioOutput.close();

      final outputFile = await _mergeVideoAndAudio(tempVideoPath, tempAudioPath, filename);

      await videoFile.delete();
      await audioFile.delete();

      setState(() {
        _downloadedFilePath = outputFile.path;
      });

      await _showNotification('Download Complete', 'File saved to ${outputFile.path}', 100);
    } else {
      audioStreamInfo = manifest.audioOnly.firstWhere(
            (e) => '${e.bitrate.kiloBitsPerSecond} kbps' == _selectedBitrate,
        orElse: () => throw Exception('Uygun ses akışı bulunamadı.'),
      );

      final stream = _youtubeExplode.videos.streamsClient.get(audioStreamInfo);

      final path = '${(await _getDownloadsDirectory('Audios')).path}/$filename';
      final file = File(path);

      final output = file.openWrite();
      await stream.pipe(output);
      await output.close();

      setState(() {
        _downloadedFilePath = path;
      });

      await _showNotification('Download Complete', 'File saved to $path', 100);
    }
  }

  Future<File> _mergeVideoAndAudio(String videoPath, String audioPath, String filename) async {
    final outputPath = 'storage/emulated/0/Download/TubDown/Videos/$filename';
    final arguments = [
      '-i',
      videoPath,
      '-i',
      audioPath,
      '-c:v',
      'copy',
      '-c:a',
      'aac',
      '-strict',
      'experimental',
      outputPath
    ];
    await _flutterFFmpeg.executeWithArguments(arguments);
    return File(outputPath);
  }

  Future<Directory> _getDownloadsDirectory(String type) async {
    final directory = await getExternalStorageDirectory();
    final downloadsDirectory = Directory('storage/emulated/0/Download/TubDown/$type');
    if (!await downloadsDirectory.exists()) {
      await downloadsDirectory.create(recursive: true);
    }
    return downloadsDirectory;
  }

  Future<void> _showNotification(String title, String body, int progress) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      progress: progress,
      maxProgress: 100,
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  void _playDownloadedFile() {
    if (_selectedFormat == 'Video' && _downloadedFilePath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(videoPath: _downloadedFilePath!),
        ),
      );
    } else if (_selectedFormat == 'Ses' && _downloadedFilePath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioPlayerScreen(audioPath: _downloadedFilePath!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(localization == 'tr' ? 'Video Detayları' : 'Video Details'),
        centerTitle: true,
        backgroundColor: Color(0xFF808080),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.video.title,
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              widget.video.description ?? '',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 16),
            Image.network(widget.video.thumbnails.mediumResUrl),
            SizedBox(height: 16),
            DropdownButton<String>(
              value: _selectedFormat,
              items: ['Video', 'Ses'].map((format) {
                return DropdownMenuItem<String>(
                  value: format,
                  child: Text(format, style: TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFormat = value!;
                  _selectedResolution = null; // Reset resolution on format change
                  _selectedBitrate = null; // Reset bitrate on format change
                });
                _fetchAvailableResolutions();
                _fetchAvailableBitrates();
              },
              dropdownColor: Color(0xFF303030),
            ),
            if (_selectedFormat == 'Video') ...[
              DropdownButton<String>(
                value: _selectedResolution,
                items: _availableResolutions.map((resolution) {
                  return DropdownMenuItem<String>(
                    value: resolution,
                    child: Text(resolution, style: TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedResolution = value;
                  });
                },
                dropdownColor: Color(0xFF303030),
              ),
            ] else if (_selectedFormat == 'Ses') ...[
              DropdownButton<String>(
                value: _selectedBitrate,
                items: _availableBitrates.map((bitrate) {
                  return DropdownMenuItem<String>(
                    value: bitrate,
                    child: Text(bitrate, style: TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBitrate = value;
                  });
                },
                dropdownColor: Color(0xFF303030),
              ),
            ],
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isDownloading ? null : _downloadFile,
              child: Text(localization == 'tr' ? 'İndir' : 'Download'),
            ),
            SizedBox(height: 16),
            if (_showPlayButton)
              ElevatedButton(
                onPressed: _playDownloadedFile,
                child: Text(localization == 'tr' ? 'Oynat' : 'Play'),
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localization == 'tr' ? 'Geri' : 'Back'),
            ),
          ],
        ),
      ),
    );
  }
}
