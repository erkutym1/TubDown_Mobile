import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

class ListePage extends StatefulWidget {
  @override
  _ListePageState createState() => _ListePageState();
}

class Localization {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'playlistDownloader': 'Playlist Downloader',
      'pastePlaylistLink': 'Paste YouTube playlist link',
      'getPlaylist': 'Get Playlist',
      'download': 'Download',
      'playlistError': 'Error fetching playlist',
      'downloadStarted': 'Download Started',
      'downloadingVideo': 'Downloading Video',
      'downloadCompleted': 'Download Completed',
      'allVideosDownloaded': 'All videos downloaded',
      'videoDownloaded': 'Video Downloaded',
      'audioDownloaded': 'Audio Downloaded',
      'fileSaved': 'File saved',
      'downloadError': 'Download Error'
    },
    'tr': {
      'playlistDownloader': 'Çalma Listesi İndirici',
      'pastePlaylistLink': 'YouTube çalma listesi bağlantısını yapıştırın',
      'getPlaylist': 'Listeyi Al',
      'download': 'İndir',
      'playlistError': 'Çalma listesi alınırken hata',
      'downloadStarted': 'İndirme Başladı',
      'downloadingVideo': 'Video İndiriliyor',
      'downloadCompleted': 'İndirme Tamamlandı',
      'allVideosDownloaded': 'Tüm videolar indirildi',
      'videoDownloaded': 'Video İndirildi',
      'audioDownloaded': 'Ses İndirildi',
      'fileSaved': 'Dosya kaydedildi',
      'downloadError': 'İndirme Hatası'
    }
  };

  static String of(BuildContext context, String key) {
    final locale = Localizations.localeOf(context).languageCode;
    return _localizedValues[locale]?[key] ?? key;
  }
}


class _ListePageState extends State<ListePage> {
  final TextEditingController _controller = TextEditingController();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  late YoutubeExplode _youtubeExplode;
  final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();
  String? _playlistTitle;
  String _selectedFormat = 'Video';

  @override
  void initState() {
    super.initState();
    _youtubeExplode = YoutubeExplode();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _getPlaylistDetails() async {
    try {
      final playlist = await _youtubeExplode.playlists.get(_controller.text);
      setState(() {
        _playlistTitle = playlist.title;
      });
    } catch (e) {
      print('Playlist bilgileri alınırken bir hata oluştu: $e');
    }
  }

  Future<void> _requestPermissions() async {
    await [Permission.storage].request();
  }

  Future<void> _downloadPlaylist() async {
    try {
      await _requestPermissions();
      final playlistId = PlaylistId(_controller.text);
      final videos = await _youtubeExplode.playlists.getVideos(playlistId).toList();
      int totalVideos = videos.length;

      for (int i = 0; i < totalVideos; i++) {
        final video = videos[i];
        await _showNotification(
            Localization.of(context, 'downloadStarted'),
            '${Localization.of(context, 'downloadingVideo')} ${i + 1} / $totalVideos...',
            i + 1,
            totalVideos);

        if (_selectedFormat == 'Video') {
          await _downloadVideoWithAudio(video);
        } else {
          await _downloadAudioOnly(video);
        }
      }

      await _showNotification(Localization.of(context, 'downloadCompleted'),
          Localization.of(context, 'allVideosDownloaded'), 100, 100);
    } catch (e) {
      print('Bir hata oluştu: $e');
    }
  }

  Future<void> _downloadVideoWithAudio(Video video) async {
    try {
      final manifest = await _youtubeExplode.videos.streamsClient.getManifest(video.id);

      final audioStreamInfo = manifest.audioOnly
          .reduce((a, b) => a.bitrate.kiloBitsPerSecond > b.bitrate.kiloBitsPerSecond ? a : b);

      final videoStreamInfo = manifest.videoOnly
          .where((e) => e.videoQualityLabel == '1080p' || e.videoQualityLabel != '1080p')
          .reduce((a, b) => a.videoResolution.height > b.videoResolution.height ? a : b);

      final videoStream = _youtubeExplode.videos.streamsClient.get(videoStreamInfo);
      final audioStream = _youtubeExplode.videos.streamsClient.get(audioStreamInfo);

      final tempVideoPath = '${(await _getDownloadsDirectory()).path}/temp_video.mp4';
      final tempAudioPath = '${(await _getDownloadsDirectory()).path}/temp_audio.mp3';

      final videoFile = File(tempVideoPath);
      final audioFile = File(tempAudioPath);

      final videoOutput = videoFile.openWrite();
      await videoStream.pipe(videoOutput);
      await videoOutput.close();

      final audioOutput = audioFile.openWrite();
      await audioStream.pipe(audioOutput);
      await audioOutput.close();

      final filename = '${video.title}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final outputFile = await _mergeVideoAndAudio(tempVideoPath, tempAudioPath, filename);

      await videoFile.delete();
      await audioFile.delete();

      await _showNotification(Localization.of(context, 'videoDownloaded'),
          '${Localization.of(context, 'fileSaved')}: ${outputFile.path}', 100, 100);
    } catch (e) {
      print('Video ve ses indirilemedi: $e');
    }
  }

  Future<void> _downloadAudioOnly(Video video) async {
    try {
      final manifest = await _youtubeExplode.videos.streamsClient.getManifest(video.id);
      final audioStreamInfo = manifest.audioOnly
          .reduce((a, b) => a.bitrate.kiloBitsPerSecond > b.bitrate.kiloBitsPerSecond ? a : b);

      final stream = _youtubeExplode.videos.streamsClient.get(audioStreamInfo);
      final filename = '${video.title}_${DateTime.now().millisecondsSinceEpoch}.mp3';

      final path = 'storage/emulated/0/Download/TubDown/Audios/$filename';
      await _createDirectoryIfNotExist(path);
      final file = File(path);

      final output = file.openWrite();
      await stream.pipe(output);
      await output.close();

      await _showNotification(Localization.of(context, 'audioDownloaded'),
          '${Localization.of(context, 'fileSaved')}: $path', 100, 100);
    } catch (e) {
      print('Ses indirilemedi: $e');
    }
  }

  Future<File> _mergeVideoAndAudio(String videoPath, String audioPath, String filename) async {
    final outputPath = 'storage/emulated/0/Download/TubDown/Videos/$filename';
    await _createDirectoryIfNotExist(outputPath);
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

  Future<void> _createDirectoryIfNotExist(String path) async {
    final directory = Directory(path).parent;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  Future<Directory> _getDownloadsDirectory() async {
    final directory = await getExternalStorageDirectory();
    final downloadsDirectory = Directory(
        'storage/emulated/0/Download/TubDown/${_selectedFormat == 'Video' ? 'Videos' : 'Audios'}');
    if (!await downloadsDirectory.exists()) {
      await downloadsDirectory.create(recursive: true);
    }
    return downloadsDirectory;
  }

  Future<void> _showNotification(
      String title, String body, int progress, int maxProgress) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      progress: progress,
      maxProgress: maxProgress,
      showProgress: true,
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
        title: Text(Localization.of(context, 'playlistDownloader')),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: Localization.of(context, 'pastePlaylistLink'),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getPlaylistDetails,
              child: Text(Localization.of(context, 'getPlaylist')),
            ),
            if (_playlistTitle != null) ...[
              SizedBox(height: 16),
              Text(
                _playlistTitle!,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                  });
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _downloadPlaylist,
                child: Text(Localization.of(context, 'download')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
