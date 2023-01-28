import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:document_scanner_flutter/document_scanner_flutter.dart';
import 'package:document_scanner_flutter/configs/configs.dart';
import 'database_helper.dart';

class RecipeEditPage extends StatefulWidget {
  final Function reload;
  final Map<String, dynamic> data;
  const RecipeEditPage({super.key, required this.reload, required this.data});

  @override
  State<RecipeEditPage> createState() => _RecipeEditPageState();
}

class _RecipeEditPageState extends State<RecipeEditPage> {
  final _formKey = GlobalKey<FormState>();

  final androidLabelsConfigs = {
    ScannerLabelsConfig.ANDROID_NEXT_BUTTON_LABEL: "Nächster Schritt",
    ScannerLabelsConfig.ANDROID_SAVE_BUTTON_LABEL: "Speichern",
    ScannerLabelsConfig.ANDROID_ROTATE_LEFT_LABEL: "Links drehen",
    ScannerLabelsConfig.ANDROID_ROTATE_RIGHT_LABEL: "Rechts drehen",
    ScannerLabelsConfig.ANDROID_ORIGINAL_LABEL: "Original",
    ScannerLabelsConfig.ANDROID_BMW_LABEL: "S/W",
    ScannerLabelsConfig.PICKER_CAMERA_LABEL: "Kamera",
    ScannerLabelsConfig.PICKER_GALLERY_LABEL: "Foto Galerie",
    ScannerLabelsConfig.ANDROID_SCANNING_MESSAGE: "Lädt...",
    ScannerLabelsConfig.ANDROID_LOADING_MESSAGE: "Lädt...",
  };

  var categoryItems = [
    'Mamis Rezepte',
    'Fleisch',
    'Apéro',
    'Fisch',
    'Dessert',
    'Kuchen',
    'Vegi'
  ];

  // Initial Selected Value
  String categoryValue = 'Mamis Rezepte';

  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController searchKeywordsController = TextEditingController();

  List<File> imagesList = [];

  @override
  void initState() {
    super.initState();
    // Retrieve the recipes when the app starts
    titleController.text = widget.data[DatabaseHelper.columnTitle];
    descriptionController.text = widget.data[DatabaseHelper.columnDescription];
    searchKeywordsController.text =
        widget.data[DatabaseHelper.columnSearchKeywords];
    if (widget.data[DatabaseHelper.columnImagePath] != "") {
      List<String> tmp = widget.data[DatabaseHelper.columnImagePath].split(";");
      for (final path in tmp) {
        final tmpPath = File(path);
        if (tmpPath.existsSync()) {
          imagesList.add(tmpPath);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rezept bearbeiten"),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showConfirmationDialog(context);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _update();
            widget.reload();
            Navigator.of(context).pop();
          }
        },
        child: const Icon(Icons.check),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      child: TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Titel',
                        ),
                        validator: _validateTitle,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      child: TextField(
                        keyboardType: TextInputType.multiline,
                        minLines: 1, //Normal textInputField will be displayed
                        maxLines:
                            3, // when user presses enter it will adapt to it
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Beschreibung',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Kategorie wählen:"),
                          DropdownButton(
                            // Initial Value
                            value: categoryValue,

                            // Down Arrow Icon
                            icon: const Icon(Icons.keyboard_arrow_down),

                            // Array list of items
                            items: categoryItems.map((String items) {
                              return DropdownMenuItem(
                                value: items,
                                child: Text(items),
                              );
                            }).toList(),
                            // After selecting the desired option,it will
                            // change button value to selected value
                            onChanged: (String? newValue) {
                              setState(() {
                                categoryValue = newValue!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      child: TextField(
                        controller: searchKeywordsController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Suchwörter eingeben',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _startScan(context);
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Text('Bilder hinzufügen'),
              ),
              if (imagesList.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 240,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: <Widget>[
                        for (final image in imagesList)
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Stack(
                              children: [
                                InkWell(
                                  onTap: () {
                                    showImageViewer(
                                        context, Image.file(image).image,
                                        doubleTapZoomable: true);
                                  },
                                  child: Image.file(
                                    image,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 10,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      imagesList.remove(image);
                                      setState(() {
                                        imagesList;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(10),
                                      backgroundColor:
                                          Colors.red, // <-- Button color
                                      foregroundColor:
                                          Colors.red, // <-- Splash color
                                    ),
                                    child: const Icon(Icons.delete,
                                        color: Colors.white),
                                  ),
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

  String? _validateTitle(String? value) {
    if (value! == "") {
      return 'Titel eingeben.';
    } else {
      return null;
    }
  }

  void _update() async {
    var db = DatabaseHelper.instance;
    String imagePath;
    if (imagesList.isNotEmpty) {
      List<String> tmp = [];
      for (final image in imagesList) {
        tmp.add(image.path);
      }
      imagePath = tmp.reduce((value, element) => '$value;$element');
    } else {
      imagePath = "";
    }
    // row to update
    Map<String, dynamic> row = {
      DatabaseHelper.columnId: widget.data[DatabaseHelper.columnId],
      DatabaseHelper.columnTitle: titleController.text,
      DatabaseHelper.columnDescription: descriptionController.text,
      DatabaseHelper.columnSearchKeywords: searchKeywordsController.text,
      DatabaseHelper.columnImagePath: imagePath,
      DatabaseHelper.columnCategory: categoryValue
    };
    final rowsAffected = await db.update(row);
    debugPrint('updated $rowsAffected row(s)');
  }

  void _delete() async {
    var db = DatabaseHelper.instance;

    final rowsDeleted = await db.delete(widget.data[DatabaseHelper.columnId]);
    debugPrint('deleted $rowsDeleted row(s): row ');
  }

  void _startScan(BuildContext context) async {
    var image = await DocumentScannerFlutter.launch(
      context,
      labelsConfig: androidLabelsConfigs,
    );
    if (image != null) {
      imagesList.add(image);
      setState(() {
        imagesList;
      });
    }
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Rezept löschen"),
          content: const Text(
              "Wollen sie das Rezept wirklich unwiderruflich löschen?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Abbrechen"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Löschen"),
              onPressed: () {
                Navigator.of(context).pop();
                _delete();
                widget.reload();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
