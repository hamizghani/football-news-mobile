import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:football_news_mobile/models/news_entry.dart';
import 'package:football_news_mobile/widgets/news_entry_card.dart';
import 'package:football_news_mobile/screens/news_detail.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class NewsEntryListPage extends StatefulWidget {
  const NewsEntryListPage({super.key});

  @override
  State<NewsEntryListPage> createState() => _NewsEntryListPageState();
}

class _NewsEntryListPageState extends State<NewsEntryListPage> {
  late Future<List<NewsEntry>> _futureEntries;

  Future<List<NewsEntry>> fetchNews(CookieRequest request) async {
    final response = await request.get('http://[YOUR_APP_URL]/api/news/');

    dynamic raw = response;
    List<dynamic> data = [];

    if (raw is String) {
      try {
        data = jsonDecode(raw) as List<dynamic>;
      } catch (_) {
        data = [];
      }
    } else if (raw is List) {
      data = raw;
    } else if (raw is Map && raw.containsKey('results')) {
      data = raw['results'] as List<dynamic>;
    } else if (raw is Map) {
      // If the API returns a map with numeric keys or wrapped payload
      data = [raw];
    }

    return data.map((e) => NewsEntry.fromJson(e)).toList();
  }

  @override
  void initState() {
    super.initState();
    // We'll initialize in didChangeDependencies because Request comes from Provider
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final request = Provider.of<CookieRequest>(context, listen: false);
    _futureEntries = fetchNews(request);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Football News')),
      body: FutureBuilder<List<NewsEntry>>(
        future: _futureEntries,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return const Center(child: Text('No news found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (_, index) => NewsEntryCard(
              news: snapshot.data![index],
              onTap: () {
                // Navigate to news detail page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewsDetailPage(
                      news: snapshot.data![index],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
