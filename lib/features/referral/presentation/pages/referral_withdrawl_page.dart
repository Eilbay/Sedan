import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/core/appColors.dart';
import 'package:optombai/features/referral/presentation/logic/referral_cubit.dart';
import 'package:optombai/features/referral/presentation/widgets/referral_withdrawals_section.dart';
import 'package:auto_route/auto_route.dart';

enum WithdrawalMethod { cardBank, phone, qr }

@RoutePage()
class ReferralWithdrawlPage extends StatefulWidget {
  const ReferralWithdrawlPage({super.key});

  @override
  State<ReferralWithdrawlPage> createState() => _ReferralWithdrawlPageState();
}

class _ReferralWithdrawlPageState extends State<ReferralWithdrawlPage> {
  WithdrawalMethod _selectedMethod = WithdrawalMethod.cardBank;

  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _cardNumberCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _bankCtrl = TextEditingController();
  final TextEditingController _fullNameCtrl = TextEditingController();

  bool _showResultOverlay = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _cardNumberCtrl.dispose();
    _phoneCtrl.dispose();
    _bankCtrl.dispose();
    _fullNameCtrl.dispose();
    super.dispose();
  }

  final ImagePicker _picker = ImagePicker();
  XFile? _qrFile;

  Future<void> _pickQrFromGallery() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (file == null) return;

      setState(() {
        _qrFile = file;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть галерею')),
      );
    }
  }

  void _removeQr() {
    setState(() {
      _qrFile = null;
    });
  }

  void _onMethodSelected(WithdrawalMethod method) {
    setState(() {
      _selectedMethod = method;
    });
  }

  Future<void> _onSubmit({
    required double balance,
    required String userId,
    required String currencyName,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    final amountStr = _amountCtrl.text.trim();
    if (amountStr.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Введите сумму вывода')),
      );
      return;
    }

    final amount = int.tryParse(amountStr);
    if (amount == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Некорректная сумма')),
      );
      return;
    }

    if (amount < 100) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Минимальная сумма вывода — 100 сом')),
      );
      return;
    }

    if (amount > balance) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Сумма больше доступного баланса')),
      );
      return;
    }

    String details;
    String comment;
    String fullName;

    if (_selectedMethod == WithdrawalMethod.cardBank) {
      final card = _cardNumberCtrl.text.trim();
      final cardDigits = card.replaceAll(RegExp(r'\D'), '');
      final fullNameStr = _fullNameCtrl.text.trim();
      final bankStr = _bankCtrl.text.trim();

      if (!RegExp(r'^\d{16}$').hasMatch(cardDigits)) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Введите корректный номер карты (16 цифр)'),
          ),
        );
        return;
      }

      if (fullNameStr.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Введите ФИО владельца')),
        );
        return;
      }

      if (bankStr.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Введите название банка')),
        );
        return;
      }

      details = 'CARD:$cardDigits;NAME:$fullNameStr;BANK:$bankStr';
      comment = bankStr;
      fullName = fullNameStr;
    } else if (_selectedMethod == WithdrawalMethod.phone) {
      final phone = _phoneCtrl.text.trim();
      final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
      final fullNameStr = _fullNameCtrl.text.trim();
      final bankStr = _bankCtrl.text.trim();

      if (phoneDigits.length < 7) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Введите корректный номер телефона'),
          ),
        );
        return;
      }

      if (fullNameStr.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Введите ФИО получателя')),
        );
        return;
      }

      if (bankStr.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Введите название банка')),
        );
        return;
      }

      details = 'PHONE:996$phoneDigits;NAME:$fullNameStr;BANK:$bankStr';
      comment = bankStr;
      fullName = fullNameStr;
    } else {
      if (_qrFile == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Прикрепите QR код')),
        );
        return;
      }

      details = 'QR_FILE:${_qrFile!.name}';
      comment = 'Вывод по QR-коду';
      fullName = _fullNameCtrl.text.trim().isEmpty
          ? 'Вывод по QR-коду'
          : _fullNameCtrl.text.trim();
    }

    await context.read<ReferralCubit>().createWithdrawal(
          amount: amount.toString(),
          details: details,
          user: userId,
          comment: comment,
          fullName: fullName,
          qrFile: _qrFile,
          currency: currencyName,
        );

    _amountCtrl.clear();
    _cardNumberCtrl.clear();
    _phoneCtrl.clear();
    _bankCtrl.clear();
    _fullNameCtrl.clear();
    _removeQr();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color bgColor = isDark ? AppColors.black : AppColors.white;
    final Color primaryText = isDark ? Colors.white : Colors.black87;
    final Color secondaryText = isDark ? Colors.white70 : Colors.black54;
    final Color mutedText = isDark ? Colors.white38 : Colors.black45;
    final Color labelText = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: primaryText,
          ),
          onPressed: () => context.router.maybePop(),
        ),
        title: Text(
          'Вывод средств',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: primaryText,
          ),
        ),
        iconTheme: IconThemeData(color: primaryText),
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: BlocConsumer<ReferralCubit, ReferralState>(
          listener: (context, state) {
            if (state.status == FetchStatus.loading) {
              setState(() {
                _showResultOverlay = false;
              });
            }

            if (state.status == FetchStatus.success ||
                state.status == FetchStatus.error) {
              setState(() {
                _showResultOverlay = true;
              });

              Future.delayed(const Duration(milliseconds: 1200), () {
                if (!mounted) return;
                setState(() {
                  _showResultOverlay = false;
                });
              });
            }
          },
          builder: (context, state) {
            final balance = state.wallet?.balance ?? 0;
            final userId = state.profile?.user ?? '';

            final userFlag =
                context.read<UserBloc>().state.user.country?.square_flag;

            final currencyName = state.currencies
                    .where((c) => c.squareFlag == userFlag)
                    .map((c) => c.name)
                    .cast<String?>()
                    .firstWhere((e) => e != null, orElse: () => '') ??
                '';

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BalanceCard(
                        isDark: isDark,
                        balance: balance,
                        currencyName: currencyName,
                        primaryText: primaryText,
                        secondaryText: secondaryText,
                        mutedText: mutedText,
                      ),
                      const SizedBox(height: 16),
                      _AmountInputCard(
                        isDark: isDark,
                        amountCtrl: _amountCtrl,
                        balance: balance,
                        currencyName: currencyName,
                        primaryText: primaryText,
                        secondaryText: secondaryText,
                        mutedText: mutedText,
                        labelText: labelText,
                      ),
                      const SizedBox(height: 16),
                      _WithdrawalMethodCard(
                        isDark: isDark,
                        selectedMethod: _selectedMethod,
                        onMethodSelected: _onMethodSelected,
                        cardNumberCtrl: _cardNumberCtrl,
                        phoneCtrl: _phoneCtrl,
                        bankCtrl: _bankCtrl,
                        fullNameCtrl: _fullNameCtrl,
                        qrFile: _qrFile,
                        onPickQr: _pickQrFromGallery,
                        onRemoveQr: _removeQr,
                        currencyName: currencyName,
                        primaryText: primaryText,
                        secondaryText: secondaryText,
                        mutedText: mutedText,
                        labelText: labelText,
                      ),
                      const SizedBox(height: 20),
                      _WithdrawButton(
                        isDark: isDark,
                        onPressed: () => _onSubmit(
                          balance: balance,
                          userId: userId,
                          currencyName: currencyName,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'История',
                        style: TextStyle(color: labelText),
                      ),
                      const SizedBox(height: 6),
                      ReferralWithdrawalsSection(
                        withdrawals: state.withdrawals,
                        currencies: state.currencies,
                      ),
                    ],
                  ),
                ),
                if (state.status == FetchStatus.loading ||
                    ((state.status == FetchStatus.success ||
                            state.status == FetchStatus.error) &&
                        _showResultOverlay))
                  _StatusOverlay(status: state.status),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Extracted widgets
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _SectionCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.black : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
      child: child,
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final bool isDark;
  final double balance;
  final String currencyName;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;

  const _BalanceCard({
    required this.isDark,
    required this.balance,
    required this.currencyName,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Реферальный баланс',
            style: TextStyle(
              color: secondaryText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$balance ${currencyName.toLowerCase()}',
            style: TextStyle(
              color: primaryText,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Доступно для вывода',
            style: TextStyle(
              color: mutedText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountInputCard extends StatelessWidget {
  final bool isDark;
  final TextEditingController amountCtrl;
  final double balance;
  final String currencyName;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color labelText;

  const _AmountInputCard({
    required this.isDark,
    required this.amountCtrl,
    required this.balance,
    required this.currencyName,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сумма вывода',
            style: TextStyle(
              color: labelText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: primaryText),
                  decoration: _buildInputDecoration(
                    hint: 'Введите сумму',
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _CurrencyBadge(
                isDark: isDark,
                currencyName: currencyName,
                primaryText: primaryText,
                secondaryText: secondaryText,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Минимальная сумма — 100 ${currencyName.toLowerCase()}',
            style: TextStyle(
              color: mutedText,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _AmountChip(
                label: '100',
                isDark: isDark,
                onTap: () => amountCtrl.text = '100',
              ),
              _AmountChip(
                label: '300',
                isDark: isDark,
                onTap: () => amountCtrl.text = '300',
              ),
              _AmountChip(
                label: '500',
                isDark: isDark,
                onTap: () => amountCtrl.text = '500',
              ),
              _AmountChip(
                label: 'Все',
                isDark: isDark,
                onTap: () => amountCtrl.text = '$balance',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrencyBadge extends StatelessWidget {
  final bool isDark;
  final String currencyName;
  final Color primaryText;
  final Color secondaryText;

  const _CurrencyBadge({
    required this.isDark,
    required this.currencyName,
    required this.primaryText,
    required this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201943) : const Color(0xFFF1F4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currencyName.toLowerCase(),
            style: TextStyle(
              color: primaryText,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: secondaryText,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback? onTap;

  const _AmountChip({
    required this.label,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.black : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class _WithdrawalMethodCard extends StatelessWidget {
  final bool isDark;
  final WithdrawalMethod selectedMethod;
  final ValueChanged<WithdrawalMethod> onMethodSelected;
  final TextEditingController cardNumberCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController bankCtrl;
  final TextEditingController fullNameCtrl;
  final XFile? qrFile;
  final VoidCallback onPickQr;
  final VoidCallback onRemoveQr;
  final String currencyName;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color labelText;

  const _WithdrawalMethodCard({
    required this.isDark,
    required this.selectedMethod,
    required this.onMethodSelected,
    required this.cardNumberCtrl,
    required this.phoneCtrl,
    required this.bankCtrl,
    required this.fullNameCtrl,
    required this.qrFile,
    required this.onPickQr,
    required this.onRemoveQr,
    required this.currencyName,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Способ получения',
            style: TextStyle(
              color: labelText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          _MethodTile(
            isDark: isDark,
            title: 'Банк / Карта',
            subtitle: 'Visa / Элкарт / Мбанк',
            icon: Icons.account_balance_wallet_outlined,
            selected: selectedMethod == WithdrawalMethod.cardBank,
            onTap: () => onMethodSelected(WithdrawalMethod.cardBank),
          ),
          if (selectedMethod == WithdrawalMethod.cardBank) ...[
            const SizedBox(height: 12),
            _CardBankFields(
              isDark: isDark,
              cardNumberCtrl: cardNumberCtrl,
              fullNameCtrl: fullNameCtrl,
              bankCtrl: bankCtrl,
              primaryText: primaryText,
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          _MethodTile(
            isDark: isDark,
            title: 'По номеру телефона',
            subtitle: 'Перевод на счёт по номеру',
            icon: Icons.phone_iphone_rounded,
            selected: selectedMethod == WithdrawalMethod.phone,
            onTap: () => onMethodSelected(WithdrawalMethod.phone),
          ),
          if (selectedMethod == WithdrawalMethod.phone) ...[
            const SizedBox(height: 12),
            _PhoneFields(
              isDark: isDark,
              phoneCtrl: phoneCtrl,
              fullNameCtrl: fullNameCtrl,
              bankCtrl: bankCtrl,
              primaryText: primaryText,
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          _MethodTile(
            isDark: isDark,
            title: 'По QR-коду',
            subtitle: 'Сканируем ваш банковский QR',
            icon: Icons.qr_code_2_rounded,
            selected: selectedMethod == WithdrawalMethod.qr,
            onTap: () => onMethodSelected(WithdrawalMethod.qr),
          ),
          if (selectedMethod == WithdrawalMethod.qr) ...[
            const SizedBox(height: 12),
            _QrSection(
              isDark: isDark,
              qrFile: qrFile,
              onPickQr: onPickQr,
              onRemoveQr: onRemoveQr,
              primaryText: primaryText,
              secondaryText: secondaryText,
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          Text(
            'Проверьте данные — средства отправляются автоматически',
            style: TextStyle(
              color: mutedText,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          Divider(
            color: isDark
                ? Colors.white12
                : Colors.black.withValues(alpha: 0.08),
          ),
          _CommissionRow(
            isDark: isDark,
            currencyName: currencyName,
            primaryText: primaryText,
            secondaryText: secondaryText,
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MethodTile({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryText = isDark ? Colors.white : Colors.black;
    final Color secondaryText = isDark ? Colors.white70 : Colors.black54;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.black : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? isDark
                    ? AppColors.white
                    : AppColors.black
                : (isDark ? Colors.white24 : Colors.black12),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryText),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            _SelectionIndicator(isDark: isDark, selected: selected),
          ],
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  final bool isDark;
  final bool selected;

  const _SelectionIndicator({
    required this.isDark,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: selected
            ? isDark
                ? AppColors.white
                : AppColors.black
            : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? isDark
                  ? AppColors.white
                  : AppColors.black
              : (isDark ? Colors.white38 : Colors.black26),
        ),
      ),
      child: selected
          ? Icon(
              Icons.check,
              size: 18,
              color: isDark ? AppColors.black : AppColors.white,
            )
          : null,
    );
  }
}

class _CardBankFields extends StatelessWidget {
  final bool isDark;
  final TextEditingController cardNumberCtrl;
  final TextEditingController fullNameCtrl;
  final TextEditingController bankCtrl;
  final Color primaryText;

  const _CardBankFields({
    required this.isDark,
    required this.cardNumberCtrl,
    required this.fullNameCtrl,
    required this.bankCtrl,
    required this.primaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: cardNumberCtrl,
          keyboardType: TextInputType.number,
          style: TextStyle(color: primaryText),
          maxLength: 16,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
          ],
          decoration: _buildInputDecoration(
            hint: 'Номер банковской карты (16 цифр)',
            isDark: isDark,
          ).copyWith(counterText: ''),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: fullNameCtrl,
          style: TextStyle(color: primaryText),
          decoration: _buildInputDecoration(
            hint: 'ФИО владельца карты',
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: bankCtrl,
          style: TextStyle(color: primaryText),
          decoration: _buildInputDecoration(
            hint: 'Название банка (Mbank, Optima, O!Bank)',
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _PhoneFields extends StatelessWidget {
  final bool isDark;
  final TextEditingController phoneCtrl;
  final TextEditingController fullNameCtrl;
  final TextEditingController bankCtrl;
  final Color primaryText;

  const _PhoneFields({
    required this.isDark,
    required this.phoneCtrl,
    required this.fullNameCtrl,
    required this.bankCtrl,
    required this.primaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF201943)
                    : const Color(0xFFF1F4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+996',
                style: TextStyle(color: primaryText),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: primaryText),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: _buildInputDecoration(
                  hint: 'Номер телефона',
                  isDark: isDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: fullNameCtrl,
          style: TextStyle(color: primaryText),
          decoration: _buildInputDecoration(
            hint: 'ФИО получателя',
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: bankCtrl,
          style: TextStyle(color: primaryText),
          decoration: _buildInputDecoration(
            hint: 'Название банка (Mbank, Optima, O!Bank)',
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _QrSection extends StatelessWidget {
  final bool isDark;
  final XFile? qrFile;
  final VoidCallback onPickQr;
  final VoidCallback onRemoveQr;
  final Color primaryText;
  final Color secondaryText;

  const _QrSection({
    required this.isDark,
    required this.qrFile,
    required this.onPickQr,
    required this.onRemoveQr,
    required this.primaryText,
    required this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    if (qrFile == null) {
      return _QrUploadButton(
        isDark: isDark,
        onPressed: onPickQr,
        primaryText: primaryText,
      );
    }

    return _QrAttachedIndicator(
      isDark: isDark,
      fileName: qrFile!.name,
      onRemove: onRemoveQr,
      primaryText: primaryText,
      secondaryText: secondaryText,
    );
  }
}

class _QrUploadButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onPressed;
  final Color primaryText;

  const _QrUploadButton({
    required this.isDark,
    required this.onPressed,
    required this.primaryText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        icon: Icon(
          Icons.qr_code_2_rounded,
          color: primaryText,
        ),
        label: Text(
          'Прикрепить QR код',
          style: TextStyle(
            fontSize: 13,
            color: primaryText,
          ),
        ),
      ),
    );
  }
}

class _QrAttachedIndicator extends StatelessWidget {
  final bool isDark;
  final String fileName;
  final VoidCallback onRemove;
  final Color primaryText;
  final Color secondaryText;

  const _QrAttachedIndicator({
    required this.isDark,
    required this.fileName,
    required this.onRemove,
    required this.primaryText,
    required this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.black : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.white : AppColors.black,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.qr_code_2_rounded, color: primaryText),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QR прикреплен',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.close_rounded, color: secondaryText),
            splashRadius: 18,
            tooltip: 'Удалить',
          ),
        ],
      ),
    );
  }
}

class _CommissionRow extends StatelessWidget {
  final bool isDark;
  final String currencyName;
  final Color primaryText;
  final Color secondaryText;

  const _CommissionRow({
    required this.isDark,
    required this.currencyName,
    required this.primaryText,
    required this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.receipt_long_outlined,
          color: isDark ? Colors.white38 : Colors.black45,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          'Комиссия: 0 ${currencyName.toLowerCase()}',
          style: TextStyle(
            color: primaryText,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(
          'Срок: до 24 часов',
          style: TextStyle(
            color: secondaryText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _WithdrawButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onPressed;

  const _WithdrawButton({
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.black : AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isDark ? Colors.white : Colors.black),
          ),
        ),
        child: Text(
          'Вывести средства',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class _StatusOverlay extends StatelessWidget {
  const _StatusOverlay({required this.status});

  final FetchStatus status;

  @override
  Widget build(BuildContext context) {
    Widget icon;

    if (status == FetchStatus.loading) {
      icon = const SizedBox(
        key: ValueKey('loading'),
        width: 56,
        height: 56,
        child: CircularProgressIndicator(strokeWidth: 4),
      );
    } else if (status == FetchStatus.success) {
      icon = const Column(
        key: ValueKey('success'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.greenAccent,
            size: 72,
          ),
          SizedBox(height: 12),
          Text(
            'Ваш запрос на модерации',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else {
      icon = const Column(
        key: ValueKey('error'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.close_rounded,
            color: Colors.redAccent,
            size: 72,
          ),
          SizedBox(height: 10),
          Text(
            'Ошибка. Попробуйте позже',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared input decoration builder
// ---------------------------------------------------------------------------

const Color _accent = Color(0xFF7B61FF);

InputDecoration _buildInputDecoration({
  required String hint,
  required bool isDark,
}) {
  final Color fill =
      isDark ? const Color(0xFF201943) : const Color(0xFFF1F4FF);
  final Color borderColor =
      isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.1);
  final Color hintColor =
      isDark ? Colors.white38 : Colors.black.withValues(alpha: 0.4);

  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: hintColor),
    filled: true,
    fillColor: fill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _accent),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}
