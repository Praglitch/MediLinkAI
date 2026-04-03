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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF060B14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          surface: Color(0xFF0F1623),
        ),
      ),
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
  final TextEditingController _queryController = TextEditingController();

  final List<Map<String, dynamic>> _quickChips = [
    {"label": "Fever", "icon": Icons.thermostat, "color": Color(0xFFEF4444)},
    {"label": "ICU", "icon": Icons.monitor_heart, "color": Color(0xFFF59E0B)},
    {"label": "Oxygen", "icon": Icons.air, "color": Color(0xFF06B6D4)},
    {"label": "Critical", "icon": Icons.warning_amber, "color": Color(0xFFEF4444)},
    {"label": "Breathing", "icon": Icons.air, "color": Color(0xFF8B5CF6)},
    {"label": "Emergency", "icon": Icons.emergency, "color": Color(0xFFEC4899)},
  ];

  void _applyChip(String label) {
    setState(() {
      userQuery = label.toLowerCase();
      _queryController.text = label;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B14),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('hospitals')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF3B82F6)),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  List<Map<String, dynamic>> hospitals = docs
                      .map((d) => d.data() as Map<String, dynamic>)
                      .toList();

                  if (userQuery.isNotEmpty) {
                    bestHospital =
                        AILogic.getBestHospital(hospitals, userQuery);
                  }

                  int critical = hospitals.where((h) {
                    int b = _parseInt(h['beds']);
                    int o = _parseInt(h['oxygen']);
                    String s = AILogic.getStatus(b, o);
                    return s == "CRITICAL" || s == "LOW";
                  }).length;
                  int stable = hospitals.length - critical;
                  String sysStatus = critical == 0
                      ? "ALL SYSTEMS NORMAL"
                      : critical == 1
                          ? "MINOR IMBALANCE"
                          : "CRITICAL ALERT";
                  Color sysColor = critical == 0
                      ? const Color(0xFF10B981)
                      : critical == 1
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFEF4444);

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [

                      // SYSTEM STATUS BANNER
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: sysColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: sysColor.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: sysColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: sysColor.withOpacity(0.6),
                                      blurRadius: 6,
                                      spreadRadius: 1)
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(sysStatus,
                                style: TextStyle(
                                    color: sysColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8)),
                            const Spacer(),
                            Text(
                              "${hospitals.length} hospitals monitored",
                              style: const TextStyle(
                                  color: Color(0xFF6B7280), fontSize: 11),
                            ),
                          ],
                        ),
                      ),

                      // STATS ROW
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(
                          children: [
                            _statBox("Total", "${hospitals.length}",
                                Icons.local_hospital_outlined,
                                const Color(0xFF3B82F6)),
                            const SizedBox(width: 10),
                            _statBox("Stable", "$stable",
                                Icons.check_circle_outline,
                                const Color(0xFF10B981)),
                            const SizedBox(width: 10),
                            _statBox("Critical", "$critical",
                                Icons.warning_amber_rounded,
                                const Color(0xFFEF4444)),
                          ],
                        ),
                      ),

                      // SEARCH BAR
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1623),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.07)),
                          ),
                          child: TextField(
                            controller: _queryController,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText:
                                  "Describe emergency or tap below...",
                              hintStyle: TextStyle(
                                  color: Color(0xFF4B5563), fontSize: 13),
                              prefixIcon: Icon(Icons.search,
                                  color: Color(0xFF4B5563), size: 18),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            onChanged: (val) => userQuery = val,
                          ),
                        ),
                      ),

                      // QUICK CHIPS
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _quickChips.map((chip) {
                            bool selected = userQuery ==
                                chip['label'].toString().toLowerCase();
                            Color c = chip['color'] as Color;
                            return GestureDetector(
                              onTap: () =>
                                  _applyChip(chip['label'].toString()),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? c.withOpacity(0.2)
                                      : c.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected
                                        ? c.withOpacity(0.7)
                                        : c.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(chip['icon'] as IconData,
                                        size: 12, color: c),
                                    const SizedBox(width: 5),
                                    Text(chip['label'].toString(),
                                        style: TextStyle(
                                            color: c,
                                            fontSize: 12,
                                            fontWeight: selected
                                                ? FontWeight.bold
                                                : FontWeight.normal)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // ANALYZE BUTTON
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() {}),
                            icon: const Icon(Icons.auto_awesome, size: 15),
                            label: const Text("Analyze with AI",
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),

                      // AI RESULT
                      if (bestHospital != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: _buildAICard(bestHospital!),
                        ),

                      // HOSPITALS HEADER
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                        child: Row(
                          children: [
                            const Text("HOSPITALS",
                                style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text("${hospitals.length}",
                                  style: const TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 10)),
                            ),
                            const Spacer(),
                            const Icon(Icons.circle,
                                color: Color(0xFF10B981), size: 7),
                            const SizedBox(width: 5),
                            const Text("Live",
                                style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 11)),
                          ],
                        ),
                      ),

                      // HOSPITAL CARDS
                      ...hospitals.map((h) => Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: _buildHospitalCard(h, bestHospital),
                          )),

                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),

            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  int _parseInt(dynamic val) {
    if (val is int) return val;
    return int.tryParse(val.toString()) ?? 0;
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1020),
        border:
            Border(bottom: BorderSide(color: Color(0xFF1A2035), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.local_hospital,
                color: Color(0xFF3B82F6), size: 17),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("MediLink AI",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              Text("Emergency Resource System",
                  style:
                      TextStyle(color: Color(0xFF4B5563), fontSize: 10)),
            ],
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Color(0xFF10B981), size: 7),
                SizedBox(width: 5),
                Text("LIVE",
                    style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(height: 7),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF6B7280), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildAICard(Map<String, dynamic> hospital) {
    int beds = _parseInt(hospital['beds']);
    int oxygen = _parseInt(hospital['oxygen']);
    Color statusColor = AILogic.getStatusColor(beds, oxygen);
    String status = AILogic.getStatus(beds, oxygen);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF3B82F6).withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: Color(0xFF3B82F6), size: 12),
              const SizedBox(width: 6),
              const Text("AI RECOMMENDATION",
                  style: TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: statusColor.withOpacity(0.35)),
                ),
                child: Text(status,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(hospital['name'] ?? "",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              _chip(Icons.bed, "$beds Beds",
                  const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              _chip(Icons.air, "$oxygen O₂",
                  const Color(0xFF06B6D4)),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFF6B7280), size: 12),
              const SizedBox(width: 6),
              Expanded(
                child: Text(hospital['reason'] ?? "",
                    style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                        height: 1.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalCard(
      Map<String, dynamic> h, Map<String, dynamic>? best) {
    int beds = _parseInt(h['beds']);
    int oxygen = _parseInt(h['oxygen']);
    String status = AILogic.getStatus(beds, oxygen);
    Color statusColor = AILogic.getStatusColor(beds, oxygen);
    bool isRecommended =
        best != null && best['name'] == h['name'];
    double bedPct = (beds / 20).clamp(0.0, 1.0);
    double oxyPct = (oxygen / 100).clamp(0.0, 1.0);
    String? lastUpdated = h['lastUpdated'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRecommended
            ? const Color(0xFF0A1628)
            : const Color(0xFF0F1623),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRecommended
              ? const Color(0xFF3B82F6).withOpacity(0.45)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: statusColor.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1)
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(h['name'] ?? "Unknown",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        if (isRecommended) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: const Color(0xFF3B82F6)
                                      .withOpacity(0.3)),
                            ),
                            child: const Text("AI Pick",
                                style: TextStyle(
                                    color: Color(0xFF3B82F6),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ]
                      ],
                    ),
                    if (lastUpdated != null)
                      Text(
                        "Updated ${_formatTime(lastUpdated)}",
                        style: const TextStyle(
                            color: Color(0xFF4B5563), fontSize: 10),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(7),
                  border:
                      Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(status,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _resourceBar("Beds", "$beds", bedPct, statusColor,
              Icons.bed_outlined),
          const SizedBox(height: 7),
          _resourceBar("Oxygen", "$oxygen units", oxyPct,
              const Color(0xFF06B6D4), Icons.air),
        ],
      ),
    );
  }

  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return "just now";
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      if (diff.inHours < 24) return "${diff.inHours}h ago";
      return "${diff.inDays}d ago";
    } catch (_) {
      return "recently";
    }
  }

  Widget _resourceBar(String label, String value, double percent,
      Color color, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: const Color(0xFF6B7280)),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF6B7280), fontSize: 11)),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.white.withOpacity(0.05),
            color: color,
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1020),
        border: Border(top: BorderSide(color: Color(0xFF1A2035))),
      ),
      child: Row(
        children: [
          Expanded(
            child: _navBtn(
              icon: Icons.dashboard_customize_outlined,
              label: "Hospital Panel",
              color: const Color(0xFF3B82F6),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => HospitalPanel())),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _navBtn(
              icon: Icons.swap_horiz_rounded,
              label: "AI Transfer",
              color: const Color(0xFFF59E0B),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ResourceTransfer())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 7),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}