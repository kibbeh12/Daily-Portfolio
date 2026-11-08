import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ink = Color(0xFF252720);
const _gold = Color(0xFFB88A44);
const _paper = Color(0xFFF7F6F2);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final prefs = await SharedPreferences.getInstance();
  runApp(DailyPortfolioApp(prefs: prefs));
}

class DailyPortfolioApp extends StatefulWidget {
  const DailyPortfolioApp({super.key, required this.prefs});
  final SharedPreferences prefs;

  @override
  State<DailyPortfolioApp> createState() => _DailyPortfolioAppState();
}

class _DailyPortfolioAppState extends State<DailyPortfolioApp> {
  late String _language = widget.prefs.getString('language') ?? '';
  late String _currency = widget.prefs.getString('currency') ?? '';

  Future<void> savePreferences({String? language, String? currency}) async {
    if (language != null) await widget.prefs.setString('language', language);
    if (currency != null) await widget.prefs.setString('currency', currency);

    setState(() {
      _language = language ?? _language;
      _currency = currency ?? _currency;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSetup = _language.isEmpty || _currency.isEmpty;
    final language = _language.isEmpty ? 'ar' : _language;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daily Portfolio',
      locale: Locale(language),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _paper,
        colorScheme: ColorScheme.fromSeed(seedColor: _gold, surface: _paper),
        appBarTheme: const AppBarTheme(backgroundColor: _paper, foregroundColor: _ink),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      home: isSetup
          ? SetupPage(onComplete: (lang, curr) => savePreferences(language: lang, currency: curr))
          : HomePage(
              prefs: widget.prefs,
              language: _language,
              currency: _currency,
              onPreferencesChanged: savePreferences,
            ),
    );
  }
}

class SetupPage extends StatefulWidget {
  const SetupPage({super.key, required this.onComplete});
  final Future<void> Function(String, String) onComplete;

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  String _language = 'ar';
  String _currency = 'USD';
  String _query = '';
  bool get _ar => _language == 'ar';

