import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ai_logic.dart'; // ✅ YOUR AI FILE

class ResourceTransfer extends StatefulWidget {
  @override
  _ResourceTransferState createState() => _ResourceTransferState();
}

class _ResourceTransferState extends State<ResourceTransfer> {

  void executeTransfer(Map<String, dynamic> transfer) async {

    try {

      var hospitals = FirebaseFirestore.instance.collection('hospitals');

      // 🔍 Get source hospital
      var sourceSnap = await hospitals
          .where('name', isEqualTo: transfer['from'])
          .get();

      // 🔍 Get target hospital
      var targetSnap = await hospitals
          .where('name', isEqualTo: transfer['to'])
          .get();

      if (sourceSnap.docs.isEmpty || targetSnap.docs.isEmpty) return;

      var sourceDoc = sourceSnap.docs.first;
      var targetDoc = targetSnap.docs.first;

      int amount = transfer['amount'];

      // 🔥 UPDATE BOTH (REAL TRANSFER)
      await hospitals.doc(sourceDoc.id).update({
        'beds': sourceDoc['beds'] - amount
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
        backgroundColor: Colors.teal,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('hospitals')
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          // 🔥 CONVERT TO LIST
          List<Map<String, dynamic>> hospitalList =
              docs.map((doc) {
            return {
              "name": doc['name'],
              "beds": doc['beds'],
              "oxygen": doc['oxygen'],
            };
          }).toList();

          // 🔥 YOUR AI FUNCTION
          var transfer = suggestTransfer(hospitalList);

          if (transfer.containsKey("message")) {
            return Center(
              child: Text(transfer['message']),
            );
          }

          return Padding(
            padding: EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "⚠️ Imbalance Detected",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),

                SizedBox(height: 20),

                Text("🔴 Critical: ${transfer['to']}"),
                Text("🟢 Surplus: ${transfer['from']}"),

                SizedBox(height: 20),

                Text(
                  "🤖 AI Suggestion:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                Text(
                  "Transfer ${transfer['amount']} beds",
                ),

                SizedBox(height: 30),

                ElevatedButton(
                  onPressed: () => executeTransfer(transfer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                  ),
                  child: Text("Execute Transfer"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}