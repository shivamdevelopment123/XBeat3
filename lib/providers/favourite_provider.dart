import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';

class FavouriteProvider extends ChangeNotifier {
  static const _boxName = 'favourites';
  late final Box<String> _box;
  final Set<String> _favs = {};

  FavouriteProvider() {
    _box = Hive.box<String>(_boxName);
    _loadFromBox();
  }

  void _loadFromBox() {
    _favs.addAll(_box.keys.cast<String>());
    notifyListeners();
  }

  bool isFav(String path) => _favs.contains(path);

  Future<void> toggle(String path) async {
    if (_favs.contains(path)) {
      await _box.delete(path);
      _favs.remove(path);
    } else {
      await _box.put(path, path);
      _favs.add(path);
    }
    notifyListeners();
  }

  List<String> get allFavs => _favs.toList();
}
