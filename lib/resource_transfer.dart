import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ai_logic.dart';

class ResourceTransfer extends StatelessWidget {
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
                  List<Map<String, dynamic>> hospitals = docs.map((d) {
                    return {
                      "id": d.id,
                      ...d.data() as Map<String, dynamic>,
                    };
                  }).toList();

                  final suggestion =
                      AILogic.getTransferSuggestion(hospitals);

                  if (suggestion == null) {
                    return _buildBalanced();
                  }

                  int fromBeds = suggestion['fromBeds'] ?? 0;
                  int toBeds = suggestion['toBeds'] ?? 0;
                  int amount = suggestion['amount'] ?? 0;

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [

                      // ALERT
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7F1D1D).withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFEF4444)
                                  .withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 16),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text("Resource Imbalance Detected",
                                      style: TextStyle(
                                          color: Color(0xFFEF4444),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                  SizedBox(height: 2),
                                  Text(
                                      "AI has identified uneven bed distribution",
                                      style: TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // TRANSFER PLAN CARD
                      Container(
                        padding: const EdgeInsets.all(16),
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
                                Icon(Icons.swap_horiz_rounded,
                                    color: Color(0xFF3B82F6), size: 13),
                                SizedBox(width: 6),
                                Text("TRANSFER PLAN",
                                    style: TextStyle(
                                        color: Color(0xFF3B82F6),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _transferCard(
                                    label: "FROM",
                                    name: suggestion['from'],
                                    beds: fromBeds,
                                    change: "-$amount",
                                    isSource: true,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3B82F6)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: const Color(0xFF3B82F6)
                                                  .withOpacity(0.2)),
                                        ),
                                        child: Column(
                                          children: [
                                            const Icon(Icons.arrow_forward,
                                                color: Color(0xFF3B82F6),
                                                size: 14),
                                            const SizedBox(height: 3),
                                            Text("$amount",
                                                style: const TextStyle(
                                                    color:
                                                        Color(0xFF3B82F6),
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const Text("beds",
                                                style: TextStyle(
                                                    color:
                                                        Color(0xFF6B7280),
                                                    fontSize: 10)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: _transferCard(
                                    label: "TO",
                                    name: suggestion['to'],
                                    beds: toBeds,
                                    change: "+$amount",
                                    isSource: false,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // AFTER TRANSFER PREVIEW
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1623),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("AFTER TRANSFER PREVIEW",
                                style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2)),
                            const SizedBox(height: 12),
                            _previewRow(
                                suggestion['from'],
                                fromBeds,
                                fromBeds - amount,
                                const Color(0xFFEF4444)),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(
                                  color: Color(0xFF1A2035), height: 1),
                            ),
                            _previewRow(
                                suggestion['to'],
                                toBeds,
                                toBeds + amount,
                                const Color(0xFF10B981)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // AI INSIGHT
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1628),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF3B82F6)
                                  .withOpacity(0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.auto_awesome,
                                color: Color(0xFF3B82F6), size: 13),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(suggestion['reason'],
                                  style: const TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 12,
                                      height: 1.5)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // EXECUTE BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.swap_horiz_rounded,
                              size: 17),
                          label: const Text("Execute Transfer",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            try {
                              final fromDoc = docs.firstWhere((d) =>
                                  (d.data() as Map)['name'] ==
                                  suggestion['from']);
                              final toDoc = docs.firstWhere((d) =>
                                  (d.data() as Map)['name'] ==
                                  suggestion['to']);

                              int currentFrom =
                                  _parseInt(fromDoc['beds']);
                              int currentTo = _parseInt(toDoc['beds']);

                              await FirebaseFirestore.instance
                                  .collection('hospitals')
                                  .doc(fromDoc.id)
                                  .update(
                                      {'beds': currentFrom - amount});
                              await FirebaseFirestore.instance
                                  .collection('hospitals')
                                  .doc(toDoc.id)
                                  .update({'beds': currentTo + amount});

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor:
                                      const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  content: const Row(children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.white, size: 15),
                                    SizedBox(width: 8),
                                    Text("Transfer Completed Successfully"),
                                  ]),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor:
                                      const Color(0xFFEF4444),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  content: Text("Error: $e"),
                                ),
                              );
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 16),
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

  Widget _buildBalanced() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.2)),
            ),
            child: const Icon(Icons.check_circle_outline,
                color: Color(0xFF10B981), size: 42),
          ),
          const SizedBox(height: 16),
          const Text("System Balanced",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text("All hospitals have adequate resources.",
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          const Text("No transfer needed.",
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome,
                    color: Color(0xFF10B981), size: 13),
                SizedBox(width: 7),
                Text("AI monitoring in real-time",
                    style: TextStyle(
                        color: Color(0xFF10B981), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
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
              Text("AI Resource Optimization",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              Text("Intelligent bed redistribution",
                  style: TextStyle(
                      color: Color(0xFF4B5563), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _transferCard({
    required String label,
    required String name,
    required int beds,
    required String change,
    required bool isSource,
  }) {
    Color color =
        isSource ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text("$beds beds now",
              style: const TextStyle(
                  color: Color(0xFF6B7280), fontSize: 11)),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(change,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _previewRow(
      String name, int before, int after, Color color) {
    return Row(
      children: [
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
                color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(name,
              style: const TextStyle(
                  color: Color(0xFF9CA3AF), fontSize: 12)),
        ),
        Text("$before beds",
            style: const TextStyle(
                color: Color(0xFF6B7280), fontSize: 12)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward,
              size: 11, color: Color(0xFF4B5563)),
        ),
        Text("$after beds",
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}