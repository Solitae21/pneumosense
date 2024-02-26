import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'home_page_widget.dart' show HomePageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/methods/connect.dart' as connect;

import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class HomePageModel extends FlutterFlowModel<HomePageWidget> {
  final unfocusNode = FocusNode();
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  String? Function(BuildContext, String?)? textControllerValidator;

  // Your additional code starts here:
  // var tempVal;
  // var oxyVal;
  // var pulseVal;
  // var connectionStatus;

  // Your additional code ends here.

  @override
  void initState(BuildContext context) {
    // checkConnection();
    // startTempUpdateTimer();
    // tempVal = '0';
    // oxyVal = '0';
    // pulseVal = '0';
    // connectionStatus = 'Not Connected';
  }

  @override
  void dispose() {
    unfocusNode.dispose();
    tabBarController?.dispose();
  }

  // dynamic _temp;
  // String? _toRound;
}
