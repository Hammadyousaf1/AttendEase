import 'package:ae/reports_Screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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

  /// Fetch attendance and enrolled users
  Future<void> fetchAttendanceData() async {
    setState(() => isLoading = true);

    final String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      // Fetch attendance for the selected date
      final attendanceResponse = await supabase
          .from('attendance')
          .select()
          .gte('timestamp', '$formattedDate 00:00:00')
          .lt('timestamp', '$formattedDate 23:59:59');

      // Fetch total enrolled users
      final usersResponse = await supabase.from('users').select();

      setState(() {
        attendanceList = List<Map<String, dynamic>>.from(attendanceResponse);
        markedCount = attendanceList.length;
        enrolledCount = usersResponse.length; // Get total users
        isLoading = false;
      });

      print("Fetched Attendance: $attendanceList");
      print("Total Enrolled Users: ${usersResponse.length}");
    } catch (error) {
      print("Error fetching data: $error");
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: GoogleFonts.kronaOneTextTheme(),
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          child: child!,
        );
      },
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
                  icon: Icon(Icons.arrow_back, color: Colors.black, size: 24.w),
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
                contentPadding:
                    EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today, color: Colors.blue),
                  onPressed: () => _selectDate(context),
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
              style: TextStyle(fontSize: 18.sp),
            ),
            SizedBox(height: 16.h),

            Row(
              children: [
                Text('ID', style: TextStyle(fontSize: 14.sp)),
                SizedBox(width: 28.w),
                Text('Name', style: TextStyle(fontSize: 14.sp)),
                SizedBox(width: 140.w),
                Text('Time', style: TextStyle(fontSize: 14.sp))
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
                            style: TextStyle(
                                fontSize: 12.sp, color: Colors.black26),
                          ),
                        )
                      : ListView.builder(
                          itemCount: attendanceList.length,
                          itemBuilder: (context, index) {
                            var student = attendanceList[index];
                            return Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.blueGrey,
                                    width: 1.w,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 50.w,
                                    child: Text(
                                      student['user_id'],
                                      style: TextStyle(
                                          fontSize: 14.sp, color: Colors.grey),
                                    ),
                                  ),
                                  SizedBox(width: 0.w),
                                  SizedBox(
                                    width: 150.w,
                                    child: Text(
                                      student['user_name'],
                                      style: TextStyle(
                                          fontSize: 14.sp, color: Colors.grey),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      DateFormat.jm().format(
                                          DateTime.parse(student['timestamp'])),
                                      style: TextStyle(
                                          fontSize: 14.sp, color: Colors.grey),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => searchuser(),
                    ),
                  );
                },
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.15,
                  height: MediaQuery.of(context).size.height * 0.06,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.search, color: Colors.white, size: 24.w),
                ),
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
        color: Colors.white,
        border: Border.all(color: Colors.black26, width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 18.sp, color: Colors.blue)),
          SizedBox(height: 8.h),
          Text(value, style: TextStyle(fontSize: 20.sp, color: Colors.blue)),
        ],
      ),
    );
  }
}
