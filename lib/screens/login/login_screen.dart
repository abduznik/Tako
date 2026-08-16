import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/session.dart';
import '../../providers/provider_exceptions.dart';
import '../dashboard/dashboard_screen.dart';

/// Generic "Add Provider" login screen. Kanboard is the only provider today,
/// but the flow (URL/username/password/remember-me, verify-before-save) is
/// written to generalize to future providers.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Kanboard');
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isConnecting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Fills in the parts users commonly omit: a scheme (defaults to https)
  /// and the `/jsonrpc.php` endpoint path, so "kanboard.example.com" and
  /// "kanboard.example.com/" both resolve to a working API URL.
  static String normalizeKanboardUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) return url;

    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(url)) {
      url = 'https://$url';
    }

    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    if (!uri.path.endsWith('jsonrpc.php')) {
      final newPath = uri.path.endsWith('/')
          ? '${uri.path}jsonrpc.php'
          : '${uri.path}/jsonrpc.php';
      return uri.replace(path: newPath).toString();
    }
    return uri.toString();
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Server URL is required';
    }
    final uri = Uri.tryParse(normalizeKanboardUrl(value));
    if (uri == null || !uri.isAbsolute || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return 'Enter a valid URL, e.g. kanboard.example.com';
    }
    return null;
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      await context.read<Session>().connectToKanboard(
            name: _nameController.text.trim(),
            baseUrl: normalizeKanboardUrl(_urlController.text),
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            rememberMe: _rememberMe,
          );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } on ProviderAuthException catch (e) {
      setState(() => _errorMessage = 'Authentication failed: $e');
    } on ProviderConnectionException catch (e) {
      setState(() => _errorMessage = "Couldn't reach server: $e");
    } catch (e) {
      setState(() => _errorMessage = 'Connection failed: $e');
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect to Kanboard')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Profile name',
                      helperText: 'A label to identify this connection',
                    ),
                    validator: (v) => _validateRequired(v, 'Profile name'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'kanboard.example.com',
                      helperText: 'https:// and /jsonrpc.php are added automatically if omitted',
                    ),
                    keyboardType: TextInputType.url,
                    validator: _validateUrl,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (v) => _validateRequired(v, 'Username'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (v) => _validateRequired(v, 'Password'),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _rememberMe,
                    onChanged: (v) => setState(() => _rememberMe = v ?? true),
                    title: const Text('Remember me'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isConnecting ? null : _submit,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: _isConnecting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Connect'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
