import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LifeManagerApp());
}

class LifeManagerApp extends StatelessWidget {
  const LifeManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدیریت زندگی',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'sans-serif',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Database? _db;
  String _today = '';

  // امتیازها
  int _score = 0;

  // خواب و اینستاگرام (انتخابی)
  int _sleepHours = 0;
  int _instaHours = 0;

  // تعداد ممنوعه‌ها
  int _pills = 0;
  int _espresso = 0;
  int _hookah = 0;

  // تسک‌های فیفا
  bool _tuskAmir = false;   // ۱۰ بازی
  bool _tuskArman = false;  // ۲۰ بازی
  bool _tuskErfan = false;  // ۳۰ بازی

  // روتین‌های شناور سلامت
  bool _walkGrocery = false;
  bool _shower = false;
  bool _nails = false;
  bool _beardTrim = false;
  bool _haircut = false;

  @override
  void initState() {
    super.initState();
    _today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'life_manager.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE daily_logs (
            date TEXT PRIMARY KEY,
            sleepHours INTEGER,
            instaHours INTEGER,
            pills INTEGER,
            espresso INTEGER,
            hookah INTEGER,
            tuskAmir INTEGER,
            tuskArman INTEGER,
            tuskErfan INTEGER,
            walkGrocery INTEGER,
            shower INTEGER,
            nails INTEGER,
            beardTrim INTEGER,
            haircut INTEGER,
            totalScore INTEGER
          )
        ''');
      },
    );
    await _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    if (_db == null) return;
    final List<Map<String, dynamic>> maps = await _db!.query(
      'daily_logs',
      where: 'date = ?',
      whereArgs: [_today],
    );

    if (maps.isNotEmpty) {
      final row = maps.first;
      setState(() {
        _sleepHours = row['sleepHours'] ?? 0;
        _instaHours = row['instaHours'] ?? 0;
        _pills = row['pills'] ?? 0;
        _espresso = row['espresso'] ?? 0;
        _hookah = row['hookah'] ?? 0;
        _tuskAmir = (row['tuskAmir'] ?? 0) == 1;
        _tuskArman = (row['tuskArman'] ?? 0) == 1;
        _tuskErfan = (row['tuskErfan'] ?? 0) == 1;
        _walkGrocery = (row['walkGrocery'] ?? 0) == 1;
        _shower = (row['shower'] ?? 0) == 1;
        _nails = (row['nails'] ?? 0) == 1;
        _beardTrim = (row['beardTrim'] ?? 0) == 1;
        _haircut = (row['haircut'] ?? 0) == 1;
        _calculateScore();
      });
    } else {
      _calculateScore();
    }
  }

  void _calculateScore() {
    int total = 0;

    // خواب
    if (_sleepHours == 8) total += 20;
    else if (_sleepHours == 10) total += 10;
    else if (_sleepHours >= 12) total -= 20;

    // اینستاگرام
    if (_instaHours == 1) total += 20;
    else if (_instaHours == 2) total += 10;
    else if (_instaHours >= 3) total -= 20;

    // قرص (سقف ۲ تا)
    if (_pills <= 2) {
      if (_pills > 0) total += 10;
    } else {
      total -= (_pills - 2) * 10;
    }

    // اسپرسو (سقف ۳ تا)
    if (_espresso <= 3) {
      if (_espresso > 0) total += 10;
    } else {
      total -= (_espresso - 3) * 10;
    }

    // قلیون (سقف ۵ بار)
    if (_hookah <= 3) {
      if (_hookah > 0) total += 20;
    } else if (_hookah <= 5) {
      total += 10;
    } else {
      total -= (_hookah - 5) * 15;
    }

    // تسک‌های فیفا
    if (_tuskAmir) total += 10;
    if (_tuskArman) total += 20;
    if (_tuskErfan) total += 30;

    // روتین‌های روزمره
    if (_walkGrocery) total += 10;
    if (_shower) total += 10;
    if (_nails) total += 10;
    if (_beardTrim) total += 10;
    if (_haircut) total += 20;

    setState(() {
      _score = total;
    });

    _saveData();
  }

  Future<void> _saveData() async {
    if (_db == null) return;
    await _db!.insert(
      'daily_logs',
      {
        'date': _today,
        'sleepHours': _sleepHours,
        'instaHours': _instaHours,
        'pills': _pills,
        'espresso': _espresso,
        'hookah': _hookah,
        'tuskAmir': _tuskAmir ? 1 : 0,
        'tuskArman': _tuskArman ? 1 : 0,
        'tuskErfan': _tuskErfan ? 1 : 0,
        'walkGrocery': _walkGrocery ? 1 : 0,
        'shower': _shower ? 1 : 0,
        'nails': _nails ? 1 : 0,
        'beardTrim': _beardTrim ? 1 : 0,
        'haircut': _haircut ? 1 : 0,
        'totalScore': _score,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Widget _buildCounterCard({
    required String title,
    required int count,
    required String subtitle,
    required VoidCallback onAdd,
    required VoidCallback onRemove,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 30, color: Colors.purpleAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
              onPressed: onRemove,
            ),
            Text(
              '$count',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('کنترل روزمره و عادات'),
        centerTitle: true,
        backgroundColor: Colors.purple.shade900,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // کارت امتیاز روز
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade700, Colors.deepPurple.shade900],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('امتیاز امروز شما', style: TextStyle(fontSize: 16, color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(
                    '$_score',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _score >= 0 ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ),
                  Text('تاریخ: $_today', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // بخش خواب
            const Text('وضعیت خواب 🛏️', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('۸ ساعت (+۲۰)'),
                  selected: _sleepHours == 8,
                  onSelected: (val) {
                    setState(() => _sleepHours = val ? 8 : 0);
                    _calculateScore();
                  },
                ),
                ChoiceChip(
                  label: const Text('۱۰ ساعت (+۱۰)'),
                  selected: _sleepHours == 10,
                  onSelected: (val) {
                    setState(() => _sleepHours = val ? 10 : 0);
                    _calculateScore();
                  },
                ),
                ChoiceChip(
                  label: const Text('۱۲+ ساعت (-۲۰)'),
                  selected: _sleepHours == 12,
                  onSelected: (val) {
                    setState(() => _sleepHours = val ? 12 : 0);
                    _calculateScore();
                  },
                ),
              ],
            ),
            const Divider(height: 30),

            // بخش اینستاگرام
            const Text('اینستاگرام 📱', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('۱ ساعت (+۲۰)'),
                  selected: _instaHours == 1,
                  onSelected: (val) {
                    setState(() => _instaHours = val ? 1 : 0);
                    _calculateScore();
                  },
                ),
                ChoiceChip(
                  label: const Text('۲ ساعت (+۱۰)'),
                  selected: _instaHours == 2,
                  onSelected: (val) {
                    setState(() => _instaHours = val ? 2 : 0);
                    _calculateScore();
                  },
                ),
                ChoiceChip(
                  label: const Text('۳+ ساعت (-۲۰)'),
                  selected: _instaHours == 3,
                  onSelected: (val) {
                    setState(() => _instaHours = val ? 3 : 0);
                    _calculateScore();
                  },
                ),
              ],
            ),
            const Divider(height: 30),

            // اقلام مصرفی
            const Text('کنترل مصرفی‌ها ⚠️', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildCounterCard(
              title: 'قرص',
              subtitle: 'مجاز: تا ۲ عدد (+۱۰)',
              count: _pills,
              icon: Icons.medication,
              onAdd: () {
                setState(() => _pills++);
                _calculateScore();
              },
              onRemove: () {
                if (_pills > 0) {
                  setState(() => _pills--);
                  _calculateScore();
                }
              },
            ),
            _buildCounterCard(
              title: 'اسپرسو',
              subtitle: 'مجاز: تا ۳ شات (+۱۰)',
              count: _espresso,
              icon: Icons.local_cafe,
              onAdd: () {
                setState(() => _espresso++);
                _calculateScore();
              },
              onRemove: () {
                if (_espresso > 0) {
                  setState(() => _espresso--);
                  _calculateScore();
                }
              },
            ),
            _buildCounterCard(
              title: 'قلیون',
              subtitle: 'سقف ۵ سر (۰ تا ۳: +۲۰ | ۴ تا ۵: +۱۰)',
              count: _hookah,
              icon: Icons.smoking_rooms,
              onAdd: () {
                setState(() => _hookah++);
                _calculateScore();
              },
              onRemove: () {
                if (_hookah > 0) {
                  setState(() => _hookah--);
                  _calculateScore();
                }
              },
            ),
            const Divider(height: 30),

            // تسک‌های کاری فیفا
            const Text('تسک فیفا (شغل گیمری) 🎮', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            CheckboxListTile(
              title: const Text('امیر (۱۰ بازی فیفا)'),
              subtitle: const Text('+۱۰ امتیاز'),
              value: _tuskAmir,
              onChanged: (val) {
                setState(() => _tuskAmir = val ?? false);
                _calculateScore();
              },
            ),
            CheckboxListTile(
              title: const Text('آرمان (۲۰ بازی فیفا)'),
              subtitle: const Text('+۲۰ امتیاز'),
              value: _tuskArman,
              onChanged: (val) {
                setState(() => _tuskArman = val ?? false);
                _calculateScore();
              },
            ),
            CheckboxListTile(
              title: const Text('عرفان (۳۰ بازی فیفا)'),
              subtitle: const Text('+۳۰ امتیاز'),
              value: _tuskErfan,
              onChanged: (val) {
                setState(() => _tuskErfan = val ?? false);
                _calculateScore();
              },
            ),
            const Divider(height: 30),

            // روتین‌های سبک زندگی
            const Text('روتین و سلامت فردی 🌿', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            CheckboxListTile(
              title: const Text('پیاده‌روی تا سوپری محل'),
              subtitle: const Text('روزانه (+۱۰)'),
              value: _walkGrocery,
              onChanged: (val) {
                setState(() => _walkGrocery = val ?? false);
                _calculateScore();
              },
            ),
            CheckboxListTile(
              title: const Text('حمام'),
              subtitle: const Text('یک روز در میان (+۱۰)'),
              value: _shower,
              onChanged: (val) {
                setState(() => _shower = val ?? false);
                _calculateScore();
              },
            ),
            CheckboxListTile(
              title: const Text('گرفتن ناخن'),
              subtitle: const Text('دو بار در هفته (+۱۰)'),
              value: _nails,
              onChanged: (val) {
                setState(() => _nails = val ?? false);
                _calculateScore();
              },
            ),
            CheckboxListTile(
              title: const Text('مرتب کردن ریش'),
              subtitle: const Text('دو بار در هفته (+۱۰)'),
              value: _beardTrim,
              onChanged: (val) {
                setState(() => _beardTrim = val ?? false);
                _calculateScore();
              },
            ),
            CheckboxListTile(
              title: const Text('اصلاح کامل مو و ریش'),
              subtitle: const Text('ماهانه (+۲۰)'),
              value: _haircut,
              onChanged: (val) {
                setState(() => _haircut = val ?? false);
                _calculateScore();
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
