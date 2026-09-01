import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'widgets/auth_constants.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_button.dart';
import 'notifiers/auth_notifier.dart';
import '../home_screen.dart';
import '../../core/providers/account_provider.dart';
import '../../core/models/user_account.dart';
import '../../core/services/auth_api_service.dart';
import 'package:uuid/uuid.dart';

class RegisterAccountTypeScreen extends StatefulWidget {
  const RegisterAccountTypeScreen({super.key});

  @override
  State<RegisterAccountTypeScreen> createState() =>
      _RegisterAccountTypeScreenState();
}

class _RegisterAccountTypeScreenState
    extends State<RegisterAccountTypeScreen> {
  int _step = 1; // 1, 2, or 3
  String _selectedType = 'personal'; // 'personal', 'business', 'child'

  // Validation errors (Personal)
  String? _firstNameError;
  String? _lastNameError;
  String? _usernameError;
  String? _dobError;
  String? _passwordError;
  String? _retypePasswordError;
  String? _personalPhoneError;

  // Validation errors (Business)
  String? _businessNameError;
  String? _customDomainError;
  String? _ownerFirstNameError;
  String? _ownerLastNameError;
  String? _adminUsernameError;
  String? _adminPasswordError;
  String? _retypeAdminPasswordError;
  String? _phoneError;

  // Validation errors (Child)
  String? _childFirstNameError;
  String? _childLastNameError;
  String? _childUsernameError;
  String? _childDobError;
  String? _childPasswordError;
  String? _childRetypePasswordError;
  String? _parentEmailError;
  String? _securityAnswerError;

  bool _isRegistering = false;
  String? _emailHandleError;

  // Username & Email Handle Suggestions State
  List<String> _usernameSuggestions = [];
  List<String> _emailHandleSuggestions = [];

  // Parent OTP State (Child)
  final _parentOtpController = TextEditingController();
  bool _isSendingParentOtp = false;
  bool _isVerifyingParentOtp = false;
  bool _parentOtpVerified = false;
  String? _parentOtpError;
  String? _parentOtpMessage;

  // Step 2 Controllers (Personal)
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _retypePasswordController = TextEditingController();
  final _personalPhoneController = TextEditingController();

  // Step 2 Controllers (Business)
  final _businessNameController = TextEditingController();
  final _customDomainController = TextEditingController();
  final _ownerFirstNameController = TextEditingController();
  final _ownerLastNameController = TextEditingController();
  final _adminUsernameController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _retypeAdminPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  // Step 2 Controllers (Child)
  final _childFirstNameController = TextEditingController();
  final _childLastNameController = TextEditingController();
  final _childUsernameController = TextEditingController();
  final _childDobController = TextEditingController();
  final _childPasswordController = TextEditingController();
  final _childRetypePasswordController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  String _securityQuestion = 'What is your favorite animal?';
  String _childGender = 'Male';
  String _personalGender = 'Male';

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  // Step 3 Controllers
  final _emailHandleController = TextEditingController();

  final List<String> _securityQuestions = [
    'What is your favorite animal?',
    'What is the name of your first pet?',
    'What is your favorite book?',
    'What is the name of your school?',
    'What is your favorite game?',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _retypePasswordController.dispose();
    _personalPhoneController.dispose();

    _businessNameController.dispose();
    _customDomainController.dispose();
    _ownerFirstNameController.dispose();
    _ownerLastNameController.dispose();
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    _retypeAdminPasswordController.dispose();
    _phoneController.dispose();

    _childFirstNameController.dispose();
    _childLastNameController.dispose();
    _childUsernameController.dispose();
    _childDobController.dispose();
    _childPasswordController.dispose();
    _childRetypePasswordController.dispose();
    _parentEmailController.dispose();
    _securityAnswerController.dispose();
    _parentOtpController.dispose();
    _emailHandleController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _firstNameError = null;
      _lastNameError = null;
      _usernameError = null;
      _dobError = null;
      _passwordError = null;
      _retypePasswordError = null;
      _personalPhoneError = null;

      _businessNameError = null;
      _customDomainError = null;
      _ownerFirstNameError = null;
      _ownerLastNameError = null;
      _adminUsernameError = null;
      _adminPasswordError = null;
      _retypeAdminPasswordError = null;
      _phoneError = null;

      _childFirstNameError = null;
      _childLastNameError = null;
      _childUsernameError = null;
      _childDobError = null;
      _childPasswordError = null;
      _childRetypePasswordError = null;
      _parentEmailError = null;
      _securityAnswerError = null;
      _emailHandleError = null;
    });
  }

  bool _validateStep2Personal() {
    _clearErrors();
    bool isValid = true;

    if (_firstNameController.text.trim().isEmpty) {
      _firstNameError = 'First Name is required';
      isValid = false;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _lastNameError = 'Last Name is required';
      isValid = false;
    }
    if (_passwordController.text.isEmpty) {
      _passwordError = 'Password is required';
      isValid = false;
    } else if (_passwordController.text.length < 6) {
      _passwordError = 'Password must be at least 6 characters';
      isValid = false;
    }
    if (_retypePasswordController.text != _passwordController.text) {
      _retypePasswordError = 'Passwords do not match';
      isValid = false;
    }

    setState(() {});
    return isValid;
  }

  bool _validateStep2Business() {
    _clearErrors();
    bool isValid = true;

    if (_businessNameController.text.trim().isEmpty) {
      _businessNameError = 'Organization / Business Name is required';
      isValid = false;
    }
    if (_ownerFirstNameController.text.trim().isEmpty) {
      _ownerFirstNameError = 'Owner First Name is required';
      isValid = false;
    }
    if (_ownerLastNameController.text.trim().isEmpty) {
      _ownerLastNameError = 'Owner Last Name is required';
      isValid = false;
    }
    if (_adminPasswordController.text.isEmpty) {
      _adminPasswordError = 'Password is required';
      isValid = false;
    } else if (_adminPasswordController.text.length < 6) {
      _adminPasswordError = 'Password must be at least 6 characters';
      isValid = false;
    }
    if (_retypeAdminPasswordController.text != _adminPasswordController.text) {
      _retypeAdminPasswordError = 'Passwords do not match';
      isValid = false;
    }

    setState(() {});
    return isValid;
  }

  bool _validateStep2Child() {
    _clearErrors();
    bool isValid = true;

    if (_childFirstNameController.text.trim().isEmpty) {
      _childFirstNameError = 'Child First Name is required';
      isValid = false;
    }
    if (_childLastNameController.text.trim().isEmpty) {
      _childLastNameError = 'Child Last Name is required';
      isValid = false;
    }
    if (_parentEmailController.text.trim().isEmpty) {
      _parentEmailError = 'Parent Email Address is required';
      isValid = false;
    }
    if (_childPasswordController.text.isEmpty) {
      _childPasswordError = 'Password is required';
      isValid = false;
    }
    if (_childRetypePasswordController.text != _childPasswordController.text) {
      _childRetypePasswordError = 'Passwords do not match';
      isValid = false;
    }

    setState(() {});
    return isValid;
  }

  void _proceedToStep3() async {
    bool isValid = false;
    if (_selectedType == 'personal') {
      isValid = _validateStep2Personal();
    } else if (_selectedType == 'business') {
      isValid = _validateStep2Business();
    } else if (_selectedType == 'child') {
      isValid = _validateStep2Child();
    }

    if (isValid) {
      final baseName = _selectedType == 'business'
          ? _ownerFirstNameController.text.trim().toLowerCase()
          : (_selectedType == 'child'
              ? _childFirstNameController.text.trim().toLowerCase()
              : _firstNameController.text.trim().toLowerCase());
      
      final domain = _selectedType == 'business' && _customDomainController.text.trim().isNotEmpty
          ? _customDomainController.text.trim()
          : 'bnxmail.com';

      _emailHandleSuggestions = [
        '$baseName@$domain',
        '${baseName}123@$domain',
        '${baseName}_bnxmail@$domain',
        '${baseName}.${DateTime.now().year}@$domain',
      ];

      // Fetch dynamic username suggestions from GET /auth/username-suggestions
      try {
        final suggestionsRes = await _apiService.fetchUsernameSuggestions();
        if (suggestionsRes.success && suggestionsRes.data is List) {
          final List backendList = suggestionsRes.data as List;
          for (var item in backendList) {
            final sName = item.toString().trim();
            if (sName.isNotEmpty && !_emailHandleSuggestions.contains('$sName@$domain')) {
              _emailHandleSuggestions.add('$sName@$domain');
            }
          }
        }
      } catch (e) {
        debugPrint('Username suggestions fallback: $e');
      }

      _emailHandleController.text = _emailHandleSuggestions.first;
      setState(() => _step = 3);
    }
  }

  final AuthApiService _apiService = AuthApiService();

  void _sendParentOtp() async {
    final parentEmail = _parentEmailController.text.trim();
    if (parentEmail.isEmpty) {
      setState(() => _parentEmailError = 'Parent Email is required');
      return;
    }

    setState(() {
      _isSendingParentOtp = true;
      _parentOtpError = null;
      _parentOtpMessage = null;
    });

    final res = await _apiService.sendParentOtp(parentEmail: parentEmail);

    setState(() {
      _isSendingParentOtp = false;
      _parentOtpMessage = res.message.isNotEmpty
          ? res.message
          : 'Verification OTP sent to $parentEmail';
    });
  }

  void _verifyParentOtp() async {
    final parentEmail = _parentEmailController.text.trim();
    final otp = _parentOtpController.text.trim();

    if (otp.length < 4) {
      setState(() => _parentOtpError = 'Enter 4-digit OTP code');
      return;
    }

    setState(() {
      _isVerifyingParentOtp = true;
      _parentOtpError = null;
    });

    final res = await _apiService.verifyParentOtp(parentEmail: parentEmail, otp: otp);

    setState(() {
      _isVerifyingParentOtp = false;
      _parentOtpVerified = res.success || res.message.toLowerCase().contains('success');
      _parentOtpMessage = res.message.isNotEmpty
          ? res.message
          : 'Parent Email verified successfully!';
    });
  }

  void _completeRegistration() async {
    final handle = _emailHandleController.text.trim();
    if (handle.isEmpty) {
      setState(() => _emailHandleError = 'Email handle is required');
      return;
    }

    setState(() => _isRegistering = true);

    final username = handle.split('@').first;
    String password = '';
    Map<String, dynamic> regPayload = {};

    if (_selectedType == 'business') {
      password = _adminPasswordController.text;
      regPayload = {
        'username': username,
        'password': password,
        'mode': 'BUSINESS',
        'ownerFirstName': _ownerFirstNameController.text.trim(),
        'ownerLastName': _ownerLastNameController.text.trim(),
        'businessName': _businessNameController.text.trim(),
        'registrationNumber': 'REG123',
        'domain': _customDomainController.text.trim().isNotEmpty ? _customDomainController.text.trim() : 'bnxmail.com',
      };
    } else if (_selectedType == 'child') {
      password = _childPasswordController.text;
      regPayload = {
        'username': username,
        'password': password,
        'mode': 'PERSONAL',
        'firstName': _childFirstNameController.text.trim(),
        'lastName': _childLastNameController.text.trim(),
        'dob': _childDobController.text.trim(),
        'parentEmail': _parentEmailController.text.trim(),
      };
    } else {
      password = _passwordController.text;
      regPayload = {
        'username': username,
        'password': password,
        'mode': 'PERSONAL',
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'dob': _dobController.text.trim(),
      };
    }

    // 1. API: POST /auth/register
    final regResponse = await _apiService.registerUser(regPayload);
    if (!regResponse.success) {
      setState(() => _isRegistering = false);
      final errorMsg = regResponse.message.isNotEmpty
          ? regResponse.message
          : 'Registration failed. Username or email may already be registered.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final tempToken = regResponse.data?['tempToken']?.toString() ?? '';

    // 2. API: POST /emails/create
    final emailResponse = await _apiService.provisionEmail(
      tempToken: tempToken,
      emailName: username,
      password: password,
      isPrimary: true,
    );

    final registeredEmail = emailResponse.data?['email']?.toString() ??
        (handle.contains('@') ? handle : '$handle@bnxmail.com');

    // 3. API: POST /business/onboard (if BUSINESS mode)
    if (_selectedType == 'business') {
      await _apiService.onboardBusiness(
        accessToken: tempToken,
        businessDetails: {
          'businessAddress': '123 Enterprise St',
          'businessPhone': _phoneController.text.trim(),
          'industry': 'Tech',
          'companySize': '1-10',
          'acceptTerms': true,
        },
      );
    }

    setState(() => _isRegistering = false);

    String fullName = '';
    AccountType accType = AccountType.personal;

    if (_selectedType == 'business') {
      fullName = '${_ownerFirstNameController.text.trim()} ${_ownerLastNameController.text.trim()} (${_businessNameController.text.trim()})';
      accType = AccountType.business;
    } else if (_selectedType == 'child') {
      fullName = '${_childFirstNameController.text.trim()} ${_childLastNameController.text.trim()}';
      accType = AccountType.personal;
    } else {
      fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      accType = AccountType.personal;
    }

    final newAccount = UserAccount(
      id: const Uuid().v4(),
      name: fullName.toUpperCase(),
      displayName: fullName.split(' ').first,
      username: username,
      email: registeredEmail,
      avatarLetter: fullName.isNotEmpty ? fullName[0].toUpperCase() : 'B',
      createdAt: DateTime.now(),
      lastUsed: DateTime.now(),
      type: accType,
      securityScore: 90,
      storageUsage: 0.1,
    );

    if (mounted) {
      final accountProvider = context.read<AccountProvider>();
      accountProvider.addAccount(newAccount);
      accountProvider.switchAccount(newAccount.id);
      context.read<AuthNotifier>().loginSuccess(accessToken: tempToken, email: registeredEmail);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account $registeredEmail registered successfully!'),
          backgroundColor: AuthConstants.primaryBlue,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthConstants.background,
      appBar: AppBar(
        title: Text(_step == 1
            ? 'Account Type'
            : (_step == 2 ? 'Account Details' : 'Choose Handle')),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AuthConstants.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_step > 1) {
              setState(() => _step--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AuthConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Progress Indicator
              Row(
                children: [
                  _buildStepIndicator(1, 'Type', _step >= 1),
                  _buildStepDivider(_step >= 2),
                  _buildStepIndicator(2, 'Details', _step >= 2),
                  _buildStepDivider(_step >= 3),
                  _buildStepIndicator(3, 'Handle', _step >= 3),
                ],
              ),
              const SizedBox(height: 24),

              if (_step == 1) _buildStep1AccountTypeSelection(),
              if (_step == 2) _buildStep2DetailsForm(),
              if (_step == 3) _buildStep3EmailHandleSelection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int stepNum, String title, bool active) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: active
                ? AuthConstants.primaryBlue
                : Colors.grey.shade300,
            child: Text(
              '$stepNum',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? AuthConstants.primaryBlue : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider(bool active) {
    return Container(
      width: 30,
      height: 2,
      color: active ? AuthConstants.primaryBlue : Colors.grey.shade300,
      margin: const EdgeInsets.only(bottom: 16),
    );
  }

  // STEP 1: ACCOUNT TYPE SELECTION
  Widget _buildStep1AccountTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Account Type',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose the account profile that best fits your security needs.',
          style: TextStyle(fontSize: 13, color: AuthConstants.textSecondary),
        ),
        const SizedBox(height: 24),

        _buildTypeCard(
          type: 'personal',
          title: 'Personal Account',
          subtitle: 'Individual zero-trust authentication for daily security & passkeys.',
          icon: Icons.person_rounded,
        ),
        const SizedBox(height: 14),

        _buildTypeCard(
          type: 'business',
          title: 'Business / Enterprise',
          subtitle: 'Multi-user domain management, SSO, and team security controls.',
          icon: Icons.business_center_rounded,
        ),
        const SizedBox(height: 14),

        _buildTypeCard(
          type: 'child',
          title: 'Child / Family Account',
          subtitle: 'Parentally supervised access with security questions & OTP controls.',
          icon: Icons.child_care_rounded,
        ),
        const SizedBox(height: 32),

        AuthButton(
          text: 'Continue to Details',
          onPressed: () => setState(() => _step = 2),
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(AuthConstants.borderRadiusLarge),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AuthConstants.borderRadiusLarge),
          border: Border.all(
            color: isSelected ? AuthConstants.primaryBlue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AuthConstants.primaryBlue.withOpacity(0.08)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AuthConstants.primaryBlue.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 26,
                color: isSelected ? AuthConstants.primaryBlue : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AuthConstants.primaryBlue : AuthConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AuthConstants.textSecondary),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: type,
              groupValue: _selectedType,
              activeColor: AuthConstants.primaryBlue,
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 2: DETAILS FORM
  Widget _buildStep2DetailsForm() {
    if (_selectedType == 'business') return _buildStep2BusinessForm();
    if (_selectedType == 'child') return _buildStep2ChildForm();
    return _buildStep2PersonalForm();
  }

  Widget _buildStep2PersonalForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Details',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter your information to set up your personal account.',
          style: TextStyle(fontSize: 13, color: AuthConstants.textSecondary),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: AuthTextField(
                label: 'First Name',
                hintText: 'John',
                prefixIcon: Icons.person_outline,
                controller: _firstNameController,
                validator: (_) => _firstNameError,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AuthTextField(
                label: 'Last Name',
                hintText: 'Doe',
                prefixIcon: Icons.person_outline,
                controller: _lastNameController,
                validator: (_) => _lastNameError,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        AuthTextField(
          label: 'Phone Number (Optional)',
          hintText: '+91 98765 43210',
          prefixIcon: Icons.phone_outlined,
          controller: _personalPhoneController,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),

        AuthTextField(
          label: 'Password',
          hintText: '••••••••',
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          controller: _passwordController,
          validator: (_) => _passwordError,
        ),
        const SizedBox(height: 16),

        AuthTextField(
          label: 'Retype Password',
          hintText: '••••••••',
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          controller: _retypePasswordController,
          validator: (_) => _retypePasswordError,
        ),
        const SizedBox(height: 28),

        AuthButton(
          text: 'Continue to Handle Selection',
          onPressed: _proceedToStep3,
        ),
      ],
    );
  }

  Widget _buildStep2BusinessForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Organization & Admin Details',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Configure your organization credentials and admin owner.',
          style: TextStyle(fontSize: 13, color: AuthConstants.textSecondary),
        ),
        const SizedBox(height: 20),

        AuthTextField(
          label: 'Business / Organization Name',
          hintText: 'Acme Corp Inc.',
          prefixIcon: Icons.business_rounded,
          controller: _businessNameController,
          validator: (_) => _businessNameError,
        ),
        const SizedBox(height: 16),

        AuthTextField(
          label: 'Custom Domain (Optional)',
          hintText: 'acmecorp.com',
          prefixIcon: Icons.language_rounded,
          controller: _customDomainController,
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: AuthTextField(
                label: 'Owner First Name',
                hintText: 'Sarah',
                prefixIcon: Icons.person_outline,
                controller: _ownerFirstNameController,
                validator: (_) => _ownerFirstNameError,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AuthTextField(
                label: 'Owner Last Name',
                hintText: 'Connor',
                prefixIcon: Icons.person_outline,
                controller: _ownerLastNameController,
                validator: (_) => _ownerLastNameError,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        AuthTextField(
          label: 'Admin Password',
          hintText: '••••••••',
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          controller: _adminPasswordController,
          validator: (_) => _adminPasswordError,
        ),
        const SizedBox(height: 16),

        AuthTextField(
          label: 'Retype Admin Password',
          hintText: '••••••••',
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          controller: _retypeAdminPasswordController,
          validator: (_) => _retypeAdminPasswordError,
        ),
        const SizedBox(height: 28),

        AuthButton(
          text: 'Continue to Handle Selection',
          onPressed: _proceedToStep3,
        ),
      ],
    );
  }

  Widget _buildStep2ChildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Child & Parent Verification',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Set up child account details and verify parent supervision.',
          style: TextStyle(fontSize: 13, color: AuthConstants.textSecondary),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: AuthTextField(
                label: 'Child First Name',
                hintText: 'Leo',
                prefixIcon: Icons.child_care_rounded,
                controller: _childFirstNameController,
                validator: (_) => _childFirstNameError,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AuthTextField(
                label: 'Child Last Name',
                hintText: 'Doe',
                prefixIcon: Icons.child_care_rounded,
                controller: _childLastNameController,
                validator: (_) => _childLastNameError,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        AuthTextField(
          label: 'Parent Email Address',
          hintText: 'parent@b2auth.com',
          prefixIcon: Icons.mark_email_read_outlined,
          controller: _parentEmailController,
          validator: (_) => _parentEmailError,
        ),
        const SizedBox(height: 10),

        // Parent OTP Verification Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AuthConstants.borderRadiusMedium),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Parent OTP Supervision', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  TextButton(
                    onPressed: _isSendingParentOtp ? null : _sendParentOtp,
                    child: _isSendingParentOtp
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_parentOtpVerified ? 'Verified ✓' : 'Send OTP'),
                  ),
                ],
              ),
              if (_parentOtpMessage != null) ...[
                Text(_parentOtpMessage!, style: const TextStyle(fontSize: 11, color: AuthConstants.primaryBlue)),
                const SizedBox(height: 8),
              ],
              if (!_parentOtpVerified) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _parentOtpController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [LengthLimitingTextInputFormatter(6)],
                        decoration: const InputDecoration(hintText: 'Enter 4-digit OTP', isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isVerifyingParentOtp ? null : _verifyParentOtp,
                      child: _isVerifyingParentOtp
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Verify'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        AuthTextField(
          label: 'Child Account Password',
          hintText: '••••••••',
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          controller: _childPasswordController,
          validator: (_) => _childPasswordError,
        ),
        const SizedBox(height: 16),

        AuthTextField(
          label: 'Retype Password',
          hintText: '••••••••',
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          controller: _childRetypePasswordController,
          validator: (_) => _childRetypePasswordError,
        ),
        const SizedBox(height: 28),

        AuthButton(
          text: 'Continue to Handle Selection',
          onPressed: _proceedToStep3,
        ),
      ],
    );
  }

  // STEP 3: EMAIL HANDLE SELECTION
  Widget _buildStep3EmailHandleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Email Handle',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select your primary B2Auth email address or custom handle.',
          style: TextStyle(fontSize: 13, color: AuthConstants.textSecondary),
        ),
        const SizedBox(height: 24),

        AuthTextField(
          label: 'Primary Email Address',
          hintText: 'username@bnxmail.com',
          prefixIcon: Icons.alternate_email,
          controller: _emailHandleController,
          validator: (_) => _emailHandleError,
        ),
        const SizedBox(height: 16),

        if (_emailHandleSuggestions.isNotEmpty) ...[
          const Text(
            'Suggested Handles:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AuthConstants.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _emailHandleSuggestions.map((suggestion) {
              final isSelected = _emailHandleController.text == suggestion;
              return ChoiceChip(
                label: Text(suggestion, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AuthConstants.textPrimary)),
                selected: isSelected,
                selectedColor: AuthConstants.primaryBlue,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _emailHandleController.text = suggestion);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],

        AuthButton(
          text: _isRegistering ? 'Creating Account...' : 'Complete & Launch B2Auth',
          isLoading: _isRegistering,
          onPressed: _isRegistering ? null : _completeRegistration,
        ),
      ],
    );
  }
}
