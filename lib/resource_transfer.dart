import 'package:flutter/material.dart';

class ResourceTransfer extends StatefulWidget {
  @override
  _ResourceTransferState createState() => _ResourceTransferState();
}

class _ResourceTransferState extends State<ResourceTransfer> {

  List<Map<String, dynamic>> hospitals = [
    {"name": "Max Hospital", "beds": 8},
    {"name": "Fortis Hospital", "beds": 2},
    {"name": "Apollo Hospital", "beds": 0},
    {"name": "AIIMS", "beds": 6},
  ];

  String? sourceHospital;
  String? targetHospital;
  int transferAmount = 2;

  void detectAndSuggest() {

    // 🧠 find max beds (surplus)
    var maxHospital = hospitals.reduce((a, b) =>
        a['beds'] > b['beds'] ? a : b);

    // 🧠 find min beds (critical)
    var minHospital = hospitals.reduce((a, b) =>
        a['beds'] < b['beds'] ? a : b);

    sourceHospital = maxHospital['name'];
    targetHospital = minHospital['name'];
  }

  void executeTransfer() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "✅ Transferred $transferAmount beds from $sourceHospital → $targetHospital",
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    detectAndSuggest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("🔄 Resource Allocation"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "⚠️ System Alert: Imbalance Detected",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),

            SizedBox(height: 20),

            Text("🔴 Critical: $targetHospital (lowest beds)"),
            Text("🟢 Surplus: $sourceHospital (highest beds)"),

            SizedBox(height: 20),

            Text(
              "🤖 AI Suggestion:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            Text(
              "Transfer $transferAmount beds from $sourceHospital → $targetHospital",
            ),

            SizedBox(height: 30),

            ElevatedButton(
              onPressed: executeTransfer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
              child: Text("Execute Transfer"),
            ),
          ],
        ),
      ),
    );
  }
}