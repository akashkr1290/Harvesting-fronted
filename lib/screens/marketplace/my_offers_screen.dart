import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/offer_status.dart';
import '../../services/api_client.dart';
import '../../services/offer_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/marketplace/offer_card.dart';

class MyOffersScreen extends StatefulWidget {
  const MyOffersScreen({super.key});

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen> {
  String? _error;
  String? _withdrawingOfferId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      await context.read<OfferService>().fetchMyOffers();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not reach the server. Check your connection and try again.');
    }
  }

  Future<void> _withdraw(String offerId) async {
    setState(() => _withdrawingOfferId = offerId);
    try {
      await context.read<OfferService>().withdraw(offerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer withdrawn.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _withdrawingOfferId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<OfferService>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Offers')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody(service)),
    );
  }

  Widget _buildBody(OfferService service) {
    if (service.isLoading && service.myOffers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && service.myOffers.isEmpty) {
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
    if (service.myOffers.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Icon(Icons.local_offer_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Center(child: Text('You haven\'t submitted any offers yet.', style: TextStyle(color: Colors.grey))),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: service.myOffers.length,
      itemBuilder: (context, index) {
        final offer = service.myOffers[index];
        final acting = _withdrawingOfferId == offer.id;
        return OfferCard(
          offer: offer,
          trailingAction: offer.status == OfferStatus.pending
              ? OutlinedButton(
                  onPressed: acting ? null : () => _withdraw(offer.id),
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger),
                  child: acting
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Withdraw'),
                )
              : null,
        );
      },
    );
  }
}
