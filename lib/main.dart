import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

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
      home: HospitalList(),
    );
  }
}

class HospitalList extends StatelessWidget {
  final CollectionReference hospitals =
      FirebaseFirestore.instance.collection('hospitals');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hospitals Data"),
      ),
      body: StreamBuilder(
        stream: hospitals.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text(doc['name']),
                  subtitle: Text(
                      "Location: ${doc['location']}\nBeds: ${doc['beds']}\nOxygen: ${doc['oxygen']}"),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}