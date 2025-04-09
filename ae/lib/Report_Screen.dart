import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class searchuser extends StatefulWidget {
  const searchuser({super.key});

  @override
  State<searchuser> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<searchuser> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _filteredResults = [];
  final _supabase = Supabase.instance.client;
  String _selectedFilter = 'all';

  /// Search Attendance from Supabase
  void _performSearch(String query) async {
    // Clear results immediately when query is empty
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _filteredResults = [];
        _searchController.clear();
      });
      return;
    }

    try {
      final response = await _supabase
          .from('attendance2')
          .select('user_id, user_name, time_out')
          .or('user_id.ilike.%$query%,user_name.ilike.%$query%');

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(response);
        _applyFilter(_selectedFilter);
      });
    } catch (e) {
      print('Error searching: $e');
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      final now = DateTime.now().toIso8601String();
      final nowDateTime = DateTime.parse(now);
      print("Applying filter: $filter");

      _filteredResults = _searchResults.where((record) {
        if (record['time_out'] == null) return false; // Ensure timestamp exists

        DateTime recordDate;
        try {
          // Convert ISO timestamp to DateTime (Ensure it's in Local Time)
          recordDate = DateTime.parse(record['time_out']).toLocal();
        } catch (e) {
          print("Invalid timestamp: ${record['time_out']}");
          return false;
        }

        bool isIncluded = false;

        switch (filter) {
          case 'last_week':
            final lastWeekStart = nowDateTime.subtract(Duration(days: 7));
            isIncluded = recordDate.isAfter(lastWeekStart) &&
                recordDate.isBefore(nowDateTime);
            break;
          case 'last_month':
            final lastMonthStart = nowDateTime.subtract(Duration(days: 30));
            final lastWeekStart = nowDateTime.subtract(Duration(days: 7));
            isIncluded = recordDate.isAfter(lastMonthStart) &&
                recordDate.isBefore(lastWeekStart);
            break;
          case 'last_year':
            final lastYearStart = nowDateTime.subtract(Duration(days: 365));
            final lastMonthStart = nowDateTime.subtract(Duration(days: 30));
            isIncluded = recordDate.isAfter(lastYearStart) &&
                recordDate.isBefore(lastMonthStart);
            break;
          default:
            isIncluded = true;
            break;
        }

        print("Record Date: $recordDate | Included: $isIncluded");
        return isIncluded;
      }).toList();

      print("Filtered results count: ${_filteredResults.length}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back,
                      color: Color.fromARGB(255, 0, 0, 0), size: 24.w),
                  onPressed: () => Navigator.pop(context),
                ),
                Image.asset(
                  'assets/logo5.png',
                  height: 55.h,
                ),
              ],
            ),
            SizedBox(height: 4.h),

            /// Title
            Text(
              'Attendance Report',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 20.sp,
              ),
            ),
            SizedBox(height: 20.h),

            /// Search Field
            TextField(
              controller: _searchController,
              onChanged: (value) {
                if (value.trim().isEmpty) {
                  setState(() {
                    _searchResults = [];
                    _filteredResults = [];
                    _searchController.clear();
                  });
                }
                _performSearch(value);
              },
              decoration: InputDecoration(
                hintText: 'Search by ID or Name',
                hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey),
                suffixIcon: Padding(
                  padding:
                      const EdgeInsets.only(right: 10.0, top: 4, bottom: 6),
                  child: Container(
                    height: 30.h,
                    width: 30.w,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.blue,
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(255, 0, 0, 0)
                                .withOpacity(0.4),
                            blurRadius: 4.r,
                            offset: Offset(0, 3.h),
                          ),
                          BoxShadow(
                            color: Color.fromARGB(255, 8, 84, 146),
                            offset: Offset(2, 3),
                          ),
                        ]),
                    child: Icon(Icons.search, color: Colors.white),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1.0),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2.0),
                  borderRadius: BorderRadius.circular(10),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Filter Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFilterButton('All', 'all'),
                _buildFilterButton('Week', 'last_week'),
                _buildFilterButton('Month', 'last_month'),
                _buildFilterButton('Year', 'last_year'),
              ],
            ),
            SizedBox(height: 16.h),

            /// Results Header
            Row(
              children: [
                Text(
                  'Results:',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
                SizedBox(width: 8.w),
                Text(
                  '${_filteredResults.length}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            Row(
              children: [
                Text('ID'),
                SizedBox(width: 28.w),
                Text('Name'),
                Expanded(child: Container()),
                Padding(
                  padding: EdgeInsets.only(right: 4.w),
                  child: Text('Date'),
                ),
              ],
            ),

            /// Results List
            Expanded(
              child: _filteredResults.isEmpty
                  ? Center(child: Text("No records found."))
                  : ListView.builder(
                      itemCount: _filteredResults.length,
                      itemBuilder: (context, index) {
                        // Sort results by date in descending order (most recent first)
                        _filteredResults.sort((a, b) =>
                            DateTime.parse(b['time_out'])
                                .compareTo(DateTime.parse(a['time_out'])));

                        final result = _filteredResults[index];

                        /// Convert ISO Timestamp to Readable Date & Time
                        DateTime parsedDate =
                            DateTime.parse(result['time_out']);
                        String formattedDate =
                            DateFormat('yyyy-MM-dd').format(parsedDate);
                        String formattedTime =
                            DateFormat('hh:mm a').format(parsedDate);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 0.0),
                          child: Container(
                            padding: EdgeInsets.only(
                                top: 12,
                                bottom: 4,
                                left: 0,
                                right: 4), // Reduced top padding from 16 to 8
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.withOpacity(0.5),
                                  width: 1.w,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(result['user_id'] ?? 'N/A',
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w200)),
                                SizedBox(width: 28.w),
                                Text(result['user_name'] ?? 'Unknown',
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w100)),
                                Expanded(child: Container()),
                                Text(
                                    DateFormat('dd-MM-yyyy').format(parsedDate),
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w100)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String text, String filter) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _selectedFilter == filter ? Colors.blue : Colors.white,
            foregroundColor:
                _selectedFilter == filter ? Colors.white : Colors.black,
            padding: EdgeInsets.symmetric(vertical: 8.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
              side: BorderSide(
                  color: _selectedFilter == filter
                      ? Colors.blue
                      : const Color.fromARGB(255, 0, 0, 0)),
            ),
            elevation: _selectedFilter == filter ? 4 : 0,
            shadowColor: _selectedFilter == filter
                ? Color.fromARGB(255, 8, 84, 146)
                : Colors.black,
          ),
          onPressed: () => _applyFilter(filter),
          child: Text(
            text,
            style: TextStyle(
                fontSize: 12.sp), // Increased font size from 8.sp to 12.sp
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
