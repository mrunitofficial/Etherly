import 'package:flutter/foundation.dart';

class IcyService with ChangeNotifier {
  String? _text;
  bool _loading = false;

  String? get text => _text;
  bool get isLoading => _loading;

  void setIdle() {
    _loading = false;
    _text = null;
    notifyListeners();
  }

  void startLoading() {
    _loading = true;
    _text = null;
    notifyListeners();
  }

  void setText(String value) {
    _text = value;
    _loading = false;
    notifyListeners();
  }

  void onPause() {
    _loading = false;
    notifyListeners();
  }
}
