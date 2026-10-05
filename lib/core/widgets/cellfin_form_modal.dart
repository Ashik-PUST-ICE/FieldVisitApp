import 'package:flutter/material.dart';

/// Item representing one top card in the Cellfin card system (matches media_1790873625141.jpg)
class CellfinCardItem {
  final String title;
  final IconData icon;

  const CellfinCardItem({
    required this.title,
    required this.icon,
  });
}

/// 4-Card System Row matching top of reference photograph
/// Shows 4 vertical cards (Icon container on top + Label below)
/// Clicking on any card selects and highlights it with Cellfin green!
class CellfinTopCardsRow extends StatelessWidget {
  final List<CellfinCardItem> cards;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const CellfinTopCardsRow({
    super.key,
    required this.cards,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(cards.length, (index) {
        final card = cards[index];
        final isSelected = index == selectedIndex;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 3.5,
              right: index == cards.length - 1 ? 0 : 3.5,
            ),
            child: InkWell(
              onTap: () => onSelect(index),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF136B3E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF136B3E)
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xFF136B3E).withOpacity(0.22)
                          : Colors.black.withOpacity(0.04),
                      blurRadius: isSelected ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.22)
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        card.icon,
                        color:
                            isSelected ? Colors.white : const Color(0xFF136B3E),
                        size: 21,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      card.title,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color:
                            isSelected ? Colors.white : const Color(0xFF374151),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Exact Cellfin Input Field matching the user's reference photograph (media_1790873625141.jpg)
/// - Pure white background
/// - 10px rounded border with #C4C4C4 subtle grey border (or #136B3E when focused)
/// - Height ~52px
/// - No floating label (clean inside placeholder hint)
/// - Optional left prefix icon (e.g., lock icon)
/// - Optional right suffix (e.g., '৳' currency sign or eye toggle)
class CellfinInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? suffixText;
  final bool obscureText;
  final TextInputType keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final bool readOnly;
  final ValueChanged<String>? onChanged;

  const CellfinInputField({
    super.key,
    this.controller,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
    this.onTap,
    this.readOnly = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF1F2937),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 14.5,
          color: Color(0xFF757575),
          fontWeight: FontWeight.w400,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC4C4C4), width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC4C4C4), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF136B3E), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
        ),
        prefixIcon: prefixIcon,
        prefixIconColor: const Color(0xFF6B7280),
        suffixIcon: suffixIcon ??
            (suffixText != null
                ? Container(
                    width: 44,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      suffixText!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  )
                : null),
        suffixIconColor: const Color(0xFF6B7280),
      ),
    );
  }
}

/// Exact Cellfin Top Officer/Sender Information Card matching the reference photograph
class CellfinOfficerCard extends StatelessWidget {
  final String name;
  final String info;

  const CellfinOfficerCard({
    super.key,
    this.name = 'MD. ASHIKUR RAHMAN',
    this.info = '01748 031 295',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.account_circle,
                  color: Color(0xFF6B7280), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF374151),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 14, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              const Icon(Icons.credit_card_outlined,
                  color: Color(0xFF6B7280), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  info,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// FULL-SCREEN FORM SCREEN matching the user's reference photograph 100%
/// Eliminates all bottom modal breaking / cut-offs!
class CellfinFormScreen extends StatefulWidget {
  final String title;
  final String officerName;
  final String officerInfo;
  final List<CellfinCardItem>? cards;
  final List<Widget> fields;
  final String submitText;
  final Future<void> Function() onSubmit;

  const CellfinFormScreen({
    super.key,
    required this.title,
    this.officerName = 'MD. ASHIKUR RAHMAN',
    this.officerInfo = '01748 031 295',
    this.cards,
    required this.fields,
    this.submitText = 'Submit',
    required this.onSubmit,
  });

  static Future<T?> push<T>({
    required BuildContext context,
    required String title,
    String? officerName,
    String? officerInfo,
    List<CellfinCardItem>? cards,
    required List<Widget> fields,
    String submitText = 'Submit',
    required Future<void> Function() onSubmit,
  }) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(
        builder: (_) => CellfinFormScreen(
          title: title,
          officerName: officerName ?? 'MD. ASHIKUR RAHMAN',
          officerInfo: officerInfo ?? '01748 031 295',
          cards: cards,
          fields: fields,
          submitText: submitText,
          onSubmit: onSubmit,
        ),
      ),
    );
  }

  @override
  State<CellfinFormScreen> createState() => _CellfinFormScreenState();
}

class _CellfinFormScreenState extends State<CellfinFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int _selectedCardIndex = 0;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final displayCards = widget.cards ??
        const [
          CellfinCardItem(title: 'CellFin', icon: Icons.phone_android_rounded),
          CellfinCardItem(
              title: 'Account', icon: Icons.account_balance_outlined),
          CellfinCardItem(title: 'Card', icon: Icons.credit_card_outlined),
          CellfinCardItem(
              title: 'mCash', icon: Icons.account_balance_wallet_outlined),
        ];

    return Scaffold(
      backgroundColor:
          const Color(0xFFF2F4F7), // Soft grey background matching photo
      appBar: AppBar(
        backgroundColor: const Color(0xFF136B3E), // Signature Forest Green
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── 1. TOP CARDS SYSTEM (Matches user photo top 4 cards) ─────────────
                CellfinTopCardsRow(
                  cards: displayCards,
                  selectedIndex: _selectedCardIndex,
                  onSelect: (index) =>
                      setState(() => _selectedCardIndex = index),
                ),

                const SizedBox(height: 14),

                // ─── 2. OFFICER / SENDER CARD ────────────────────────────────────────
                CellfinOfficerCard(
                  name: widget.officerName,
                  info: widget.officerInfo,
                ),

                const SizedBox(height: 14),

                // ─── 3. THE INPUT FIELDS ─────────────────────────────────────────────
                ...widget.fields.map(
                  (field) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: field,
                  ),
                ),

                const SizedBox(height: 10),

                // ─── 4. SOLID FOREST GREEN SUBMIT BUTTON (Never breaks!) ─────────────
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _isSubmitting = true);
                            try {
                              await widget.onSubmit();
                            } finally {
                              if (mounted)
                                setState(() => _isSubmitting = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF136B3E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.2),
                        )
                      : Text(
                          widget.submitText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),

                // Safe bottom padding so nothing is ever cut off or broken
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compatibility wrapper: Automatically redirects any CellfinFormModal.show() call
/// to open the gorgeous Full-Screen Form Screen so modals NEVER break at the bottom!
class CellfinFormModal {
  CellfinFormModal._();

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? officerName,
    String? officerInfo,
    List<CellfinCardItem>? cards,
    required List<Widget> fields,
    String submitText = 'Submit',
    required Future<void> Function() onSubmit,
  }) {
    return CellfinFormScreen.push<T>(
      context: context,
      title: title,
      officerName: officerName,
      officerInfo: officerInfo,
      cards: cards,
      fields: fields,
      submitText: submitText,
      onSubmit: onSubmit,
    );
  }
}
