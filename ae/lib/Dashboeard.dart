import 'package:flutter/material.dart';
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
  int markedCount = 0;
  int enrolledCount = 0;
  List<Map<String, dynamic>> attendanceList = [];

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('EEEE, dd MMM yyyy').format(selectedDate);
    fetchAttendanceData();
  }

  /// Fetch attendance based on selected date
  Future<void> fetchAttendanceData() async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    final response = await supabase
        .from('attendance')
        .select()
        .eq('date', formattedDate); // Fetch records for selected date

    setState(() {
      attendanceList = response;
      markedCount =
          response.where((entry) => entry['status'] == 'marked').length;
      enrolledCount =
          response.where((entry) => entry['status'] == 'enrolled').length;
    });
  }

  /// Date Picker Function
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
        fetchAttendanceData(); // Fetch new data for the selected date
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AttendEase Dashboard")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dashboard",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),

            // Date Picker Field
            TextField(
              controller: _dateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Select Date",
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today, color: Colors.blue),
                  onPressed: () => _selectDate(context),
                ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onTap: () => _selectDate(context),
            ),

            SizedBox(height: 20),

            // Attendance Summary Cards
            Row(
              children: [
                Expanded(child: _buildCard("Marked", markedCount.toString())),
                SizedBox(width: 10),
                Expanded(
                    child: _buildCard("Enrolled", enrolledCount.toString())),
              ],
            ),

            SizedBox(height: 20),

            // Attendance List
            Expanded(
              child: attendanceList.isEmpty
                  ? Center(child: Text("No records found for this date."))
                  : ListView.builder(
                      itemCount: attendanceList.length,
                      itemBuilder: (context, index) {
                        var student = attendanceList[index];
                        return ListTile(
                          leading:
                              CircleAvatar(child: Text(student['user_id'])),
                          title: Text(student['user_name']),
                          subtitle: Text("Status: ${student['status']}"),
                          trailing: Text(
                            DateFormat.jm()
                                .format(DateTime.parse(student['timestamp'])),
                            style: TextStyle(color: Colors.grey),
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

  /// Widget for attendance summary cards
  Widget _buildCard(String title, String value) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: Column(
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue)),
          SizedBox(height: 8),
          Text(value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
