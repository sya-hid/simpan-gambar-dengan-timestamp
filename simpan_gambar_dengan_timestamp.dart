import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class SimpanGambarTimeStamp extends StatefulWidget {
  const SimpanGambarTimeStamp({super.key});

  @override
  _SimpanGambarTimeStampState createState() => _SimpanGambarTimeStampState();
}

class _SimpanGambarTimeStampState extends State<SimpanGambarTimeStamp> {
  final GlobalKey _globalKey = GlobalKey();

  Future<void> _captureAndSave() async {
    try {
      //RenderRepaintBoundary digunakan untuk membungkus widget lain agar bisa diambil gambarnya (screenshot)
      // boundary adalah objek RenderRepaintBoundary yang diambil dari konteks global _globalKey.
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage();
      // Gambar yang diambil diubah menjadi format byte data (ByteData) dengan format PNG (ImageByteFormat.png).
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      // Kemudian, data byte tersebut dikonversi menjadi Uint8List, yang merupakan representasi byte dari gambar PNG.
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      // direktori aplikasi di perangkat, tempat file dapat disimpan.
      final directory = await getApplicationDocumentsDirectory();
      //simpan gambar diperangnkat
      final imagePath = '${directory.path}/image_with_timestamp.png';
      final imageFile = File(imagePath);
      // untuk menulis data byte gambar ke file tersebut
      await imageFile.writeAsBytes(pngBytes);

      await uploadFile(imageFile);
    } catch (e) {
      print(e);
    }
  }

  Future<void> uploadFile(File file) async {
    try {
      String fileName = 'images/${DateTime.now().millisecondsSinceEpoch}.png';
      final firebaseStorageRef = FirebaseStorage.instance.ref().child(fileName);

      UploadTask uploadTask = firebaseStorageRef.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask.whenComplete(() {});
      final urlDownload = await snapshot.ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('images').add({
        'url': urlDownload,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTimestamp =
        DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now());

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RepaintBoundary(
            key: _globalKey,
            child: Stack(
              children: <Widget>[
                Image.network(
                  'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg',
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      formattedTimestamp,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _captureAndSave,
            child: const Text('Save Image with Timestamp'),
          ),
        ],
      ),
    );
  }
}
