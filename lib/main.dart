import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'ai_logic.dart';
import 'hospital_panel.dart';
import 'resource_transfer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediLink AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  String userQuery = "";
  Map<String, dynamic>? bestHospital;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MediLink AI"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🧠 USER INPUT
            TextField(
              decoration: const InputDecoration(
                hintText: "Describe emergency (fever / ICU / oxygen)",
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                userQuery = val;
              },
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              child: const Text("Analyze"),
            ),

            const SizedBox(height: 20),

            /// 🔴 LIVE DATA
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('hospitals')
                    .snapshots(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  List<Map<String, dynamic>> hospitals = docs.map((d) {
                    return d.data() as Map<String, dynamic>;
                  }).toList();

                  /// 🤖 AI CALCULATION
                  if (userQuery.isNotEmpty) {
                    bestHospital =
                        AILogic.getBestHospital(hospitals, userQuery);
                  }

                  return Column(
                    children: [

                      /// 🤖 AI RESULT
                      if (bestHospital != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Best: ${bestHospital!['name']}",
                                style:
                                    const TextStyle(fontSize: 16),
                              ),
                              Text(
                                  "Beds: ${bestHospital!['beds']} | Oxygen: ${bestHospital!['oxygen']}"),
                              Text(
                                "AI Insight: ${bestHospital!['reason']}",
                                style: const TextStyle(
                                    color: Colors.white70),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 10),

                      /// 🏥 LIST
                      Expanded(
                        child: ListView.builder(
                          itemCount: hospitals.length,
                          itemBuilder: (context, index) {

                            final h = hospitals[index];
                            int beds = h['beds'] ?? 0;

                            return Card(
                              child: ListTile(
                                title:
                                    Text(h['name'] ?? "Unknown"),
                                subtitle: Text(
                                    "Beds: $beds | Oxygen: ${h['oxygen']}"),
                                trailing: Text(
                                  AILogic.getStatus(beds),
                                  style: const TextStyle(
                                      fontWeight:
                                          FontWeight.bold),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            /// 🔀 NAVIGATION
            Row(
              children: [

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HospitalPanel(),
                        ),
                      );
                    },
                    child: const Text("Hospital Panel"),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResourceTransfer(),
                        ),
                      );
                    },
                    child: const Text("AI Transfer"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}