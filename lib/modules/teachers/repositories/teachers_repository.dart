import 'package:enough_convert/enough_convert.dart';
import 'package:http/http.dart' as http;

class TeachersRepository {
  final codec = const Windows1251Codec(allowInvalid: false);

  Future<List<String>> loadFacultiesPages(String link1, {String? link2}) async {
    final pageText1 = await http.readBytes(Uri.https('portal.esstu.ru', link1));
    if (link2 == null) {
      return [codec.decode(pageText1)];
    }

    final pageText2 = await http.readBytes(Uri.https('portal.esstu.ru', link2));
    return [codec.decode(pageText1), codec.decode(pageText2)];
  }

  Future<List<String>> loadDepartmentPages(String link1,
      {String? link2}) async {
    final pageText1 = await http.readBytes(Uri.https('portal.esstu.ru', link1));
    if (link2 == null) {
      return [codec.decode(pageText1)];
    }

    final pageText2 = await http.readBytes(Uri.https('portal.esstu.ru', link2));
    return [codec.decode(pageText1), codec.decode(pageText2)];
  }
}
