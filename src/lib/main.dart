import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:src/pages/about_page.dart';
import 'package:src/pages/announcement_page.dart';
import 'package:src/pages/board_page.dart';
import 'package:src/pages/donate_page.dart';
import 'package:src/pages/forgot_page.dart';
import 'package:src/pages/help_page.dart';
import 'package:src/pages/item_page.dart';
import 'package:src/pages/manage_page.dart';
import 'package:src/pages/event_page.dart';
import 'package:src/pages/events_page.dart';
import 'package:src/pages/home_page.dart';
import 'package:src/pages/login_page.dart';
import 'package:src/pages/map_page.dart';
import 'package:src/pages/order_page.dart';
import 'package:src/pages/scan_page.dart';
import 'package:src/pages/transactions_page.dart';
import 'package:src/pages/roles_page.dart';
import 'package:src/pages/settings_page.dart';
import 'package:src/pages/profile_page.dart';
import 'package:src/pages/notifications_page.dart';
import 'package:src/pages/shop_page.dart';
import 'package:src/pages/signup_page.dart';
import 'package:src/pages/splash_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:src/pages/verify_page.dart';
import 'firebase_options.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void setupInteractedMessage() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Important Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  });
}

void main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
      final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
        analytics: analytics,
      );

      final permission = await FirebaseMessaging.instance.requestPermission();

      if (permission.authorizationStatus == AuthorizationStatus.authorized) {
        if (Platform.isIOS) {
          String? token;
          while (token == null) {
            token = await FirebaseMessaging.instance.getAPNSToken();
            if (token == null) {
              await Future<void>.delayed(Duration(seconds: 1));
            }
          }
        }

        FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);

        const AndroidInitializationSettings androidInit =
            AndroidInitializationSettings('@drawable/ic_stat_notification');
        final DarwinInitializationSettings iosInit =
            DarwinInitializationSettings();

        await flutterLocalNotificationsPlugin.initialize(
          InitializationSettings(android: androidInit, iOS: iosInit),
        );

        setupInteractedMessage();

        await FirebaseMessaging.instance.subscribeToTopic("ida-app-default");
      }

      // Stripe.publishableKey =
      //     "pk_test_51RnYlzQkArntKpGlapTuIf51Fvsi1CittiW7jyvqGN4mKEg9z5baV4kWtOKWHWiW14TzzRqxbSXHZQz01xRJeK8k00gJ2IaMpr";
      Stripe.publishableKey =
          "pk_live_51RnYlmH4Cdv9foKx4W0Qq3mbHLG5V5RAPgkoNj36dlvj5YzLErdZBEnWNiS75sjY1UO127RO4xKRfIuaKYFvAuuf00mjmkL60F";
      Stripe.merchantIdentifier = "merchant.ida.src";
      Stripe.instance.applySettings();

      runApp(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Illini Dads",
          navigatorObservers: [observer],
          routes: {
            "/": (context) => SplashPage(),
            "/login": (context) => LoginPage(),
            "/signup": (context) => SignupPage(),
            "/verify": (context) => VerifyPage(),
            "/forgot": (context) => ForgotPage(),
            "/home": (context) => HomePage(),
            "/shop": (context) => ShopPage(),
            "/events": (context) => EventsPage(),
            "/event": (context) => EventPage(),
            "/map": (context) => MapPage(),
            "/profile": (context) => ProfilePage(),
            "/notifications": (context) => NotificationsPage(),
            "/manage": (context) => ManagePage(),
            "/about": (context) => AboutPage(),
            "/settings": (context) => SettingsPage(),
            "/item": (context) => ItemPage(),
            "/donate": (context) => DonatePage(),
            "/board": (context) => BoardPage(),
            "/announcement": (context) => AnnouncementPage(),
            "/roles": (context) => RolesPage(),
            "/help": (context) => HelpPage(),
            "/transactions": (context) => TransactionsPage(),
            "/order": (context) => OrderPage(),
            "/scan": (context) => ScanPage()
          },
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Color(0xFFFF5F05),
              primary: Color(0xFFFF5F05),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Color(0xFF9C9A9D), width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Color(0xFF9C9A9D), width: 2),
              ),
              hintStyle: TextStyle(
                fontSize: 18,
                fontFamily: GoogleFonts.montserrat().fontFamily,
                fontWeight: FontWeight.normal,
                color: Color(0xFF9C9A9D),
              ),
              errorStyle: TextStyle(
                fontSize: 14,
                fontFamily: GoogleFonts.sourceSans3().fontFamily,
                fontWeight: FontWeight.normal,
                color: Colors.red,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: ButtonStyle(
                overlayColor: WidgetStatePropertyAll(Color(0x3313294B)),
                textStyle: WidgetStatePropertyAll(
                  TextStyle(fontWeight: FontWeight.normal),
                ),
              ),
            ),
            bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: Colors.transparent,
            ),
            primaryColor: Color(0xFF9C9A9D),
            primaryColorLight: Color(0xFFFF5F05),
            primaryColorDark: Color(0xFF13294B),
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF13294B),
              surfaceTintColor: Colors.transparent,
            ),
            textTheme: TextTheme(
              headlineLarge: TextStyle(
                fontSize: 26,
                fontFamily: GoogleFonts.montserrat().fontFamily,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
              headlineMedium: TextStyle(
                fontSize: 24,
                fontFamily: GoogleFonts.montserrat().fontFamily,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
              headlineSmall: TextStyle(
                fontSize: 22,
                fontFamily: GoogleFonts.montserrat().fontFamily,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
              titleLarge: TextStyle(
                fontSize: 26,
                fontFamily: GoogleFonts.sourceSans3().fontFamily,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
              titleMedium: TextStyle(
                fontSize: 24,
                fontFamily: GoogleFonts.sourceSans3().fontFamily,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
              titleSmall: TextStyle(
                fontSize: 22,
                fontFamily: GoogleFonts.sourceSans3().fontFamily,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
              bodyLarge: TextStyle(
                fontSize: 18,
                fontFamily: GoogleFonts.sourceSans3().fontFamily,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
              bodyMedium: TextStyle(
                fontSize: 14,
                fontFamily: GoogleFonts.sourceSans3().fontFamily,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
              bodySmall: TextStyle(
                fontSize: 12,
                fontFamily: GoogleFonts.sourceSans3().fontFamily,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
              labelLarge: TextStyle(
                fontSize: 18,
                fontFamily: GoogleFonts.montserrat().fontFamily,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
              labelMedium: TextStyle(
                fontSize: 14,
                fontFamily: GoogleFonts.montserrat().fontFamily,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
              labelSmall: TextStyle(
                fontSize: 12,
                fontFamily: GoogleFonts.montserrat().fontFamily,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
            typography: Typography(
              black: TextTheme(
                headlineLarge: TextStyle(
                  fontSize: 26,
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
                headlineMedium: TextStyle(
                  fontSize: 24,
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
                headlineSmall: TextStyle(
                  fontSize: 22,
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
                titleLarge: TextStyle(
                  fontSize: 26,
                  fontFamily: GoogleFonts.sourceSans3().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
                titleMedium: TextStyle(
                  fontSize: 24,
                  fontFamily: GoogleFonts.sourceSans3().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
                titleSmall: TextStyle(
                  fontSize: 22,
                  fontFamily: GoogleFonts.sourceSans3().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
                bodyLarge: TextStyle(
                  fontSize: 18,
                  fontFamily: GoogleFonts.sourceSans3().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
                bodyMedium: TextStyle(
                  fontSize: 14,
                  fontFamily: GoogleFonts.sourceSans3().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
                bodySmall: TextStyle(
                  fontSize: 12,
                  fontFamily: GoogleFonts.sourceSans3().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
                labelLarge: TextStyle(
                  fontSize: 18,
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
                labelMedium: TextStyle(
                  fontSize: 14,
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
                labelSmall: TextStyle(
                  fontSize: 12,
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
              ),
              white: TextTheme(
                headlineLarge: TextStyle(
                  fontSize: 26,
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
                headlineMedium: TextStyle(
                  fontSize: 24,
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
                headlineSmall: TextStyle(
                  fontSize: 22,
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
                titleLarge: TextStyle(
                  fontSize: 26,
                  fontFamily: GoogleFonts.sourceSans3().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
                titleMedium: TextStyle(
                  fontSize: 24,
                  fontFamily: GoogleFonts.sourceSans3().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
                titleSmall: TextStyle(
                  fontSize: 22,
                  fontFamily: GoogleFonts.sourceSans3().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
                bodyLarge: TextStyle(
                  fontSize: 18,
                  fontFamily: GoogleFonts.sourceSans3().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
                bodyMedium: TextStyle(
                  fontSize: 14,
                  fontFamily: GoogleFonts.sourceSans3().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
                bodySmall: TextStyle(
                  fontSize: 12,
                  fontFamily: GoogleFonts.sourceSans3().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
                labelLarge: TextStyle(
                  fontSize: 18,
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
                labelMedium: TextStyle(
                  fontSize: 14,
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
                labelSmall: TextStyle(
                  fontSize: 12,
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              dayBackgroundColor: WidgetStateProperty.resolveWith<Color?>((
                states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return Color(0xFFFF5F05);
                }
                return Colors.transparent;
              }),
              dayForegroundColor: WidgetStateProperty.resolveWith<Color?>((
                states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return Color(0xFF13294B);
                } else if (states.contains(WidgetState.disabled)) {
                  return Color(0xFF9C9A9D);
                }
                return Colors.black;
              }),
              dayShape: WidgetStateProperty.resolveWith<OutlinedBorder?>((
                states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return CircleBorder(
                    side: BorderSide(color: Color(0xFF13294B)),
                  );
                }
                return CircleBorder();
              }),
              weekdayStyle: TextStyle(
                fontSize: 14,
                fontFamily: GoogleFonts.montserrat().fontFamily,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              dayStyle: TextStyle(
                fontSize: 14,
                fontFamily: GoogleFonts.montserrat().fontFamily,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
              cancelButtonStyle: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                foregroundColor: WidgetStatePropertyAll(Colors.black),
                textStyle: WidgetStatePropertyAll(
                  TextStyle(
                    fontSize: 16,
                    fontFamily: GoogleFonts.montserrat().fontFamily,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
              ),
              confirmButtonStyle: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                foregroundColor: WidgetStatePropertyAll(Colors.black),
                textStyle: WidgetStatePropertyAll(
                  TextStyle(
                    fontSize: 16,
                    fontFamily: GoogleFonts.montserrat().fontFamily,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
              ),
              todayBorder: BorderSide(color: Color(0xFFFF5F05)),
              todayBackgroundColor: WidgetStatePropertyAll(Color(0xFF13294B)),
              todayForegroundColor: WidgetStatePropertyAll(Color(0xFFFF5F05)),
              yearOverlayColor: WidgetStatePropertyAll(Color(0xFF13294B)),
              yearStyle: TextStyle(
                fontSize: 16,
                fontFamily: GoogleFonts.montserrat().fontFamily,
                fontWeight: FontWeight.normal,
              ),
              headerHelpStyle: TextStyle(
                fontSize: 20,
                fontFamily: GoogleFonts.montserrat().fontFamily,
                fontWeight: FontWeight.normal,
              ),
              dividerColor: Color(0xFF9C9A9D),
            ),

            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              cancelButtonStyle: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                foregroundColor: WidgetStatePropertyAll(Colors.black),
                textStyle: WidgetStatePropertyAll(
                  TextStyle(
                    fontSize: 16,
                    fontFamily: GoogleFonts.montserrat().fontFamily,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
              ),
              confirmButtonStyle: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                foregroundColor: WidgetStatePropertyAll(Colors.black),
                textStyle: WidgetStatePropertyAll(
                  TextStyle(
                    fontSize: 16,
                    fontFamily: GoogleFonts.montserrat().fontFamily,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
              ),
              hourMinuteTextStyle: TextStyle(fontSize: 40),
              dialBackgroundColor: Color(0xFFEEEEEE),
              helpTextStyle: TextStyle(
                fontSize: 20,
                fontFamily: GoogleFonts.montserrat().fontFamily,
                fontWeight: FontWeight.normal,
              ),
              hourMinuteColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Color(0xFFCCCCCC);
                }
                return Color(0xFFEEEEEE);
              }),
            ),
          ),
        ),
      );
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}
