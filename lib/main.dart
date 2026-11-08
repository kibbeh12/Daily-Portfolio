import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DailyPortfolioApp());
}

class DailyPortfolioApp extends StatefulWidget {
  const DailyPortfolioApp({super.key});

  @override
  State<DailyPortfolioApp> createState() => _DailyPortfolioAppState();
}

class _DailyPortfolioAppState extends State<DailyPortfolioApp> {
  late AppState _appState;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _appState = AppState.fromPrefs(prefs);
    setState(() {
      _isLoaded = true;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await _appState.saveToPrefs(prefs);
  }

  void _addTransaction(Transaction tx) {
    setState(() {
      _appState.transactions.insert(0, tx);
    });
    _save();
  }

  void _deleteTransaction(String id) {
    setState(() {
      _appState.transactions.removeWhere((item) => item.id == id);
    });
    _save();
  }

  void _addWallet(Wallet wallet) {
    setState(() {
      _appState.wallets.add(wallet);
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daily Portfolio',
      locale: Locale(_appState.languageCode),
      themeMode: _appState.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F5F2),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: AppShell(
        appState: _appState,
        onAddTransaction: _addTransaction,
        onDeleteTransaction: _deleteTransaction,
        onAddWallet: _addWallet,
        onSave: _save,
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.appState,
    required this.onAddTransaction,
    required this.onDeleteTransaction,
    required this.onAddWallet,
    required this.onSave,
  });

  final AppState appState;
  final void Function(Transaction) onAddTransaction;
  final void Function(String) onDeleteTransaction;
  final void Function(Wallet) onAddWallet;
  final Future<void> Function() onSave;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        appState: widget.appState,
        onAddTransaction: widget.onAddTransaction,
      ),
      AddTransactionScreen(
        appState: widget.appState,
        onAddTransaction: widget.onAddTransaction,
      ),
      TransactionsScreen(
        appState: widget.appState,
        onDeleteTransaction: widget.onDeleteTransaction,
      ),
      WalletsScreen(
        appState: widget.appState,
        onAddWallet: widget.onAddWallet,
      ),
      ReportsScreen(appState: widget.appState),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'لوحة التحكم'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'إضافة'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'المعاملات'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'المحافظ'),
          NavigationDestination(icon: Icon(Icons.bar_chart_rounded), selectedIcon: Icon(Icons.bar_chart), label: 'التقارير'),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _selectedIndex = 1),
              icon: const Icon(Icons.add),
              label: const Text('إضافة معاملة'),
            )
          : null,
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.appState,
    required this.onAddTransaction,
  });

  final AppState appState;
  final void Function(Transaction) onAddTransaction;

  double get totalIncome {
    return appState.transactions
        .where((t) => t.type == EntryType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpense {
    return appState.transactions
        .where((t) => t.type == EntryType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get balance {
    return totalIncome - totalExpense;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final monthExpenses = appState.transactions.where((t) {
      return t.type == EntryType.expense &&
          t.date.year == today.year &&
          t.date.month == today.month;
    }).toList();

    final categoryTotals = <String, double>{};
    for (final item in monthExpenses) {
      categoryTotals[item.category] = (categoryTotals[item.category] ?? 0) + item.amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            color: const Color(0xFF1F1F1F),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'رصيدك الحالي',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    appState.formatMoney(balance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddTransactionScreen(
                              appState: appState,
                              onAddTransaction: onAddTransaction,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة معاملة'),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'الإيرادات',
                  value: appState.formatMoney(totalIncome),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'المصروفات',
                  value: appState.formatMoney(totalExpense),
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'تحليل إنفاقك',
            child: sortedCategories.isEmpty
                ? const Text('لا توجد مصروفات هذا الشهر')
                : Column(
                    children: sortedCategories.take(4).map((entry) {
                      final total = entry.value;
                      final pct = totalExpense == 0 ? 0.0 : (total / totalExpense).clamp(0.0, 1.0);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key),
                                Text(appState.formatMoney(total)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: pct,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'الميزانية',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إجمالي هذا الشهر'),
                    Text(appState.formatMoney(totalExpense)),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: totalExpense == 0 ? 0 : ((totalExpense / (appState.monthlyBudget == 0 ? 1 : appState.monthlyBudget)).clamp(0.0, 1.0)),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('المعدل: ${appState.formatMoney(appState.monthlyBudget)}'),
                    Text('المتبقي: ${appState.formatMoney(appState.monthlyBudget - totalExpense)}'),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    required this.appState,
    required this.onAddTransaction,
  });

  final AppState appState;
  final void Function(Transaction) onAddTransaction;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  EntryType _type = EntryType.expense;
  String _selectedWalletId = '';
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.appState.wallets.isNotEmpty) {
      _selectedWalletId = widget.appState.wallets.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _type == EntryType.expense ? expenseCategories : incomeCategories;

    return Scaffold(
      appBar: AppBar(title: const Text('إضافة معاملة')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          SegmentedButton<EntryType>(
            segments: const [
              ButtonSegment(value: EntryType.expense, label: Text('مصروف')),
              ButtonSegment(value: EntryType.income, label: Text('دخل')),
            ],
            selected: {_type},
            onSelectionChanged: (value) {
              setState(() {
                _type = value.first;
                _selectedCategory = categories.first;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedWalletId.isEmpty ? null : _selectedWalletId,
            decoration: const InputDecoration(labelText: 'المحفظة'),
            items: widget.appState.wallets
                .map((wallet) => DropdownMenuItem(value: wallet.id, child: Text(wallet.name)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedWalletId = value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(labelText: 'الفئة'),
            items: categories.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedCategory = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'المبلغ',
              suffixText: widget.appState.primaryCurrency,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'التاريخ'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                  const Icon(Icons.calendar_today_outlined),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              if (_selectedWalletId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إنشاء محفظة أولاً')),
                );
                return;
              }
              final amount = double.tryParse(amountController.text.trim().replaceAll(',', '.'));
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('أدخل مبلغًا صحيحًا')),
                );
                return;
              }

              final tx = Transaction(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                walletId: _selectedWalletId,
                type: _type,
                amount: amount,
                category: _selectedCategory,
                note: noteController.text.trim(),
                date: _selectedDate,
              );

              widget.onAddTransaction(tx);
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.save),
            label: const Text('حفظ'),
          )
        ],
      ),
    );
  }
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({
    super.key,
    required this.appState,
    required this.onDeleteTransaction,
  });

  final AppState appState;
  final void Function(String) onDeleteTransaction;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _walletFilter = 'all';
  String _typeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.appState.transactions.where((tx) {
      final walletMatch = _walletFilter == 'all' || tx.walletId == _walletFilter;
      final typeMatch = _typeFilter == 'all' ||
          (_typeFilter == 'expense' && tx.type == EntryType.expense) ||
          (_typeFilter == 'income' && tx.type == EntryType.income);
      return walletMatch && typeMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('المعاملات')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _walletFilter,
                    decoration: const InputDecoration(labelText: 'المحفظة'),
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('الكل')),
                      ...widget.appState.wallets.map(
                        (wallet) => DropdownMenuItem(value: wallet.id, child: Text(wallet.name)),
                      ),
                    ],
                    onChanged: (value) => setState(() => _walletFilter = value ?? 'all'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _typeFilter,
                    decoration: const InputDecoration(labelText: 'النوع'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('الكل')),
                      DropdownMenuItem(value: 'expense', child: Text('المصروف')),
                      DropdownMenuItem(value: 'income', child: Text('الدخل')),
                    ],
                    onChanged: (value) => setState(() => _typeFilter = value ?? 'all'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('لا توجد معاملات'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final tx = filtered[index];
                        final wallet = widget.appState.wallets.firstWhere(
                          (item) => item.id == tx.walletId,
                          orElse: () => Wallet(id: 'na', name: 'غير محدد', currency: widget.appState.primaryCurrency),
                        );
                        return Dismissible(
                          key: ValueKey(tx.id),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => widget.onDeleteTransaction(tx.id),
                          child: Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    tx.type == EntryType.expense ? Colors.red.withAlpha(35) : Colors.green.withAlpha(35),
                                child: Icon(
                                  tx.type == EntryType.expense ? Icons.outgoing_mail : Icons.call_received,
                                  color: tx.type == EntryType.expense ? Colors.red : Colors.green,
                                ),
                              ),
                              title: Text(tx.category),
                              subtitle: Text('${wallet.name} • ${DateFormat('yyyy-MM-dd').format(tx.date)}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${tx.type == EntryType.expense ? '-' : '+'}${widget.appState.formatMoney(tx.amount)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: tx.type == EntryType.expense ? Colors.red : Colors.green,
                                    ),
                                  ),
                                  if (tx.note.isNotEmpty) Text(tx.note, maxLines: 1),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({
    super.key,
    required this.appState,
    required this.onAddWallet,
  });

  final AppState appState;
  final void Function(Wallet) onAddWallet;

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  final nameController = TextEditingController();
  String _selectedCurrency = 'USD';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المحافظ')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: const Text('إنشاء محفظة'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'اسم المحفظة'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: const InputDecoration(labelText: 'العملة'),
                      items: currencyOptions.map((currency) {
                        return DropdownMenuItem(value: currency, child: Text(currency));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedCurrency = value);
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('إلغاء'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      widget.onAddWallet(
                        Wallet(
                          id: DateTime.now().microsecondsSinceEpoch.toString(),
                          name: name,
                          currency: _selectedCurrency,
                        ),
                      );
                      nameController.clear();
                      Navigator.pop(ctx);
                    },
                    child: const Text('حفظ'),
                  )
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: widget.appState.wallets.map((wallet) {
          final walletTransactions = widget.appState.transactions.where((tx) => tx.walletId == wallet.id).toList();
          final walletIncome = walletTransactions.where((tx) => tx.type == EntryType.income).fold(0.0, (sum, tx) => sum + tx.amount);
          final walletExpense = walletTransactions.where((tx) => tx.type == EntryType.expense).fold(0.0, (sum, tx) => sum + tx.amount);
          final balance = walletIncome - walletExpense;

          return Card(
            child: ListTile(
              title: Text(wallet.name),
              subtitle: Text('العملة: ${wallet.currency}'),
              trailing: Text(
                widget.appState.formatMoney(balance, wallet.currency),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthMap = <String, double>{};
    for (final tx in appState.transactions) {
      final key = DateFormat('MMM yyyy', 'ar').format(tx.date);
      if (tx.date.year == now.year) {
        monthMap[key] = (monthMap[key] ?? 0) + (tx.type == EntryType.expense ? tx.amount : -tx.amount);
      }
    }

    final categorySummary = <String, double>{};
    for (final tx in appState.transactions.where((item) => item.type == EntryType.expense)) {
      categorySummary[tx.category] = (categorySummary[tx.category] ?? 0) + tx.amount;
    }

    final topCategory = categorySummary.entries.isEmpty
    ? null
    : (categorySummary.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)));


    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'الدخل / المصروف',
            child: Row(
              children: [
                Expanded(child: _MiniMetric(title: 'الدخل', value: appState.formatMoney(appState.totalIncome), color: Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _MiniMetric(title: 'المصروف', value: appState.formatMoney(appState.totalExpense), color: Colors.red)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'أكثر فئة تم صرفها',
            child: topCategory == null
                ? const Text('لا توجد بيانات')
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(topCategory.first.key),
                        Text(appState.formatMoney(topCategory.first.value)),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'المستوى الشهري',
            child: Column(
              children: monthMap.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Text(
                        entry.value >= 0 ? '+${appState.formatMoney(entry.value)}' : appState.formatMoney(entry.value),
                        style: TextStyle(color: entry.value >= 0 ? Colors.green : Colors.red),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.title, required this.value, required this.color});

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(32),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _language = 'ar';
  String _currency = 'USD';
  ThemeMode _themeMode = ThemeMode.system;
  bool _biometricLock = false;
  bool _showOnStartup = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(title: 'عام', children: [
            DropdownButtonFormField<String>(
              value: _language,
              items: const [
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'fr', child: Text('Français')),
              ],
              onChanged: (value) => setState(() => _language = value ?? 'ar'),
              decoration: const InputDecoration(labelText: 'اللغة'),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'بحث عن لغة'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _currency,
              items: currencyOptions.map((code) => DropdownMenuItem(value: code, child: Text(code))).toList(),
              onChanged: (value) => setState(() => _currency = value ?? 'USD'),
              decoration: const InputDecoration(labelText: 'العملة الرئيسية'),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'بحث عن عملة'),
            ),
          ]),
          _SettingsSection(title: 'المظهر', children: [
            RadioListTile<ThemeMode>(
              title: const Text('فاتح'),
              value: ThemeMode.light,
              groupValue: _themeMode,
              onChanged: (value) => setState(() => _themeMode = value ?? ThemeMode.system),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('داكن'),
              value: ThemeMode.dark,
              groupValue: _themeMode,
              onChanged: (value) => setState(() => _themeMode = value ?? ThemeMode.system),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('تلقائي'),
              value: ThemeMode.system,
              groupValue: _themeMode,
              onChanged: (value) => setState(() => _themeMode = value ?? ThemeMode.system),
            ),
            SwitchListTile(
              title: const Text('شاشة البداية'),
              subtitle: const Text('لوحة التحكم أو إضافة'),
              value: _showOnStartup,
              onChanged: (value) => setState(() => _showOnStartup = value),
            )
          ]),
          _SettingsSection(title: 'الأمان', children: [
            SwitchListTile(
              title: const Text('قفل التطبيق بالبصمة'),
              value: _biometricLock,
              onChanged: (value) => setState(() => _biometricLock = value),
            ),
          ]),
          _SettingsSection(title: 'النسخ الاحتياطي', children: [
            ListTile(
              title: const Text('تصدير نسخة احتياطية'),
              trailing: const Icon(Icons.file_upload_outlined),
              onTap: () {},
            ),
            ListTile(
              title: const Text('استيراد نسخة احتياطية'),
              trailing: const Icon(Icons.file_download_outlined),
              onTap: () {},
            ),
          ]),
          _SettingsSection(title: 'المزيد', children: [
            ListTile(title: const Text('تغيير العملة الرئيسية'), trailing: Text(_currency)),
            ListTile(title: const Text('النسخة الحالية'), trailing: const Text('1.0.0')),
          ])
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class AppState {
  AppState({
    required this.wallets,
    required this.transactions,
    required this.languageCode,
    required this.themeMode,
    required this.primaryCurrency,
    required this.monthlyBudget,
  });

  final List<Wallet> wallets;
  final List<Transaction> transactions;
  final String languageCode;
  final ThemeMode themeMode;
  final String primaryCurrency;
  final double monthlyBudget;

  double get totalIncome => transactions
      .where((tx) => tx.type == EntryType.income)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get totalExpense => transactions
      .where((tx) => tx.type == EntryType.expense)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  String formatMoney(double value, [String? currency]) {
    final code = currency ?? primaryCurrency;
    return '${NumberFormat('#,##0.00', 'en').format(value)} $code';
  }

  static AppState fromPrefs(SharedPreferences prefs) {
    final walletsJson = prefs.getString('wallets') ?? '[]';
    final txsJson = prefs.getString('transactions') ?? '[]';
    final wallets = (jsonDecode(walletsJson) as List<dynamic>)
        .map((item) => Wallet.fromJson(item as Map<String, dynamic>))
        .toList();

    final transactions = (jsonDecode(txsJson) as List<dynamic>)
        .map((item) => Transaction.fromJson(item as Map<String, dynamic>))
        .toList();

    final languageCode = prefs.getString('language_code') ?? 'ar';
    final themeModeValue = prefs.getString('theme_mode') ?? 'system';
    final primaryCurrency = prefs.getString('primary_currency') ?? 'USD';
    final monthlyBudget = prefs.getDouble('monthly_budget') ?? 0.0;

    return AppState(
      wallets: wallets.isEmpty ? [Wallet(id: 'main', name: 'المحفظة الرئيسية', currency: primaryCurrency)] : wallets,
      transactions: transactions,
      languageCode: languageCode,
      themeMode: themeModeValue == 'dark'
          ? ThemeMode.dark
          : themeModeValue == 'light'
              ? ThemeMode.light
              : ThemeMode.system,
      primaryCurrency: primaryCurrency,
      monthlyBudget: monthlyBudget,
    );
  }

  Future<void> saveToPrefs(SharedPreferences prefs) async {
    await prefs.setString('wallets', jsonEncode(wallets.map((wallet) => wallet.toJson()).toList()));
    await prefs.setString('transactions', jsonEncode(transactions.map((tx) => tx.toJson()).toList()));
    await prefs.setString('language_code', languageCode);
    await prefs.setString('primary_currency', primaryCurrency);
    await prefs.setDouble('monthly_budget', monthlyBudget);
  }
}

class Wallet {
  Wallet({required this.id, required this.name, required this.currency});

  final String id;
  final String name;
  final String currency;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'currency': currency,
      };

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      name: json['name'] as String,
      currency: json['currency'] as String? ?? 'USD',
    );
  }
}

enum EntryType { expense, income }

class Transaction {
  Transaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
  });

  final String id;
  final String walletId;
  final EntryType type;
  final double amount;
  final String category;
  final String note;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'walletId': walletId,
        'type': type.name,
        'amount': amount,
        'category': category,
        'note': note,
        'date': date.toIso8601String(),
      };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      walletId: json['walletId'] as String? ?? 'main',
      type: json['type'] == 'income' ? EntryType.income : EntryType.expense,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String? ?? 'Other',
      note: json['note'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
    );
  }
}

const expenseCategories = [
  'Food',
  'Transport',
  'Health',
  'Bills',
  'Shopping',
  'Entertainment',
  'Home',
  'Other',
];

const incomeCategories = [
  'Salary',
  'Gift',
  'Freelance',
  'Investment',
  'Other',
];

const currencyOptions = [
  'USD',
  'SAR',
  'EGP',
  'AED',
  'KWD',
  'QAR',
  'GBP',
  'EUR',
];
