// my_gate_pass.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

class MyGatePass extends StatefulWidget {
  const MyGatePass({super.key});

  @override
  State<MyGatePass> createState() => _MyGatePassState();
}

class _MyGatePassState extends State<MyGatePass> {
  // Use direct colors instead of AppTheme to avoid errors
  static const Color _primaryColor = Color(0xFFDC2626);
  static const Color _glassColor = Color(0x1AFFFFFF);
  static const Color _glassBorder = Color(0x33FFFFFF);
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Color(0xB3FFFFFF);
  static const Color _textTertiary = Color(0x8AFFFFFF);
  
  static const List<Color> _backgroundGradient = [
    Color(0xFF1A1A1A),
    Color(0xFF2D1B1B),
    Color(0xFF1A1A1A),
  ];

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: _textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _buildQrPayload(Map<String, dynamic> data, String passId) {
    final studentName = (data['studentName'] ?? '').toString();
    final rollNumber = (data['rollNumber'] ?? data['roll'] ?? data['username'] ?? '').toString();
    final department = (data['department'] ?? data['dept'] ?? '').toString();
    final departure = (data['departureTime'] ?? '').toString();
    final ret = (data['returnTime'] ?? '').toString();
    final studentDocId = (data['studentDocId'] ?? '').toString();
    final uid = (data['uid'] ?? '').toString();
    final reason = (data['reason'] ?? '').toString();
    return {
      'passId': passId, 
      'studentName': studentName,
      'rollNumber': rollNumber,
      'department': department,
      'reason': reason,
      'departureTime': departure,
      'returnTime': ret,
      'studentDocId': studentDocId,
      'uid': uid,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _backgroundGradient,
            ),
          ),
          child: const Center(
            child: Text(
              'Not signed in',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    final uid = user.uid;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _glassColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _glassBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: _textSecondary),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'My Gate Pass',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('gatepass_requests')
                      .where('uid', isEqualTo: uid)
                      .orderBy('createdAt', descending: true)
                      .limit(1)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _glassColor,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: _glassBorder),
                          ),
                          child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                            strokeWidth: 3,
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _glassColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _glassBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: _textTertiary,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No Gate Pass Found",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "You haven't requested any gate pass yet.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final passDoc = snapshot.data!.docs.first;
                    final data = passDoc.data() as Map<String, dynamic>;
                    final status = (data['status'] ?? 'Pending').toString();
                    final statusLower = status.toLowerCase();

                    final returnTimeStr = data['returnTime'] as String? ?? '2000-01-01T00:00:00.000';
                    final isExpired = DateTime.now().isAfter(DateTime.parse(returnTimeStr));
                    final isUsed = (statusLower == 'in' || statusLower == 'returned');

                    final studentName = (data['studentName'] ?? '').toString();
                    final rollNumber = (data['rollNumber'] ?? data['roll'] ?? data['username'] ?? '').toString();
                    final department = (data['department'] ?? data['dept'] ?? '').toString();
                    final reason = (data['reason'] ?? '').toString();
                    final departure = (data['departureTime'] ?? '').toString();
                    final ret = (data['returnTime'] ?? '').toString();
                    final createdAt = data['createdAt'];

                    final payloadMap = _buildQrPayload(data, passDoc.id);
                    final qrData = jsonEncode(payloadMap);
                    
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // Student Info Card
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _glassColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _glassBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _glassColor,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: _glassBorder),
                                        ),
                                        child: const Icon(
                                          Icons.credit_card_outlined,
                                          color: _textPrimary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Student Information',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: _textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _infoRow('Name', studentName),
                                  _infoRow('Roll No', rollNumber),
                                  _infoRow('Department', department),
                                  if (reason.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _glassColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _glassBorder),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Reason',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: _textSecondary,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            reason,
                                            style: const TextStyle(
                                              color: _textPrimary,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (departure.isNotEmpty || ret.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _glassColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _glassBorder),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _infoRow('Departure', departure),
                                          _infoRow('Return', ret),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (createdAt != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: Text(
                                        'Requested: ${createdAt is Timestamp ? DateFormat('dd-MM-yyyy hh:mm a').format(createdAt.toDate()) : createdAt.toString()}',
                                        style: const TextStyle(
                                          color: _textTertiary, 
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Status Widget
                          if (statusLower == 'approved' && !isExpired)
                            _buildStatusWidget(
                              icon: Icons.verified_outlined,
                              color: Colors.green,
                              message: "Gate Pass Approved!",
                              subMessage: "Valid until ${ret.substring(0, 16).replaceAll('T', ' ')}",
                              qrData: qrData,
                              showQr: true,
                              status: "APPROVED",
                            )
                          else if (statusLower == 'out' && !isExpired)
                            _buildStatusWidget(
                              icon: Icons.directions_walk_outlined,
                              color: Colors.orange,
                              message: "Currently Out of Campus",
                              subMessage: "Return before ${ret.substring(0, 16).replaceAll('T', ' ')}",
                              qrData: qrData,
                              showQr: true,
                              status: "OUT",
                            )
                          else if (isUsed || isExpired)
                            _buildStatusWidget(
                              icon: Icons.lock_clock_outlined,
                              color: Colors.grey,
                              message: isExpired ? "Gate Pass Expired" : "Gate Pass Used",
                              subMessage: isUsed ? "Status: $status" : "",
                              showQr: false,
                              status: isExpired ? "EXPIRED" : "USED",
                            )
                          else if (statusLower == 'rejected')
                            _buildStatusWidget(
                              icon: Icons.cancel_outlined,
                              color: Colors.red,
                              message: "Gate Pass Rejected",
                              subMessage: reason.isNotEmpty ? 'Reason: $reason' : '',
                              showQr: false,
                              status: "REJECTED",
                            )
                          else
                            _buildStatusWidget(
                              icon: Icons.pending_actions_outlined,
                              color: Colors.blue,
                              message: "Request Pending",
                              subMessage: "Status: $status",
                              showQr: false,
                              status: "PENDING",
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusWidget({
    required IconData icon,
    required Color color,
    required String message,
    String subMessage = '',
    String qrData = '',
    bool showQr = false,
    required String status,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _glassColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (showQr) ...[
              // QR Code at the TOP
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                  gapless: true,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // QR Instructions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _glassColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Scan this QR at the gate to go out or return",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
            
            // Status Badge - Smaller text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            
            const SizedBox(height: 16),
            
            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Sub Message
            if (subMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  subMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}