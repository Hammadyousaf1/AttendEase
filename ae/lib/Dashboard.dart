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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: GoogleFonts.kronaOneTextTheme(
              TextTheme(
                bodySmall: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey), // Consistent with search hint text
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              dayStyle: GoogleFonts.kronaOne(
                  fontSize: 12.sp, // Matches other text sizes in app
                  color: Colors.blue),
              yearStyle: GoogleFonts.kronaOne(
                  fontSize: 12.sp, color: Colors.grey), // Matches results text
              headerHeadlineStyle: GoogleFonts.kronaOne(
                  fontSize: 24.sp,
                  color: Colors.black), // Matches dashboard title
              weekdayStyle: GoogleFonts.kronaOne(
                  fontSize: 12.sp, color: Colors.grey), // Matches results text
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
                      border: Border.all(
                        color: Colors.black.withOpacity(0.3),
                        width: 1.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 0, 0, 0)
                              .withOpacity(0.4),
                          blurRadius: 4.r,
                          offset: Offset(0, 3.h),
                        ),
                        BoxShadow(
                          color: Colors.black,
                          spreadRadius: 0,
                          blurRadius: 0,
                          offset: Offset(2, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.calendar_today,
                          color: const Color.fromARGB(255, 255, 255, 255),
                          size: 20.w),
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
              style: TextStyle(
                fontSize: 18.sp,
              ),
            ),
            SizedBox(
              height: 16.h,
            ),
            Row(
              children: [
                Text('ID', style: TextStyle(fontSize: 14.sp)),
                SizedBox(
                  width: 28.w,
                ),
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
                                          fontSize: 14.sp,
                                          color: const Color.fromARGB(
                                              255, 102, 102, 102)),
                                    ),
                                  ),
                                  SizedBox(width: 0.w),
                                  SizedBox(
                                    width: 150.w,
                                    child: Text(
                                      student['user_name'],
                                      style: TextStyle(
                                          fontSize: 14.sp,
                                          color: const Color.fromARGB(
                                              255, 102, 102, 102)),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      DateFormat.jm().format(
                                          DateTime.parse(student['timestamp'])),
                                      style: TextStyle(
                                          fontSize: 14.sp,
                                          color: const Color.fromARGB(
                                              255, 102, 102, 102)),
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
                  padding: EdgeInsets.all(0.w),
                  margin: EdgeInsets.only(
                      right: MediaQuery.of(context).size.width * 0.03,
                      bottom: MediaQuery.of(context).size.height * 0.008),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    border: Border.all(
                      color: Colors.black.withOpacity(0.3),
                      width: 1.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color.fromARGB(255, 0, 0, 0).withOpacity(0.4),
                        blurRadius: 4.r,
                        offset: Offset(0, 3.h),
                      ),
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(2.5.w, 3.5.h),
                      ),
                    ],
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
        color: const Color.fromARGB(255, 255, 255, 255),
        border: Border.all(
          color: Colors.black26,
          width: 1.w,
        ),
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
