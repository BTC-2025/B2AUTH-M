import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/zero_trust_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/policy_rule_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class ZeroTrustPage extends StatefulWidget {
  const ZeroTrustPage({super.key});

  @override
  State<ZeroTrustPage> createState() => _ZeroTrustPageState();
}

class _ZeroTrustPageState extends State<ZeroTrustPage> {
  // Sandbox test parameters
  String _testLocation = 'Germany';
  int _testRiskScore = 65;
  bool _testCompromised = false;

  void _showAddPolicyDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final conditionCtrl = TextEditingController();
    PolicyAction selectedAction = PolicyAction.requireMfa;
    String selectedCategory = 'Geo Location';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('New Zero Trust Policy'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      controller: nameCtrl,
                      hintText: 'Policy Title (e.g., Block Rooted Devices)',
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: conditionCtrl,
                      hintText: 'IF Condition (e.g., Risk Score > 50)',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PolicyAction>(
                      initialValue: selectedAction,
                      decoration: const InputDecoration(labelText: 'THEN Action'),
                      items: PolicyAction.values.map((a) {
                        return DropdownMenuItem(
                          value: a,
                          child: Text(a.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedAction = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty && conditionCtrl.text.isNotEmpty) {
                      context.read<ZeroTrustProvider>().addPolicy(
                            nameCtrl.text,
                            conditionCtrl.text,
                            selectedAction,
                            selectedCategory,
                          );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add Rule'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final zeroTrust = context.watch<ZeroTrustProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zero Trust Adaptive Access Engine'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add Policy Rule',
            onPressed: () => _showAddPolicyDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Policy Sandbox Simulator Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.science_rounded, color: AppColors.primaryBlue),
                      SizedBox(width: 8),
                      Text(
                        'Policy Engine Sandbox & Evaluation',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          hintText: 'Location (e.g. Germany)',
                          onChanged: (val) => _testLocation = val,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          hintText: 'Risk Score (0-100)',
                          onChanged: (val) => _testRiskScore = int.tryParse(val) ?? 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: _testCompromised,
                        onChanged: (val) => setState(() => _testCompromised = val ?? false),
                      ),
                      const Expanded(
                        child: Text('Compromised OS Device', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CustomButton(
                    text: 'Simulate Request',
                    icon: Icons.play_arrow_rounded,
                    isFullWidth: true,
                    onPressed: () {
                      zeroTrust.runSimulation(
                        location: _testLocation,
                        riskScore: _testRiskScore,
                        isDeviceCompromised: _testCompromised,
                      );
                    },
                  ),
                  if (zeroTrust.simulationResult.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        zeroTrust.simulationResult,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Conditional Access Rules',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${zeroTrust.policies.length} Rules',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Policy Rules List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: zeroTrust.policies.length,
              itemBuilder: (context, index) {
                final policy = zeroTrust.policies[index];
                return PolicyRuleCard(
                  policy: policy,
                  onToggle: (val) => zeroTrust.togglePolicy(policy.id),
                  onDelete: () => zeroTrust.deletePolicy(policy.id),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
