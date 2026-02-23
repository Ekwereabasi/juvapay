import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/wallet_service.dart';
import '../../../view_models/wallet_view_model.dart';

class WalletTransferView extends StatefulWidget {
  const WalletTransferView({super.key});

  @override
  State<WalletTransferView> createState() => _WalletTransferViewState();
}

class _WalletTransferViewState extends State<WalletTransferView> {
  final WalletService _walletService = WalletService();

  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController(
    text: 'Wallet transfer',
  );

  bool _isSubmitting = false;
  Map<String, dynamic>? _resolvedRecipient;

  @override
  void initState() {
    super.initState();
    _recipientController.addListener(() {
      if (_resolvedRecipient != null) {
        setState(() {
          _resolvedRecipient = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<Map<String, dynamic>?> _resolveRecipient() async {
    final recipientInput = _recipientController.text.trim();
    if (recipientInput.isEmpty) {
      _showMessage('Enter recipient username or user ID', isError: true);
      return null;
    }

    final recipient = await _walletService.resolveTransferRecipient(
      recipientInput,
    );

    if (recipient == null) {
      _showMessage(
        'Recipient not found. Enter a valid @username or user ID.',
        isError: true,
      );
      return null;
    }

    if (recipient['isSelf'] == true) {
      _showMessage('You cannot transfer to your own wallet.', isError: true);
      return null;
    }

    if (mounted) {
      setState(() {
        _resolvedRecipient = recipient;
      });
    }

    return recipient;
  }

  Future<void> _submitTransfer() async {
    final walletViewModel = context.read<WalletViewModel>();
    final amount = double.tryParse(_amountController.text.trim());
    final description =
        _noteController.text.trim().isEmpty
            ? 'Wallet transfer'
            : _noteController.text.trim();

    if (amount == null || amount <= 0) {
      _showMessage('Enter a valid transfer amount.', isError: true);
      return;
    }

    if (amount > 100000) {
      _showMessage('Maximum transfer amount is ₦100,000.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final balanceCheck = await walletViewModel.checkBalance(amount);
      if (balanceCheck['hasSufficientBalance'] != true) {
        _showMessage(
          'Insufficient balance. Available: ₦${(balanceCheck['availableBalance'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
          isError: true,
        );
        return;
      }

      final recipient = _resolvedRecipient ?? await _resolveRecipient();
      if (recipient == null) return;

      final result = await walletViewModel.transferBetweenWallets(
        destinationUserId: recipient['userId'].toString(),
        amount: amount,
        description: description,
      );

      if (result['success'] == true) {
        await walletViewModel.refreshWalletData();

        _showMessage(
          'Transfer successful. Ref: ${result['transferReference'] ?? 'N/A'}',
        );

        if (mounted) {
          setState(() {
            _amountController.clear();
            _resolvedRecipient = null;
          });
        }
      } else {
        _showMessage(
          result['message']?.toString() ?? 'Transfer failed',
          isError: true,
        );
      }
    } catch (e) {
      _showMessage('Transfer failed: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletViewModel = context.watch<WalletViewModel>();
    final fallbackAvailableBalance =
        walletViewModel.wallet?.availableBalance ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet Transfer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<Wallet>(
              stream: _walletService.watchWallet(),
              builder: (context, snapshot) {
                final availableBalance =
                    snapshot.data?.availableBalance ?? fallbackAvailableBalance;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Balance',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₦${availableBalance.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _recipientController,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                labelText: 'Recipient (@username or user ID)',
                prefixIcon: const Icon(Icons.person_search_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  onPressed: _isSubmitting ? null : _resolveRecipient,
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: 'Validate recipient',
                ),
              ),
            ),
            if (_resolvedRecipient != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Recipient: ${_resolvedRecipient!['fullName'] ?? 'User'} '
                  '(@${_resolvedRecipient!['username'] ?? 'unknown'})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              enabled: !_isSubmitting,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₦ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              enabled: !_isSubmitting,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Fee: 1% (min ₦10, max ₦1,000). Maximum transfer per transaction: ₦100,000.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitTransfer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Send Transfer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
