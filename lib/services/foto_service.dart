import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Escolhe uma foto (galeria ou câmera) e guarda uma cópia na pasta privada do
/// app. Somente o caminho do arquivo é gravado no banco.
class FotoService {
  FotoService._();

  static final ImagePicker _picker = ImagePicker();

  static Future<String?> escolher(ImageSource origem) async {
    final XFile? arquivo = await _picker.pickImage(
      source: origem,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (arquivo == null) {
      return null;
    }
    final base = await getApplicationDocumentsDirectory();
    final pasta = Directory(p.join(base.path, 'fotos'));
    if (!await pasta.exists()) {
      await pasta.create(recursive: true);
    }
    final destino =
        p.join(pasta.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(arquivo.path).copy(destino);
    return destino;
  }
}
