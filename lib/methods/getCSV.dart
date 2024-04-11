import 'dart:ffi';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:convert';
import '../pages/home_page/home_page_widget.dart' as homePage;
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadCsv {
  late String _temp;
  late String _pulse;
  late String _oxy;
  late String _result;
  late String _date;
  late String _time;
  List<List<dynamic>> data = [];
  List<List<dynamic>> alertData = [];

  String get temp => _temp;
  String get pulse => _pulse;
  String get oxy => _oxy;
  String get result => _result;
  String get date => _date;
  String get time => _time;
  // List<List<dynamic>> get data => _data;

  void getCSV() {
    const Duration updateInterval = Duration(seconds: 1);

    Timer.periodic(updateInterval, (Timer timer) async {
      await displayDownloadedData(); // Update temperature periodically
    });
  }

  Future<List<List<dynamic>>> downloadCSVData() async {
    final String wemosIPAddress = '192.168.4.1';
    String url =
        "http://${wemosIPAddress}/history"; // Replace with your Wemos' IP address
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print('Response Body: ${response.body}');
        String csvData = response.body;
        // final prefs = await SharedPreferences.getInstance();
        // await prefs.setString('csvData', csvData);
        // print(csvData);
        if (csvData.isNotEmpty) {
          // Split the CSV data into lines (rows)
          List<String> csvLines = csvData.split('\n');

          // Loop through each CSV line (row)
          for (String line in csvLines) {
            // Skip the header row (optional):
            if (line.startsWith('temp,pulse,oxy,result,date,time')) {
              continue;
            }

            // Split the line into data points
            List<String> dataPoints = line.split(',');

            // Ensure the expected number of data points
            if (dataPoints.length == 6) {
              // Access data points by index (replace with your processing logic)
              String temperature = dataPoints[0];
              String pulse = dataPoints[1];
              String oxygen = dataPoints[2];
              String result = dataPoints[3];
              String date = dataPoints[4].replaceAll("_", ",");
              String time = dataPoints[5];
              List<dynamic> rowData = [
                temperature,
                pulse,
                oxygen,
                result,
                date,
                time
              ];

              // Add the rowData to the main data list
              data.add(rowData);

              // Example processing: Print data points from the list
              // print(data);
              // print('---');
              // return data;
              // Update UI or perform further processing with these values
            } else {
              // Handle case where data is not in expected format (e.g., log an error)
              return data;
            }
          }
        }

        print('Successul CSV Access');
        print(data);
        print('---');
        return data;
        // Show success message or handle download completion
      } else {
        // Handle error fetching data
        return data;
      }
    } catch (e) {
      // Handle exception during HTTP request
      return data;
    }
    return data;
  }

  Future<List<List<dynamic>>> alertCSVData() async {
    final String wemosIPAddress = '192.168.4.1';
    String url =
        "http://${wemosIPAddress}/alert"; // Replace with your Wemos' IP address
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print('Response Body: ${response.body}');
        String csvData = response.body;
        // final prefs = await SharedPreferences.getInstance();
        // await prefs.setString('csvData', csvData);
        // print(csvData);
        if (csvData.isNotEmpty) {
          // Split the CSV data into lines (rows)
          List<String> csvLines = csvData.split('\n');

          // Loop through each CSV line (row)
          for (String line in csvLines) {
            // Skip the header row (optional):
            if (line.startsWith('alert,value,intensity,date,time')) {
              continue;
            }

            // Split the line into data points
            List<String> dataPoints = line.split(',');

            // Ensure the expected number of data points
            if (dataPoints.length == 5) {
              // Access data points by index (replace with your processing logic)
              String alert = dataPoints[0];
              String value = dataPoints[1];
              String intensity = dataPoints[2];
              String date = dataPoints[3].replaceAll("_", ",");
              String time = dataPoints[4];
              List<dynamic> rowData = [alert, value, intensity, date, time];

              // Add the rowData to the main data list
              alertData.add(rowData);

              // Example processing: Print data points from the list
              // print(data);
              // print('---');
              // return data;
              // Update UI or perform further processing with these values
            } else {
              // Handle case where data is not in expected format (e.g., log an error)
              return alertData;
            }
          }
        }

        print('Successul alert CSV Access');
        print(alertData);
        print('---');
        return alertData;
        // Show success message or handle download completion
      } else {
        // Handle error fetching data
        return alertData;
      }
    } catch (e) {
      // Handle exception during HTTP request
      return alertData;
    }
  }

  // Stream<List<List<dynamic>>> alertCSVDataStream() async* {
  //   while (true) {
  //     // Loop to simulate continuous data updates (optional)
  //     final String wemosIPAddress = '192.168.4.1';
  //     String url =
  //         "http://${wemosIPAddress}/alert"; // Replace with your Wemos' IP

  //     try {
  //       var response = await http.get(Uri.parse(url));
  //       if (response.statusCode == 200) {
  //         String csvData = response.body;
  //         print(csvData);
  //         if (csvData.isNotEmpty) {
  //           List<String> csvLines = csvData.split('\n');

  //           // List<List<dynamic>> alertData = [];
  //           for (String line in csvLines) {
  //             if (line.startsWith('temp,date,time')) {
  //               continue;
  //             }

  //             List<String> dataPoints = line.split(',');
  //             if (dataPoints.length == 3) {
  //               String temperature = dataPoints[0];
  //               String date = dataPoints[1].replaceAll("_", ",");
  //               String time = dataPoints[2];
  //               List<dynamic> rowData = [temperature, date, time];
  //               alertData.add(rowData);
  //             }
  //           }

  //           // Yield the processed data list
  //           print('Successul alert CSV Access');
  //           print(alertData);
  //           yield alertData;
  //         }
  //       } else {
  //         // Handle error fetching data (optional)
  //       }
  //     } catch (e) {
  //       // Handle exception during HTTP request (optional)
  //     }

  //     // Optional: Add a delay between data fetches to simulate real-time updates
  //     await Future.delayed(Duration(seconds: 5)); // Adjust delay as needed
  //   }
  // }

  Future<String> _getSavedCSVData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('csvData') ??
        ''; // Default to empty string if not found
  }

  Future<void> displayDownloadedData() async {
    downloadCSVData();
    String csvData = await _getSavedCSVData();
    if (csvData.isNotEmpty) {
      // Split the CSV data into lines (rows)
      List<String> csvLines = csvData.split('\n');

      // Loop through each CSV line (row)
      for (String line in csvLines) {
        // Skip the header row (optional):
        if (line.startsWith('temp,pulse,oxy,result,date,time')) {
          continue;
        }

        // Split the line into data points
        List<String> dataPoints = line.split(',');

        // Ensure the expected number of data points
        if (dataPoints.length == 6) {
          // Access data points by index (replace with your processing logic)
          String temperature = dataPoints[0];
          String pulse = dataPoints[1];
          String oxygen = dataPoints[2];
          String result = dataPoints[3];
          String date = dataPoints[4];
          String time = dataPoints[5];
          List<dynamic> rowData = [
            temperature,
            pulse,
            oxygen,
            result,
            date,
            time
          ];

          // Add the rowData to the main data list
          data.add(rowData);

          // Example processing: Print data points from the list
          print(data);
          print('---');
          // Update UI or perform further processing with these values
        } else {
          // Handle case where data is not in expected format (e.g., log an error)
        }
      }
    }
  }

  Future<void> _saveFile(List<int> fileBytes) async {
    Directory? directory = await getExternalStorageDirectory();
    final File file = File('${directory!.path}/history.csv');
    await file.writeAsBytes(fileBytes);
    print('processing');
  }

  Future<List<List<dynamic>>> fetchCSVData() async {
    List<List<dynamic>> csvData;
    final String wemosIPAddress = '192.168.4.1';
    String url =
        "http://${wemosIPAddress}/history"; // Replace with your Wemos' IP address
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // await _saveFile(response.bodyBytes);
        print('Downloaded File Successfully');
        // Directory? directory = await getExternalStorageDirectory();
        // final File file = File('${directory!.path}/history.csv');
        // final String contents = await file.readAsString();
        csvData = const CsvToListConverter().convert(response.body);
        // print(contents);
        print(csvData);
        print('CSV Loaded Successfully');
        // Process the received CSV data (replace with your parsing logic)
        data = csvData;
        return data;
      } else {
        print('Unable to get CSV');
        return data;
        // Handle error fetching data
      }
    } catch (e) {
      // Handle exception during HTTP request
      print('Unable to get CSV');
      return data;
    }
  }
}
