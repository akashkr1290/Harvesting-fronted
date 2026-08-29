import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/offer_status.dart';
import '../../services/api_client.dart';
import '../../services/offer_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/marketplace/offer_card.dart';
import 'order_detail_screen.dart';

class OffersReceivedScreen extends StatefulWidget {
  const OffersReceivedScreen({super.key});

  @override
  State<OffersReceivedScreen> createState() => _OffersReceivedScreenState();
}

class _OffersReceivedScreenState extends State<OffersReceivedScreen> {
  String? _error;
  String? _actingOnOfferId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      await context.read<OfferService>().fetchReceived();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not reach the server. Check your connection and try again.');
    }
  }

  Future<void> _accept(String offerId) async {
    setState(() => _actingOnOfferId = offerId);
    try {
      final order = await context.read<OfferService>().accept(offerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer accepted — order created.')));
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: (e.isForbidden || e.isConflict) ? AppTheme.danger : null),
      );
    } finally {
      if (mounted) setState(() => _actingOnOfferId = null);
    }
  }

  Future<void> _reject(String offerId) async {
    setState(() => _actingOnOfferId = offerId);
    try {
      await context.read<OfferService>().reject(offerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer rejected.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _actingOnOfferId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<OfferService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Offers Received')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody(service)),
    );
  }

  Widget _buildBody(OfferService service) {
    if (service.isLoading && service.received.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && service.received.isEmpty) {
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
    if (service.received.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Icon(Icons.local_offer_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Center(child: Text('No offers received yet.', style: TextStyle(color: Colors.grey))),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: service.received.length,
      itemBuilder: (context, index) {
        final offer = service.received[index];
        final acting = _actingOnOfferId == offer.id;
        return OfferCard(
          offer: offer,
          showBuyer: true,
          trailingAction: offer.status == OfferStatus.pending
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: acting ? null : () => _reject(offer.id),
                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: acting ? null : () => _accept(offer.id),
                        child: acting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Accept'),
                      ),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}
