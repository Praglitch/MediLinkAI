import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ai_logic.dart';

class ResourceTransfer extends StatefulWidget {
  @override
  _ResourceTransferState createState() => _ResourceTransferState();
}

class _ResourceTransferState extends State<ResourceTransfer> {

  Future<void> executeTransfer(Map<String, dynamic> transfer) async {
    try {
      var hospitals =
          FirebaseFirestore.instance.collection('hospitals');

      var sourceSnap = await hospitals
          .where('name', isEqualTo: transfer['from'])
          .get();

      var targetSnap = await hospitals
          .where('name', isEqualTo: transfer['to'])
          .get();

      if (sourceSnap.docs.isEmpty || targetSnap.docs.isEmpty) return;

      var sourceDoc = sourceSnap.docs.first;
      var targetDoc = targetSnap.docs.first;

      int amount = transfer['amount'];

      await hospitals.doc(sourceDoc.id).update({
        'beds': (sourceDoc['beds'] - amount).clamp(0, 999)
      });

      await hospitals.doc(targetDoc.id).update({
        'beds': targetDoc['beds'] + amount
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Transfer Executed Successfully")),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("🔄 Resource Optimization"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('hospitals')
            .snapshots(),

        builder: (context, snapshot) {

          // ⏳ Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // ❌ No data
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Scanning network...\nNo data yet",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          // 🔥 Convert Firestore → List<Map>
          List<Map<String, dynamic>> hospitalList =
              docs.map((doc) {
            return {
              "name": doc['name'],
              "beds": doc['beds'],
              "oxygen": doc['oxygen'],
            };
          }).toList();

          // 🔥 AI Logic
          var transfer = suggestTransfer(hospitalList);

          return Padding(
            padding: EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // 🔥 Header
                Text(
                  "🔄 Smart Resource Allocation",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 20),

                // 🟢 CASE 1: SYSTEM STABLE
                if (transfer.containsKey("message")) ...[

                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF121A2F),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "✅ ${transfer['message']}",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          transfer['action'] ?? "",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                ] else ...[

                  // 🔴 Critical hospital
                  Text(
                    "🔴 Critical: ${transfer['to']}",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  // 🟢 Surplus hospital
                  Text(
                    "🟢 Surplus: ${transfer['from']}",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 20),

                  Text(
                    "🤖 AI Suggestion:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 5),

                  Text(
                    "Transfer ${transfer['amount']} beds",
                  ),

                  SizedBox(height: 10),

                  Text(
                    "Impact: System balance will improve",
                    style: TextStyle(color: Colors.green),
                  ),

                  SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: () => executeTransfer(transfer),
                    child: Text("Execute Transfer"),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}