import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/produce_image.dart';
import '../../services/api_client.dart';
import '../../services/localization_service.dart';
import '../../services/market_price_service.dart';
import '../../services/marketplace_service.dart';
import '../../services/produce_image_service.dart';
import '../../services/voice_service.dart';
import '../../widgets/simple/crop_art.dart';
import '../../widgets/simple/simple_ui.dart';
import 'my_crops_simple_screen.dart';

/// Sell a crop in four steps, no typing needed:
/// 1 pick the crop picture, 2 quantity + when ready + village, 3 price (with today's
/// mandi price shown), 4 take a photo of the real crop. Then the listing is created,
/// the photo is checked, and if the check passes it goes on sale straight away.
class SellWizardScreen extends StatefulWidget {
  const SellWizardScreen({super.key});

  @override
  State<SellWizardScreen> createState() => _SellWizardScreenState();
}

class _SellWizardScreenState extends State<SellWizardScreen> {
  static const _steps = 4;
  int _step = 0;
  CropOption? _crop;
  final _otherCrop = TextEditingController();
  double _qty = 100;
  int _readyInDays = 0;
  final _village = TextEditingController();
  double _price = 20;
  bool _priceTouched = false;
  MandiPrice? _mandi;
  bool _mandiLoaded = false;
  XFile? _photo;
  Uint8List? _photoBytes;
  bool _busy = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final mine = context.read<MarketplaceService>().myListings;
    if (mine.isNotEmpty) _village.text = mine.first.location;
  }

  @override
  void dispose() {
    _otherCrop.dispose();
    _village.dispose();
    super.dispose();
  }

  String get _cropApiName => _crop?.apiName ?? _otherCrop.text.trim();

  String _cropLabel(LocalizationService loc) => _crop != null ? loc.t(_crop!.labelKey) : _otherCrop.text.trim();

  bool get _canContinue {
    switch (_step) {
      case 0:
        return _cropApiName.isNotEmpty;
      case 1:
        return _qty > 0 && _village.text.trim().isNotEmpty;
      case 2:
        return _price > 0;
      default:
        return _photo != null;
    }
  }

  Future<void> _loadMandi() async {
    if (_cropApiName.isEmpty) return;
    final district = _village.text.trim().isEmpty ? null : _village.text.trim();
    final p = await context.read<MarketPriceService>().latest(_cropApiName, district: district);
    if (!mounted) return;
    setState(() {
      _mandi = p;
      _mandiLoaded = true;
      if (!_priceTouched && p != null) _price = p.modalPerKg.roundToDouble().clamp(1, 100000).toDouble();
    });
  }

  void _next() {
    if (!_canContinue) return;
    if (_step == 1) _loadMandi();
    if (_step < _steps - 1) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _listen(void Function(String) onHeard) async {
    final loc = context.read<LocalizationService>();
    final heard = await context.read<VoiceService>().listen(localeId: loc.speechLocaleId);
    if (heard != null && heard.trim().isNotEmpty && mounted) onHeard(heard.trim());
  }

  Future<void> _takePhoto(ImageSource source) async {
    try {
      final x = await _picker.pickImage(source: source, maxWidth: 1800, imageQuality: 88);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (mounted) {
        setState(() {
          _photo = x;
          _photoBytes = bytes;
        });
      }
    } catch (_) {
      // Camera denied or unavailable: the gallery button is still there.
    }
  }

  Future<void> _submit() async {
    final loc = context.read<LocalizationService>();
    final market = context.read<MarketplaceService>();
    final images = context.read<ProduceImageService>();
    setState(() => _busy = true);
    try {
      final listing = await market.createListing(
        cropName: _cropApiName,
        quantity: _qty,
        unit: 'kg',
        harvestDate: DateTime.now().add(Duration(days: _readyInDays)),
        location: _village.text.trim(),
        expectedPricePerUnit: _price,
      );
      final bytes = _photoBytes ?? await _photo!.readAsBytes();
      final name = _photo!.name.isEmpty ? 'crop.jpg' : _photo!.name;
      final image = await images.upload(listingId: listing.id, bytes: bytes, filename: name, isPrimary: true);
      String message;
      PillKind kind;
      if (image.decision == ImageDecision.accept) {
        await market.publish(listing.id);
        message = loc.t('listed_success');
        kind = PillKind.good;
      } else if (image.decision == ImageDecision.reject) {
        message = loc.t('photo_rejected');
        kind = PillKind.bad;
      } else {
        message = loc.t('photo_review');
        kind = PillKind.waiting;
      }
      if (!mounted) return;
      await _showResult(message, kind);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MyCropsSimpleScreen()));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.t('no_internet'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showResult(String message, PillKind kind) {
    final loc = context.read<LocalizationService>();
    context.read<VoiceService>().speak(message, language: loc.ttsLanguage);
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            kind == PillKind.good
                ? Icons.check_circle_rounded
                : kind == PillKind.bad
                    ? Icons.cancel_rounded
                    : Icons.schedule_rounded,
            size: 72,
            color: kind == PillKind.good
                ? SimpleColors.green
                : kind == PillKind.bad
                    ? SimpleColors.red
                    : SimpleColors.orange,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          BigButton(label: loc.t('done'), onPressed: () => Navigator.of(ctx).pop()),
        ]),
      ),
    );
  }

  String _speech(LocalizationService loc) {
    switch (_step) {
      case 0:
        return loc.t('which_crop');
      case 1:
        return '${loc.tf('how_much', {'crop': _cropLabel(loc)})} ${_qty.toStringAsFixed(0)} ${loc.t('kg')}';
      case 2:
        return [
          '${loc.t('your_price')}: ₹${_price.toStringAsFixed(0)}',
          if (_mandi != null) loc.tf('mandi_today', {'price': _mandi!.modalPerKg.toStringAsFixed(0)}),
          '${loc.t('total')}: ${rupees(_qty * _price)}',
        ].join('. ');
      default:
        return '${loc.t('take_photo')}. ${loc.t('photo_hint')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final title = switch (_step) {
      0 => loc.t('which_crop'),
      1 => loc.tf('how_much', {'crop': _cropLabel(loc)}),
      2 => loc.t('your_price'),
      _ => loc.t('take_photo'),
    };
    return PopScope(
      canPop: _step == 0 && !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy) _back();
      },
      child: SimplePage(
        header: Column(children: [
          SimpleHeader(title: title, speakText: () => _speech(loc)),
          Padding(padding: const EdgeInsets.only(top: 4), child: StepDots(current: _step, total: _steps)),
        ]),
        children: [
          if (_step == 0) ..._cropStep(loc),
          if (_step == 1) ..._quantityStep(loc),
          if (_step == 2) ..._priceStep(loc),
          if (_step == 3) ..._photoStep(loc),
        ],
        bottom: [
          BigButton(
            label: _step == _steps - 1 ? loc.t('put_for_sale') : loc.t('next'),
            icon: _step == _steps - 1 ? Icons.sell_rounded : Icons.arrow_forward_rounded,
            onPressed: _canContinue ? _next : null,
            busy: _busy,
          ),
        ],
      ),
    );
  }

  List<Widget> _cropStep(LocalizationService loc) => [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.82,
          children: [
            for (final c in cropOptions)
              Semantics(
                button: true,
                selected: _crop?.id == c.id,
                label: loc.t(c.labelKey),
                child: Material(
                  color: _crop?.id == c.id ? SimpleColors.greenSoft : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => setState(() {
                      _crop = c;
                      _otherCrop.clear();
                    }),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: _crop?.id == c.id ? SimpleColors.green : SimpleColors.line,
                            width: _crop?.id == c.id ? 3 : 2),
                      ),
                      child: Stack(children: [
                        Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            CropPicture(cropName: c.apiName, size: 60),
                            const SizedBox(height: 4),
                            Text(loc.t(c.labelKey),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: SimpleColors.ink)),
                          ]),
                        ),
                        if (_crop?.id == c.id)
                          const Positioned(
                              top: 6, right: 6, child: Icon(Icons.check_circle_rounded, color: SimpleColors.green, size: 28)),
                      ]),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _otherCrop,
          style: const TextStyle(fontSize: 20),
          onChanged: (_) => setState(() => _crop = null),
          decoration: InputDecoration(
            labelText: loc.t('speak_crop'),
            suffixIcon: IconButton(
              iconSize: 30,
              tooltip: loc.t('speak_crop'),
              icon: const Icon(Icons.mic_rounded, color: SimpleColors.green),
              onPressed: () => _listen((heard) => setState(() {
                _crop = cropOptions.where((c) => heard.toLowerCase().contains(loc.t(c.labelKey).toLowerCase()) ||
                    heard.toLowerCase().contains(c.apiName.toLowerCase())).firstOrNull;
                if (_crop == null) _otherCrop.text = heard;
              })),
            ),
          ),
        ),
      ];

  List<Widget> _quantityStep(LocalizationService loc) => [
        Row(children: [
          CropPicture(cropName: _cropApiName, size: 52),
          const SizedBox(width: 10),
          Expanded(
              child: Text(_cropLabel(loc),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: SimpleColors.ink))),
        ]),
        const SizedBox(height: 12),
        QuantityStepper(
          value: _qty,
          step: _qty >= 500 ? 50 : 10,
          min: 10,
          unitLabel: loc.t('kg'),
          quickPicks: const [50, 100, 500, 1000],
          quickLabel: (q) => q >= 1000 ? '${(q / 1000).toStringAsFixed(0)} t' : q.toStringAsFixed(0),
          onChanged: (v) => setState(() => _qty = v),
          onVoice: () => _listen((heard) {
            final n = VoiceService.numberFrom(heard);
            if (n != null && n > 0) setState(() => _qty = n);
          }),
        ),
        const SizedBox(height: 18),
        Text(loc.t('when_harvest'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final d in const [0, 3, 7, 15])
            ChoiceChip(
              label: Text(d == 0 ? loc.t('today') : loc.tf('in_days', {'n': d}),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              selected: _readyInDays == d,
              selectedColor: SimpleColors.greenSoft,
              side: BorderSide(color: _readyInDays == d ? SimpleColors.green : SimpleColors.line, width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              onSelected: (_) => setState(() => _readyInDays = d),
            ),
        ]),
        const SizedBox(height: 18),
        TextField(
          controller: _village,
          style: const TextStyle(fontSize: 20),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: loc.t('village_location'),
            prefixIcon: const Icon(Icons.place_rounded),
            suffixIcon: IconButton(
              iconSize: 30,
              icon: const Icon(Icons.mic_rounded, color: SimpleColors.green),
              onPressed: () => _listen((heard) => setState(() => _village.text = heard)),
            ),
          ),
        ),
      ];

  List<Widget> _priceStep(LocalizationService loc) => [
        QuantityStepper(
          value: _price,
          step: 1,
          min: 1,
          unitLabel: '₹ ${loc.t('per_kg')}',
          format: (v) => '₹${v.toStringAsFixed(0)}',
          onChanged: (v) => setState(() {
            _price = v;
            _priceTouched = true;
          }),
          onVoice: () => _listen((heard) {
            final n = VoiceService.numberFrom(heard);
            if (n != null && n > 0) {
              setState(() {
                _price = n;
                _priceTouched = true;
              });
            }
          }),
        ),
        const SizedBox(height: 12),
        if (!_mandiLoaded)
          const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
        else ...[
          MandiCompare(mandiPerKg: _mandi?.modalPerKg),
          if (_mandi != null) ...[
            const SizedBox(height: 8),
            Center(child: MandiCompare(mandiPerKg: _mandi!.modalPerKg, pricePerKg: _price)),
          ],
        ],
        const SizedBox(height: 18),
        Center(
          child: Column(children: [
            Text('${_qty.toStringAsFixed(0)} ${loc.t('kg')} × ₹${_price.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 18, color: SimpleColors.quiet)),
            Text('= ${rupees(_qty * _price)}',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: SimpleColors.green)),
          ]),
        ),
      ];

  List<Widget> _photoStep(LocalizationService loc) => [
        Text(loc.t('photo_hint'), style: const TextStyle(fontSize: 18, color: SimpleColors.ink)),
        const SizedBox(height: 12),
        if (_photoBytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(aspectRatio: 4 / 3, child: Image.memory(_photoBytes!, fit: BoxFit.cover)),
          )
        else
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: SimpleColors.line, width: 2),
            ),
            child: Center(child: CropPicture(cropName: _cropApiName, size: 110)),
          ),
        const SizedBox(height: 12),
        BigButton(
          label: _photo == null ? loc.t('take_photo') : loc.t('retake'),
          icon: Icons.photo_camera_rounded,
          outlined: _photo != null,
          onPressed: () => _takePhoto(ImageSource.camera),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _takePhoto(ImageSource.gallery),
          icon: const Icon(Icons.photo_library_rounded),
          label: Text(loc.t('from_gallery'), style: const TextStyle(fontSize: 17)),
        ),
      ];
}
