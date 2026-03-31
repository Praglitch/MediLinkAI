import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'hospital_panel.dart';
import 'resource_transfer.dart';
import 'ai_logic.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediLinkAI',
      debugShowCheckedModeBanner: false,

      // 🔥 FULL DARK THEME FIXED
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFF0A0F1C),

        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF121A2F),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF00F2FF),
            foregroundColor: Colors.black,
          ),
        ),

        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white),

          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
        ),
      ),

      home: HospitalList(),
    );
  }
}

class HospitalList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    final hospitals =
        FirebaseFirestore.instance.collection('hospitals');

    return Scaffold(
      appBar: AppBar(
        title: Text("🧠 MediLink AI System"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: hospitals.snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Scanning network...\nNo data yet",
                textAlign: TextAlign.center,
              ),
            );
          }

          final docs = snapshot.data!.docs;

          // 🔥 FIRESTORE → LIST
          List<Map<String, dynamic>> hospitalList =
              docs.map((doc) {
            return {
              "name": doc['name'],
              "beds": doc['beds'],
              "oxygen": doc['oxygen'],
              "location": doc['location'],
            };
          }).toList();

          // 🔥 AI LOGIC
          var best = getBestHospital(hospitalList);
          String bestHospitalName = best['name'];

          return Padding(
            padding: EdgeInsets.all(12),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // 🔥 SYSTEM STATUS HEADER
                Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Color(0xFF121A2F),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: Colors.green, size: 10),
                      SizedBox(width: 8),
                      Text("SYSTEM ACTIVE // LIVE SYNC"),
                    ],
                  ),
                ),

                // 🔘 BUTTONS
                Row(
                  children: [

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HospitalPanel(),
                            ),
                          );
                        },
                        child: Text("⚙️ Manage"),
                      ),
                    ),

                    SizedBox(width: 10),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ResourceTransfer(),
                            ),
                          );
                        },
                        child: Text("🔄 Optimize"),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 15),

                // 🤖 AI BOX
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF121A2F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF00F2FF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "🤖 AI Decision",
                        style: TextStyle(
                          color: Color(0xFF00F2FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "$bestHospitalName is optimal\nReason: Highest availability",
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 15),

                Text(
                  "📊 System Status",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 10),

                // 🏥 HOSPITAL LIST
                Expanded(
                  child: ListView(
                    children: docs.map((doc) {

                      int beds = doc['beds'];

                      String status;
                      Color statusColor;

                      if (beds == 0) {
                        status = "🔴 Critical";
                        statusColor = Colors.red;
                      } else if (beds < 5) {
                        status = "🟡 Moderate";
                        statusColor = Colors.orange;
                      } else {
                        status = "🟢 Optimal";
                        statusColor = Colors.green;
                      }

                      bool isBest =
                          doc['name'] == bestHospitalName;

                      return Card(
                        color: Color(0xFF121A2F),

                        elevation: isBest ? 6 : 2,

                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          side: isBest
                              ? BorderSide(
                                  color: Color(0xFF00F2FF),
                                  width: 2)
                              : BorderSide.none,
                        ),

                        margin:
                            EdgeInsets.symmetric(vertical: 8),

                        child: ListTile(
                          title: Text(
                            doc['name'],
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                "📍 ${doc['location']}\nBeds: ${doc['beds']} | Oxygen: ${doc['oxygen']}",
                                style: TextStyle(
                                    color: Colors.white70),
                              ),
                              Text(
                                "Last Sync: Live",
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey),
                              ),
                            ],
                          ),

                          trailing: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isBest)
                                Text(
                                  "⭐ Best",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );

                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}