  @override
  Widget build(BuildContext context) {
    final currencies = currencyNames.entries.where((entry) =>
      entry.key.toLowerCase().contains(_query.toLowerCase()) ||
      entry.value.toLowerCase().contains(_query.toLowerCase())).toList();

    return Directionality(
      textDirection: _ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 20),
                  Container(
                    height: 66,
                    width: 66,
                    decoration: BoxDecoration(
                      color: _gold.withOpacity(.13),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined, color: _gold, size: 34),
                  ),
                  const SizedBox(height: 22),
                  const Text('Daily Portfolio', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w800, color: _ink)),
                  const SizedBox(height: 6),
                  Text(
                    _ar ? 'مصروفك اليومي، بوضوح وهدوء.' : 'Your daily spending, simply in view.',
                    style: const TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                  const SizedBox(height: 28),
                  Text(_ar ? 'اختر اللغة' : 'Choose language', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'ar', label: Text('العربية')),
                      ButtonSegment(value: 'en', label: Text('English')),
                    ],
                    selected: {_language},
                    onSelectionChanged: (value) => setState(() => _language = value.first),
                  ),
                  const SizedBox(height: 22),
                  Text(_ar ? 'اختر العملة' : 'Choose currency', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      hintText: _ar ? 'ابحث بالاسم أو الرمز' : 'Search by name or code',
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _query = value.trim()),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 230,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: currencies.isEmpty
                        ? Center(child: Text(_ar ? 'ما لقينا عملة بهذا البحث' : 'No currencies found'))
                        : ListView.builder(
                            itemCount: currencies.length,
                            itemBuilder: (context, index) {
                              final item = currencies[index];
                              return RadioListTile<String>(
                                dense: true,
                                value: item.key,
                                groupValue: _currency,
                                title: Text('${item.key} · ${item.value}'),
                                onChanged: (value) => setState(() => _currency = value!),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _ink, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () => widget.onComplete(_language, _currency),
                    child: Text(_ar ? 'ابدأ الآن' : 'Get started'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _ar ? 'بدون حساب. مصروفاتك محفوظة على جهازك.' : 'No account. Your expenses stay on this device.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
  });

  final String id;
  final double amount;
  final String category;
  final String note;
  final DateTime date;

  Map<String, Object?> toJson() => {
        'id': id,
        'amount': amount,
        'category': category,
        'note': note,
        'date': date.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String? ?? 'Other',
        note: json['note'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.prefs,
    required this.language,
    required this.currency,
    required this.onPreferencesChanged,
  });

  final SharedPreferences prefs;
  final String language;
  final String currency;
  final Future<void> Function({String? language, String? currency}) onPreferencesChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Expense> _expenses;
  late double _monthlyBudget;
  bool get _ar => widget.language == 'ar';

  @override
  void initState() {
    super.initState();
    _monthlyBudget = widget.prefs.getDouble('monthlyBudget') ?? 0;
    try {
      final list = jsonDecode(widget.prefs.getString('expenses') ?? '[]') as List<dynamic>;
      _expenses = list.map((item) => Expense.fromJson(item as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (_) {
      _expenses = [];
    }
  }

  Future<void> _persist() =>
      widget.prefs.setString('expenses', jsonEncode(_expenses.map((e) => e.toJson()).toList()));

  double _sum(Iterable<Expense> list) => list.fold(0, (total, expense) => total + expense.amount);

  String _money(double amount) =>
      '${NumberFormat('#,##0.##', _ar ? 'ar' : 'en').format(amount)} ${widget.currency}';

  Future<void> _addExpense() async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    var category = 'Food';

    final result = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _paper,
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_ar ? 'مصروف جديد' : 'New expense', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _ar ? 'المبلغ' : 'Amount',
                  suffixText: widget.currency,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                decoration: InputDecoration(labelText: _ar ? 'التصنيف' : 'Category'),
                items: expenseCategories
                    .map((key) => DropdownMenuItem(value: key, child: Text(_categoryName(key))))
                    .toList(),
                onChanged: (value) => setModal(() => category = value ?? 'Other'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLength: 80,
                decoration: InputDecoration(
                  labelText: _ar ? 'ملاحظة (اختياري)' : 'Note (optional)',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text.trim().replaceAll(',', '.'));
                  if (amount != null && amount > 0) {
                    Navigator.pop(
                      context,
                      Expense(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        amount: amount,
                        category: category,
                        note: noteController.text.trim(),
                        date: DateTime.now(),
                      ),
                    );
                  }
                },
                child: Text(_ar ? 'حفظ المصروف' : 'Save expense'),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() => _expenses.insert(0, result));
      await _persist();
    }
  }

  String _categoryName(String category) {
    if (!_ar) return category;
    return const {
      'Food': 'طعام',
      'Transport': 'مواصلات',
      'Shopping': 'تسوق',
      'Bills': 'فواتير',
      'Health': 'صحة',
      'Entertainment': 'ترفيه',
      'Home': 'منزل',
      'Other': 'أخرى',
    }[category] ?? category;
  }

  IconData _categoryIcon(String category) => const {
        'Food': Icons.restaurant,
        'Transport': Icons.directions_bus,
        'Shopping': Icons.shopping_bag_outlined,
        'Bills': Icons.receipt_long,
        'Health': Icons.favorite_border,
        'Entertainment': Icons.movie_outlined,
        'Home': Icons.home_outlined,
      }[category] ?? Icons.more_horiz;

  Future<void> _setBudget() async {
    final controller = TextEditingController(
      text: _monthlyBudget == 0 ? '' : _monthlyBudget.toStringAsFixed(2),
    );

    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_ar ? 'الميزانية الشهرية' : 'Monthly budget'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: _ar ? 'المبلغ' : 'Amount',
            suffixText: widget.currency,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(_ar ? 'إلغاء' : 'Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              double.tryParse(controller.text.trim().replaceAll(',', '.')),
            ),
            child: Text(_ar ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );

    if (value != null && value >= 0) {
      setState(() => _monthlyBudget = value);
      await widget.prefs.setDouble('monthlyBudget', value);
    }
  }

  Future<void> _settings() async {
    final result = await showModalBottomSheet<_AppSettings>(
      context: context,
      backgroundColor: _paper,
      builder: (context) => SettingsSheet(
        language: widget.language,
        currency: widget.currency,
        onBudget: () {
          Navigator.pop(context);
          _setBudget();
        },
      ),
    );

    if (result != null) {
      await widget.onPreferencesChanged(language: result.language, currency: result.currency);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayExpenses =
        _expenses.where((e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day);
    final monthExpenses = _expenses.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
    final todayTotal = _sum(todayExpenses);
    final monthTotal = _sum(monthExpenses);
    final budgetProgress = _monthlyBudget <= 0 ? 0.0 : (monthTotal / _monthlyBudget).clamp(0.0, 1.0);

    return Directionality(
      textDirection: _ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daily Portfolio', style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              tooltip: _ar ? 'الإعدادات' : 'Settings',
              onPressed: _settings,
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addExpense,
          backgroundColor: _ink,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(_ar ? 'أضف مصروف' : 'Add expense'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
          children: [
            Text(DateFormat.yMMMMEEEEd(_ar ? 'ar' : 'en').format(now), style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_ar ? 'مصروف اليوم' : \"Today's spending\", style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(_money(todayTotal), style: const TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 18),
                  const Divider(color: Colors.white24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_ar ? 'هذا الشهر' : 'This month', style: const TextStyle(color: Colors.white70)),
                      Text(
                        _money(monthTotal),
                        style: const TextStyle(color: Color(0xFFE2C17E), fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_ar ? 'ميزانية الشهر' : 'Monthly budget', style: const TextStyle(fontWeight: FontWeight.w700)),
                        TextButton(
                          onPressed: _setBudget,
                          child: Text(_monthlyBudget <= 0 ? (_ar ? 'تحديد' : 'Set') : (_ar ? 'تعديل' : 'Edit')),
                        ),
                      ],
                    ),
                    if (_monthlyBudget <= 0)
                      Text(
                        _ar ? 'حدد ميزانيتك لمتابعة مصروفاتك' : 'Set a budget to keep spending on track',
                        style: const TextStyle(color: Colors.black54),
                      )
                    else ...[
                      Text(
                        '${_money(monthTotal)} / ${_money(_monthlyBudget)}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: budgetProgress,
                          minHeight: 8,
                          color: monthTotal > _monthlyBudget ? Colors.redAccent : _gold,
                          backgroundColor: _paper,
                        ),
                      ),
                      if (monthTotal > _monthlyBudget)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _ar ? 'تجاوزت الميزانية الشهرية' : 'You are over your monthly budget',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_ar ? 'مصروفات هذا الشهر' : 'This month', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                Text('${monthExpenses.length}', style: const TextStyle(color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 8),
            if (_expenses.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 40, color: _gold),
                      const SizedBox(height: 10),
                      Text(_ar ? 'ما سجلت أي مصروف لسه' : 'No expenses recorded yet', style: const TextStyle(color: Colors.black54)),
                      Text(_ar ? 'اضغط «أضف مصروف» للبدء' : 'Tap “Add expense” to get started', style: const TextStyle(color: Colors.black38)),
                    ],
                  ),
                ),
              )
            else
              ..._expenses.take(100).map(
                (expense) => Dismissible(
                  key: ValueKey(expense.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    setState(() => _expenses.removeWhere((e) => e.id == expense.id));
                    await _persist();
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _gold.withOpacity(.12),
                        child: Icon(_categoryIcon(expense.category), color: _gold),
                      ),
                      title: Text(_categoryName(expense.category)),
                      subtitle: Text(
                        '${expense.note.isEmpty ? '' : '${expense.note} · '}${DateFormat.yMMMd(_ar ? 'ar' : 'en').add_jm().format(expense.date)}',
                      ),
                      trailing: Text(
                        '-${_money(expense.amount)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const expenseCategories = ['Food', 'Transport', 'Shopping', 'Bills', 'Health', 'Entertainment', 'Home', 'Other'];

class _AppSettings {
  const _AppSettings(this.language, this.currency);
  final String language;
  final String currency;
}

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key, required this.language, required this.currency, required this.onBudget});
  final String language;
  final String currency;
  final VoidCallback onBudget;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late String _language = widget.language;
  late String _currency = widget.currency;
  String _query = '';
  bool get _ar => _language == 'ar';

  @override
  Widget build(BuildContext context) {
    final currencies = currencyNames.entries
        .where((entry) =>
            entry.key.toLowerCase().contains(_query.toLowerCase()) ||
            entry.value.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return SafeArea(
      child: Directionality(
        textDirection: _ar ? TextDirection.rtl : TextDirection.ltr,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .78,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _ar ? 'الإعدادات' : 'Settings',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, _AppSettings(_language, _currency)),
                      child: Text(_ar ? 'تم' : 'Done'),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(_ar ? 'تحديد الميزانية الشهرية' : 'Set monthly budget'),
                onTap: widget.onBudget,
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(_ar ? 'اللغة' : 'Language', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'ar', label: Text('العربية')),
                    ButtonSegment(value: 'en', label: Text('English')),
                  ],
                  selected: {_language},
                  onSelectionChanged: (value) => setState(() => _language = value.first),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: _ar ? 'ابحث عن العملة' : 'Search currency',
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _query = value.trim()),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: currencies.length,
                  itemBuilder: (context, index) {
                    final item = currencies[index];
                    return RadioListTile<String>(
                      dense: true,
                      value: item.key,
                      groupValue: _currency,
                      title: Text('${item.key} · ${item.value}'),
                      onChanged: (value) => setState(() => _currency = value!),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const currencyNames = <String, String>{
  'AED': 'UAE Dirham',
  'AFN': 'Afghan Afghani',
  'ALL': 'Albanian Lek',
  'AMD': 'Armenian Dram',
  'ANG': 'Netherlands Antillean Guilder',
  'AOA': 'Angolan Kwanza',
  'ARS': 'Argentine Peso',
  'AUD': 'Australian Dollar',
  'AWG': 'Aruban Florin',
  'AZN': 'Azerbaijani Manat',
  'BAM': 'Convertible Mark',
  'BBD': 'Barbados Dollar',
  'BDT': 'Bangladeshi Taka',
  'BGN': 'Bulgarian Lev',
  'BHD': 'Bahraini Dinar',
  'BIF': 'Burundian Franc',
  'BMD': 'Bermudian Dollar',
  'BND': 'Brunei Dollar',
  'BOB': 'Bolivian Boliviano',
  'BRL': 'Brazilian Real',
  'BSD': 'Bahamian Dollar',
  'BTN': 'Bhutanese Ngultrum',
  'BWP': 'Botswana Pula',
  'BYN': 'Belarusian Ruble',
  'BZD': 'Belize Dollar',
  'CAD': 'Canadian Dollar',
  'CDF': 'Congolese Franc',
  'CHF': 'Swiss Franc',
  'CLP': 'Chilean Peso',
  'CNY': 'Chinese Yuan',
  'COP': 'Colombian Peso',
  'CRC': 'Costa Rican Colon',
  'CUP': 'Cuban Peso',
  'CVE': 'Cabo Verde Escudo',
  'CZK': 'Czech Koruna',
  'DJF': 'Djiboutian Franc',
  'DKK': 'Danish Krone',
  'DOP': 'Dominican Peso',
  'DZD': 'Algerian Dinar',
  'EGP': 'Egyptian Pound',
  'ERN': 'Eritrean Nakfa',
  'ETB': 'Ethiopian Birr',
  'EUR': 'Euro',
  'FJD': 'Fiji Dollar',
  'FKP': 'Falkland Islands Pound',
  'GBP': 'Pound Sterling',
  'GEL': 'Georgian Lari',
  'GHS': 'Ghanaian Cedi',
  'GIP': 'Gibraltar Pound',
  'GMD': 'Dalasi',
  'GNF': 'Guinean Franc',
  'GTQ': 'Guatemalan Quetzal',
  'GYD': 'Guyanese Dollar',
  'HKD': 'Hong Kong Dollar',
  'HNL': 'Honduran Lempira',
  'HTG': 'Haitian Gourde',
  'HUF': 'Hungarian Forint',
  'IDR': 'Indonesian Rupiah',
  'ILS': 'Israeli New Shekel',
  'INR': 'Indian Rupee',
  'IQD': 'Iraqi Dinar',
  'IRR': 'Iranian Rial',
  'ISK': 'Icelandic Króna',
  'JMD': 'Jamaican Dollar',
  'JOD': 'Jordanian Dinar',
  'JPY': 'Japanese Yen',
  'KES': 'Kenyan Shilling',
  'KGS': 'Kyrgyzstani Som',
  'KHR': 'Cambodian Riel',
  'KMF': 'Comorian Franc',
  'KPW': 'North Korean Won',
  'KRW': 'South Korean Won',
  'KWD': 'Kuwaiti Dinar',
  'KYD': 'Cayman Islands Dollar',
  'KZT': 'Kazakhstani Tenge',
  'LAK': 'Lao Kip',
  'LBP': 'Lebanese Pound',
  'LKR': 'Sri Lankan Rupee',
  'LRD': 'Liberian Dollar',
  'LSL': 'Lesotho Loti',
  'LYD': 'Libyan Dinar',
  'MAD': 'Moroccan Dirham',
  'MDL': 'Moldovan Leu',
  'MGA': 'Malagasy Ariary',
  'MKD': 'Macedonian Denar',
  'MMK': 'Myanmar Kyat',
  'MNT': 'Mongolian Tögrög',
  'MOP': 'Macanese Pataca',
  'MRU': 'Mauritanian Ouguiya',
  'MUR': 'Mauritian Rupee',
  'MVR': 'Maldivian Rufiyaa',
  'MWK': 'Malawian Kwacha',
  'MXN': 'Mexican Peso',
  'MYR': 'Malaysian Ringgit',
  'MZN': 'Mozambican Metical',
  'NAD': 'Namibian Dollar',
  'NGN': 'Nigerian Naira',
  'NIO': 'Nicaraguan Córdoba',
  'NOK': 'Norwegian Krone',
  'NPR': 'Nepalese Rupee',
  'NZD': 'New Zealand Dollar',
  'OMR': 'Omani Rial',
  'PAB': 'Panamanian Balboa',
  'PEN': 'Peruvian Sol',
  'PGK': 'Papua New Guinean Kina',
  'PHP': 'Philippine Peso',
  'PKR': 'Pakistani Rupee',
  'PLN': 'Polish Złoty',
  'PYG': 'Paraguayan Guaraní',
  'QAR': 'Qatari Riyal',
  'RON': 'Romanian Leu',
  'RSD': 'Serbian Dinar',
  'RUB': 'Russian Ruble',
  'RWF': 'Rwandan Franc',
  'SAR': 'Saudi Riyal',
  'SBD': 'Solomon Islands Dollar',
  'SCR': 'Seychelles Rupee',
  'SDG': 'Sudanese Pound',
  'SEK': 'Swedish Krona',
  'SGD': 'Singapore Dollar',
  'SHP': 'Saint Helena Pound',
  'SLE': 'Sierra Leonean Leone',
  'SOS': 'Somali Shilling',
  'SRD': 'Surinamese Dollar',
  'SSP': 'South Sudanese Pound',
  'STN': 'São Tomé and Príncipe Dobra',
  'SYP': 'Syrian Pound',
  'SZL': 'Swazi Lilangeni',
  'THB': 'Thai Baht',
  'TJS': 'Tajikistani Somoni',
  'TMT': 'Turkmenistan Manat',
  'TND': 'Tunisian Dinar',
  'TOP': 'Tongan Paʻanga',
  'TRY': 'Turkish Lira',
  'TTD': 'Trinidad and Tobago Dollar',
  'TWD': 'New Taiwan Dollar',
  'TZS': 'Tanzanian Shilling',
  'UAH': 'Ukrainian Hryvnia',
  'UGX': 'Ugandan Shilling',
  'USD': 'US Dollar',
  'UYU': 'Uruguayan Peso',
  'UZS': 'Uzbekistan Som',
  'VES': 'Venezuelan Bolívar',
  'VND': 'Vietnamese Đồng',
  'VUV': 'Vanuatu Vatu',
  'WST': 'Samoan Tala',
  'XAF': 'Central African CFA Franc',
  'XCD': 'East Caribbean Dollar',
  'XOF': 'West African CFA Franc',
  'XPF': 'CFP Franc',
  'YER': 'Yemeni Rial',
  'ZAR': 'South African Rand',
  'ZMW': 'Zambian Kwacha',
  'ZWL': 'Zimbabwean Dollar',
};
