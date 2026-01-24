// bank_account_screen.dart
import 'package:flutter/material.dart';
import 'package:juvapay/services/bank_service.dart';

class BankAccountScreen extends StatefulWidget {
  const BankAccountScreen({super.key});

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  final BankService _bankService = BankService();
  final TextEditingController _accountNumberController =
      TextEditingController();

  List<BankModel> _banks = [];
  BankModel? _selectedBank;
  UserBankDetails? _userBankDetails;
  bool _isLoading = true;
  bool _isLoadingBanks = false;
  bool _isVerifying = false;
  bool _isSaving = false;
  String? _verifiedAccountName;
  String? _verifiedBankName;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Fetch data in parallel
      final bankDetailsFuture = _bankService.getUserBankDetails();
      final banksFuture = _bankService.getBanks();

      // Wait for both to complete
      final bankDetails = await bankDetailsFuture;
      final banks = await banksFuture;

      setState(() {
        // Handle null bank details properly
        if (bankDetails != null) {
          _userBankDetails = bankDetails as UserBankDetails; // Explicit cast
        } else {
          _userBankDetails = null;
        }

        _banks = banks;
        _isLoading = false;
        _errorMessage = null;
      });

      // Pre-fill if user has existing bank details
      if (_userBankDetails != null) {
        _selectedBank = _banks.firstWhere(
          (bank) => bank.code == _userBankDetails!.bankCode,
          orElse:
              () => BankModel(
                name: _userBankDetails!.bankName,
                code: _userBankDetails!.bankCode,
              ),
        );
        _accountNumberController.text = _userBankDetails!.accountNumber;
        _verifiedAccountName = _userBankDetails!.accountName;
        _verifiedBankName = _userBankDetails!.bankName;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data. Please try again.';
      });
      _showSnackBar('Error loading data: $e', true);
    }
  }

  Future<void> _verifyAccount() async {
    if (_selectedBank == null) {
      _showSnackBar('Please select a bank', true);
      return;
    }

    if (_accountNumberController.text.isEmpty) {
      _showSnackBar('Please enter account number', true);
      return;
    }

    if (_accountNumberController.text.length != 10) {
      _showSnackBar('Account number must be 10 digits', true);
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final result = await _bankService.verifyAccountNumber(
        bankCode: _selectedBank!.code,
        accountNumber: _accountNumberController.text,
      );

      if (result['success'] == true) {
        setState(() {
          _verifiedAccountName = result['account_name'];
          _verifiedBankName = result['bank_name'];
        });
        _showSnackBar('Account verified successfully', false);
      } else {
        setState(() {
          _verifiedAccountName = null;
          _verifiedBankName = null;
          _errorMessage = result['message'];
        });
        _showSnackBar(result['message'], true);
      }
    } catch (e) {
      setState(() {
        _verifiedAccountName = null;
        _verifiedBankName = null;
        _errorMessage = 'Network error. Please check your connection.';
      });
      _showSnackBar('Verification failed: $e', true);
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _saveBankDetails() async {
    if (_selectedBank == null) {
      _showSnackBar('Please select a bank', true);
      return;
    }

    if (_accountNumberController.text.isEmpty) {
      _showSnackBar('Please enter account number', true);
      return;
    }

    if (_verifiedAccountName == null) {
      _showSnackBar('Please verify account number first', true);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final result = await _bankService.saveBankDetails(
        bankCode: _selectedBank!.code,
        bankName: _verifiedBankName ?? _selectedBank!.name,
        accountNumber: _accountNumberController.text,
        accountName: _verifiedAccountName!,
      );

      if (result['success'] == true) {
        _showSnackBar(result['message'], false);
        await _loadData(); // Reload data
        if (mounted) {
          Navigator.pop(context); // Go back after successful save
        }
      } else {
        setState(() => _errorMessage = result['message']);
        _showSnackBar(result['message'], true);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save. Please try again.');
      _showSnackBar('Failed to save bank details: $e', true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteBankDetails() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Bank Details'),
            content: const Text(
              'Are you sure you want to delete your bank details? You will need to re-enter them for withdrawals.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final result = await _bankService.deleteBankDetails();
                  if (result['success'] == true) {
                    _showSnackBar(result['message'], false);
                    setState(() {
                      _userBankDetails = null;
                      _selectedBank = null;
                      _accountNumberController.clear();
                      _verifiedAccountName = null;
                      _verifiedBankName = null;
                    });
                  } else {
                    _showSnackBar(result['message'], true);
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildBankDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<BankModel>(
                value: _selectedBank,
                isExpanded: true,
                hint: const Text('Select Bank'),
                icon: const Icon(Icons.arrow_drop_down),
                items:
                    _banks
                        .map(
                          (bank) => DropdownMenuItem(
                            value: bank,
                            child: Text(
                              bank.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (bank) {
                  setState(() {
                    _selectedBank = bank;
                    _verifiedAccountName = null;
                    _verifiedBankName = null;
                    _errorMessage = null;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Account'),
        centerTitle: true,
        actions: [
          if (_userBankDetails != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteBankDetails,
              tooltip: 'Delete Bank Details',
            ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: theme.primaryColor),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Bank Details Card
                    if (_userBankDetails != null) ...[
                      _buildBankDetailsCard(),
                      const SizedBox(height: 30),
                    ],

                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Bank Selection
                    const Text(
                      'Select Bank',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildBankDropdown(),

                    const SizedBox(height: 20),

                    // Account Number Input
                    const Text(
                      'Account Number',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _accountNumberController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      decoration: InputDecoration(
                        hintText: 'Enter 10-digit account number',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.account_balance_wallet),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _accountNumberController.clear();
                            setState(() {
                              _verifiedAccountName = null;
                              _verifiedBankName = null;
                            });
                          },
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          if (value.length != 10) {
                            _verifiedAccountName = null;
                            _verifiedBankName = null;
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _isVerifying ||
                                    _selectedBank == null ||
                                    _accountNumberController.text.length != 10
                                ? null
                                : _verifyAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child:
                            _isVerifying
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                                : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.verified_user, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'VERIFY ACCOUNT',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),

                    // Verified Account Info
                    if (_verifiedAccountName != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.verified,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Account Verified',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildVerifiedInfoRow(
                              'Bank',
                              _verifiedBankName ?? '',
                            ),
                            _buildVerifiedInfoRow(
                              'Account Name',
                              _verifiedAccountName!,
                            ),
                            _buildVerifiedInfoRow(
                              'Account Number',
                              '****${_accountNumberController.text.substring(6)}',
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 30),

                    // Save Button
                    if (_verifiedAccountName != null &&
                        _userBankDetails == null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveBankDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child:
                              _isSaving
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.save, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'SAVE BANK DETAILS',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }

  Widget _buildBankDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Current Bank Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Bank', _userBankDetails!.bankName),
            _buildDetailRow(
              'Account Number',
              _userBankDetails!.maskedAccountNumber,
            ),
            _buildDetailRow('Account Name', _userBankDetails!.accountName),
            _buildDetailRow(
              'Last Updated',
              '${_userBankDetails!.updatedAt.day}/${_userBankDetails!.updatedAt.month}/${_userBankDetails!.updatedAt.year}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
