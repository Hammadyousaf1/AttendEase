import 'package:ae/reports_Screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  TextEditingController _dateController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  int markedCount = 0;
  int enrolledCount = 0;
  List<Map<String, dynamic>> attendanceList = [];

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('EEEE, dd MMM yyyy').format(selectedDate);
    fetchAttendanceData();
  }

  /// Fetch attendance data for selected date (ISO 8601 format)
  Future<void> fetchAttendanceData() async {
    setState(() => isLoading = true);

    final String formattedDate = selectedDate.toIso8601String().split('T')[0];

    try {
      final response = await supabase
          .from('attendance')
          .select()
          .gte('timestamp', '${formattedDate}T00:00:00.000Z')
          .lt('timestamp', '${formattedDate}T23:59:59.999Z');

      setState(() {
        attendanceList = List<Map<String, dynamic>>.from(response);
        markedCount = attendanceList.length;
        enrolledCount = attendanceList.length;
        isLoading = false;
      });

      print("Fetched Data: $attendanceList");
    } catch (error) {
      print("Error fetching attendance: $error");
      setState(() => isLoading = false);
    }
  }

  /// Show date picker and update attendance data
  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
        _dateController.text =
            DateFormat('EEEE, dd MMM yyyy').format(selectedDate);
        fetchAttendanceData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => ReportsScreen()));
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          Icons.search,
          color: Colors.white,
        ),
      ),
      body: Container(
        color: Colors.white,
        padding: EdgeInsets.all(20.w),
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
                  'assets/logo2.png',
                  height: 35.h,
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Text(
              "Dashboard",
              style: TextStyle(fontSize: 20.sp),
            ),
            SizedBox(height: 20.h),

            // Date Picker
            TextField(
              controller: _dateController,
              readOnly: true,
              style: TextStyle(fontSize: 12.sp),
              decoration: InputDecoration(
                labelText: "Select Date",
                contentPadding: EdgeInsets.symmetric(
                    vertical: 20.h,
                    horizontal: 12.w), // Increased vertical padding
                suffixIcon: Padding(
                  padding: EdgeInsets.only(right: 12.w, top: 6.h, bottom: 6.h),
                  child: Container(
                    width: 30.w,
                    height: 30.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.r),
                      color: Colors.blue,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.calendar_today,
                          color: Colors.white, size: 20.w),
                      onPressed: () => _selectDate(context),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              onTap: () => _selectDate(context),
            ),
            SizedBox(height: 20.h),

            // Attendance Summary Cards
            Row(
              children: [
                Expanded(child: _buildCard("Marked", markedCount.toString())),
                SizedBox(width: 10.w),
                Expanded(
                    child: _buildCard("Enrolled", enrolledCount.toString())),
              ],
            ),
            SizedBox(height: 30.h),

            Text(
              'Daily Report',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 20.h,
            ),
            Row(
              children: [
                Text('ID',
                    style: TextStyle(
                        fontSize: 14.sp, fontWeight: FontWeight.bold)),
                SizedBox(
                  width: 50.w,
                ),
                Text('Name',
                    style: TextStyle(
                        fontSize: 14.sp, fontWeight: FontWeight.bold)),
                SizedBox(width: 150.w),
                Text('Time',
                    style:
                        TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold))
              ],
            ),

            // Attendance List
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : attendanceList.isEmpty
                      ? Center(
                          child: Text(
                            "No records found for this date.",
                            style:
                                TextStyle(fontSize: 12.sp, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: attendanceList.length,
                          itemBuilder: (context, index) {
                            var student = attendanceList[index];
                            return Row(
                              children: [
                                SizedBox(
                                  width: 50.w,
                                  child: Text(
                                    student['user_id'],
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                ),
                                SizedBox(width: 20.w),
                                SizedBox(
                                  width: 150.w,
                                  child: Text(
                                    student['user_name'],
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    DateFormat.jm().format(
                                        DateTime.parse(student['timestamp'])),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: const Color.fromARGB(255, 0, 0, 0),
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
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

  /// Widget for attendance summary cards
  Widget _buildCard(String title, String value) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        color: Colors.grey[200],
      ),
      child: Column(
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue)),
          SizedBox(height: 8.h),
          Text(value,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
