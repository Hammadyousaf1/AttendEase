import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  final _supabase = Supabase.instance.client;

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      final response = await _supabase
          .from('attendance')
          .select()
          .or('id.ilike.%$query%,name.ilike.%$query%')
          ._execute();

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(response.data ?? []);
      });
    } catch (e) {
      print('Error searching: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70.h,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20.w),
            child: Image.asset(
              'assets/Group2.png',
              height: 40.h,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendence Report',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 25.sp,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 10.h,
            ),
            TextField(
              controller: _searchController,
              onChanged: _performSearch,
              decoration: InputDecoration(
                  hintText: 'Search',
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: 15.h,
                      width: 15.w,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          color: Theme.of(context).colorScheme.primary),
                      child: Icon(
                        Icons.search,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.blue,
                          style: BorderStyle.solid,
                          width: 2.0),
                      borderRadius: BorderRadius.circular(10)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10))),
            ),
            SizedBox(
              height: 20.h,
            ),
            Text(
              'Results',
              style: TextStyle(
                fontSize: 15.sp,
              ),
            ),
            SizedBox(
              height: 10.h,
            ),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ID', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Time', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(result['id'] ?? ''),
                        Text(result['name'] ?? ''),
                        Text(result['date'] ?? ''),
                        Text(result['time'] ?? ''),
                      ],
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
}

extension on PostgrestFilterBuilder<PostgrestList> {
  _execute() {}
}
