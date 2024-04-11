import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:pneumosense/components/alertContainer.dart';
import 'package:pneumosense/components/freshTab.dart';
import 'package:pneumosense/components/historyContainer.dart';
import 'package:pneumosense/methods/getCSV.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'home_page_model.dart';
export 'home_page_model.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/methods/connect.dart' as connect;
import 'package:web_socket_channel/io.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late HomePageModel _model;
  final channel = IOWebSocketChannel.connect('ws://192.168.4.1:81');
  final scaffoldKey = GlobalKey<ScaffoldState>();
  dynamic pulseVal;
  dynamic tempVal;
  dynamic oxyVal;
  dynamic connectionStatus;
  dynamic battery;
  late double _containerHeight;
  dynamic _battery;
  dynamic _temp;
  dynamic _pulse;
  dynamic _pulseRound;
  dynamic _oxy;
  dynamic _oxyRound;
  String? _toRound;
  late Timer _updateTimer; // Store the reference to the Timer
  bool _isTimerActive = false;
  late DateTime now;
  late bool isVisible;
  late bool pressed;
  late ReadCsv myCSV;
  late double _calibrateTemp;
  late double _calibrateBpm;
  late double _calibrateOxy;
  late String lastDiagDate;
  late String lastDiagTime;
  late List<List<dynamic>> _data;
  bool _isFetchingData = false;
  Future<List<List<dynamic>>>? _dataFuture;
  Future<List<List<dynamic>>>? _alertDataFutureHandler;
  Future<List<List<dynamic>>>? _alertData;
  final StreamController<String> _timeStreamController =
      StreamController<String>.broadcast();
  final StreamController<String> _dateStreamController =
      StreamController<String>.broadcast();
  // late List<int> rawBattList;
  // late String formattedTime;
  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());
    _model.tabBarController = TabController(
      vsync: this,
      length: 3,
      initialIndex: 0,
    )..addListener(() {
        _handleTabSelection;
      });
    pulseVal = '0';
    tempVal = '0';
    oxyVal = '0';
    _calibrateTemp = 0.5;
    _calibrateBpm = 0;
    _calibrateOxy = 0;
    _containerHeight = 60.0;
    pressed = false;
    lastDiagDate = 'Not Available';
    lastDiagTime = '.';
    connectionStatus = 'Not Connected';
    now = DateTime.now();
    // Split on space to get date part
    _updateTimer = Timer(Duration.zero, () {});
    _isTimerActive = true;
    startTempUpdateTimer();
    requestStoragePermission();
    WidgetsBinding.instance!.addObserver(this);
    isVisible = false;
    myCSV = ReadCsv();
    // myCSV.getCSV();
    // getCSV(true);
    startListeningToTime();
    startListeningToDate();
    // _dataFuture = myCSV.downloadCSVData();
    CSVTimer();
    alertCSVTimer();
  }

  @override
  void dispose() {
    // Remove the observer when the widget is disposed
    WidgetsBinding.instance!.removeObserver(this);
    _model.tabBarController!.dispose();
    // Cancel the timer when the widget is disposed
    _updateTimer.cancel();
    _model.dispose();
    super.dispose();
    _timeStreamController.close();
    _dateStreamController.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.resumed) {
      // App has resumed, restart the timer
      if (_isTimerActive) {
        startTempUpdateTimer();
      }
    } else {
      // App is in a background or inactive state, stop the timer
      _updateTimer.cancel();
    }
  }

  void CSVTimer() {
    if (!isVisible) {
      Timer.periodic(Duration(seconds: 1), (timer) async {
        await getCSV(isVisible);
        if (isVisible) {
          timer.cancel();
        }
      });
    }
  }

  void alertCSVTimer() {
    if (!isVisible) {
      Timer.periodic(Duration(seconds: 1), (timer) async {
        await getAlertCSV(isVisible);
        if (isVisible) {
          timer.cancel();
        }
      });
    }
  }

  Future<void> getCSV(bool connected) async {
    try {
      if (connected) {
        print('getting csv');
        _dataFuture = myCSV.downloadCSVData();
        // _alertData = myCSV.alertCSVData();

        // print(_data);
      } else {
        print('not yet connected');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> getAlertCSV(bool connected) async {
    try {
      if (connected) {
        print('getting alert csv');
        List<List<dynamic>>? newAlertData = await myCSV.alertCSVData();

        if (newAlertData != null && newAlertData.isNotEmpty) {
          final List<List<dynamic>>? currentData = await _alertData;
          if (currentData == null ||
              newAlertData.length != currentData.length) {
            setState(() {
              _alertData = Future.value(newAlertData);
              print('alert data updated');
            });
          } else {
            print('alert data is still up to date');
          }
        } else {
          print('alert data is empty or null');
        }
      } else {
        print('alert data not received');
      }
    } catch (e) {
      print(e);
    }
  }

  void _handleTabSelection() {
    if (_model.tabBarController!.index == 1) {
      // Call your function when the second tab is selected
      print('this is called');
      // myCSV.fetchCSVData();
    }
  }

  Future<void> requestStoragePermission() async {
    final PermissionStatus status =
        await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      // Permission granted, proceed with file access
      print('Storage permission granted');
    } else if (status.isDenied) {
      // Permission denied, explain and potentially request again
      print('Storage permission denied');
      await Permission.storage.request(); // Can request again if desired
    } else if (status.isPermanentlyDenied) {
      // User has permanently denied permission, open app settings
      await openAppSettings();
    }
  }

//   void startListeningToTime() {
//   while (true) {
//     var now = DateTime.now();
//     String formattedTime = DateFormat('hh:mm a').format(now);
//     _timeStreamController.add(formattedTime);
//     await Future.delayed(Duration(seconds: 1));
//   }
// }

  Stream<String> getTimeStream() {
    return _timeStreamController.stream;
  }

  void startListeningToTime() async {
    while (true) {
      var now = DateTime.now();
      String formattedTime = DateFormat('hh:mm a')
          .format(now); // Example using string manipulation
      _timeStreamController.add(formattedTime);
      await Future.delayed(
          Duration(seconds: 1)); // Wait 1 second before emitting again
    }
  }

  // Stream<String> getTimeStream() async* {
  //   while (true) {
  //     var now = DateTime.now();
  //     String formattedTime = DateFormat('hh:mm a')
  //         .format(now); // Example using string manipulation
  //     yield formattedTime;
  //     await Future.delayed(
  //         Duration(seconds: 1)); // Wait 1 second before emitting again
  //   }
  // }

  // Stream<String> getDateStream() async* {
  //   while (true) {
  //     var now = DateTime.now();
  //     String formattedDate = DateFormat('MMMM dd,yyyy')
  //         .format(now); // Example using string manipulation
  //     yield formattedDate;
  //     await Future.delayed(
  //         Duration(seconds: 1)); // Wait 1 second before emitting again
  //   }
  // }

  Future<List<List<dynamic>>> getFreshCSVData() async {
    // You can implement a flag or timestamp logic here
    // For example, a flag set to true when the tab is switched
    bool needsRefresh = true; // Replace with your refresh logic

    if (needsRefresh) {
      return myCSV.downloadCSVData();
    } else {
      throw Exception(
          'No refresh needed'); // Or return cached data if available
    }
  }

  Stream<String> getDateStream() {
    return _dateStreamController.stream;
  }

  void startListeningToDate() async {
    while (true) {
      var now = DateTime.now();
      String formattedDate = DateFormat('MMMM dd,yyyy')
          .format(now); // Example using string manipulation
      _dateStreamController.add(formattedDate);
      await Future.delayed(
          Duration(seconds: 1)); // Wait 1 second before emitting again
    }
  }

  // int smoothBatt(int rawBatt) {
  //   if (rawBattList.length < 5 && !rawBattList.contains(rawBatt)) {
  //     rawBattList.add(rawBatt);
  //     return 0;
  //   } else if (rawBattList.length == 5) {
  //     rawBattList.sort();
  //     print(rawBattList);
  //     if (rawBattList.contains(rawBatt)) {
  //       print(rawBattList);
  //       return rawBattList[2];
  //     } else if (!rawBattList.contains(rawBatt)) {
  //       if (rawBatt == rawBattList[-1] + 1) {
  //         rawBattList.removeAt(0);
  //         rawBattList.add(rawBatt);
  //       } else if (rawBatt == rawBattList[0] - 1) {
  //         rawBattList.insert(0, rawBatt);
  //         rawBattList.removeAt(5);
  //       }
  //       print(rawBattList);
  //       return rawBattList[2];
  //     }
  //     print(rawBattList);
  //     return rawBattList[2];
  //   }
  //   print(rawBattList);
  //   return 0;
  // }

  Future<void> checkConnection() async {
    final String wemosIPAddress =
        '192.168.4.1'; // Replace with your Wemos D1 Mini IP address

    try {
      final response = await http.get(Uri.parse('http://$wemosIPAddress/'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          isVisible = true;
          connectionStatus = 'Connected';
          _temp = jsonData['tempVal'];
          _pulse = jsonData['pulseVal'];
          _oxy = jsonData['oxyVal'];

          _toRound = _temp.toStringAsFixed(2);
          _temp = double.parse(_toRound!) + _calibrateTemp;

          _pulseRound = _pulse.toStringAsFixed(2);
          _pulse = double.parse(_pulseRound!) + _calibrateBpm;

          _oxyRound = _oxy.toStringAsFixed(2);
          _oxy = double.parse(_oxyRound!) + _calibrateOxy;

          _battery = jsonData['batVal'];
          battery = _battery.toStringAsFixed(0);
          print(battery);

          if (_temp < 0) {
            tempVal = '0.0';
          } else {
            tempVal = _temp.toString();
          }

          if (_oxy < 0) {
            oxyVal = '0.0';
          } else {
            oxyVal = _oxy.toString();
          }

          if (_pulse < 0) {
            pulseVal = '0.0';
          } else {
            pulseVal = _pulse.toString();
          }
          // Debug print
          print('Temp: $tempVal');
          print('Oxygen: $oxyVal'); // Debug print
          print('Pulse: $pulseVal');
          // Debug print
        });
      } else {
        setState(() {
          isVisible = false;
          connectionStatus = 'Not Connected';
          tempVal = '0';
          oxyVal = '0';
          pulseVal = '0';
        });
      }
    } catch (e) {
      setState(() {
        isVisible = false;
        connectionStatus = '$e';
        tempVal = '0';
        oxyVal = '0';
        pulseVal = '0';
      });
    }
  }

  void disposeTimer() {
    _updateTimer.cancel();
  }

  void startTempUpdateTimer() {
    const Duration updateInterval = Duration(seconds: 1);

    // Cancel the previous timer, if any
    _updateTimer.cancel();

    // Store the reference to the new Timer
    _updateTimer = Timer.periodic(updateInterval, (Timer timer) async {
      await checkConnection(); // Update temperature periodically
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isiOS) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarBrightness: Theme.of(context).brightness,
          systemStatusBarContrastEnforced: true,
        ),
      );
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primary,
      body: SafeArea(
        top: true,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(30.0, 0.0, 30.0, 0.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Align(
                alignment: AlignmentDirectional(-1.0, 0.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Add your onPressed behavior here
                        print('Container pressed');
                        if (!pressed) {
                          setState(() {
                            _containerHeight = 60.0;
                            pressed = true;
                            _calibrateTemp = 0.5;
                            _calibrateBpm = 0.0;
                            _calibrateOxy = 0.0;
                          });
                        } else {
                          setState(() {
                            _containerHeight = 70.0;
                            pressed = false;
                            _calibrateTemp = 5.0;
                            _calibrateBpm = 0.0;
                            _calibrateOxy = -5.0;
                          });
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 160.0,
                          height: _containerHeight,
                          fit: BoxFit.scaleDown,
                          alignment: Alignment(-1.0, 0.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment(0, 0),
                        child: TabBar(
                          tabAlignment: TabAlignment.start,
                          isScrollable: true,
                          labelColor: FlutterFlowTheme.of(context).primaryText,
                          unselectedLabelColor:
                              FlutterFlowTheme.of(context).secondaryText,
                          labelPadding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 20.0, 0.0),
                          labelStyle:
                              FlutterFlowTheme.of(context).titleSmall.override(
                                    fontFamily: 'sf pro display',
                                    fontWeight: FontWeight.bold,
                                    useGoogleFonts: false,
                                    lineHeight: 2.0,
                                  ),
                          unselectedLabelStyle: TextStyle(),
                          indicatorColor:
                              FlutterFlowTheme.of(context).primaryText,
                          indicatorWeight: 3.0,
                          padding: EdgeInsets.all(4.0),
                          tabs: [
                            Tab(
                              text: 'Goat Status',
                            ),
                            Tab(
                              text: 'History',
                            ),
                            Tab(
                              text: 'Alerts',
                            ),
                          ],
                          controller: _model.tabBarController,
                          onTap: (i) async {
                            [() async {}, () async {}][i]();
                          },
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _model.tabBarController,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 50.0, 0.0, 0.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Text(
                                                pulseVal,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'sf pro display',
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondary,
                                                          fontSize: 25.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          useGoogleFonts: false,
                                                        ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Text(
                                                'bpm',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'sf pro display',
                                                          fontSize: 15.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          useGoogleFonts: false,
                                                        ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        0.0, 10.0, 0.0, 10.0),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                  child: Image.asset(
                                                    'assets/images/bpm.png',
                                                    width: 55.0,
                                                    height: 55.0,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Text(
                                                'Pulse Rate',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'sf pro display',
                                                          fontSize: 15.0,
                                                          useGoogleFonts: false,
                                                        ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 150.0,
                                        child: VerticalDivider(
                                          thickness: 1.0,
                                          color: Color(0xFF959595),
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Text(
                                                tempVal,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'sf pro display',
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondary,
                                                          fontSize: 25.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          useGoogleFonts: false,
                                                        ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Text(
                                                '°C',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'sf pro display',
                                                          fontSize: 15.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          useGoogleFonts: false,
                                                        ),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 10.0, 0.0, 10.0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                  child: Image.asset(
                                                    'assets/images/temp.png',
                                                    width: 48.0,
                                                    height: 40.0,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Text(
                                                'Body\nTemperature',
                                                textAlign: TextAlign.center,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'sf pro display',
                                                          fontSize: 15.0,
                                                          useGoogleFonts: false,
                                                        ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 150.0,
                                        child: VerticalDivider(
                                          thickness: 1.0,
                                          color: Color(0xFF959595),
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Text(
                                                oxyVal,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'sf pro display',
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondary,
                                                          fontSize: 25.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          useGoogleFonts: false,
                                                        ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Text(
                                                '% O2',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'sf pro display',
                                                          fontSize: 15.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          useGoogleFonts: false,
                                                        ),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 13.0, 0.0, 13.0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                  child: Image.asset(
                                                    'assets/images/oxygen.png',
                                                    width: 35.0,
                                                    height: 35.0,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Text(
                                                'Oxygen\nSaturation',
                                                textAlign: TextAlign.center,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily:
                                                              'sf pro display',
                                                          fontSize: 15.0,
                                                          useGoogleFonts: false,
                                                        ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 30.0, 0.0, 0.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Container(
                                                width: 100.0,
                                                height: 100.0,
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  0.0,
                                                                  0.0,
                                                                  10.0),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          Text(
                                                            'Date:',
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'sf pro display',
                                                                  fontSize:
                                                                      15.0,
                                                                  useGoogleFonts:
                                                                      false,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  0.0,
                                                                  0.0,
                                                                  10.0),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          Text(
                                                            'Time:',
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'sf pro display',
                                                                  fontSize:
                                                                      15.0,
                                                                  useGoogleFonts:
                                                                      false,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Text(
                                                          'Last Diagnosis:',
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                fontFamily:
                                                                    'sf pro display',
                                                                fontSize: 15.0,
                                                                useGoogleFonts:
                                                                    false,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Container(
                                              width: 197.0,
                                              height: 100.0,
                                              decoration: BoxDecoration(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryBackground,
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 0.0,
                                                                0.0, 10.0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        StreamBuilder<String>(
                                                          stream:
                                                              getDateStream(),
                                                          builder: (context,
                                                              snapshot) {
                                                            if (snapshot
                                                                .hasData) {
                                                              return Text(
                                                                snapshot.data!,
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'sf pro display',
                                                                      fontSize:
                                                                          15.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      useGoogleFonts:
                                                                          false,
                                                                    ),
                                                              );
                                                            } else if (snapshot
                                                                .hasError) {
                                                              return Text(
                                                                  'Error: ${snapshot.error}');
                                                            }
                                                            return Expanded(
                                                                child: Row(
                                                              children: [
                                                                Text(
                                                                    'Fetching Date')
                                                              ],
                                                            ));
                                                            ; // Show loading indicator initially
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 0.0,
                                                                0.0, 10.0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        StreamBuilder<String>(
                                                          stream:
                                                              getTimeStream(),
                                                          builder: (context,
                                                              snapshot) {
                                                            if (snapshot
                                                                .hasData) {
                                                              return Text(
                                                                snapshot.data!,
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'sf pro display',
                                                                      fontSize:
                                                                          15.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      useGoogleFonts:
                                                                          false,
                                                                    ),
                                                              );
                                                            } else if (snapshot
                                                                .hasError) {
                                                              return Text(
                                                                  'Error: ${snapshot.error}');
                                                            }
                                                            return Expanded(
                                                                child: Row(
                                                              children: [
                                                                Text(
                                                                    'Fetching Time')
                                                              ],
                                                            )); // Show loading indicator initially
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: [
                                                      Text(
                                                        '${lastDiagDate}',
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodyMedium
                                                            .override(
                                                              fontFamily:
                                                                  'sf pro display',
                                                              fontSize: 14.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              useGoogleFonts:
                                                                  false,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 30.0, 0.0, 0.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        FFButtonWidget(
                                          onPressed: isVisible
                                              ? () async {
                                                  disposeTimer();
                                                  context.pushNamed(
                                                    'DiagnosticPhaseOne',
                                                    queryParameters: {
                                                      'calibrateTemp':
                                                          serializeParam(
                                                        _calibrateTemp,
                                                        ParamType.double,
                                                      ),
                                                      'calibrateBpm':
                                                          serializeParam(
                                                        _calibrateBpm,
                                                        ParamType.double,
                                                      ),
                                                      'calibrateOxy':
                                                          serializeParam(
                                                        _calibrateOxy,
                                                        ParamType.double,
                                                      ),
                                                    }.withoutNulls,
                                                    extra: <String, dynamic>{
                                                      kTransitionInfoKey:
                                                          TransitionInfo(
                                                        hasTransition: true,
                                                        transitionType:
                                                            PageTransitionType
                                                                .rightToLeft,
                                                      ),
                                                    },
                                                  );
                                                }
                                              : null,
                                          text: 'Take Diagnostic Test',
                                          options: FFButtonOptions(
                                            height: 40.0,
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    24.0, 0.0, 24.0, 0.0),
                                            iconPadding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 0.0, 0.0, 0.0),
                                            color: Color(0xFFDDDDDD),
                                            textStyle: FlutterFlowTheme.of(
                                                    context)
                                                .titleSmall
                                                .override(
                                                  fontFamily: 'sf pro display',
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                  useGoogleFonts: false,
                                                ),
                                            elevation: 3.0,
                                            borderSide: BorderSide(
                                              color: Colors.transparent,
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(22.0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              child: Text(
                                                  'Connection Status: ${connectionStatus}'),
                                            ),
                                          ],
                                        ),
                                        Visibility(
                                          visible: isVisible,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(10.0),
                                                child: Text(
                                                    'Battery Percentage: ${battery}%'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Text(
                            //   'Tab View 2',
                            //   style: FlutterFlowTheme.of(context)
                            //       .bodyMedium
                            //       .override(
                            //         fontFamily: 'sf pro display',
                            //         fontSize: 32.0,
                            //         useGoogleFonts: false,
                            //       ),
                            // ),
                            // HistoryContainer(
                            //     temp: '76',
                            //     pulse: '76',
                            //     oxy: '76',
                            //     date: 'February 07, 2024',
                            //     time: ' 9:41 AM',
                            //     result: 0.5),
                            // Padding(
                            //   padding: EdgeInsetsDirectional.all(10.0),
                            //   child: Expanded(
                            //       child: ListView.builder(
                            //           itemCount: myCSV.data.length,
                            //           itemBuilder: (context, int index) {
                            //             return HistoryContainer(
                            //                 temp: myCSV.data[index][0],
                            //                 pulse: myCSV.date[index][1],
                            //                 oxy: myCSV.date[index][2],
                            //                 date: myCSV.date[index][4],
                            //                 time: myCSV.date[index][5],
                            //                 result: myCSV.date[index][3]);
                            //           })),
                            // )
                            FutureBuilder<List<List<dynamic>>>(
                              future: _dataFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  // _isFetchingData =
                                  //     true; // Set flag while fetching
                                  return Center(
                                      child: CircularProgressIndicator());
                                } else if (snapshot.hasData) {
                                  final data = snapshot.data!;
                                  _isFetchingData = false;

                                  lastDiagDate =
                                      '${data[data.length - 1][4]}(${data[data.length - 1][5]})';
                                  // lastDiagTime = data[data.length - 1][5];

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
                                      //     Row(
                                      //   children: [
                                      //     Text(data[index][0]),
                                      //     Text(data[index][1]),
                                      //     Text(data[index][2]),
                                      //     Text(data[index][3]),
                                      //     Text(data[index][4]),
                                      //     Text(data[index][5]),
                                      //   ],
                                      // );
                                    },
                                  );
                                  // Text('$data');
                                } else if (snapshot.hasError) {
                                  return Text(
                                      'Error fetching data: ${snapshot.error}');
                                } else {
                                  return Center(
                                      child: CircularProgressIndicator());
                                }
                              },
                            ),
                            FutureBuilder<List<List<dynamic>>>(
                              future: _alertData,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  // _isFetchingData =
                                  //     true; // Set flag while fetching
                                  return Center(
                                      child: CircularProgressIndicator());
                                } else if (snapshot.hasData) {
                                  final data = snapshot.data!;
                                  _isFetchingData = false;
                                  return ListView.builder(
                                    itemCount: data.length,
                                    itemBuilder: (context, index) {
                                      return AlertWidget(
                                          alert: data[index][0],
                                          value: data[index][1],
                                          intensity: data[index][2],
                                          date: data[index][3],
                                          time: data[index][4]);
                                    },
                                  );
                                  // Text('$data');
                                } else if (snapshot.hasError) {
                                  return Text(
                                      'Error fetching data: ${snapshot.error}');
                                } else {
                                  return Center(
                                      child: CircularProgressIndicator());
                                }
                              },
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
