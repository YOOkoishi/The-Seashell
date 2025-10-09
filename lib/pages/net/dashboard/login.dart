import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '/services/provider.dart';

class NetLoginDialog extends StatefulWidget {
  const NetLoginDialog({super.key, required this.serviceType});

  final NetServiceType serviceType;

  @override
  State<NetLoginDialog> createState() => _NetLoginDialogState();
}

class _NetLoginDialogState extends State<NetLoginDialog> {
  final ServiceProvider _serviceProvider = ServiceProvider.instance;

  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _extraCodeController;

  bool _isLoading = false;
  String? _errorMessage;

  bool _isNeedExtraCode = false;
  bool _isLoadingExtraCodeImage = false;
  Uint8List? _extraCodeImage;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _extraCodeController = TextEditingController();
    _refreshRequirement();
  }

  Future<void> _refreshRequirement() async {
    if (_serviceProvider.currentNetServiceType != widget.serviceType) {
      _serviceProvider.switchNetService(widget.serviceType);
    }
    try {
      final needExtraCodeNew =
          (await _serviceProvider.netService.getLoginRequirements())
              .isNeedExtraCode;
      if (mounted) {
        setState(() {
          _isNeedExtraCode = needExtraCodeNew;
        });
        if (needExtraCodeNew) {
          await _loadExtraCodeImage();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadExtraCodeImage() async {
    if (_isLoadingExtraCodeImage) return;

    setState(() {
      _isLoadingExtraCodeImage = true;
    });

    try {
      final image = await _serviceProvider.netService.getCodeImage();

      if (mounted) {
        setState(() {
          _extraCodeImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingExtraCodeImage = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _extraCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Switch to the appropriate service type
    final targetType = widget.serviceType;
    if (_serviceProvider.currentNetServiceType != targetType) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        _serviceProvider.switchNetService(targetType);
        await _refreshRequirement();
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _serviceProvider.loginToNetService(
        _usernameController.text.trim(),
        _passwordController.text,
        extraCode: _extraCodeController.text.trim().isEmpty
            ? null
            : _extraCodeController.text.trim(),
      );

      // Login succeeded
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // Login failed
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
        _refreshRequirement();
        if (_isNeedExtraCode) {
          await _loadExtraCodeImage();
        }
        _extraCodeController.text = '';
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    bool isLoginAllowed() {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      return widget.serviceType == NetServiceType.mock ||
          username.isNotEmpty && password.isNotEmpty;
    }

    return AlertDialog(
      title: const Text('校园网登录'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('请输入校园网的账号和密码。', style: theme.textTheme.bodySmall),
            if (widget.serviceType == NetServiceType.mock) ...[
              const SizedBox(height: 8),
              Text(
                '您正在使用 Mock 环境进行离线测试。'
                '\n'
                '您无需输入账号和密码。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
                hintText: '学工号',
              ),
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {
                // Trigger rebuild for login button state
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: '密码'),
              obscureText: true,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {
                // Trigger rebuild for login button state
              }),
            ),
            if (_isNeedExtraCode) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _extraCodeController,
                          decoration: const InputDecoration(labelText: '验证码'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_isLoadingExtraCodeImage)
                        const SizedBox(
                          height: 48,
                          width: 128,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_extraCodeImage != null)
                        InkWell(
                          onTap: _loadExtraCodeImage,
                          child: Image.memory(
                            _extraCodeImage!,
                            height: 48,
                            width: 128,
                            fit: BoxFit.contain,
                          ),
                        )
                      else
                        SizedBox(
                          height: 48,
                          width: 128,
                          child: Center(
                            child: TextButton(
                              onPressed: _loadExtraCodeImage,
                              child: const Text('加载验证码'),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text('点击验证码可刷新', style: theme.textTheme.bodySmall),
                ],
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: (_isLoading || !isLoginAllowed()) ? null : _handleLogin,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('登录'),
        ),
      ],
    );
  }
}
