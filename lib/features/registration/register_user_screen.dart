import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../services/localization_service.dart';
import '../../services/voice_service.dart';
import '../../widgets/simple/simple_ui.dart';
import 'registration_api.dart';

/// Registration made for people who do not read or type much:
/// 1 name + mobile + 6-digit PIN, 2 OTP, 3 "I am a…" picture cards,
/// 4 village/district/state/PIN code, 5 photos (farmer/FPO only), 6 bank (farmer only).
/// No email, no username, no Aadhaar needed; users log in with their mobile number.
class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

enum _Step { basics, otp, role, address, documents, bank }

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();
  final _otp = TextEditingController();
  final _village = TextEditingController();
  final _district = TextEditingController();
  final _pincode = TextEditingController();
  final _holder = TextEditingController();
  final _account = TextEditingController();
  final _ifsc = TextEditingController();
  final _bank = TextEditingController();
  String _state = 'Maharashtra';
  String? _role;
  String? _token;
  _Step _step = _Step.basics;
  bool _busy = false;
  final Map<String, Uint8List> _docs = {};
  final Map<String, String> _docNames = {};
  final _picker = ImagePicker();

  static const _states = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh', 'Goa', 'Gujarat', 'Haryana',
    'Himachal Pradesh', 'Jharkhand', 'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
    'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana',
    'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal', 'Andaman and Nicobar Islands', 'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu', 'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Lakshadweep', 'Puducherry',
  ];

  @override
  void dispose() {
    for (final c in [_name, _mobile, _pin, _pin2, _otp, _village, _district, _pincode, _holder, _account, _ifsc, _bank]) {
      c.dispose();
    }
    super.dispose();
  }

  RegistrationApi get _api => RegistrationApi(context.read<ApiClient>());
  LocalizationService get _loc => context.read<LocalizationService>();

  List<_Step> get _flow => [
        _Step.basics,
        _Step.otp,
        _Step.role,
        _Step.address,
        if (_role == 'FARMER' || _role == 'FPO') _Step.documents,
        if (_role == 'FARMER') _Step.bank,
      ];

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m, style: const TextStyle(fontSize: 17))));

  Future<void> _run(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
    } on ApiException catch (e) {
      if (mounted) _toast(e.details.isNotEmpty ? '${e.message} ${e.details.join(', ')}' : e.message);
    } catch (_) {
      if (mounted) _toast(_loc.t('no_internet'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------- step actions
  Future<void> _submitBasics() async {
    if (_name.text.trim().isEmpty) return _toast(_loc.t('field_required'));
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(_mobile.text.trim())) return _toast(_loc.t('invalid_mobile'));
    if (!RegExp(r'^\d{6}$').hasMatch(_pin.text)) return _toast(_loc.t('choose_pin'));
    if (_pin.text != _pin2.text) return _toast(_loc.t('pin_mismatch'));
    await _run(() async {
      _token ??= (await _api.start(username: '', password: _pin.text, fullName: _name.text.trim(), email: ''))['registrationToken']
          as String;
      await _api.sendMobile(_token!, _mobile.text.trim());
      setState(() => _step = _Step.otp);
    });
  }

  Future<void> _verifyOtp() async {
    if (_otp.text.trim().length != 6) return _toast(_loc.t('enter_otp'));
    await _run(() async {
      await _api.verifyMobile(_token!, _otp.text.trim());
      setState(() => _step = _Step.role);
    });
  }

  Future<void> _chooseRole(String role) async {
    await _run(() async {
      await _api.role(_token!, role);
      setState(() {
        _role = role;
        _step = _Step.address;
      });
    });
  }

  Future<void> _submitAddress() async {
    if (_village.text.trim().isEmpty || _district.text.trim().isEmpty) return _toast(_loc.t('field_required'));
    if (!RegExp(r'^\d{6}$').hasMatch(_pincode.text.trim())) return _toast(_loc.t('pincode'));
    await _run(() async {
      await _api.address(_token!, {
        'addressLine': '',
        'villageOrCity': _village.text.trim(),
        'district': _district.text.trim(),
        'state': _state,
        'pincode': _pincode.text.trim(),
      });
      if (_flow.contains(_Step.documents)) {
        setState(() => _step = _Step.documents);
      } else {
        await _finish();
      }
    });
  }

  Future<void> _pick(String type, ImageSource source) async {
    try {
      final x = await _picker.pickImage(source: source, maxWidth: 1800, imageQuality: 85);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      setState(() {
        _docs[type] = bytes;
        _docNames[type] = x.name.isEmpty ? '$type.jpg' : x.name;
      });
    } catch (_) {}
  }

  Future<void> _submitDocuments() async {
    final needed = _role == 'FARMER' ? ['photo', 'khet-receipt'] : ['photo'];
    if (needed.any((t) => !_docs.containsKey(t))) return _toast(_loc.t('field_required'));
    await _run(() async {
      for (final e in _docs.entries) {
        await _api.upload(_token!, e.key, e.value, _docNames[e.key] ?? '${e.key}.jpg');
      }
      if (_role == 'FARMER') {
        setState(() => _step = _Step.bank);
      } else {
        await _finish();
      }
    });
  }

  Future<void> _submitBank() async {
    if ([_holder, _account, _ifsc, _bank].any((c) => c.text.trim().isEmpty)) return _toast(_loc.t('field_required'));
    await _run(() async {
      await _api.bankDetails(_token!, _holder.text.trim(), _account.text.replaceAll(' ', ''), _ifsc.text.trim().toUpperCase(),
          _bank.text.trim());
      await _finish();
    });
  }

  Future<void> _finish() async {
    await _api.submit(_token!);
    if (!mounted) return;
    final loc = _loc;
    context.read<VoiceService>().speak(loc.t('account_ready'), language: loc.ttsLanguage);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_rounded, size: 72, color: SimpleColors.green),
          const SizedBox(height: 12),
          Text(loc.t('account_ready'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(_mobile.text.trim(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 16),
          BigButton(label: loc.t('login_btn'), onPressed: () => Navigator.of(ctx).pop()),
        ]),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  void _back() {
    final i = _flow.indexOf(_step);
    // OTP cannot be "un-verified", so going back stops at the role step.
    if (i <= 0 || _step == _Step.role) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _step = _flow[i - 1]);
    }
  }

  Future<void> _voiceInto(TextEditingController c, {bool digitsOnly = false}) async {
    final heard = await context.read<VoiceService>().listen(localeId: _loc.speechLocaleId);
    if (heard == null || !mounted) return;
    setState(() {
      if (digitsOnly) {
        const dev = '०१२३४५६७८९';
        final cleaned = heard.split('').map((ch) => dev.contains(ch) ? dev.indexOf(ch).toString() : ch).join();
        c.text = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
      } else {
        c.text = heard;
      }
    });
  }

  // ---------------------------------------------------------------- UI
  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final flow = _flow;
    final index = flow.indexOf(_step);
    final (String title, List<Widget> body, String action, VoidCallback? onAction) = switch (_step) {
      _Step.basics => (loc.t('reg_title'), _basics(loc), loc.t('send_otp'), _submitBasics),
      _Step.otp => (loc.t('enter_otp'), _otpStep(loc), loc.t('verify'), _verifyOtp),
      _Step.role => (loc.t('i_am'), _roleStep(loc), '', null),
      _Step.address => (loc.t('village'), _addressStep(loc), loc.t('next'), _submitAddress),
      _Step.documents => (loc.t('photo_of_you'), _documentsStep(loc), loc.t('next'), _submitDocuments),
      _Step.bank => (loc.t('bank_account'), _bankStep(loc), loc.t('create_account'), _submitBank),
    };

    return PopScope(
      canPop: _step == _Step.basics && !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy) _back();
      },
      child: SimplePage(
        header: Column(children: [
          SimpleHeader(title: title, speakText: () => title),
          Padding(padding: const EdgeInsets.only(top: 4), child: StepDots(current: index < 0 ? 0 : index, total: flow.length)),
        ]),
        children: body,
        bottom: [
          if (onAction != null) BigButton(label: action, onPressed: onAction, busy: _busy, icon: Icons.arrow_forward_rounded),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? type, bool obscure = false, int? maxLength, IconData? icon, bool voice = false, bool digits = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        keyboardType: type,
        obscureText: obscure,
        maxLength: maxLength,
        inputFormatters: digits ? [FilteringTextInputFormatter.digitsOnly] : null,
        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, letterSpacing: obscure ? 6 : 0),
        decoration: InputDecoration(
          labelText: label,
          counterText: '',
          prefixIcon: icon == null ? null : Icon(icon, size: 26),
          suffixIcon: voice
              ? IconButton(
                  iconSize: 28,
                  icon: const Icon(Icons.mic_rounded, color: SimpleColors.green),
                  onPressed: () => _voiceInto(c, digitsOnly: digits),
                )
              : null,
        ),
      ),
    );
  }

  List<Widget> _basics(LocalizationService loc) => [
        _field(_name, loc.t('your_name'), icon: Icons.person_rounded, voice: true),
        _field(_mobile, loc.t('mobile_or_username'),
            type: TextInputType.phone, maxLength: 10, icon: Icons.phone_android_rounded, voice: true, digits: true),
        _field(_pin, loc.t('choose_pin'), type: TextInputType.number, obscure: true, maxLength: 6, icon: Icons.lock_rounded, digits: true),
        _field(_pin2, loc.t('pin_again'), type: TextInputType.number, obscure: true, maxLength: 6, icon: Icons.lock_rounded, digits: true),
      ];

  List<Widget> _otpStep(LocalizationService loc) => [
        Text('${loc.t('enter_otp')}: ${_mobile.text}', style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 12),
        TextField(
          controller: _otp,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: 12),
          decoration: const InputDecoration(counterText: ''),
        ),
        TextButton(
          onPressed: _busy ? null : () => _run(() => _api.sendMobile(_token!, _mobile.text.trim())),
          child: Text(loc.t('send_otp'), style: const TextStyle(fontSize: 17)),
        ),
      ];

  List<Widget> _roleStep(LocalizationService loc) {
    Widget card(String role, IconData icon, String label) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BigActionTile(
            height: 110,
            icon: Icon(icon, size: 44, color: SimpleColors.green),
            title: label,
            onTap: _busy ? () {} : () => _chooseRole(role),
          ),
        );
    return [
      card('FARMER', Icons.agriculture_rounded, loc.t('role_farmer_s')),
      card('FPO', Icons.groups_rounded, loc.t('role_fpo_s')),
      card('CONSUMER', Icons.home_rounded, loc.t('role_consumer_s')),
      card('BULK_BUYER', Icons.store_rounded, loc.t('role_bulk_s')),
    ];
  }

  List<Widget> _addressStep(LocalizationService loc) => [
        _field(_village, loc.t('village'), icon: Icons.place_rounded, voice: true),
        _field(_district, loc.t('district'), icon: Icons.map_rounded, voice: true),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: DropdownButtonFormField<String>(
            initialValue: _state,
            isExpanded: true,
            style: const TextStyle(fontSize: 20, color: SimpleColors.ink),
            decoration: InputDecoration(labelText: loc.t('state')),
            items: [for (final s in _states) DropdownMenuItem(value: s, child: Text(s))],
            onChanged: (v) => setState(() => _state = v ?? _state),
          ),
        ),
        _field(_pincode, loc.t('pincode'), type: TextInputType.number, maxLength: 6, icon: Icons.pin_drop_rounded, voice: true, digits: true),
      ];

  List<Widget> _documentsStep(LocalizationService loc) {
    Widget doc(String type, String label, IconData icon) {
      final has = _docs.containsKey(type);
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: has ? SimpleColors.green : SimpleColors.line, width: has ? 3 : 2),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(has ? Icons.check_circle_rounded : icon, size: 36, color: has ? SimpleColors.green : SimpleColors.quiet),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
          ]),
          if (has) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(_docs[type]!, height: 140, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: BigButton(
                label: loc.t('take_photo'),
                icon: Icons.photo_camera_rounded,
                outlined: has,
                onPressed: () => _pick(type, ImageSource.camera),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              iconSize: 30,
              tooltip: loc.t('from_gallery'),
              onPressed: () => _pick(type, ImageSource.gallery),
              icon: const Icon(Icons.photo_library_rounded),
            ),
          ]),
        ]),
      );
    }

    return [
      doc('photo', loc.t('photo_of_you'), Icons.face_rounded),
      if (_role == 'FARMER') doc('khet-receipt', loc.t('land_record'), Icons.description_rounded),
    ];
  }

  List<Widget> _bankStep(LocalizationService loc) => [
        _field(_holder, loc.t('bank_holder'), icon: Icons.person_rounded, voice: true),
        _field(_account, loc.t('bank_account'), type: TextInputType.number, maxLength: 18, icon: Icons.account_balance_rounded, digits: true),
        _field(_ifsc, loc.t('ifsc'), icon: Icons.qr_code_rounded),
        _field(_bank, loc.t('bank_name'), icon: Icons.account_balance_rounded, voice: true),
      ];
}
