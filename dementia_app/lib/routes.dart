import 'package:flutter/material.dart';
import 'package:mytestapp/caregivers/caregivers.dart';
import 'package:mytestapp/medicineInfo/medicine_info.dart';
import 'package:mytestapp/memory_aid/memory_aid.dart';
import 'package:mytestapp/profile/profile.dart';
import 'package:mytestapp/home/home.dart';
import 'package:mytestapp/login/login.dart';
import 'package:mytestapp/puzzles/puzzles.dart';
import 'package:mytestapp/voice/voice.dart';
import 'package:mytestapp/role/role.dart';
import 'package:mytestapp/connect/connect.dart';
import 'package:mytestapp/messages/messages.dart';
import 'package:mytestapp/medicinealertscreen/medicine.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (BuildContext context) => const HomeScreen(),
  '/login': (BuildContext context) => const LoginScreen(),
  '/profile': (BuildContext context) => const ProfileScreen(),
  '/medicineInfo': (BuildContext context) => const MedicineInfoScreen(),
  '/caregivers': (BuildContext context) => const CaregiversScreen(),
  '/memoryAid': (BuildContext context) =>  FamilyTreeApp(),
  '/puzzles': (BuildContext context) =>  const GamesScreen(),
  '/voice': (BuildContext context) => const VoiceScreen(),
  '/role': (BuildContext context) => const RoleScreen(),
  '/connect': (BuildContext context) => const ConnectScreen(),
  '/message':(BuildContext context)=>const MessageScreen(),
  '/medicine':(BuildContext context)=>const MedicationAlertScreen(),

};
