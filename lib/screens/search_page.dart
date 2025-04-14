import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  List<dynamic> _results = [];
  bool _isLoading = false;
  String? _error;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _searchArtist(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() {
          _results = [];
          _isLoading = false;
          _error = null;
        });
        return;
      }
      setState(() {
        _isLoading = true;
        _error = null;
      });
      try {
        final result = await _apiService.searchArtist(query);
        setState(() {
          _results = result['results']['artistmatches']['artist'];
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search artists...',
                suffixIcon: Icon(Icons.search),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
              onChanged: _searchArtist,
              onSubmitted: (_) => _searchArtist(_searchController.text),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              Expanded(
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) => AnimatedOpacity(
                    opacity: 0.3,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).hintColor,
                        borderRadius: const BorderRadius.all(Radius.circular(4)),
                      ),
                    ),
                  ),
                ),
              ),
            if (_error != null)
              Text(
                'Error: $_error',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final artist = _results[index];
                  return AnimatedSlide(
                    offset: Offset(0, index * 0.05),
                    duration: const Duration(milliseconds: 200), 
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(
                        artist['name'],
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        'Listeners: ${artist['listeners']}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}