import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

const gold = Color(0xffa87918);
const darkGold = Color(0xff70500f);

void runHotelApp() => runApp(const HotelApp());

class HotelApp extends StatelessWidget {
  const HotelApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Hotel',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: gold),
          scaffoldBackgroundColor: const Color(0xfffffbf2),
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xfffffbf2), foregroundColor: Color(0xff2f281b)),
          filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: darkGold, foregroundColor: Colors.white)),
        ),
        home: const LoginScreen(),
      );
}
