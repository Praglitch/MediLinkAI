import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ ADD THIS

class HospitalPanel extends StatefulWidget {
  @override
  _HospitalPanelState createState() => _HospitalPanelState();
}

class _HospitalPanelState extends State<HospitalPanel> {

  String? selectedHospital;

  final TextEditingController bedsController = TextEditingController();
  final TextEditingController oxygenController = TextEditingController();

  // 🧠 SAME LIST (NO CHANGE)
  final List<String> hospitals = [
    "Max Hospital",
    "Fortis Hospital",
    "Apollo Hospital",
    "AIIMS"
  ];

  // 🔥 UPDATED FUNCTION (REAL FIREBASE)
  void updateData() async {

    if (selectedHospital == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Select hospital first")),
      );
      return;
    }

    try {

      // 🔍 FIND DOCUMENT
      var snapshot = await FirebaseFirestore.instance
          .collection('hospitals')
          .where('name', isEqualTo: selectedHospital)
          .get();

      if (snapshot.docs.isNotEmpty) {

        var docId = snapshot.docs.first.id;

        // 🔥 UPDATE DATA
        await FirebaseFirestore.instance
            .collection('hospitals')
            .doc(docId)
            .update({
          'beds': int.tryParse(bedsController.text) ?? 0,
          'oxygen': int.tryParse(oxygenController.text) ?? 0,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Live Updated Successfully")),
        );

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Hospital not found in database")),
        );

      }

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
        title: Text("🏥 Hospital Panel"),
        backgroundColor: Colors.teal,
      ),

      body: Padding(
        padding: EdgeInsets.all(16),

        child: Column(
          children: [

            // 🔽 DROPDOWN
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Select Hospital",
              ),
              value: selectedHospital,
              items: hospitals.map((h) {
                return DropdownMenuItem(
                  value: h,
                  child: Text(h),
                );
              }).toList(),

              onChanged: (value) {
                setState(() {
                  selectedHospital = value;
                });
              },
            ),

            SizedBox(height: 15),

            TextField(
              controller: bedsController,
              decoration: InputDecoration(
                labelText: "Beds Available",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

            SizedBox(height: 15),

            TextField(
              controller: oxygenController,
              decoration: InputDecoration(
                labelText: "Oxygen Units",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: updateData,
              child: Text("Update Resources"),
            ),

            SizedBox(height: 10),

            // 💎 SMALL WINNING DETAIL
            Text(
              "Last Sync: Live",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}