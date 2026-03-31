import 'package:flutter/material.dart';

class HospitalPanel extends StatefulWidget {
  @override
  _HospitalPanelState createState() => _HospitalPanelState();
}

class _HospitalPanelState extends State<HospitalPanel> {

  String? selectedHospital;

  final TextEditingController bedsController = TextEditingController();
  final TextEditingController oxygenController = TextEditingController();

  // 🧠 Dummy hospital list
  final List<String> hospitals = [
    "Max Hospital",
    "Fortis Hospital",
    "Apollo Hospital",
    "AIIMS"
  ];

  void updateData() {

    if (selectedHospital == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Select hospital first")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "✅ Updated $selectedHospital\nBeds: ${bedsController.text}, Oxygen: ${oxygenController.text}",
        ),
      ),
    );
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
          ],
        ),
      ),
    );
  }
}