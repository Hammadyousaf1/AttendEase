import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  TextEditingController datecontroller = TextEditingController();

  @override
  void initState() {
    super.initState();
    datecontroller.text =
        DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());
  }

  Future<void> selectdate() async {
    DateTime? pickdate = await showDatePicker(
        context: (context),
        firstDate: DateTime(2000),
        lastDate: DateTime(3000));
    if (pickdate != null) {
      setState(() {
        datecontroller.text =
            DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextField(
          readOnly: true,
        ),
      ),
    );
  }
}
