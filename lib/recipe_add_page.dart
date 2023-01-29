import 'package:flutter/material.dart';
import 'dart:io';
import 'package:document_scanner_flutter/document_scanner_flutter.dart';
import 'package:document_scanner_flutter/configs/configs.dart';
import 'package:recipe/database_helper.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';

class AddRecipePage extends StatefulWidget {
  final Function reload;
  const AddRecipePage({super.key, required this.reload});

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
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

  List<File> imagesList = [];

  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController searchKeywordsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Neues Rezept"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _insert();
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
                                      image.delete();
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

  void _insert() async {
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
    // row to insert
    Map<String, dynamic> row = {
      DatabaseHelper.columnTitle: titleController.text,
      DatabaseHelper.columnDescription: descriptionController.text,
      DatabaseHelper.columnSearchKeywords: searchKeywordsController.text,
      DatabaseHelper.columnImagePath: imagePath,
      DatabaseHelper.columnCategory: categoryValue
    };
    await db.insert(row);
  }

  String? _validateTitle(String? value) {
    if (value! == "") {
      return 'Titel eingeben.';
    } else {
      return null;
    }
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
}
