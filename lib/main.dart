import 'dart:convert';
import 'dart:ui' as ui;

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
  await initializeDateFormatting('ar');
  await initializeDateFormatting('en');
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

  Future<void> _savePreferences({String? language, String? currency}) async {
    if (language != null) {
      await widget.prefs.setString('language', language);
    }
    if (currency != null) {
      await widget.prefs.setString('currency', currency);
    }

    if (!mounted) return;
    setState(() {
      _language = language ?? _language;
      _currency = currency ?? _currency;
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = _language.isEmpty ? 'ar' : _language;
    final needsSetup = _language.isEmpty || _currency.isEmpty;

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: _gold,
          surface: _paper,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _paper,
          foregroundColor: _ink,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      home: needsSetup
          ? SetupPage(onComplete: (language, currency) {
              return _savePreferences(
                language: language,
                currency: currency,
              );
            })
          : HomePage(
              prefs: widget.prefs,
              language: _language,
              currency: _currency,
              onPreferencesChanged: _savePreferences,
            ),
    );
  }
}

class SetupPage extends StatefulWidget {
  const SetupPage({super.key, required this.onComplete});

  final Future<void> Function(String language, String currency) onComplete;

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  String _language = 'ar';
  String _currency = 'USD';
  String _query = '';

  bool get _isArabic => _language == 'ar';

