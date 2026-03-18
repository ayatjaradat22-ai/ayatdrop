import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  static const Color dropRed = Color(0xFFFF1111);

    @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "saved_addresses".tr(),
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                   Padding(
                    padding: const EdgeInsets.only(left: 5, bottom: 20),
                    child: Text(
                      "address_subtitle".tr(),
                      style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),

                  _buildAddressTile(
                    context,
                    title: "home_label".tr(),
                    address: "Address, Vancouver, BC V6B 4G1",
                    icon: Icons.home_rounded,
                    isDefault: true,
                  ),

                  _buildAddressTile(
                    context,
                    title: "office_label".tr(),
                    address: "725 Granville St, Vancouver, BC V7Y 1G5",
                    icon: Icons.work_rounded,
                    isDefault: false,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(25.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_location_alt_rounded, color: dropRed, size: 20),
                  label: Text("add_new_address".tr(),
                      style: const TextStyle(color: dropRed, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: dropRed, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressTile(
    BuildContext context, {
    required String title,
    required String address,
    required IconData icon,
    required bool isDefault
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDefault ? dropRed.withOpacity(0.3) : (isDark ? Colors.white10 : Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDefault ? dropRed.withOpacity(0.1) : (isDark ? Colors.white10 : Colors.grey.shade50),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: isDefault ? dropRed : (isDark ? Colors.white54 : Colors.grey[400]), size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: dropRed, borderRadius: BorderRadius.circular(5)),
                        child: Text("default_badge".tr(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 5),
                Text(address, style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: Icon(Icons.edit_outlined, color: isDark ? Colors.white54 : Colors.grey, size: 20),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}