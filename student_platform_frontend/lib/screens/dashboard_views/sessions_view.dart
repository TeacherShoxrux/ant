import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/responsive_dialog.dart';
import 'package:intl/intl.dart';
import 'package:student_platform_frontend/widgets/app_toast.dart';

class SessionsView extends StatefulWidget {
  const SessionsView({super.key});

  @override
  State<SessionsView> createState() => _SessionsViewState();
}

class _SessionsViewState extends State<SessionsView> {
  final ApiService _apiService = ApiService();
  
  List<UserSession> _sessions = [];
  bool _isLoading = true;
  
  int _currentPage = 1;
  final int _limit = 10;
  int _totalCount = 0;
  
  DateTime? _startDate;
  DateTime? _endDate;
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _startDate != null && _endDate != null 
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF1E3A8A),
            colorScheme: const ColorScheme.light(primary: Color(0xFF1E3A8A)),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _currentPage = 1;
      });
      _loadSessions();
    }
  }

  void _clearDates() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _currentPage = 1;
    });
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.getSessions(
        page: _currentPage, 
        limit: _limit, 
        query: _searchController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
      );
      setState(() {
        _sessions = List<UserSession>.from(result['sessions'] ?? []);
        _totalCount = result['totalCount'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      if(mounted) {
        AppToast.show(context, 'Xatolik: $e', isError: true);
      }
      setState(() => _isLoading = false);
    }
  }

  void _onSearch() {
    setState(() => _currentPage = 1);
    _loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    int totalPages = (_totalCount / _limit).ceil();
    if(totalPages < 1) totalPages = 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 16.0 : 24.0;

        return Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Login Sessiyalari (Tarix)',
                style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
              ),
              const SizedBox(height: 24),
              
              // Filters
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                children: [
                  Expanded(
                    flex: isMobile ? 0 : 2,
                    child: SizedBox(
                      width: isMobile ? double.infinity : null,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'F.I.O yoki IP orqali izlash...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onSubmitted: (_) => _onSearch(),
                      ),
                    ),
                  ),
                  if (isMobile) const SizedBox(height: 12) else const SizedBox(width: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectDateRange,
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            _startDate != null && _endDate != null
                                ? '${DateFormat('dd.MM.yyyy').format(_startDate!)} - ${DateFormat('dd.MM.yyyy').format(_endDate!)}'
                                : isMobile ? 'Sana' : 'Sana oralig\'ini tanlash',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(18),
                            side: const BorderSide(color: Color(0xFF1E3A8A)),
                            foregroundColor: const Color(0xFF1E3A8A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      if (_startDate != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _clearDates,
                          icon: const Icon(Icons.clear, color: Colors.red),
                          tooltip: 'Sanani tozalash',
                        ),
                      ],
                    ],
                  ),
                  if (isMobile) const SizedBox(height: 12) else const SizedBox(width: 16),
                  SizedBox(
                    width: isMobile ? double.infinity : null,
                    child: ElevatedButton.icon(
                      onPressed: _onSearch,
                      icon: const Icon(Icons.search),
                      label: const Text('Izlash'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

          // Table
          Expanded(
            child: Card(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _sessions.isEmpty
                  ? const Center(child: Text("Sessiyalar topilmadi", style: TextStyle(color: Colors.grey)))
                  : ListView(
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                            dataRowMaxHeight: 70,
                            columns: const [
                              DataColumn(label: Text('Rasm')),
                              DataColumn(label: Text('F.I.Sh.')),
                              DataColumn(label: Text('Sana / Vaqt')),
                              DataColumn(label: Text('IP & Manzil')),
                              DataColumn(label: Text('Qurilma (Browser)')),
                            ],
                            rows: _sessions.map((s) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    s.faceImagePath != null && s.faceImagePath!.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          '${ApiService.baseUrl.replaceAll('/api', '')}${s.faceImagePath!.startsWith('/') ? '' : '/'}${s.faceImagePath}',
                                          width: 45, height: 45, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                                        ),
                                      )
                                    : const Icon(Icons.person, color: Colors.grey, size: 40)
                                  ),
                                  DataCell(
                                    InkWell(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => ResponsiveDialog(
                                            title: 'Talaba ma\'lumotlari',
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                CircleAvatar(
                                                  radius: 60,
                                                  backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                                                  backgroundImage: s.faceImagePath != null && s.faceImagePath!.isNotEmpty
                                                    ? NetworkImage('${ApiService.baseUrl.replaceAll('/api', '')}${s.faceImagePath!.startsWith('/') ? '' : '/'}${s.faceImagePath}')
                                                    : null,
                                                  child: s.faceImagePath == null || s.faceImagePath!.isEmpty
                                                      ? const Icon(Icons.person, size: 60, color: Color(0xFF1E3A8A))
                                                      : null,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(s.studentName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                                const Divider(height: 32),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.account_circle, color: Color(0xFF1E3A8A), size: 20),
                                                      const SizedBox(width: 12),
                                                      const SizedBox(width: 80, child: Text('Login:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                                      Expanded(child: Text(s.username, style: const TextStyle(fontWeight: FontWeight.w500))),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.phone, color: Color(0xFF1E3A8A), size: 20),
                                                      const SizedBox(width: 12),
                                                      const SizedBox(width: 80, child: Text('Telefon:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                                      Expanded(child: Text(s.phone, style: const TextStyle(fontWeight: FontWeight.w500))),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.admin_panel_settings, color: Color(0xFF1E3A8A), size: 20),
                                                      const SizedBox(width: 12),
                                                      const SizedBox(width: 80, child: Text('Rol:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                                      Expanded(child: Text(s.roleName, style: const TextStyle(fontWeight: FontWeight.w500))),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Yopish'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: Text(
                                        s.studentName, 
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), decoration: TextDecoration.underline),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(DateFormat('dd.MM.yyyy HH:mm').format(s.loginTime.toLocal()))),
                                  DataCell(Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.ipAddress ?? "Noma'lum", style: const TextStyle(fontWeight: FontWeight.w500)),
                                      Text(s.locationInfo ?? "", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  )),
                                  DataCell(
                                    SizedBox(
                                      width: 250,
                                      child: Text(s.deviceInfo ?? "Noma'lum", 
                                        overflow: TextOverflow.ellipsis, 
                                        maxLines: 2,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    )
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          // Pagination
          const SizedBox(height: 16),
          if (!_isLoading && _totalCount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Jami $_totalCount ta dan ${(_currentPage - 1) * _limit + 1} - ${(_currentPage * _limit).clamp(0, _totalCount)} ko\'rsatilmoqda'),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentPage > 1 ? () {
                        setState(() => _currentPage--);
                        _loadSessions();
                      } : null,
                    ),
                    Text('$_currentPage / $totalPages', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentPage < totalPages ? () {
                        setState(() => _currentPage++);
                        _loadSessions();
                      } : null,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
}
