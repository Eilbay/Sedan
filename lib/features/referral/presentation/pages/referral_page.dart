import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/core/appColors.dart';
import 'package:optombai/features/referral/presentation/widgets/referral_invitees_section.dart';
import 'package:optombai/features/referral/presentation/widgets/referral_profile_card.dart';
import 'package:optombai/features/referral/presentation/widgets/referral_transactions_section.dart';
import 'package:optombai/features/referral/presentation/widgets/referral_wallet_card.dart';

import 'package:auto_route/auto_route.dart';
import 'package:optombai/features/referral/presentation/logic/referral_cubit.dart';

@RoutePage()
class ReferralPage extends StatelessWidget {
  const ReferralPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
        title: const Text(
          'Реферальная программа',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: !isDark ? AppColors.white : AppColors.black,
        ),
        child: SafeArea(
          top: false,
          child: BlocBuilder<ReferralCubit, ReferralState>(
            buildWhen: (previous, current) =>
                previous.status != current.status ||
                previous.wallet != current.wallet ||
                previous.invitees != current.invitees ||
                previous.transactions != current.transactions ||
                previous.withdrawals != current.withdrawals,
            builder: (context, state) {
              switch (state.status) {
                case FetchStatus.initial:
                case FetchStatus.loading:
                  return const _LoadingView();
                case FetchStatus.error:
                  return _ErrorView(
                    message: state.errorMessage,
                    onRetry: () => context.read<ReferralCubit>().load(),
                  );
                case FetchStatus.success:
                  return _SuccessView(state: state);
              }
            },
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.onRetry,
    this.message,
  });

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).textTheme.titleLarge?.color ?? Colors.white;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message ?? 'Произошла ошибка',
              textAlign: TextAlign.center,
              style: TextStyle(color: color),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8146FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.state});

  final ReferralState state;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<ReferralCubit>().refresh(),
      color: const Color(0xFF8146FF),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 130, 16, 24),
        children: [
          if (state.profile != null) ...[
            ReferralProfileCard(profile: state.profile!),
            const SizedBox(height: 16),
          ],
          if (state.wallet != null) ...[
            ReferralWalletCard(
              wallet: state.wallet!,
              currencies: state.currencies,
            ),
            const SizedBox(height: 16),
          ],
          ReferralInviteesSection(invitees: state.invitees),
          const SizedBox(height: 16),
          ReferralTransactionsSection(
            transactions: state.transactions,
            currencies: state.currencies,
          ),
        ],
      ),
    );
  }
}
