import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'arama_secilen.dart'; // Video detaylarını gösterecek sayfa

class AramaPage extends StatefulWidget {
  @override
  _AramaPageState createState() => _AramaPageState();
}

class _AramaPageState extends State<AramaPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Video> _searchResults = [];
  bool _isLoading = false;

  final YoutubeExplode _youtubeExplode = YoutubeExplode();

  Future<void> _searchVideos(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final searchResults = await _youtubeExplode.search.getVideos(query);
      setState(() {
        _searchResults = searchResults.toList();
      });
    } catch (e) {
      print('Bir hata oluştu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(localization == 'tr' ? 'YouTube Arama' : 'YouTube Search'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView( // Wrap the Column with SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: localization == 'tr' ? 'Arama Terimi' : 'Search Term',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.black,
                hintText: localization == 'tr' ? 'Arama yapın...' : 'Search...',
                hintStyle: TextStyle(color: Colors.white54),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                String query = _searchController.text.trim();
                if (query.isNotEmpty) {
                  _searchVideos(query);
                }
              },
              child: Text(localization == 'tr' ? 'Ara' : 'Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // primary yerine backgroundColor kullanın
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              shrinkWrap: true, // Prevent ListView from expanding
              physics: NeverScrollableScrollPhysics(), // Disable ListView scrolling
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final video = _searchResults[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Card(
                      color: Colors.black,
                      elevation: 4.0,
                      child: ListTile(
                        contentPadding: EdgeInsets.all(8.0),
                        leading: Image.network(
                          video.thumbnails.mediumResUrl ?? '', // null check ekleyin
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                        title: Text(
                          video.title,
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          video.description,
                          style: TextStyle(color: Colors.white54),
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AramaSecilenPage(video: video),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