  @override
  Widget build(BuildContext context) {
    final currencies = currencyNames.entries.where((entry) {
      final query = _query.toLowerCase();
      return entry.key.toLowerCase().contains(query) ||
          entry.value.toLowerCase().contains(query);
    }).toList();

    return Directionality(
      textDirection:
          _isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 20),
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: _gold,
                    size: 58,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Daily Portfolio',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isArabic
                        ? 'مصروفك اليومي، بوضوح وهدوء.'
                        : 'Your daily spending, simply in view.',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _isArabic ? 'اختر اللغة' : 'Choose language',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'ar',
                        label: Text('العربية'),
                      ),
                      ButtonSegment(
                        value: 'en',
                        label: Text('English'),
                      ),
                    ],
                    selected: {_language},
                    onSelectionChanged: (value) {
                      setState(() => _language = value.first);
                    },
                  ),
                  const SizedBox(height: 22),
                  Text(
                    _isArabic ? 'اختر العملة' : 'Choose currency',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      hintText: _isArabic
                          ? 'ابحث بالاسم أو الرمز'
                          : 'Search by name or code',
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() => _query = value.trim());
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 230,
                    child: Card(
                      child: currencies.isEmpty
                          ? Center(
                              child: Text(
                                _isArabic
                                    ? 'ما لقينا عملة بهذا البحث'
                                    : 'No currencies found',
                              ),
                            )
                          : ListView.builder(
                              itemCount: currencies.length,
                              itemBuilder: (context, index) {
                                final item = currencies[index];
                                return RadioListTile<String>(
                                  dense: true,
                                  value: item.key,
                                  groupValue: _currency,
                                  title: Text('${item.key} · ${item.value}'),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _currency = value);
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _ink,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => widget.onComplete(_language, _currency),
                    child: Text(_isArabic ? 'ابدأ الآن' : 'Get started'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isArabic
                        ? 'بدون حساب. مصروفاتك محفوظة على جهازك.'
                        : 'No account. Your expenses stay on this device.',
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

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String? ?? 'Other',
      note: json['note'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
    );
  }
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
  final Future<void> Function({
    String? language,
    String? currency,
  }) onPreferencesChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Expense> _expenses;
  late double _monthlyBudget;

  bool get _isArabic => widget.language == 'ar';

  @override
  void initState() {
    super.initState();
    _monthlyBudget = widget.prefs.getDouble('monthlyBudget') ?? 0;

    try {
      final saved = jsonDecode(
        widget.prefs.getString('expenses') ?? '[]',
      ) as List<dynamic>;

      _expenses = saved
          .map(
            (item) => Expense.fromJson(item as Map<String, dynamic>),
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (_) {
      _expenses = [];
    }
  }

  Future<void> _persistExpenses() {
    final json = jsonEncode(
      _expenses.map((expense) => expense.toJson()).toList(),
    );
    return widget.prefs.setString('expenses', json);
  }

  double _sum(Iterable<Expense> expenses) {
    return expenses.fold(0, (total, expense) => total + expense.amount);
  }

  String _money(double amount) {
    final locale = _isArabic ? 'ar' : 'en';
    return '${NumberFormat('#,##0.##', locale).format(amount)} ${widget.currency}';
  }

  String _categoryName(String category) {
    if (!_isArabic) return category;

    return const {
          'Food': 'طعام',
          'Transport': 'مواصلات',
          'Shopping': 'تسوق',
          'Bills': 'فواتير',
          'Health': 'صحة',
          'Entertainment': 'ترفيه',
          'Home': 'منزل',
          'Other': 'أخرى',
        }[category] ??
        category;
  }

  IconData _categoryIcon(String category) {
    return const {
          'Food': Icons.restaurant,
          'Transport': Icons.directions_bus,
          'Shopping': Icons.shopping_bag_outlined,
          'Bills': Icons.receipt_long,
          'Health': Icons.favorite_border,
          'Entertainment': Icons.movie_outlined,
          'Home': Icons.home_outlined,
        }[category] ??
        Icons.more_horiz;
  }

  Future<void> _addExpense() async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    var category = 'Food';

    final expense = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _paper,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isArabic ? 'مصروف جديد' : 'New expense',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _isArabic ? 'المبلغ' : 'Amount',
                      suffixText: widget.currency,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(
                      labelText: _isArabic ? 'التصنيف' : 'Category',
                    ),
                    items: expenseCategories.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(_categoryName(item)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() => category = value ?? 'Other');
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLength: 80,
                    decoration: InputDecoration(
                      labelText:
                          _isArabic ? 'ملاحظة (اختياري)' : 'Note (optional)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {
                      final amount = double.tryParse(
                        amountController.text.trim().replaceAll(',', '.'),
                      );

                      if (amount != null && amount > 0) {
                        Navigator.pop(
                          sheetContext,
                          Expense(
                            id: DateTime.now()
                                .microsecondsSinceEpoch
                                .toString(),
                            amount: amount,
                            category: category,
                            note: noteController.text.trim(),
                            date: DateTime.now(),
                          ),
                        );
                      }
                    },
                    child: Text(
                      _isArabic ? 'حفظ المصروف' : 'Save expense',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    amountController.dispose();
    noteController.dispose();

    if (expense != null) {
      setState(() => _expenses.insert(0, expense));
      await _persistExpenses();
    }
  }

  Future<void> _setBudget() async {
    final controller = TextEditingController(
      text: _monthlyBudget == 0 ? '' : _monthlyBudget.toString(),
    );

    final budget = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_isArabic ? 'الميزانية الشهرية' : 'Monthly budget'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: _isArabic ? 'المبلغ' : 'Amount',
              suffixText: widget.currency,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_isArabic ? 'إلغاء' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(
                  controller.text.trim().replaceAll(',', '.'),
                );
                Navigator.pop(context, value);
              },
              child: Text(_isArabic ? 'حفظ' : 'Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (budget != null && budget >= 0) {
      setState(() => _monthlyBudget = budget);
      await widget.prefs.setDouble('monthlyBudget', budget);
    }
  }

  Future<void> _openSettings() async {
    final result = await showModalBottomSheet<AppSettings>(
      context: context,
      backgroundColor: _paper,
      builder: (context) {
        return SettingsSheet(
          language: widget.language,
          currency: widget.currency,
        );
      },
    );

    if (result != null) {
      await widget.onPreferencesChanged(
        language: result.language,
        currency: result.currency,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final todayExpenses = _expenses.where((expense) {
      return expense.date.year == now.year &&
          expense.date.month == now.month &&
          expense.date.day == now.day;
    });

    final monthExpenses = _expenses.where((expense) {
      return expense.date.year == now.year &&
          expense.date.month == now.month;
    }).toList();

    final todayTotal = _sum(todayExpenses);
    final monthTotal = _sum(monthExpenses);
    final budgetProgress = _monthlyBudget <= 0
        ? 0.0
        : (monthTotal / _monthlyBudget).clamp(0.0, 1.0);

    return Directionality(
      textDirection:
          _isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Daily Portfolio',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: _isArabic ? 'الإعدادات' : 'Settings',
              onPressed: _openSettings,
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addExpense,
          backgroundColor: _ink,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(_isArabic ? 'أضف مصروف' : 'Add expense'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
          children: [
            Text(
              DateFormat.yMMMMEEEEd(_isArabic ? 'ar' : 'en').format(now),
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isArabic ? 'مصروف اليوم' : "Today's spending",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _money(todayTotal),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: Colors.white24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isArabic ? 'هذا الشهر' : 'This month',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        _money(monthTotal),
                        style: const TextStyle(
                          color: Color(0xFFE2C17E),
                          fontWeight: FontWeight.w700,
                        ),
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
                        Text(
                          _isArabic ? 'ميزانية الشهر' : 'Monthly budget',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextButton(
                          onPressed: _setBudget,
                          child: Text(
                            _monthlyBudget <= 0
                                ? (_isArabic ? 'تحديد' : 'Set')
                                : (_isArabic ? 'تعديل' : 'Edit'),
                          ),
                        ),
                      ],
                    ),
                    if (_monthlyBudget <= 0)
                      Text(
                        _isArabic
                            ? 'حدد ميزانيتك لمتابعة مصروفاتك'
                            : 'Set a budget to keep spending on track',
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
                          color: monthTotal > _monthlyBudget
                              ? Colors.redAccent
                              : _gold,
                          backgroundColor: _paper,
                        ),
                      ),
                      if (monthTotal > _monthlyBudget)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _isArabic
                                ? 'تجاوزت الميزانية الشهرية'
                                : 'You are over your monthly budget',
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
                Text(
                  _isArabic ? 'مصروفات هذا الشهر' : 'This month',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${monthExpenses.length}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_expenses.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 40,
                        color: _gold,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isArabic
                            ? 'ما سجلت أي مصروف لسه'
                            : 'No expenses recorded yet',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      Text(
                        _isArabic
                            ? 'اضغط «أضف مصروف» للبدء'
                            : 'Tap “Add expense” to get started',
                        style: const TextStyle(color: Colors.black38),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._expenses.take(100).map((expense) {
                return Dismissible(
                  key: ValueKey(expense.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: AlignmentDirectional.centerStart,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (_) async {
                    setState(() {
                      _expenses.removeWhere((item) => item.id == expense.id);
                    });
                    await _persistExpenses();
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _gold.withOpacity(.12),
                        child: Icon(
                          _categoryIcon(expense.category),
                          color: _gold,
                        ),
                      ),
                      title: Text(_categoryName(expense.category)),
                      subtitle: Text(
                        '${expense.note.isEmpty ? '' : '${expense.note} · '}${DateFormat.yMMMd(_isArabic ? 'ar' : 'en').add_jm().format(expense.date)}',
                      ),
                      trailing: Text(
                        '-${_money(expense.amount)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class AppSettings {
  const AppSettings(this.language, this.currency);

  final String language;
  final String currency;
}

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({
    super.key,
    required this.language,
    required this.currency,
  });

  final String language;
  final String currency;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late String _language = widget.language;
  late String _currency = widget.currency;
  String _query = '';

  bool get _isArabic => _language == 'ar';

  @override
  Widget build(BuildContext context) {
    final currencies = currencyNames.entries.where((entry) {
      final query = _query.toLowerCase();
      return entry.key.toLowerCase().contains(query) ||
          entry.value.toLowerCase().contains(query);
    }).toList();

    return SafeArea(
      child: Directionality(
        textDirection:
            _isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.78,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isArabic ? 'الإعدادات' : 'Settings',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          AppSettings(_language, _currency),
                        );
                      },
                      child: Text(_isArabic ? 'تم' : 'Done'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    _isArabic ? 'اللغة' : 'Language',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                  onSelectionChanged: (value) {
                    setState(() => _language = value.first);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: TextField(
                  decoration: InputDecoration(
                    hintText:
                        _isArabic ? 'ابحث عن العملة' : 'Search currency',
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() => _query = value.trim());
                  },
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
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _currency = value);
                        }
                      },
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

const expenseCategories = [
  'Food',
  'Transport',
  'Shopping',
  'Bills',
  'Health',
  'Entertainment',
  'Home',
  'Other',
];

const currencyNames = <String, String>{
  'AED': 'UAE Dirham',
  'AFN': 'Afghan Afghani',
  'ALL': 'Albanian Lek',
  'AMD': 'Armenian Dram',
  'ARS': 'Argentine Peso',
  'AUD': 'Australian Dollar',
  'BHD': 'Bahraini Dinar',
  'BRL': 'Brazilian Real',
  'CAD': 'Canadian Dollar',
  'CHF': 'Swiss Franc',
  'CNY': 'Chinese Yuan',
  'EGP': 'Egyptian Pound',
  'EUR': 'Euro',
  'GBP': 'Pound Sterling',
  'INR': 'Indian Rupee',
  'IQD': 'Iraqi Dinar',
  'JOD': 'Jordanian Dinar',
  'JPY': 'Japanese Yen',
  'KWD': 'Kuwaiti Dinar',
  'LBP': 'Lebanese Pound',
  'MAD': 'Moroccan Dirham',
  'OMR': 'Omani Rial',
  'PKR': 'Pakistani Rupee',
  'QAR': 'Qatari Riyal',
  'SAR': 'Saudi Riyal',
  'SYP': 'Syrian Pound',
  'TND': 'Tunisian Dinar',
  'TRY': 'Turkish Lira',
  'USD': 'US Dollar',
  'YER': 'Yemeni Rial',
  'ZAR': 'South African Rand',
};
