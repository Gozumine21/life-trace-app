import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('利用規約')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LifeTrace 利用規約',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              _Section(
                title: '1. 禁止事項',
                body:
                    '本アプリでは、不適切なコンテンツ（暴力的・差別的・わいせつな表現、誹謗中傷、なりすまし、スパム、違法行為を助長する投稿など）および迷惑ユーザーの行為を一切容認しません。'
                    'これらに該当する投稿・行為が確認された場合、事前の通知なくコンテンツを削除し、当該アカウントの利用を停止することがあります。',
              ),
              _Section(
                title: '2. 通報機能',
                body:
                    '不適切な投稿を見つけた場合、投稿詳細画面から「通報する」機能を使ってご報告いただけます。'
                    '開発者は通報を受け付けてから24時間以内に内容を確認し、問題があると判断した場合は速やかにコンテンツの削除および投稿者の利用停止（アカウント排除）を行います。',
              ),
              _Section(
                title: '3. ブロック機能',
                body:
                    '他のユーザーをブロックすると、そのユーザーの投稿は即座にあなたのフィード・検索結果から表示されなくなります。'
                    'ブロックの実施は記録され、開発者が状況を確認できるようになっています。',
              ),
              _Section(
                title: '4. アカウントの停止',
                body:
                    '禁止事項に違反したユーザーについては、通報の有無にかかわらず、開発者の判断でコンテンツの削除およびアカウントの利用停止を行うことがあります。',
              ),
              _Section(
                title: '5. 免責事項',
                body:
                    '本アプリはユーザーが投稿したコンテンツについて、可能な限り迅速に対応しますが、投稿内容そのものについて開発者が責任を負うものではありません。',
              ),
              _Section(
                title: '6. 規約の変更',
                body: '本規約の内容は、法令の変更や機能追加に伴い、予告なく変更されることがあります。',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(height: 1.6)),
        ],
      ),
    );
  }
}
