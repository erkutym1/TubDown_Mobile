import 'package:flutter/material.dart';
import 'package:tubdown/linkle.dart';
import 'package:tubdown/arama.dart';
import 'package:tubdown/liste.dart';
import 'package:tubdown/indirilenler.dart'; // Import the IndirilenlerPage
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale _locale = Locale('tr', ''); // Varsayılan dil Türkçe

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TubDown - EY',
      locale: _locale,
      supportedLocales: [
        Locale('en', ''), // İngilizce
        Locale('tr', ''), // Türkçe
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first; // Varsayılan dil
      },
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
              builder: (context) => LinklePage(language: AutofillHints.language,),
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

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isTurkish = true; // Başlangıçta Türkçe

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TubDown - EY'),
        centerTitle: true,
      ),
      body: SingleChildScrollView( // Wrap the Column with SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(top: 45, bottom: 15),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(_createPageRoute(LinklePage(language: AutofillHints.language,)));
                  },
                  child: Text(isTurkish ? 'Linkle İndir' : 'Download with Link'),
                ),
              ),
              SizedBox(height: 6),
              Container(
                margin: EdgeInsets.only(bottom: 15),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(_createPageRoute(AramaPage()));
                  },
                  child: Text(isTurkish ? 'Arama Yap' : 'Search'),
                ),
              ),
              SizedBox(height: 6),
              Container(
                margin: EdgeInsets.only(bottom: 15),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(_createPageRoute(ListePage()));
                  },
                  child: Text(isTurkish ? 'Liste İndir' : 'Download Playlist'),
                ),
              ),
              SizedBox(height: 6),
              Container(
                margin: EdgeInsets.only(bottom: 100),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(_createPageRoute(IndirilenlerPage()));
                  },
                  child: Text(isTurkish ? 'İndirilenler' : 'Downloads'),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    isTurkish = !isTurkish;
                    MyApp.setLocale(context, isTurkish ? Locale('tr', '') : Locale('en', ''));
                  });
                },
                icon: Image.asset(
                  isTurkish ? 'assets/images/turkish.png' : 'assets/images/english.png',
                  width: 24,
                  height: 24,
                ),
                label: Text(isTurkish ? 'Türkçe' : 'English'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blue, // Buton rengi
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

