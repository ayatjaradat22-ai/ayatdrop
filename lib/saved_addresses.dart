import 'package:flutter/material.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  static const Color dropRed = Color(0xFFFF1111); // الأحمر الموحد للهوية

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Saved Addresses",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 20),
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
                  const Padding(
                    padding: EdgeInsets.only(left: 5, bottom: 20),
                    child: Text(
                      "Where should we drop your deals?",
                      style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),

                  // بطاقة عنوان المنزل
                  _buildAddressTile(
                    title: "Home",
                    address: "Address, Vancouver, BC V6B 4G1",
                    icon: Icons.home_rounded,
                    isDefault: true,
                  ),

                  // بطاقة عنوان العمل
                  _buildAddressTile(
                    title: "Office",
                    address: "725 Granville St, Vancouver, BC V7Y 1G5",
                    icon: Icons.work_rounded,
                    isDefault: false,
                  ),
                ],
              ),
            ),

            // زر إضافة عنوان جديد في الأسفل بشكل ثابت
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_location_alt_rounded, color: dropRed, size: 20),
                  label: const Text("Add New Address",
                      style: TextStyle(color: dropRed, fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildAddressTile({
    required String title,
    required String address,
    required IconData icon,
    required bool isDefault
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDefault ? dropRed.withOpacity(0.3) : Colors.grey.shade100),
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
              color: isDefault ? dropRed.withOpacity(0.1) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: isDefault ? dropRed : Colors.grey[400], size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: dropRed, borderRadius: BorderRadius.circular(5)),
                        child: const Text("DEFAULT", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
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
                icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}