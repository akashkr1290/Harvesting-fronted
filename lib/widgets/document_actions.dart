import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

/// A button that fetches a PDF from the backend and hands it to the
/// device's native share sheet — the user then picks WhatsApp, email, or
/// anything else installed. This is deliberately not a WhatsApp/email API
/// integration: the SOW itself describes WhatsApp sharing as a "download
/// and send" approach, and this applies the same idea to email so no SMTP
/// credentials are needed. If automatic server-sent email is wanted later,
/// that's a separate addition once mail server credentials exist.
class DocumentDownloadButton extends StatefulWidget {
  final ApiClient apiClient;
  final String documentPath;
  final String fileName;
  final String label;
  final IconData icon;

  const DocumentDownloadButton({
    super.key,
    required this.apiClient,
    required this.documentPath,
    required this.fileName,
    this.label = 'Download / Share PDF',
    this.icon = Icons.picture_as_pdf_outlined,
  });

  @override
  State<DocumentDownloadButton> createState() => _DocumentDownloadButtonState();
}

class _DocumentDownloadButtonState extends State<DocumentDownloadButton> {
  bool _loading = false;

  Future<void> _download() async {
    setState(() => _loading = true);
    try {
      final bytes = await widget.apiClient.getBytes(widget.documentPath);
      if (!mounted) return;
      final file = XFile.fromData(
        Uint8List.fromList(bytes),
        name: widget.fileName,
        mimeType: 'application/pdf',
      );
      await Share.shareXFiles([file], text: widget.fileName);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: e.isConflict ? AppTheme.danger : null,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reach the server. Check your connection and try again.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : _download,
      icon: _loading
          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(widget.icon),
      label: Text(_loading ? 'Preparing...' : widget.label),
    );
  }
}
