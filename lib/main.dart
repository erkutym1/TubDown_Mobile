import 'package:flutter/material.dart';
import 'package:tubdown/linkle.dart';
import 'package:tubdown/arama.dart';
import 'package:tubdown/liste.dart';
import 'package:tubdown/indirilenler.dart'; // Import the IndirilenlerPage

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TubDown - EY',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFF808080), // Koyu arka plan rengi
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF808080), // Başlık arka planı
          foregroundColor: Colors.white, // Başlık rengi
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600), // Başlık punto
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            minimumSize: Size(double.infinity, 60),
            padding: EdgeInsets.symmetric(vertical: 16),
            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: MainScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/linkle':
            return MaterialPageRoute(
              builder: (context) => LinklePage(),
              settings: settings,
            );
          case '/arama':
            return MaterialPageRoute(
              builder: (context) => AramaPage(),
              settings: settings,
            );
          case '/liste':
            return MaterialPageRoute(
              builder: (context) => ListePage(),
              settings: settings,
            );
          case '/indirilenler': // Add route for IndirilenlerPage
            return MaterialPageRoute(
              builder: (context) => IndirilenlerPage(),
              settings: settings,
            );
          default:
            return null;
        }
      },
    );
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TubDown - EY'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(top: 1, bottom: 35),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(_createPageRoute(LinklePage()));
                  },
                  child: Text('Linkle İndir'),
                ),
              ),
              SizedBox(height: 6), // Butonlar arasında boşluk bırakmak için
              Container(
                margin: EdgeInsets.only(bottom: 35),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(_createPageRoute(AramaPage()));
                  },
                  child: Text('Arama Yap'),
                ),
              ),
              SizedBox(height: 6),
              Container(
                margin: EdgeInsets.only(bottom: 35), // Butonlar arasında 6 piksel boşluk bırak
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(_createPageRoute(ListePage()));
                  },
                  child: Text('Liste İndir'),
                ),
              ),
              SizedBox(height: 6), // Butonlar arasında boşluk bırakmak için
              Container(
                margin: EdgeInsets.only(bottom: 100), // Butonlar arasında 6 piksel boşluk bırak
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(_createPageRoute(IndirilenlerPage()));
                  },
                  child: Text('İndirilenler'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PageRoute _createPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end);
        var offsetAnimation = animation.drive(tween.chain(CurveTween(curve: curve)));
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }
}
