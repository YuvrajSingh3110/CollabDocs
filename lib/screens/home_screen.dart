import 'package:docs_clone/common/widgets/loader.dart';
import 'package:docs_clone/models/document_model.dart';
import 'package:docs_clone/repository/auth_repository.dart';
import 'package:docs_clone/repository/document_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';

import '../colors.dart';
import '../models/error_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void signOut(WidgetRef ref) {
    ref.read(authRepositoryProvider).signOut();
    ref.read(userProvider.notifier).update((state) => null);
  }

  void createDocument(BuildContext context, WidgetRef ref) async {
    String token = ref.read(userProvider)!.token;
    final navigator = Routemaster.of(context);
    final sMessenger = ScaffoldMessenger.of(context);
    final errorModel =
        await ref.read(docRepositoryProvider).createDocument(token);
    if (errorModel.data != null) {
      navigator.push('/document/${errorModel.data.id}');
    } else {
      sMessenger.showSnackBar(SnackBar(content: Text(errorModel.error!)));
    }
  }

  void navigateToDocument(BuildContext context, String docId) {
    Routemaster.of(context).push('/document/$docId');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: kWhiteColor,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () => createDocument(context, ref),
              icon: const Icon(
                Icons.add,
                color: kBlackColor,
              ),
            ),
            IconButton(
              onPressed: () => signOut(ref),
              icon: const Icon(
                Icons.logout,
                color: kRedColor,
              ),
            ),
          ],
        ),
        body: FutureBuilder(
          future: ref
              .watch(docRepositoryProvider)
              .getDocuments(ref.watch(userProvider)!.token),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Loader();
            }
            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: ListView.builder(
                itemCount: snapshot.data!.data.length,
                itemBuilder: (context, index) {
                  DocumentModel document = snapshot.data!.data[index];
                  return InkWell(
                    onTap: () => navigateToDocument(context, document.id),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10),
                      decoration: BoxDecoration(
                        color: kBlueColor,
                        borderRadius: BorderRadius.circular(18)
                      ),
                      child: Center(
                        child: Text(
                          document.title,
                          style: const TextStyle(fontSize: 16, color: kWhiteColor),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ));
  }
}
