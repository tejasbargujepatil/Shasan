import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  DateTime? subscriptionExpiry;
  final String upiLink = 'upi://pay?pa=8087194408@ibl&pn=ShasanMitra&am=99&cu=INR';
  final TextEditingController _codeController = TextEditingController();

  // Replace this with a secure code generation system offline or server-side
  final String validCode = 'SHASAN9'; // You change this monthly/week

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryMillis = prefs.getInt('subscriptionExpiry') ?? 0;

    if (expiryMillis != 0) {
      DateTime expiry = DateTime.fromMillisecondsSinceEpoch(expiryMillis);
      if (expiry.isAfter(DateTime.now())) {
        setState(() {
          subscriptionExpiry = expiry;
        });
      } else {
        await prefs.remove('subscriptionExpiry');
        setState(() {
          subscriptionExpiry = null;
        });
      }
    }
  }

  Future<void> _verifyAndActivate(String enteredCode) async {
    if (enteredCode.trim() != validCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Invalid code. Please contact support.")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final expiryDate = DateTime.now().add(const Duration(days: 30));
    await prefs.setInt('subscriptionExpiry', expiryDate.millisecondsSinceEpoch);
    setState(() {
      subscriptionExpiry = expiryDate;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("🎉 Premium activated until ${DateFormat.yMMMd().format(expiryDate)}")),
    );
  }

  Future<void> _cancelSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Subscription"),
        content: const Text("Are you sure you want to cancel your premium access?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
        ],
      ),
    );
    if (confirm == true) {
      await prefs.remove('subscriptionExpiry');
      setState(() {
        subscriptionExpiry = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Premium cancelled.")),
      );
    }
  }

  int _daysRemaining() {
    if (subscriptionExpiry == null) return 0;
    return subscriptionExpiry!.difference(DateTime.now()).inDays + 1;
  }

  bool get _isPremium => subscriptionExpiry != null && subscriptionExpiry!.isAfter(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Premium Subscription")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              _isPremium
                  ? "🌟 You are a Premium Member!"
                  : "Unlock Premium Access\n(₹99 / month)",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            if (_isPremium) ...[
              Text(
                "Your subscription is valid till:",
                style: TextStyle(color: Colors.grey[700]),
              ),
              Text(
                DateFormat.yMMMMd().format(subscriptionExpiry!),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "${_daysRemaining()} day(s) remaining",
                style: TextStyle(color: Colors.green[700]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.cancel),
                label: const Text("Cancel Subscription"),
                onPressed: _cancelSubscription,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ] else ...[
              QrImageView(data: upiLink, size: 250, backgroundColor: Colors.white),
              const SizedBox(height: 12),
              const Text("Pay ₹99 using any UPI app and get your unlock code."),
              const SizedBox(height: 20),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: "Enter Unlock Code",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.lock_open),
                label: const Text("Unlock Premium"),
                onPressed: () => _verifyAndActivate(_codeController.text),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


