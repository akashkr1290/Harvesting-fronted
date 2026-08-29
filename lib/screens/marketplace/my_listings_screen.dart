import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_client.dart';
import '../../services/marketplace_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/marketplace/listing_card.dart';
import 'create_edit_listing_screen.dart';
import 'listing_detail_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      await context.read<MarketplaceService>().fetchMyListings();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not reach the server. Check your connection and try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<MarketplaceService>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context)
              .push<bool>(MaterialPageRoute(builder: (_) => const CreateEditListingScreen()));
          if (created == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Listing'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(service),
      ),
    );
  }

  Widget _buildBody(MarketplaceService service) {
    if (service.isLoading && service.myListings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && service.myListings.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline, size: 40, color: AppTheme.danger.withOpacity(0.7)),
          const SizedBox(height: 12),
          Center(child: Text(_error!, textAlign: TextAlign.center)),
          const SizedBox(height: 16),
          Center(child: OutlinedButton(onPressed: _load, child: const Text('Retry'))),
        ],
      );
    }
    if (service.myListings.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Icon(Icons.storefront_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Center(child: Text('You have no listings yet.', style: TextStyle(color: Colors.grey))),
          Center(child: Text('Tap "New Listing" to create one.', style: TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      itemCount: service.myListings.length,
      itemBuilder: (context, index) {
        final listing = service.myListings[index];
        return ListingCard(
          listing: listing,
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ListingDetailScreen(listingId: listing.id, isOwner: true)),
            );
            _load();
          },
        );
      },
    );
  }
}
