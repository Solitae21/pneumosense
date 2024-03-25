import 'package:pneumosense/methods/fileManagement.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'diagnostic_phase_one_model.dart';
export 'diagnostic_phase_one_model.dart';
import '../../methods/connect.dart' as connect;
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../../methods/learning_model.dart' as pneumosense;

class DiagnosticPhaseOneWidget extends StatefulWidget {
  const DiagnosticPhaseOneWidget({super.key});

  @override
  State<DiagnosticPhaseOneWidget> createState() =>
      _DiagnosticPhaseOneWidgetState();
}

class _DiagnosticPhaseOneWidgetState extends State<DiagnosticPhaseOneWidget> {
  late DiagnosticPhaseOneModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  double progress = 0.0;
  dynamic connectionStatus;
  dynamic pulseVal;
  dynamic tempVal;
  dynamic oxyVal;
  dynamic _temp;
  dynamic _pulse;
  dynamic _pulseRound;
  dynamic _oxy;
  dynamic _oxyRound;
  String? _toRound;
  var progressText;
  late double progressMul;
  late List<double> pulseAvgList;
  late List<double> oxyAvgList;
  late List<double> tempAvgList;
  late double pulseAvg;
  late double tempAvg;
  late double oxyAvg;
  final pneumosenseModel = pneumosense.PneumoniaDetector();
  late bool isVisible;
  FileManager file = FileManager();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DiagnosticPhaseOneModel());
    progress = 0.0;
    progressText = '0';
    progressMul = 0.00;
    pulseAvgList = [];
    oxyAvgList = [];
    tempAvgList = [];
    getDiagData();
    processData(isComplete);
    isVisible = false;
  }

  Completer<bool> isComplete = Completer<bool>();

  Future<void> getValues(bool isCompleted) async {
    final String wemosIPAddress =
        '192.168.4.1'; // Replace with your Wemos D1 Mini IP address
    if (isCompleted == false) {
      try {
        final response = await http.get(Uri.parse('http://$wemosIPAddress/'));
        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          setState(() {
            connectionStatus = 'Connected';
            _temp = jsonData['tempVal'];
            _toRound = _temp.toStringAsFixed(2);
            _temp = double.parse(_toRound!);

            _pulse = jsonData['pulseVal'];
            _pulseRound = _pulse.toStringAsFixed(2);
            _pulse = double.parse(_pulseRound!);

            _oxy = jsonData['oxyVal'];
            _oxyRound = _oxy.toStringAsFixed(2);
            _oxy = double.parse(_oxyRound!);

            // tempVal = _temp.toString();
            // print('Temp: $tempVal'); // Debug print
            // oxyVal = _oxy.toString();
            // print('Oxygen: $oxyVal'); // Debug print
            // pulseVal = _pulse.toString();
            // print('Pulse: $pulseVal'); // Debug print
            if (progress < 0.6) {
              tempAvgList.add(jsonData['tempVal']);
              pulseAvgList.add(jsonData['pulseVal']);
              oxyAvgList.add(jsonData['oxyVal']);
              progress = progress + 0.01;
              progressMul = progress * 100;
              progressText = progressMul.toStringAsFixed(0);
              print(tempAvgList);
              print(oxyAvgList);
              print(pulseAvgList);
              print(progress);
            }
          });
        } else {
          setState(() {
            connectionStatus = 'Not Connected to Wemos D1 Mini';
            tempVal = '0';
            oxyVal = '0';
            pulseVal = '0';
          });
        }
      } catch (e) {
        setState(() {
          connectionStatus = 'Error: $e';
          tempVal = '0';
          oxyVal = '0';
          pulseVal = '0';
        });
      }
    }
  }

  // void startDiagnosticTimer() {
  //   const Duration updateInterval = Duration(seconds: 1);

  //   Timer.periodic(updateInterval, (Timer timer) async {
  //     await getValues(); // Update temperature periodically
  //   });
  // }

  void processData(Completer<bool> isComplete) async {
    bool isCompleted = await isComplete.future;
    if (isCompleted == true) {
      await pneumosenseModel.loadModel();
      setState(() {
        progress = 0.7;
        progressMul = progress * 100;
        progressText = progressMul.toStringAsFixed(0);
        tempAvg = connect.getAverage(tempAvgList);
        oxyAvg = connect.getAverage(oxyAvgList);
        pulseAvg = connect.getAverage(pulseAvgList);
        // tempAvg = 41;
        // oxyAvg = 40;
        // pulseAvg = 9;
        progress = 0.8;
        progressMul = progress * 100;
        progressText = progressMul.toStringAsFixed(0);
        print(progress);
        print(tempAvg);
        print(oxyAvg);
        print(pulseAvg);
        print(
            '${tempAvgList.length},${oxyAvgList.length},${pulseAvgList.length}');
        tempAvgList.clear();
        oxyAvgList.clear();
        pulseAvgList.clear();
        progress = 1.0;
        progressMul = progress * 100;
        progressText = progressMul.toStringAsFixed(0);
        isVisible = true;
      });
      final result = await pneumosenseModel.predict(
          // Call predict inside the callback
          tempAvg: tempAvg,
          pulseAvg: pulseAvg,
          oxyAvg: oxyAvg);
      file.writeJsonFile(
          temp: tempAvg,
          pulse: pulseAvg,
          oxy: oxyAvg,
          result: result,
          date: connect.formattedDate(),
          time: connect.formattedTime());
    }
  }

  void getDiagData() {
    bool timerCanceled = false;
    if (progress < 0.6) {
      Timer.periodic(Duration(seconds: 1), (timer) async {
        await getValues(timerCanceled);

        if (progress >= 0.6) {
          timerCanceled = true;
          isComplete.complete(true);
          timer.cancel();
        }
      });
    }
    // else if (progress >= 0.6) {
    //   setState(() {
    //     progress = 1.0;
    //     progressMul = progress * 100;
    //     progressText = progressMul.toStringAsFixed(0);
    //     tempAvg = connect.getAverage(tempAvgList);
    //     oxyAvg = connect.getAverage(oxyAvgList);
    //     pulseAvg = connect.getAverage(pulseAvgList);
    //     print(progress);
    //     print(tempAvg);
    //     print(oxyAvg);
    //     print(pulseAvg);
    //     print(
    //         '${tempAvgList.length},${oxyAvgList.length},${pulseAvgList.length}');
    //     tempAvgList.clear();
    //     oxyAvgList.clear();
    //     pulseAvgList.clear();
    //   });
    // }

    // while (progress < 0.6) {
    //   startDiagnosticTimer();
    // }
    // if (progress >= 0.6) {
    //   setState(() {
    //     progress = 1.0;
    //     progressMul = progress * 100;
    //     progressText = progressMul.toStringAsFixed(0);
    //     tempAvg = connect.getAverage(tempAvgList);
    //     oxyAvg = connect.getAverage(oxyAvgList);
    //     pulseAvg = connect.getAverage(pulseAvgList);
    //     print(progress);
    //     print(tempAvg);
    //     print(oxyAvg);
    //     print(pulseAvg);
    //     print(
    //         '${tempAvgList.length},${oxyAvgList.length},${pulseAvgList.length}');
    //     tempAvgList.clear();
    //     oxyAvgList.clear();
    //     pulseAvgList.clear();
    //   });
    // }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
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

    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 160.0,
                          height: 60.0,
                          fit: BoxFit.scaleDown,
                          alignment: Alignment(-1.0, 0.0),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 50.0, 0.0, 0.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Diagnosing...',
                            textAlign: TextAlign.start,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'sf pro display',
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  useGoogleFonts: false,
                                ),
                          ),
                        ],
                      ),
                      Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 30.0, 0.0, 0.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularPercentIndicator(
                              percent: progress,
                              radius: 150.0,
                              lineWidth: 20.0,
                              animation: true,
                              animateFromLastPercent: true,
                              progressColor:
                                  FlutterFlowTheme.of(context).secondary,
                              backgroundColor:
                                  FlutterFlowTheme.of(context).accent4,
                              center: Text(
                                '${progressText}%',
                                style: FlutterFlowTheme.of(context)
                                    .headlineLarge
                                    .override(
                                      fontFamily: 'sf pro display',
                                      fontSize: 50.0,
                                      fontWeight: FontWeight.bold,
                                      useGoogleFonts: false,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 30.0, 0.0, 0.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Please wait while the diagnosis is complete.',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'sf pro display',
                                    fontSize: 15.0,
                                    useGoogleFonts: false,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 0.0),
                  child: Visibility(
                    visible: isVisible,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FFButtonWidget(
                          onPressed: () async {
                            connect.sendDiagDataToWemos();
                            context.goNamed('DiagnosticPhaseTwo');
                          },
                          text: 'View Results',
                          options: FFButtonOptions(
                            height: 40.0,
                            padding: EdgeInsetsDirectional.fromSTEB(
                                24.0, 0.0, 24.0, 0.0),
                            iconPadding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 0.0),
                            color: Color(0xFFDDDDDD),
                            textStyle: FlutterFlowTheme.of(context)
                                .titleSmall
                                .override(
                                  fontFamily: 'sf pro display',
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  useGoogleFonts: false,
                                ),
                            elevation: 3.0,
                            borderSide: BorderSide(
                              color: Colors.transparent,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(18.0),
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
      ),
    );
  }
}
