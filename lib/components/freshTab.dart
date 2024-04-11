import 'package:flutter/material.dart';
import 'package:pneumosense/components/historyContainer.dart';
import 'package:pneumosense/methods/getCSV.dart';

class FreshDataTab extends StatefulWidget {
  final Function onTabSwitch; // Callback to update refresh flag

  const FreshDataTab({Key? key, required this.onTabSwitch}) : super(key: key);

  @override
  _FreshDataTabState createState() => _FreshDataTabState();
}

class _FreshDataTabState extends State<FreshDataTab> {
  bool needsRefresh = true; // Flag for forcing data refresh

  late ReadCsv myCSV;

  @override
  void initState() {
    super.initState();
    widget.onTabSwitch(); // Call callback on tab switch initially
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<List<dynamic>>>(
      future: getFreshCSVData(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data!;
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              return HistoryContainer(
                temp: data[index][0],
                pulse: data[index][1],
                oxy: data[index][2],
                date: data[index][4],
                time: data[index][5],
                result: data[index][3],
              );
            },
          );
        } else if (snapshot.hasError) {
          return Text('Error fetching data: ${snapshot.error}');
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<List<List<dynamic>>> getFreshCSVData() async {
    if (needsRefresh) {
      needsRefresh = false; // Reset flag after download
      return myCSV.downloadCSVData();
    } else {
      throw Exception('No refresh needed'); // Force rebuild
    }
  }
}
