import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_client.dart';
import '../../services/marketplace_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/marketplace/listing_card.dart';
import 'listing_detail_screen.dart';

class MarketplaceBrowseScreen extends StatefulWidget {
  const MarketplaceBrowseScreen({super.key});

  @override
  State<MarketplaceBrowseScreen> createState() => _MarketplaceBrowseScreenState();
}

class _MarketplaceBrowseScreenState extends State<MarketplaceBrowseScreen> {
  final _queryController = TextEditingController();
  final _locationController = TextEditingController();
  final _cropController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  String? _error;
  bool _filtersOpen = false;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _locationController.dispose();
    _cropController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _error = null);
    try {
      await context.read<MarketplaceService>().searchMarketplace(
            query: _queryController.text.trim().isEmpty ? null : _queryController.text.trim(),
            location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
            cropName: _cropController.text.trim().isEmpty ? null : _cropController.text.trim(),
            minPrice: double.tryParse(_minPriceController.text.trim()),
            maxPrice: double.tryParse(_maxPriceController.text.trim()),
          );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not reach the server. Check your connection and try again.');
    }
  }

  void _clearFilters() {
    _locationController.clear();
    _cropController.clear();
    _minPriceController.clear();
    _maxPriceController.clear();
    _search();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<MarketplaceService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    decoration: const InputDecoration(
                      hintText: 'Search crop, location, or seller',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_filtersOpen ? Icons.filter_alt : Icons.filter_alt_outlined),
                  tooltip: 'Filters',
                  onPressed: () => setState(() => _filtersOpen = !_filtersOpen),
                ),
              ],
            ),
          ),
          if (_filtersOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cropController,
                          decoration: const InputDecoration(labelText: 'Crop'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _locationController,
                          decoration: const InputDecoration(labelText: 'Location'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Min Price'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Max Price'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(onPressed: _clearFilters, child: const Text('Clear')),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(onPressed: _search, child: const Text('Apply')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(child: _buildResults(service)),
        ],
      ),
    );
  }

  Widget _buildResults(MarketplaceService service) {
    if (service.isLoading && service.marketplaceResults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && service.marketplaceResults.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.error_outline, size: 40, color: AppTheme.danger.withOpacity(0.7)),
          const SizedBox(height: 12),
          Center(child: Text(_error!, textAlign: TextAlign.center)),
          const SizedBox(height: 16),
          Center(child: OutlinedButton(onPressed: _search, child: const Text('Retry'))),
        ],
      );
    }
    if (service.marketplaceResults.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Icon(Icons.storefront_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Center(child: Text('No listings match your search.', style: TextStyle(color: Colors.grey))),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: _search,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        itemCount: service.marketplaceResults.length,
        itemBuilder: (context, index) {
          final listing = service.marketplaceResults[index];
          return ListingCard(
            listing: listing,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ListingDetailScreen(listingId: listing.id)),
            ),
          );
        },
      ),
    );
  }
}
