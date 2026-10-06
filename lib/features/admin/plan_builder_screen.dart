import 'package:flutter/material.dart';
import '../../services/saas_backend_service.dart';
import '../../models/saas_models.dart';
import '../../app/theme/app_colors.dart';

class PlanBuilderScreen extends StatefulWidget {
  const PlanBuilderScreen({super.key});

  @override
  State<PlanBuilderScreen> createState() => _PlanBuilderScreenState();
}

class _PlanBuilderScreenState extends State<PlanBuilderScreen> {
  final _saas = SaaSBackendService();
  final _formKey = GlobalKey<FormState>();
  
  String _name = '';
  String _slug = '';
  String _description = '';
  PlanType _type = PlanType.regular;
  double _price = 0;
  int _maxDevices = 1;
  int _maxAi = 50;

  bool _isLoading = false;

  void _savePlan() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    setState(() => _isLoading = true);
    
    await _saas.createCustomPlan(Plan(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      slug: _slug,
      name: _name,
      description: _description,
      type: _type,
      monthlyPrice: _price,
      maxDevices: _maxDevices,
      maxAiRequests: _maxAi,
      isActive: true,
    ));

    await _saas.logAuditAction('admin', 'CREATE_PLAN', 'Created plan $_name');
    
    setState(() => _isLoading = false);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkDeepBg : const Color(0xFFF7FAF8);
    final textP = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text('Plan Builder', style: TextStyle(color: textP, fontWeight: FontWeight.w700, fontFamily: 'Plus Jakarta Sans')),
        iconTheme: IconThemeData(color: textP),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionTitle('Basic Information', textP),
                const SizedBox(height: 12),
                _buildTextField('Plan Name', (val) => _name = val!),
                const SizedBox(height: 12),
                _buildTextField('Slug (e.g. pro-yearly)', (val) => _slug = val!),
                const SizedBox(height: 12),
                _buildTextField('Description', (val) => _description = val!, maxLines: 2),
                const SizedBox(height: 24),
                
                _buildSectionTitle('Configuration', textP),
                const SizedBox(height: 12),
                DropdownButtonFormField<PlanType>(
                  value: _type,
                  decoration: _inputDecoration('Plan Type', isDark),
                  dropdownColor: isDark ? AppColors.darkElevatedCard : Colors.white,
                  items: PlanType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase(), style: TextStyle(color: textP)))).toList(),
                  onChanged: (val) => setState(() => _type = val!),
                ),
                const SizedBox(height: 12),
                _buildTextField('Monthly Price (Rp)', (val) => _price = double.tryParse(val!) ?? 0, keyboardType: TextInputType.number),
                const SizedBox(height: 24),

                _buildSectionTitle('Limits & Quotas', textP),
                const SizedBox(height: 12),
                _buildTextField('Max Devices', (val) => _maxDevices = int.tryParse(val!) ?? 1, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _buildTextField('Max AI Requests / Month', (val) => _maxAi = int.tryParse(val!) ?? 50, keyboardType: TextInputType.number),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _savePlan,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save Dynamic Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(title, style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w700, color: color));
  }

  Widget _buildTextField(String label, FormFieldSetter<String> onSaved, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      decoration: _inputDecoration(label, isDark),
      style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      onSaved: onSaved,
    );
  }

  InputDecoration _inputDecoration(String label, bool isDark) {
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary),
      filled: true,
      fillColor: isDark ? AppColors.darkCard : Colors.white,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)),
    );
  }
}
