import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_sejahtera_ng/core/widgets/glass_container.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_sejahtera_ng/features/vaccine/screens/widgets/digital_cert_card.dart';
import 'package:my_sejahtera_ng/features/vaccine/screens/widgets/add_vaccine_sheet.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:my_sejahtera_ng/core/providers/user_provider.dart';
import 'package:my_sejahtera_ng/features/vaccine/services/pdf_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class VaccineScreen extends ConsumerStatefulWidget {
  const VaccineScreen({super.key});

  @override
  ConsumerState<VaccineScreen> createState() => _VaccineScreenState();
}

class _VaccineScreenState extends ConsumerState<VaccineScreen> {
  List<Map<String, dynamic>> _vaccineRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVaccineRecords();
  }

  Future<void> _fetchVaccineRecords() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user != null) {
        final data = await supabase
            .from('vaccine_records')
            .select()
            .eq('user_id', user.id)
            .order('dose_number');
            
        setState(() {
          _vaccineRecords = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching vaccines: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(""), // Clean look
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddVaccineSheet(
              onSaved: _fetchVaccineRecords,
            ),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F2027), Color(0xFF2C5364)], // Deep premium dark
          ),
        ),
        child: SafeArea(
          child: Column(
             children: [
               const SizedBox(height: 10),
               // Title
               Text("My Digital Certificate", style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
               const SizedBox(height: 10),
               
               // Main Carousel Content
               Expanded(
                 child: PageView(
                   controller: PageController(viewportFraction: 0.85),
                   physics: const BouncingScrollPhysics(),
                   children: [
                     // Card 1: The Main Certificate
                     Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                       child: Center(
                          child: Stack(
                            children: [
                              const DigitalCertCard(),
                              if (_isLoading)
                                Positioned.fill(child: Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator())))
                            ],
                          )
                       ),
                     ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                     
                     // Card 2: Dose Details
                     Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                       child: Center(child: _buildDoseHistoryCard()),
                     ),
                   ],
                 ),
               ),
               
               const SizedBox(height: 20),
               
               // Indicators (Dots)
               Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                   const SizedBox(width: 8),
                   Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle)),
                 ],
               ),
               
               const SizedBox(height: 30),
               
               // Action Button
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 40),
                 child: SizedBox(
                   width: double.infinity,
                   child: ElevatedButton.icon(
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.white.withOpacity(0.1),
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: const BorderSide(color: Colors.white30))
                     ),
                     onPressed: _isLoading ? null : () async {
                        final user = ref.read(userProvider);
                        if (user != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Generating PDF... Please wait.")),
                          );
                          try {
                            print("Starting PDF generation for user: ${user.fullName}");
                            await PdfService().generateAndShareCertificate(user);
                            print("PDF generation completed.");
                          } catch (e, stack) {
                            print("Error generating PDF: $e\n$stack");
                             if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            }
                          }
                        } else {
                          print("User is null!");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Error: User not logged in found.")),
                          );
                        }
                     }, 
                     icon: const Icon(LucideIcons.download),
                     label: const Text("Export PDF"),
                   ),
                 ),
               ),
               const SizedBox(height: 20),
             ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoseHistoryCard() {
    return GlassContainer(
      height: 500,
      width: double.infinity,
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(30),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.history, color: Colors.blueAccent),
              const SizedBox(width: 10),
              Text("VACCINATION RECORD", style: GoogleFonts.shareTechMono(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                : _vaccineRecords.isEmpty 
                    ? const Center(child: Text("No records found", style: TextStyle(color: Colors.white54)))
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: _vaccineRecords.length,
                        separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 30),
                        itemBuilder: (context, index) {
                          final record = _vaccineRecords[index];
                          return InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => AddVaccineSheet(
                                  initialRecord: record,
                                  onSaved: _fetchVaccineRecords,
                                ),
                              );
                            },
                            child: _buildDoseItem(
                              record['dose_number'].toString(),
                              record['vaccine_name'] ?? 'Unknown',
                              DateFormat('dd MMM yyyy').format(DateTime.parse(record['date_administered'])),
                              record['location'] ?? 'Unknown Location',
                              record['batch_number'] ?? '-',
                            ),
                          );
                        },
                      ),
          ),
          // Demo Button to generate data if empty
          if (!_isLoading && _vaccineRecords.isEmpty)
             TextButton(
               onPressed: () async {
                  setState(() => _isLoading = true);
                  await Supabase.instance.client.rpc('generate_demo_vaccine_record');
                  await _fetchVaccineRecords();
               },
               child: const Text("Generate Demo Records", style: TextStyle(color: Colors.blueAccent)),
             )
        ],
      ),
    );
  }

  Widget _buildDoseItem(String num, String name, String date, String loc, String batch) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("DOSE $num", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
              child: const Text("COMPLETED", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 5),
        Text(name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(date, style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(LucideIcons.mapPin, size: 12, color: Colors.white30),
            const SizedBox(width: 4),
            Expanded(child: Text(loc, style: const TextStyle(color: Colors.white38, fontSize: 12), overflow: TextOverflow.ellipsis)),
          ],
        ),
        Text("Batch: $batch", style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    ).animate().fadeIn().slideX();
  }
}
