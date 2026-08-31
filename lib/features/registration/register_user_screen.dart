import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/language_selector_widget.dart';
import '../../services/localization_service.dart';
import 'registration_api.dart';

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});
  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController(),
      _password = TextEditingController(),
      _name = TextEditingController(),
      _email = TextEditingController(),
      _mobile = TextEditingController(),
      _mobileOtp = TextEditingController(),
      _aadhaar = TextEditingController(),
      _aadhaarOtp = TextEditingController(),
      _address = TextEditingController(),
      _city = TextEditingController(),
      _district = TextEditingController(),
      _state = TextEditingController(text: 'Bihar'),
      _pin = TextEditingController();

  final Map<String, XFile> _docs = {};
  String? _token, _role;
  int _step = 0;
  bool _busy = false, _mobileVerified = false, _aadhaarVerified = false, _addressSaved = false;
  final _picker = ImagePicker();

  @override
  void dispose() {
    for (final c in [
      _username,
      _password,
      _name,
      _email,
      _mobile,
      _mobileOtp,
      _aadhaar,
      _aadhaarOtp,
      _address,
      _city,
      _district,
      _state,
      _pin
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  RegistrationApi get api => RegistrationApi(context.read<ApiClient>());

  Future<void> _run(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    final loc = context.read<LocalizationService>();
    try {
      await fn();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.t('server_error')}: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    await _run(() async {
      final r = await api.start(
          username: _username.text.trim(),
          password: _password.text,
          fullName: _name.text.trim(),
          email: _email.text.trim());
      _token = r['registrationToken'] as String;
      setState(() => _step = 1);
    });
  }

  Future<void> _sendMobile() async {
    await _run(() async {
      await api.sendMobile(_token!, _mobile.text.trim());
    });
  }

  Future<void> _verifyMobile() async {
    await _run(() async {
      await api.verifyMobile(_token!, _mobileOtp.text.trim());
      setState(() => _mobileVerified = true);
    });
  }

  Future<void> _sendAadhaar() async {
    await _run(() async {
      await api.sendAadhaar(_token!, _aadhaar.text.replaceAll(' ', '').trim());
    });
  }

  Future<void> _verifyAadhaar() async {
    await _run(() async {
      await api.verifyAadhaar(_token!, _aadhaarOtp.text.trim());
      setState(() => _aadhaarVerified = true);
    });
  }

  Future<void> _saveRole() async {
    if (_role == null) return;
    await _run(() async {
      await api.role(_token!, _role!);
      setState(() => _step = 4);
    });
  }

  Future<void> _saveAddress() async {
    await _run(() async {
      await api.address(_token!, {
        'addressLine': _address.text.trim(),
        'villageOrCity': _city.text.trim(),
        'district': _district.text.trim(),
        'state': _state.text.trim(),
        'pincode': _pin.text.trim()
      });
      setState(() {
        _addressSaved = true;
        _step = 5;
      });
    });
  }

  Future<void> _pick(String type) async {
    final x = await _picker.pickImage(
        source: type == 'photo' || type == 'signature' ? ImageSource.gallery : ImageSource.camera,
        maxWidth: 1800);
    if (x != null) setState(() => _docs[type] = x);
  }

  Future<void> _uploadDocs() async {
    final loc = context.read<LocalizationService>();
    if (_docs.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('upload_all_docs'))),
      );
      return;
    }
    await _run(() async {
      for (final e in _docs.entries) {
        final bytes = await e.value.readAsBytes();
        await api.upload(_token!, e.key, bytes, e.value.name);
      }
      setState(() => _step = 6);
    });
  }

  Future<void> _submit() async {
    final loc = context.read<LocalizationService>();
    await _run(() async {
      await api.submit(_token!);
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: Text(loc.t('registration_complete')),
            content: Text(
                '${loc.t('username')}: ${_username.text}\n${loc.t('step_role')}: ${_roleLabel(_role!)}'),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text(loc.t('go_to_login')),
              )
            ],
          ),
        );
      }
    });
  }

  String _roleLabel(String r) {
    final loc = context.read<LocalizationService>();
    return {
          'FARMER': loc.t('role_farmer'),
          'FPO': loc.t('role_fpo'),
          'CONSUMER': loc.t('role_consumer'),
          'BULK_BUYER': loc.t('role_bulk_buyer'),
        }[r] ??
        r;
  }

  Widget _field(TextEditingController c, String label,
          {bool password = false, String? Function(String?)? validator}) {
    final loc = context.watch<LocalizationService>();
    return TextFormField(
      controller: c,
      obscureText: password,
      decoration: InputDecoration(labelText: label),
      validator: validator ?? (v) => v == null || v.trim().isEmpty ? loc.t('required') : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final titles = [
      loc.t('step_account'),
      loc.t('step_mobile_otp'),
      loc.t('step_aadhaar_otp'),
      loc.t('step_role'),
      loc.t('step_address'),
      loc.t('step_documents'),
      loc.t('step_review'),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('register_title')),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: LanguageSelectorWidget(isCompact: true),
          ),
        ],
      ),
      body: StepProgressIndicator(
        step: _step,
        titles: titles,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(child: _body(loc)),
        ),
      ),
    );
  }

  Widget _body(LocalizationService loc) {
    switch (_step) {
      case 0:
        return Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field(_name, loc.t('full_name')),
              const SizedBox(height: 12),
              _field(_email, loc.t('email')),
              const SizedBox(height: 12),
              _field(_username, loc.t('username')),
              const SizedBox(height: 12),
              _field(_password, loc.t('password'), password: true, validator: (v) {
                if (v == null || v.length < 8) return loc.t('min_8_chars');
                if (!RegExp(r'(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z0-9])').hasMatch(v)) {
                  return loc.t('password_complexity');
                }
                return null;
              }),
              const SizedBox(height: 24),
              _button(loc.t('continue_btn'), _start),
            ],
          ),
        );
      case 1:
        return Column(
          children: [
            _field(_mobile, loc.t('mobile_number'),
                validator: (v) =>
                    RegExp(r'^[6-9]\d{9}$').hasMatch(v ?? '') ? null : loc.t('enter_valid_mobile')),
            const SizedBox(height: 12),
            _button(loc.t('send_otp'), _sendMobile),
            const SizedBox(height: 12),
            if (_mobileVerified) ...[
              Text('${loc.t('step_mobile_otp')} ${loc.t('otp_verified')}'),
              const SizedBox(height: 12),
              _button(loc.t('continue_btn'), () => setState(() => _step = 2)),
            ] else ...[
              _field(_mobileOtp, loc.t('enter_6_digit_otp')),
              const SizedBox(height: 12),
              _button(loc.t('verify_otp'), _verifyMobile),
            ],
          ],
        );
      case 2:
        return Column(
          children: [
            _field(_aadhaar, loc.t('aadhaar_number'),
                validator: (v) => RegExp(r'^\d{12}$').hasMatch((v ?? '').replaceAll(' ', ''))
                    ? null
                    : loc.t('enter_valid_aadhaar')),
            const SizedBox(height: 12),
            _button(loc.t('send_aadhaar_otp'), _sendAadhaar),
            const SizedBox(height: 12),
            if (_aadhaarVerified) ...[
              Text('${loc.t('step_aadhaar_otp')} ${loc.t('otp_verified')}'),
              const SizedBox(height: 12),
              _button(loc.t('continue_btn'), () => setState(() => _step = 3)),
            ] else ...[
              _field(_aadhaarOtp, loc.t('enter_6_digit_otp')),
              const SizedBox(height: 12),
              _button(loc.t('verify_otp'), _verifyAadhaar),
            ],
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(loc.t('select_role'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            for (final r in ['FARMER', 'FPO', 'CONSUMER', 'BULK_BUYER'])
              RadioListTile<String>(
                value: r,
                groupValue: _role,
                onChanged: (v) => setState(() => _role = v),
                title: Text(_roleLabel(r)),
              ),
            const SizedBox(height: 12),
            _button(loc.t('continue_btn'), _saveRole),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(_address, loc.t('address_line')),
            _field(_city, loc.t('village_city')),
            _field(_district, loc.t('district')),
            _field(_state, loc.t('state')),
            _field(_pin, loc.t('pincode'),
                validator: (v) =>
                    RegExp(r'^\d{6}$').hasMatch(v ?? '') ? null : loc.t('enter_valid_pincode')),
            const SizedBox(height: 20),
            _button(loc.t('continue_btn'), _saveAddress),
          ],
        );
      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _doc(loc, 'khet-receipt', loc.t('upload_khet_receipt')),
            _doc(loc, 'signature', loc.t('upload_signature')),
            _doc(loc, 'photo', loc.t('upload_photo')),
            const SizedBox(height: 20),
            _button(loc.t('upload_and_continue'), _uploadDocs),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _summary(loc.t('username'), _username.text),
            _summary(loc.t('mobile_number'), _mask(_mobile.text)),
            _summary(loc.t('aadhaar_number'), _maskAadhaar(_aadhaar.text)),
            _summary(loc.t('step_role'), _roleLabel(_role!)),
            _summary(loc.t('step_address'),
                '${_address.text}, ${_city.text}, ${_district.text}, ${_state.text} - ${_pin.text}'),
            _summary(loc.t('step_documents'), '${_docs.length}/3 ${loc.t('uploaded')}'),
            const SizedBox(height: 24),
            _button(loc.t('submit_registration'), _submit),
          ],
        );
    }
  }

  Widget _doc(LocalizationService loc, String type, String label) => Card(
        child: ListTile(
          title: Text(label),
          subtitle: Text(_docs[type]?.name ?? loc.t('not_uploaded')),
          trailing: IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _pick(type),
          ),
        ),
      );

  Widget _summary(String k, String v) =>
      ListTile(title: Text(k, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(v));

  String _mask(String s) =>
      s.length < 4 ? 'XXXXXXXXXX' : 'XXXXXX${s.substring(s.length - 4)}';
  String _maskAadhaar(String s) {
    final x = s.replaceAll(' ', '');
    return x.length < 4 ? 'XXXX-XXXX-XXXX' : 'XXXX-XXXX-${x.substring(x.length - 4)}';
  }

  Widget _button(String text, VoidCallback fn) => ElevatedButton(
        onPressed: _busy ? null : fn,
        child: _busy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(text),
      );
}

class StepProgressIndicator extends StatelessWidget {
  final int step;
  final List<String> titles;
  final Widget child;
  const StepProgressIndicator(
      {super.key, required this.step, required this.titles, required this.child});
  @override
  Widget build(BuildContext context) => Column(
        children: [
          LinearProgressIndicator(value: (step + 1) / titles.length, minHeight: 4),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${step + 1}. ${titles[step]}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(child: child),
        ],
      );
}
