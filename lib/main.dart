import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'hospital_panel.dart';
import 'resource_transfer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediLinkAI',
      debugShowCheckedModeBanner: false,
      home: HospitalList(),
    );
  }
}

class HospitalList extends StatelessWidget {
  HospitalList({super.key});

  @override
  Widget build(BuildContext context) {

    final hospitals =
        FirebaseFirestore.instance.collection('hospitals');

    return Scaffold(
      appBar: AppBar(
        title: Text("🧠 MediLink AI System"),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: hospitals.snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No hospital data found"));
          }

          final docs = snapshot.data!.docs;

          // 🧠 AI LOGIC (best hospital = max beds)
          var bestDoc = docs[0];
          for (var d in docs) {
            if (d['beds'] > bestDoc['beds']) {
              bestDoc = d;
            }
          }

          String bestHospitalName = bestDoc['name'];

          return Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

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

                // 📊 SYSTEM STATUS
                Text(
                  "📊 System Status",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 6),

                Text("Total Hospitals: ${docs.length}"),

                SizedBox(height: 10),

                // 🤖 AI DECISION
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "🤖 AI Decision: Best Allocation → $bestHospitalName",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Reason: Highest available beds and stable capacity",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),

                SizedBox(height: 12),

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

                      bool isBest = doc['name'] == bestHospitalName;

                      return Card(
                        elevation: isBest ? 6 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isBest
                              ? BorderSide(color: Colors.green, width: 2)
                              : BorderSide.none,
                        ),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(
                            doc['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            "📍 ${doc['location']}\nBeds: ${doc['beds']} | Oxygen: ${doc['oxygen']}",
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
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