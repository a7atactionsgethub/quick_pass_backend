// view_requests.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class MyGatePass extends StatefulWidget {
  final String rollNumber;

  const MyGatePass({
    super.key,
    required this.rollNumber,
  });

  @override
  State<MyGatePass> createState() => _MyGatePassState();
}

class _MyGatePassState extends State<MyGatePass> {
  // Backend URL
  final String _baseUrl = 'http://127.0.0.1:5000/api';
  
  // Use direct colors
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

  List<dynamic> _gatePasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGatePasses();
  }

  Future<void> _fetchGatePasses() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('$_baseUrl/gatepass/student/${widget.rollNumber}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _gatePasses = data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching gate passes: $e');
      setState(() => _isLoading = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
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
                      'My Gate Passes',
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
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                        ),
                      )
                    : _gatePasses.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _gatePasses.length,
                            itemBuilder: (context, index) {
                              final pass = _gatePasses[index];
                              return _buildGatePassCard(pass);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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

  Widget _buildGatePassCard(Map<String, dynamic> pass) {
    final status = pass['status'] ?? 'Pending';
    final Color statusColor = status.toLowerCase() == 'approved' 
        ? Colors.green 
        : status.toLowerCase() == 'rejected'
            ? Colors.red
            : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _glassColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Request #${pass['id']}',
                style: const TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Reason: ${pass['reason'] ?? 'N/A'}',
            style: const TextStyle(color: _textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Departure: ${_formatDate(pass['departureTime'])}',
            style: const TextStyle(color: _textSecondary, fontSize: 12),
          ),
          Text(
            'Return: ${_formatDate(pass['returnTime'])}',
            style: const TextStyle(color: _textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}