import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/localization_service.dart';

/// Picture-first crop choices. [apiName] is the English name sent to the backend
/// (it matches Agmarknet commodity names, so mandi prices and forecasts work).
class CropOption {
  final String id;
  final String apiName;
  final String labelKey;
  final String svg;
  final Color tint;
  const CropOption(this.id, this.apiName, this.labelKey, this.svg, this.tint);
}

const _tomato = '<svg viewBox="0 0 64 64"><circle cx="32" cy="36" r="22" fill="#D9412B"/><path d="M22 16c4 2 7 2 10 0 3 2 6 2 10 0-2 4-6 6-10 6s-8-2-10-6z" fill="#3E8E41"/><path d="M32 10v8" stroke="#3E8E41" stroke-width="3" stroke-linecap="round"/></svg>';
const _onion = '<svg viewBox="0 0 64 64"><path d="M32 8c3 8 18 14 18 30a18 18 0 0 1-36 0C14 22 29 16 32 8z" fill="#A8466F"/><path d="M32 22v30" stroke="#E7B8CB" stroke-width="2"/><path d="M26 54l-2 6M32 56v6M38 54l2 6" stroke="#8C6A4A" stroke-width="2" stroke-linecap="round"/></svg>';
const _potato = '<svg viewBox="0 0 64 64"><ellipse cx="32" cy="34" rx="24" ry="17" fill="#B98A52"/><circle cx="22" cy="30" r="2" fill="#7A5A30"/><circle cx="38" cy="38" r="2" fill="#7A5A30"/><circle cx="42" cy="27" r="1.6" fill="#7A5A30"/></svg>';
const _mango = '<svg viewBox="0 0 64 64"><path d="M20 22c8-10 30-6 30 14 0 14-14 20-24 16S10 34 20 22z" fill="#F2A33A"/><path d="M40 14c4-4 8-4 12-2-2 4-6 6-12 2z" fill="#3E8E41"/><path d="M38 18l2-6" stroke="#6B4A2A" stroke-width="2.5" stroke-linecap="round"/></svg>';
const _banana = '<svg viewBox="0 0 64 64"><path d="M12 22c4 22 26 32 42 22-14 2-30-6-34-24z" fill="#F2D23A" stroke="#C9A81E" stroke-width="2" stroke-linejoin="round"/><path d="M12 22l-2-6" stroke="#6B4A2A" stroke-width="3" stroke-linecap="round"/></svg>';
const _chilli = '<svg viewBox="0 0 64 64"><path d="M18 16c2 18 10 32 30 38-12-10-18-22-20-38z" fill="#3E9B3A"/><path d="M18 16c2-4 6-6 10 0" stroke="#2C6E2A" stroke-width="3" fill="none" stroke-linecap="round"/></svg>';
const _cauliflower = '<svg viewBox="0 0 64 64"><path d="M8 40c6-18 42-18 48 0-10 8-38 8-48 0z" fill="#5E9E4A"/><circle cx="24" cy="32" r="8" fill="#F3EBD3"/><circle cx="34" cy="28" r="9" fill="#F3EBD3"/><circle cx="42" cy="34" r="7" fill="#F3EBD3"/></svg>';
const _grapes = '<svg viewBox="0 0 64 64"><circle cx="24" cy="22" r="7" fill="#6A3E8E"/><circle cx="38" cy="22" r="7" fill="#6A3E8E"/><circle cx="31" cy="33" r="7" fill="#7D4FA3"/><circle cx="20" cy="34" r="6" fill="#6A3E8E"/><circle cx="42" cy="34" r="6" fill="#6A3E8E"/><circle cx="31" cy="45" r="7" fill="#6A3E8E"/><path d="M31 15V8" stroke="#6B4A2A" stroke-width="3" stroke-linecap="round"/></svg>';
const _leaf = '<svg viewBox="0 0 64 64"><path d="M32 56V26" stroke="#2C6E2A" stroke-width="3" stroke-linecap="round"/><path d="M32 26c0-12 8-18 20-18 0 12-8 18-20 18z" fill="#3E9B3A"/><path d="M32 36c0-9-6-14-16-14 0 9 6 14 16 14z" fill="#5E9E4A"/></svg>';

const List<CropOption> cropOptions = [
  CropOption('tomato', 'Tomato', 'crop_tomato', _tomato, Color(0xFFF6E1DC)),
  CropOption('onion', 'Onion', 'crop_onion', _onion, Color(0xFFF1E1EA)),
  CropOption('potato', 'Potato', 'crop_potato', _potato, Color(0xFFF1E8DA)),
  CropOption('mango', 'Mango', 'crop_mango', _mango, Color(0xFFFBEBD3)),
  CropOption('banana', 'Banana', 'crop_banana', _banana, Color(0xFFFBF3D0)),
  CropOption('chilli', 'Green Chilli', 'crop_chilli', _chilli, Color(0xFFE3EFE0)),
  CropOption('cauliflower', 'Cauliflower', 'crop_cauliflower', _cauliflower, Color(0xFFEDF2E6)),
  CropOption('grapes', 'Grapes', 'crop_grapes', _grapes, Color(0xFFECE3F2)),
];

/// The picture for any crop name the backend returns; a leaf for crops not in the list.
CropOption? cropOptionFor(String cropName) {
  final n = cropName.trim().toLowerCase();
  for (final c in cropOptions) {
    if (c.apiName.toLowerCase() == n || c.id == n || (c.id == 'chilli' && n.contains('chil'))) return c;
  }
  return null;
}

/// Crop name in the app language when known, otherwise as the seller typed it.
String localCropName(LocalizationService loc, String apiName) {
  final c = cropOptionFor(apiName);
  return c == null ? apiName : loc.t(c.labelKey);
}

class CropPicture extends StatelessWidget {
  final String cropName;
  final double size;
  const CropPicture({super.key, required this.cropName, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final c = cropOptionFor(cropName);
    return SvgPicture.string(c?.svg ?? _leaf, width: size, height: size, excludeFromSemantics: true);
  }
}
