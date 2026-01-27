// qr_scanner_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  String scannedData = 'Scan a QR code to get data';
  bool isScanning = true;
  bool isLoading = false;
  Map<String, dynamic>? _scannedStudent;

  // Glassmorphism Colors
  final Color _primaryRed = const Color(0xFFDC2626);
  final Color _darkRed = const Color(0xFF991B1B);
  final Color _glassWhite = Colors.white.withOpacity(0.1);
  final Color _glassBorder = Colors.white.withOpacity(0.2);

  Future<void> _showInvalidPassDialog(String message, String title, IconData icon) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF2A1A1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: _primaryRed,
                size: 60,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [_primaryRed, _darkRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resetScan();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processBarcode(String data) async {
    if (!isScanning || isLoading) return;

    setState(() {
      isLoading = true;
      isScanning = false;
    });

    try {
      final Map<String, dynamic> parsedJson = jsonDecode(data);
      final roll = parsedJson['roll'] ?? parsedJson['rollNumber'];
      final departureStr = parsedJson['departureTime'];
      final returnStr = parsedJson['returnTime'];
      final passId = parsedJson['passId'];

      if (roll == null || departureStr == null || returnStr == null || passId == null) {
        throw const FormatException("Missing required fields in QR code data.");
      }

      final departureTime = DateTime.parse(departureStr).toLocal();
      final returnTime = DateTime.parse(returnStr).toLocal();
      final now = DateTime.now();

      if (now.isBefore(departureTime)) {
        await _showInvalidPassDialog(
          "Gatepass not yet valid.\nValid from: ${DateFormat('dd-MM-yyyy hh:mm a').format(departureTime)}",
          "Not Yet Valid",
          Icons.access_time,
        );
        return;
      }

      if (now.isAfter(returnTime)) {
        await _showInvalidPassDialog(
          "Gatepass has expired.\nValid until: ${DateFormat('dd-MM-yyyy hh:mm a').format(returnTime)}",
          "Gatepass Expired",
          Icons.error_outline,
        );
        return;
      }

      // Check if pass exists in gatepass_requests
      final requestDocSnapshot =
          await FirebaseFirestore.instance.collection('gatepass_requests').doc(passId).get();

      if (!requestDocSnapshot.exists) {
        await _showInvalidPassDialog("Gatepass not found in system.", "Invalid Gatepass", Icons.block);
        return;
      }

      if (mounted) {
        setState(() {
          _scannedStudent = parsedJson;
          scannedData = 'Gatepass for ${parsedJson['studentName'] ?? parsedJson['name']} is valid.';
        });
      }
    } catch (e) {
      if (mounted) {
        _showInvalidPassDialog(
          'Error processing QR code: $e',
          'Scan Error',
          Icons.qr_code_scanner,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _handleStatus(String action) async {
    if (_scannedStudent == null || isLoading) return;

    setState(() => isLoading = true);

    try {
      final roll = _scannedStudent!['roll'] ?? _scannedStudent!['rollNumber'];
      final passId = _scannedStudent!['passId'];
      final gatepassesCollection = FirebaseFirestore.instance.collection('gatepasses');

      if (roll == null) {
        throw Exception("Roll number missing in scanned data.");
      }

      final now = FieldValue.serverTimestamp();

      if (action.toLowerCase() == 'out') {
        // Check if already out without in
        final query = await gatepassesCollection
            .where('rollNumber', isEqualTo: roll)
            .where('status', isEqualTo: 'Out')
            .where('inTime', isNull: true)
            .get();

        if (query.docs.isNotEmpty) {
          await _showInvalidPassDialog(
            "Student is already marked OUT and has not returned yet.",
            "Already Out",
            Icons.warning,
          );
          return;
        }

        // Add new "Out" record with current time as outTime
        await gatepassesCollection.add({
          ..._scannedStudent!,
          'status': 'Out',
          'outTime': now,
          'inTime': null,
          'passRequestId': passId,
          'createdAt': now,
          'reason': _scannedStudent!['reason'] ?? '',
        });
      } else if (action.toLowerCase() == 'in') {
        // Find last "Out" record with no inTime
        final query = await gatepassesCollection
            .where('rollNumber', isEqualTo: roll)
            .where('status', isEqualTo: 'Out')
            .where('inTime', isNull: true)
            .orderBy('outTime', descending: true)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          await _showInvalidPassDialog(
            "No OUT record found. Please scan OUT before scanning IN.",
            "No Out Record",
            Icons.warning,
          );
          return;
        }

        final docRef = query.docs.first.reference;

        await docRef.update({
          'inTime': now,
          'status': 'In',
        });
      } else {
        throw Exception('Invalid action: $action');
      }

      if (!mounted) return;
      
      // Show success dialog
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF2A1A1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _glassBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
                const SizedBox(height: 20),
                Text(
                  'Success!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Marked as ${action.toLowerCase()}",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [_primaryRed, _darkRed],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _resetScan();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

    } catch (e) {
      if (mounted) {
        _showInvalidPassDialog(
          'Error saving to gatepasses: $e',
          'Save Error',
          Icons.error_outline,
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _resetScan() {
    setState(() {
      scannedData = 'Scan a QR code to get data';
      isScanning = true;
      _scannedStudent = null;
    });
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF2A1A1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.logout,
                color: _primaryRed,
                size: 60,
              ),
              const SizedBox(height: 20),
              const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to logout?',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _glassBorder),
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [_primaryRed, _darkRed],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      context.go('/signin');
    }
  }

  Widget _statusButton(String label, Color color) {
    return Container(
      width: 120,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [color, Color.alphaBlend(Colors.black.withOpacity(0.3), color)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _handleStatus(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label, 
          style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF2D1B1B),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: Column(
          children: [
            // App Bar
            Container(
              padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 16),
              decoration: BoxDecoration(
                color: _glassWhite,
                border: Border(bottom: BorderSide(color: _glassBorder)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'QR Scanner - Security',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _glassWhite,
                      border: Border.all(color: _glassBorder),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white70),
                      onPressed: _confirmLogout,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _glassBorder, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: MobileScanner(
                              controller: MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates),
                              onDetect: (barcodeCapture) {
                                final data = barcodeCapture.barcodes.firstOrNull?.rawValue;
                                if (data != null && isScanning) {
                                  _processBarcode(data);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _glassWhite,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _glassBorder, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _scannedStudent != null
                                    ? 'Gatepass for ${_scannedStudent!['studentName'] ?? _scannedStudent!['name'] ?? 'N/A'}'
                                    : scannedData,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 12),
                              if (_scannedStudent != null) ...[
                                Text(
                                  'Roll: ${_scannedStudent!['roll'] ?? _scannedStudent!['rollNumber'] ?? 'N/A'}  Dept: ${_scannedStudent!['department'] ?? _scannedStudent!['dept'] ?? 'N/A'}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _statusButton('In', Colors.green),
                                    _statusButton('Out', _primaryRed),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _glassBorder),
                                ),
                                child: ElevatedButton(
                                  onPressed: _resetScan,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Scan Another QR',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isLoading)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}