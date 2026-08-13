import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum LegalDocument {
  about('非公式について', 'assets/legal/about_ja.md'),
  terms('利用規約', 'assets/legal/terms_ja.md'),
  privacy('プライバシーポリシー', 'assets/legal/privacy_ja.md');

  const LegalDocument(this.title, this.assetPath);

  final String title;
  final String assetPath;
}

class LegalPage extends StatefulWidget {
  const LegalPage({super.key, required this.document});

  final LegalDocument document;

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  late Future<String> _body;

  @override
  void initState() {
    super.initState();
    _body = rootBundle.loadString(widget.document.assetPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.title),
      ),
      body: FutureBuilder<String>(
        future: _body,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('読み込みに失敗しました: ${snapshot.error}'));
          }
          return SelectionArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Text(
                snapshot.data ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.55,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}
