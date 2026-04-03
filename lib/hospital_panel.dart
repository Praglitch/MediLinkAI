import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ai_logic.dart';

class HospitalPanel extends StatefulWidget {
  @override
  State<HospitalPanel> createState() => _HospitalPanelState();
}

class _HospitalPanelState extends State<HospitalPanel> {
  final TextEditingController bedsController = TextEditingController();
  final TextEditingController oxygenController = TextEditingController();
  String? selectedHospitalId;
  String? selectedHospitalName;

  int _parseInt(dynamic val) {
    if (val is int) return val;
    return int.tryParse(val.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B14),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('hospitals')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF3B82F6)));
                  }

                  final docs = snapshot.data!.docs;

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [

                      // UPDATE FORM
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1623),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.edit_outlined,
                                    color: Color(0xFF3B82F6), size: 14),
                                SizedBox(width: 7),
                                Text("UPDATE RESOURCES",
                                    style: TextStyle(
                                        color: Color(0xFF3B82F6),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2)),
                              ],
                            ),
                            const SizedBox(height: 16),

                            const Text("Select Hospital",
                                style: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF060B14),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color:
                                        Colors.white.withOpacity(0.07)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  hint: const Text("Choose hospital",
                                      style: TextStyle(
                                          color: Color(0xFF4B5563),
                                          fontSize: 13)),
                                  value: selectedHospitalId,
                                  dropdownColor: const Color(0xFF0F1623),
                                  isExpanded: true,
                                  items: docs.map((doc) {
                                    final data = doc.data()
                                        as Map<String, dynamic>;
                                    return DropdownMenuItem(
                                      value: doc.id,
                                      child: Text(
                                          data['name'] ?? "Unknown",
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      selectedHospitalId = val;
                                      selectedHospitalName = (docs
                                              .firstWhere(
                                                  (d) => d.id == val)
                                              .data()
                                          as Map)['name'];
                                    });
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("Beds Available",
                                          style: TextStyle(
                                              color: Color(0xFF9CA3AF),
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight.w500)),
                                      const SizedBox(height: 6),
                                      _inputField(
                                          bedsController,
                                          "e.g. 12",
                                          Icons.bed_outlined),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("Oxygen Units",
                                          style: TextStyle(
                                              color: Color(0xFF9CA3AF),
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight.w500)),
                                      const SizedBox(height: 6),
                                      _inputField(
                                          oxygenController,
                                          "e.g. 40",
                                          Icons.air),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.sync, size: 15),
                                label: const Text("Update Resources",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF3B82F6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                onPressed: () async {
                                  if (selectedHospitalId == null)
                                    return;
                                  int beds = int.tryParse(
                                          bedsController.text.trim()) ??
                                      0;
                                  int oxygen = int.tryParse(
                                          oxygenController.text
                                              .trim()) ??
                                      0;
                                  await FirebaseFirestore.instance
                                      .collection('hospitals')
                                      .doc(selectedHospitalId)
                                      .update({
                                    'beds': beds,
                                    'oxygen': oxygen,
                                    'lastUpdated':
                                        DateTime.now().toString(),
                                  });
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    backgroundColor:
                                        const Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    content: Row(children: [
                                      const Icon(Icons.check_circle,
                                          color: Colors.white, size: 15),
                                      const SizedBox(width: 8),
                                      Text(
                                          "${selectedHospitalName ?? 'Hospital'} updated"),
                                    ]),
                                  ));
                                  bedsController.clear();
                                  oxygenController.clear();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: const [
                          Text("LIVE STATUS",
                              style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2)),
                          SizedBox(width: 8),
                          Icon(Icons.circle,
                              color: Color(0xFF10B981), size: 7),
                        ],
                      ),

                      const SizedBox(height: 10),

                      ...docs.map((doc) {
                        final data =
                            doc.data() as Map<String, dynamic>;
                        int beds = _parseInt(data['beds']);
                        int oxygen = _parseInt(data['oxygen']);
                        String status = AILogic.getStatus(beds, oxygen);
                        Color statusColor =
                            AILogic.getStatusColor(beds, oxygen);
                        double bedPct = (beds / 20).clamp(0.0, 1.0);
                        double oxyPct =
                            (oxygen / 100).clamp(0.0, 1.0);
                        String? lastUpdated = data['lastUpdated'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1623),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    Colors.white.withOpacity(0.05)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                            color: statusColor
                                                .withOpacity(0.5),
                                            blurRadius: 5)
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(data['name'] ?? "Unknown",
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight:
                                                    FontWeight.w600)),
                                        if (lastUpdated != null)
                                          Text(
                                            "Updated ${_formatTime(lastUpdated)}",
                                            style: const TextStyle(
                                                color: Color(0xFF4B5563),
                                                fontSize: 10),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      border: Border.all(
                                          color:
                                              statusColor.withOpacity(0.3)),
                                    ),
                                    child: Text(status,
                                        style: TextStyle(
                                            color: statusColor,
                                            fontSize: 10,
                                            fontWeight:
                                                FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _bar("Beds", "$beds", bedPct, statusColor,
                                  Icons.bed_outlined),
                              const SizedBox(height: 6),
                              _bar("Oxygen", "$oxygen units", oxyPct,
                                  const Color(0xFF06B6D4), Icons.air),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1020),
        border: Border(
            bottom: BorderSide(color: Color(0xFF1A2035), width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.white.withOpacity(0.07)),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 13, color: Colors.white60),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hospital Control Panel",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              Text("Update resource availability",
                  style: TextStyle(
                      color: Color(0xFF4B5563), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String hint,
      IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF060B14),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Color(0xFF4B5563)),
          prefixIcon:
              Icon(icon, color: const Color(0xFF4B5563), size: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 13),
        ),
      ),
    );
  }

  Widget _bar(String label, String value, double percent, Color color,
      IconData icon) {
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
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.white.withOpacity(0.05),
            color: color,
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}