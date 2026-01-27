import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryFilterWidget extends StatefulWidget {
  final Function(int year, String month, String letter) onFilterChanged;
  final int initialYear;
  final String initialMonth;
  final String initialLetter;

  const HistoryFilterWidget({
    super.key,
    required this.onFilterChanged,
    required this.initialYear,
    required this.initialMonth,
    required this.initialLetter,
  });

  @override
  _HistoryFilterWidgetState createState() => _HistoryFilterWidgetState();
}

class _HistoryFilterWidgetState extends State<HistoryFilterWidget> {
  late int _selectedYear;
  late String _selectedMonth;
  late String _selectedLetter;

  // Use 3-letter month abbreviations
  final List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  
  final List<String> _letters = [
    'All', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _selectedMonth = widget.initialMonth;
    _selectedLetter = widget.initialLetter;
  }

  void _changeYear(int direction) {
    setState(() {
      _selectedYear += direction;
    });
    widget.onFilterChanged(_selectedYear, _selectedMonth, _selectedLetter);
  }

  void _selectMonth(String month) {
    setState(() {
      _selectedMonth = month;
    });
    widget.onFilterChanged(_selectedYear, _selectedMonth, _selectedLetter);
  }

  void _selectLetter(String letter) {
    setState(() {
      _selectedLetter = letter;
    });
    widget.onFilterChanged(_selectedYear, _selectedMonth, _selectedLetter);
  }

  void _clearFilters() {
    final now = DateTime.now();
    final currentMonth = DateFormat('MMM').format(now); // Use MMM format
    
    setState(() {
      _selectedYear = now.year;
      _selectedMonth = currentMonth;
      _selectedLetter = 'All';
    });
    widget.onFilterChanged(_selectedYear, _selectedMonth, _selectedLetter);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with filter label
            Row(
              children: [
                Icon(Icons.filter_list, color: Colors.white.withOpacity(0.7), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Filter History',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _clearFilters,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Year and Month Row
            Row(
              children: [
                // Year Selector
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Year',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.chevron_left, 
                                  color: Colors.white.withOpacity(0.7), size: 18),
                              onPressed: () => _changeYear(-1),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  _selectedYear.toString(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.chevron_right, 
                                  color: Colors.white.withOpacity(0.7), size: 18),
                              onPressed: () => _changeYear(1),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Month Selector
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Month',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Center(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedMonth,
                              icon: Icon(Icons.arrow_drop_down, 
                                  color: Colors.white.withOpacity(0.7), size: 18),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              dropdownColor: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(12),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  _selectMonth(newValue);
                                }
                              },
                              items: ['All', ..._months].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      value,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Alphabet Selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name Starts With',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _letters.length,
                    itemBuilder: (context, index) {
                      final letter = _letters[index];
                      final isSelected = _selectedLetter == letter;

                      return GestureDetector(
                        onTap: () => _selectLetter(letter),
                        child: Container(
                          width: 36,
                          height: 36,
                          margin: EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFFDC2626).withOpacity(0.3)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected 
                                  ? const Color(0xFFDC2626)
                                  : Colors.white.withOpacity(0.2),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              letter,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Active Filter Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.filter_alt, size: 14, color: Colors.white.withOpacity(0.6)),
                  const SizedBox(width: 8),
                  Text(
                    'Showing: $_selectedMonth $_selectedYear${_selectedLetter != 'All' ? ' • Starts with $_selectedLetter' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
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