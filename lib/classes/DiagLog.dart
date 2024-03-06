class DiagLog {
  late var _temp;
  late var _pulse;
  late var _oxy;
  late var _result;
  late var _date;
  late var _time;

  DiagLog(
      this._temp, this._pulse, this._oxy, this._result, this._date, this._time);

  DiagLog.fromJson(Map<String, dynamic> json)
      : _temp = json['temp'],
        _pulse = json['pulse'],
        _oxy = json['oxy'],
        _result = json['result'],
        _date = json['date'],
        _time = json['time'];

  Map<String, dynamic> toJson() => {
        'temp': _temp,
        'pulse': _pulse,
        'oxy': _oxy,
        'result': _result,
        'date': _date,
        'time': _time
      };

  String get getTemp => _temp.toString();
  String get getPulse => _pulse.toString();
  String get getOxy => _oxy.toString();
  String get getResult => _result.toString();
  String get getDate => _date.toString();
  String get getTime => _time.toString();
}
