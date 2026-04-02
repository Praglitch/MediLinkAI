import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'ai_logic.dart';

class ResourceTransfer extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Resource Optimization"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('hospitals')
              .snapshots(),
          builder: (context, snapshot) {

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            /// 🔄 CONVERT DATA SAFELY
            List<Map<String, dynamic>> hospitals = docs.map((d) {
              return {
                "id": d.id,
                ...d.data() as Map<String, dynamic>,
              };
            }).toList();

            /// 🤖 AI SUGGESTION
            final suggestion =
                AILogic.getTransferSuggestion(hospitals);

            if (suggestion == null) {
              return const Center(
                child: Text("System Balanced ✅"),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// ⚠️ ALERT
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "⚠️ Resource Imbalance Detected",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),

                const SizedBox(height: 20),

                /// 📊 DETAILS
                Text(
                  "From: ${suggestion['from']}",
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  "To: ${suggestion['to']}",
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  "Transfer: ${suggestion['amount']} beds",
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 10),

                Text(
                  "AI Insight: ${suggestion['reason']}",
                  style: const TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 20),

                /// 🚀 EXECUTE BUTTON
                ElevatedButton(
                  onPressed: () async {

                    try {

                      final fromDoc = docs.firstWhere(
                        (d) =>
                            (d.data() as Map)['name'] ==
                            suggestion['from'],
                      );

                      final toDoc = docs.firstWhere(
                        (d) =>
                            (d.data() as Map)['name'] ==
                            suggestion['to'],
                      );

                      int amount = suggestion['amount'];

                      int fromBeds =
                          (fromDoc['beds'] ?? 0) as int;

                      int toBeds =
                          (toDoc['beds'] ?? 0) as int;

                      /// 🔄 UPDATE FIRESTORE
                      await FirebaseFirestore.instance
                          .collection('hospitals')
                          .doc(fromDoc.id)
                          .update({
                        'beds': fromBeds - amount,
                      });

                      await FirebaseFirestore.instance
                          .collection('hospitals')
                          .doc(toDoc.id)
                          .update({
                        'beds': toBeds + amount,
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Transfer Completed ✅"),
                        ),
                      );

                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error: $e"),
                        ),
                      );
                    }
                  },
                  child: const Text("Execute Transfer"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}