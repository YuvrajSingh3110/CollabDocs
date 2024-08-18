import 'dart:async';

import 'package:docs_clone/colors.dart';
import 'package:docs_clone/common/widgets/loader.dart';
import 'package:docs_clone/models/document_model.dart';
import 'package:docs_clone/repository/auth_repository.dart';
import 'package:docs_clone/repository/document_repository.dart';
import 'package:docs_clone/repository/socket_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';

import '../models/error_model.dart';

class DocumentScreen extends ConsumerStatefulWidget {
  final String id;
  const DocumentScreen({super.key, required this.id});

  @override
  ConsumerState<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends ConsumerState<DocumentScreen> {
  TextEditingController titleController =
      TextEditingController(text: 'Untitled Document');
  QuillController? _controller;
  ErrorModel? errorModel;
  SocketRepository socketRepository = SocketRepository();

  @override
  void initState() {
    super.initState();
    socketRepository.joinRoom(widget.id);
    fetchDocumentData();
    socketRepository.changeListener((data) => {
          _controller?.compose(
              Delta.fromJson(data['delta']),
              _controller?.selection ??
                  const TextSelection.collapsed(offset: 0),
              ChangeSource.remote)
        });
    Timer.periodic(const Duration(seconds: 2), (timer) {
      socketRepository.autoSave(<String, dynamic>{
        'delta': _controller!.document.toDelta(),
        'room': widget.id,
      });
    });
  }

  void fetchDocumentData() async {
    errorModel = await ref
        .read(docRepositoryProvider)
        .getDocumentById(ref.read(userProvider)!.token, widget.id);
    if (errorModel!.data != null) {
      titleController.text = (errorModel!.data as DocumentModel).title;
      _controller = QuillController(
          document: errorModel!.data.content.isEmpty
              ? Document()
              : Document.fromDelta(Delta.fromJson(errorModel!.data.content)),
          selection: const TextSelection.collapsed(offset: 0));
      setState(() {});
    }
    _controller!.document.changes.listen((event) {
      // 1-> entire content of doc
      // 2-> changes that are made from prev part
      // 3-> local? -> we have typed remote?
      if (event.source == ChangeSource.local) {
        Map<String, dynamic> map = {
          'delta': event.change,
          'room': widget.id,
        };
        socketRepository.typing(map);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    titleController.dispose();
  }

  void updateTitle(WidgetRef ref, String title) {
    ref.read(docRepositoryProvider).updateTitle(
        token: ref.read(userProvider)!.token, id: widget.id, title: title);
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(
        body: Loader(),
      );
    }
    return Scaffold(
        appBar: AppBar(
          backgroundColor: kWhiteColor,
          elevation: 0,
          title: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Routemaster.of(context).replace('/');
                },
                child: Image.asset(
                  'assets/docs-logo.png',
                  height: 30,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                      contentPadding: EdgeInsets.only(left: 10),
                      border: InputBorder.none,
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: kBlueColor),
                      )),
                  onSubmitted: (value) => updateTitle(ref, value),
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    elevation: 0, backgroundColor: kBlueColor),
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                          text:
                              'http://localhost:3000/#/document/${widget.id}'))
                      .then((value) => {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Link copied!',
                                ),
                              ),
                            )
                          });
                },
                icon: const Icon(
                  Icons.lock,
                  size: 16,
                  color: kWhiteColor,
                ),
                label: const Text(
                  'Share',
                  style: TextStyle(color: kWhiteColor),
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(color: kGreyColor, width: 0.1)),
            ),
          ),
        ),
        body: Center(
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              QuillSimpleToolbar(
                configurations:
                    QuillSimpleToolbarConfigurations(controller: _controller!),
              ),
              const SizedBox(
                height: 10,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Card(
                    elevation: 5,
                    child: Container(
                      color: kWhiteColor,
                      padding: const EdgeInsets.all(10),
                      child: QuillEditor.basic(
                        configurations:
                            QuillEditorConfigurations(controller: _controller!),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ));
  }
}
