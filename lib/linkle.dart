import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart'; // FFmpeg paketi ekleyin

class LinklePage extends StatefulWidget {
  @override
  _LinklePageState createState() => _LinklePageState();
}

class _LinklePageState extends State<LinklePage> {
  final TextEditingController _urlController = TextEditingController();
  String _videoTitle = '';
  String _selectedFormat = 'Video';
  String? _selectedResolution;
  String? _selectedBitrate;
  late YoutubeExplode _youtubeExplode;
  Video? _video;
  List<String> _videoResolutions = [];
  List<String> _audioBitrates = [];

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg(); // FFmpeg nesnesi

  @override
  void initState() {
    super.initState();
    _youtubeExplode = YoutubeExplode();

    final AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _fetchVideoTitle(String url) async {
    try {
      _video = await _youtubeExplode.videos.get(url);
      final manifest = await _youtubeExplode.videos.streamsClient.getManifest(url);

      setState(() {
        _videoTitle = _video?.title ?? 'Başlık alınamadı';

        _videoResolutions = manifest.videoOnly
            .map((e) => e.videoQualityLabel)
            .where((label) => label != null)
            .toSet()
            .cast<String>()
            .toList();

        _audioBitrates = manifest.audioOnly
            .map((e) => e.bitrate.kiloBitsPerSecond.toString())
            .where((bitrate) => bitrate != null)
            .toSet()
            .cast<String>()
            .toList();

        _selectedResolution = _videoResolutions.isNotEmpty ? _videoResolutions.first : null;
        _selectedBitrate = _audioBitrates.isNotEmpty ? _audioBitrates.first : null;
      });
    } catch (e) {
      setState(() {
        _videoTitle = 'Bir hata oluştu: $e';
      });
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.storage,
    ].request();
  }

  Future<void> _downloadFile(String url, String filename) async {
    try {
      final fileType = _selectedFormat == 'Video' ? 'Video' : 'Ses';
      final notificationTitle = '$fileType - ${filename.split('.').first}';
      await _showNotification(notificationTitle, 'Downloading...', 0);

      final manifest = await _youtubeExplode.videos.streamsClient.getManifest(url);
      StreamInfo? videoStreamInfo;
      StreamInfo? audioStreamInfo;

      if (_selectedFormat == 'Video') {
        // En yüksek bitrate'e sahip ses akışını seç
        audioStreamInfo = manifest.audioOnly
            .reduce((a, b) => a.bitrate.kiloBitsPerSecond > b.bitrate.kiloBitsPerSecond ? a : b);

        videoStreamInfo = manifest.videoOnly
            .firstWhere(
                (e) => e.videoQualityLabel == _selectedResolution,
            orElse: () => throw Exception('Uygun video akışı bulunamadı.')
        );

        // Video ve ses akışlarını indir
        final videoStream = _youtubeExplode.videos.streamsClient.get(videoStreamInfo);
        final audioStream = _youtubeExplode.videos.streamsClient.get(audioStreamInfo);

        final tempVideoPath = '${(await _getDownloadsDirectory()).path}/temp_video.mp4';
        final tempAudioPath = '${(await _getDownloadsDirectory()).path}/temp_audio.mp3';

        // Video ve ses dosyalarını indir
        final videoFile = File(tempVideoPath);
        final audioFile = File(tempAudioPath);

        final videoOutput = videoFile.openWrite();
        await videoStream.pipe(videoOutput);
        await videoOutput.close();

        final audioOutput = audioFile.openWrite();
        await audioStream.pipe(audioOutput);
        await audioOutput.close();

        // Video ve ses dosyalarını birleştir
        final outputFile = await _mergeVideoAndAudio(tempVideoPath, tempAudioPath, filename);

        // Geçici dosyaları sil
        await videoFile.delete();
        await audioFile.delete();

        await _showNotification(notificationTitle, 'File saved to ${outputFile.path}', 100);
      } else {
        // Ses indirme
        audioStreamInfo = manifest.audioOnly
            .firstWhere(
                (e) => e.bitrate.kiloBitsPerSecond.toString() == _selectedBitrate,
            orElse: () => throw Exception('Uygun ses akışı bulunamadı.')
        );

        final stream = _youtubeExplode.videos.streamsClient.get(audioStreamInfo);

        final path = '${(await _getDownloadsDirectory()).path}/$filename';
        final file = File(path);

        final output = file.openWrite();
        await stream.pipe(output);
        await output.close();

        await _showNotification(notificationTitle, 'File saved to $path', 100);
      }
    } catch (e) {
      print('Bir hata oluştu: $e');
      await _showNotification('Download failed', 'An error occurred: $e', 0);
    }
  }

  Future<File> _mergeVideoAndAudio(String videoPath, String audioPath, String filename) async {
    final outputPath = 'storage/emulated/0/Download/TubDown/Videos/$filename';
    final arguments = [
      '-i', videoPath,
      '-i', audioPath,
      '-c:v', 'copy',
      '-c:a', 'aac',
      '-strict', 'experimental',
      outputPath
    ];
    await _flutterFFmpeg.executeWithArguments(arguments);
    return File(outputPath);
  }

  Future<Directory> _getDownloadsDirectory() async {
    final directory = await getExternalStorageDirectory();
    final downloadsDirectory = Directory('storage/emulated/0/Download/TubDown/${_selectedFormat == 'Video' ? 'Videos' : 'Audios'}');
    if (!await downloadsDirectory.exists()) {
      await downloadsDirectory.create(recursive: true);
    }
    return downloadsDirectory;
  }

  Future<void> _showNotification(String title, String body, int progress) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      progress: progress,
      maxProgress: 100,
    );

    NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Linkle İndir'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'YouTube Video Linki',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.black,
                hintText: 'YouTube video URL girin',
                hintStyle: TextStyle(color: Colors.white),
                labelStyle: TextStyle(color: Colors.white),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                String url = _urlController.text.trim();
                if (url.isNotEmpty) {
                  _fetchVideoTitle(url);
                }
              },
              child: Text('Get Video Info'),
            ),
            SizedBox(height: 16),
            if (_videoTitle.isNotEmpty) ...[
              Text(
                'Video Başlığı:',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                _videoTitle,
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              SizedBox(height: 16),
              DropdownButton<String>(
                value: _selectedFormat,
                dropdownColor: Colors.black,
                style: TextStyle(color: Colors.white),
                items: <String>['Video', 'Ses'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedFormat = newValue!;
                    _selectedResolution = _selectedFormat == 'Video' && _videoResolutions.isNotEmpty ? _videoResolutions.first : null;
                    _selectedBitrate = _selectedFormat == 'Ses' && _audioBitrates.isNotEmpty ? _audioBitrates.first : null;
                  });
                },
              ),
              SizedBox(height: 16),
              if (_selectedFormat == 'Video') ...[
                DropdownButton<String>(
                  value: _selectedResolution,
                  dropdownColor: Colors.black,
                  style: TextStyle(color: Colors.white),
                  items: _videoResolutions.map((String resolution) {
                    return DropdownMenuItem<String>(
                      value: resolution,
                      child: Text(resolution),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedResolution = newValue!;
                    });
                  },
                ),
              ],
              if (_selectedFormat == 'Ses') ...[
                DropdownButton<String>(
                  value: _selectedBitrate,
                  dropdownColor: Colors.black,
                  style: TextStyle(color: Colors.white),
                  items: _audioBitrates.map((String bitrate) {
                    return DropdownMenuItem<String>(
                      value: bitrate,
                      child: Text(bitrate),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedBitrate = newValue!;
                    });
                  },
                ),
              ],
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await _requestPermissions();
                  String url = _urlController.text.trim();
                  if (url.isNotEmpty) {
                    String filename = '${_videoTitle}_${DateTime.now().millisecondsSinceEpoch}.${_selectedFormat == 'Video' ? 'mp4' : 'mp3'}';
                    await _downloadFile(url, filename);
                  }
                },
                child: Text('İndir'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
