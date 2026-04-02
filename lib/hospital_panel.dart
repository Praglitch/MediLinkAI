import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HospitalPanel extends StatefulWidget {
  @override
  State<HospitalPanel> createState() => _HospitalPanelState();
}

class _HospitalPanelState extends State<HospitalPanel> {

  final TextEditingController bedsController = TextEditingController();
  final TextEditingController oxygenController = TextEditingController();

  String? selectedHospitalId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hospital Control Panel"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🔴 LIVE DATA DROPDOWN
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('hospitals')
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final docs = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  hint: const Text("Select Hospital"),
                  value: selectedHospitalId,
                  items: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(data['name'] ?? "Unknown"),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedHospitalId = val;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            /// 🛏️ BEDS INPUT
            TextField(
              controller: bedsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Beds Available",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            /// 🫁 OXYGEN INPUT
            TextField(
              controller: oxygenController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Oxygen Units",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔄 UPDATE BUTTON
            ElevatedButton(
              onPressed: () async {

                if (selectedHospitalId == null) return;

                int beds =
                    int.tryParse(bedsController.text.trim()) ?? 0;

                int oxygen =
                    int.tryParse(oxygenController.text.trim()) ?? 0;

                await FirebaseFirestore.instance
                    .collection('hospitals')
                    .doc(selectedHospitalId)
                    .update({
                  'beds': beds,
                  'oxygen': oxygen,
                  'lastUpdated': DateTime.now().toString(),
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Updated successfully"),
                  ),
                );

                bedsController.clear();
                oxygenController.clear();
              },
              child: const Text("Update Resources"),
            ),

            const SizedBox(height: 20),

            /// 📡 LIVE SYNC DISPLAY
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

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {

                      final data =
                          docs[index].data() as Map<String, dynamic>;

                      return Card(
                        child: ListTile(
                          title: Text(data['name'] ?? "Unknown"),
                          subtitle: Text(
                              "Beds: ${data['beds']} | Oxygen: ${data['oxygen']}"),
                          trailing: Text(
                            data['lastUpdated'] ?? "Just now",
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}