import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:tubdown/video_player_screen.dart';
import 'package:tubdown/audio_player_screen.dart';
import 'package:intl/intl.dart';

class IndirilenlerPage extends StatefulWidget {
  // Add a key parameter to the constructor
  const IndirilenlerPage({Key? key}) : super(key: key);

  @override
  _IndirilenlerPageState createState() => _IndirilenlerPageState();
}

class Localization {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'downloads': 'Downloads',
      'videos': 'Videos',
      'audios': 'Audios',
      'videoTitle': 'Video Title',
      'audioTitle': 'Audio Title',
      'noFiles': 'No files available',
    },
    'tr': {
      'downloads': 'İndirilenler',
      'videos': 'Videolar',
      'audios': 'Sesler',
      'videoTitle': 'Video Başlığı',
      'audioTitle': 'Ses Başlığı',
      'noFiles': 'Dosya bulunamadı',
    }
  };

  static String of(BuildContext context, String key) {
    final locale = Localizations.localeOf(context).languageCode;
    return _localizedValues[locale]?[key] ?? key;
  }
}


class _IndirilenlerPageState extends State<IndirilenlerPage> {
  List<FileSystemEntity> _files = [];
  String _currentDirectory = '';
  bool _isVideoSelected = true;

  @override
  void initState() {
    super.initState();
    _getDirectoryPath();
  }

  Future<void> _getDirectoryPath() async {
    final directory = await getDownloadsDirectory();
    if (directory != null) {
      final tubDownDirectory = Directory('storage/emulated/0/Download/TubDown');
      final videosDirectory = Directory('${tubDownDirectory.path}/Videos');
      final audiosDirectory = Directory('${tubDownDirectory.path}/Audios');

      setState(() {
        _currentDirectory = _isVideoSelected ? videosDirectory.path : audiosDirectory.path;
        _updateFileList();
      });
    }
  }

  Future<void> _updateFileList() async {
    final directory = Directory(_currentDirectory);
    final files = directory.listSync().reversed.toList(); // Reverses the list
    setState(() {
      _files = files;
    });
  }

  void _onFileTap(FileSystemEntity file) {
    if (file is File) {
      final filePath = file.path;
      if (filePath.endsWith('.mp4')) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(videoPath: filePath),
        ));
      } else if (filePath.endsWith('.mp3')) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => AudioPlayerScreen(audioPath: filePath),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.of(context, 'downloads')),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                SizedBox(
                  width: 100, // Set a fixed width for the button
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isVideoSelected = true;
                        _getDirectoryPath();
                      });
                    },
                    child: Text(Localization.of(context, 'videos')),
                  ),
                ),
                SizedBox(
                  width: 100, // Set a fixed width for the button
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isVideoSelected = false;
                        _getDirectoryPath();
                      });
                    },
                    child: Text(Localization.of(context, 'audios')),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _files.isEmpty
                ? Center(child: Text(Localization.of(context, 'noFiles')))
                : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                final fileName = file.uri.pathSegments.last;
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(8.0),
                    title: Text(fileName),
                    onTap: () => _onFileTap(file),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
