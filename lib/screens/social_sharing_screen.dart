import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocketbase/pocketbase.dart'; // Impor PocketBase
import 'package:volunteervibe/services/pocketbase_service.dart'; // Impor PocketBaseService
import 'package:intl/intl.dart'; // Untuk pemformatan tanggal
import 'package:share_plus/share_plus.dart'; // Impor share_plus
import 'package:url_launcher/url_launcher.dart'; // Impor url_launcher untuk tautan aplikasi langsung
import 'package:volunteervibe/utils/app_constants.dart'; // Impor app_constants.dart

class SocialSharingScreen extends StatefulWidget {
  @override
  _SocialSharingScreenState createState() => _SocialSharingScreenState();
}

class _SocialSharingScreenState extends State<SocialSharingScreen> {
  final PocketBaseService _pbService = PocketBaseService(); // Instance dari PocketBaseService

  List<RecordModel> _recentActivities = []; // Mengubah menjadi RecordModel
  bool _isLoading = true;

  final List<Map<String, dynamic>> _socialPlatforms = [
    {
      'name': 'Facebook',
      'icon': Icons.facebook,
      'color': Color(0xFF1877F2),
      'connected': true,
      // URL berbagi web resmi untuk Facebook (direkomendasikan)
      'share_url_template': 'https://www.facebook.com/sharer/sharer.php?u={link}&quote={text}', 
    },
    {
      'name': 'Instagram',
      'icon': Icons.camera_alt,
      'color': Color(0xFFE4405F),
      'connected': true,
      // Instagram sangat membatasi berbagi teks langsung ke feed melalui skema URL.
      // `share_plus` akan membuka aplikasi Instagram, dan pengguna mungkin perlu menyalin/menempel teks secara manual.
      // Untuk berbagi gambar/video ke Instagram Story, share_plus memiliki metode shareXFiles.
    },
    {
      'name': 'Twitter',
      'icon': Icons.alternate_email, // Ganti dengan Icons.twitter jika menggunakan font_awesome
      'color': Color(0xFF1DA1F2),
      'connected': false,
      'share_url_template': 'https://twitter.com/intent/tweet?text={text}&url={link}', 
    },
    {
      'name': 'LinkedIn',
      'icon': Icons.work, // Ganti dengan Icons.linkedin jika menggunakan font_awesome
      'color': Color(0xFF0A66C2),
      'connected': false,
      'share_url_template': 'https://www.linkedin.com/shareArticle?mini=true&url={link}&title={title}&summary={description}', 
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchRecentActivities(); // Ambil data saat inisialisasi
  }

  Future<void> _fetchRecentActivities() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final currentUser = _pbService.getCurrentUser();
      if (currentUser != null) {
        // Pastikan 'organization_id' dan 'categories_id' diperluas (expanded)
        final events = await _pbService.fetchJoinedEvents(userId: currentUser.id);
        setState(() {
          _recentActivities = events;
        });
      } else {
        setState(() {
          _recentActivities = [];
        });
        // Opsional, tampilkan pesan bahwa pengguna tidak login
      }
    } catch (e) {
      print("Error fetching recent activities: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat aktivitas: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Berbagi Sosial',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Color(0xFF6C63FF)),
            onPressed: _showSocialSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator( // Menambahkan RefreshIndicator
          onRefresh: _fetchRecentActivities,
          color: Color(0xFF6C63FF),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(), // Memastikan scrollability untuk RefreshIndicator
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSharingStats(),
                _buildConnectedAccounts(),
                _buildRecentActivities(),
                _buildSharingTips(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSharingStats() {
    return Container(
      margin: EdgeInsets.all(24),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9F7AEA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.share, color: Colors.white, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dampak Berbagi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Inspirasi orang lain untuk menjadi sukarelawan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('7', 'Postingan Dibagikan', Icons.share),
              ),
              Expanded(
                child: _buildStatItem('142', 'Orang Terjangkau', Icons.people),
              ),
              Expanded(
                child: _buildStatItem('23', 'Terinspirasi Bergabung', Icons.favorite),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildConnectedAccounts() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Akun Terhubung',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: _showSocialSettings,
                child: Text(
                  'Kelola',
                  style: TextStyle(color: Color(0xFF6C63FF)),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3,
            ),
            itemCount: _socialPlatforms.length,
            itemBuilder: (context, index) {
              final platform = _socialPlatforms[index];
              return _buildPlatformCard(platform);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformCard(Map<String, dynamic> platform) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: platform['connected'] 
            ? platform['color'].withOpacity(0.1) 
            : Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: platform['connected'] 
              ? platform['color'].withOpacity(0.3) 
              : Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: platform['connected'] 
                  ? platform['color'] 
                  : Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              platform['icon'],
              color: Colors.white,
              size: 16,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  platform['name'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: platform['connected'] 
                        ? Color(0xFF2D3748) 
                        : Color(0xFF718096),
                  ),
                ),
                Text(
                  platform['connected'] ? 'Terhubung' : 'Tidak Terhubung',
                  style: TextStyle(
                    fontSize: 10,
                    color: platform['connected'] 
                        ? Color(0xFF10B981) 
                        : Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Container(
      margin: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aktivitas Terbaru',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 16),
          _isLoading
              ? Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
              : _recentActivities.isEmpty
                  ? _buildEmptyState() // Gunakan state kosong khusus untuk aktivitas
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _recentActivities.length,
                      itemBuilder: (context, index) {
                        return _buildActivityCard(_recentActivities[index]);
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(RecordModel activityRecord) {
    // Ekstrak data dari PocketBase RecordModel
    final String title = activityRecord.getStringValue('title', 'Tidak Ada Judul');
    // Asumsi ada field 'date' dan bisa diparse untuk tanggal event.
    final DateTime eventDate = DateFormat('yyyy-MM-dd').parse(activityRecord.getStringValue('date', DateTime.now().toIso8601String()));
    // Asumsi ada field 'duration_hours' atau sejenisnya, atau hitung placeholder.
    // Mari kita asumsikan ada field 'duration_hours', default ke 0 jika tidak ditemukan.
    final int hours = activityRecord.getIntValue('duration_hours', 4); // Default ke 4 jam jika tidak ditentukan

    final int points = activityRecord.getIntValue('point_event', 0);
    final int maxParticipants = activityRecord.getIntValue('max_participant', 0);

    // Akses relasi yang diperluas (expanded relations)
    final organization = activityRecord.expand['organization_id']?.first;
    final category = activityRecord.expand['categories_id']?.first;

    final String orgName = organization?.getStringValue('name', 'Organisasi Tidak Dikenal') ?? 'Organisasi Tidak Dikenal';
    final String categoryName = category?.getStringValue('name', 'Tanpa Kategori') ?? 'Tanpa Kategori';

    // Dapatkan URL avatar organisasi
    String? orgAvatarUrl;
    if (organization != null && organization.getStringValue('avatar').isNotEmpty) {
      orgAvatarUrl = _pbService.getFileUrl(organization, organization.getStringValue('avatar'));
    }

    // Asumsi ada field 'isShared' di record event, atau bisa disimulasikan
    bool isShared = activityRecord.data.containsKey('isShared') ? activityRecord.getBoolValue('isShared') : false;


    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              gradient: orgAvatarUrl == null ? LinearGradient( // Gunakan gradien jika tidak ada gambar
                colors: [Color(0xFF6C63FF), Color(0xFF9F7AEA)],
              ) : null,
              // Tampilkan gambar organisasi di sini
              image: orgAvatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(orgAvatarUrl),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken), // Opsional: gelapkan gambar agar teks mudah dibaca
                    )
                  : null, // Jika tidak ada gambar, tampilkan gradien
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isShared 
                          ? Color(0xFF10B981) 
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isShared ? Icons.check : Icons.share,
                          size: 12,
                          color: isShared ? Colors.white : Color(0xFF6C63FF),
                        ),
                        SizedBox(width: 4),
                        Text(
                          isShared ? 'Dibagikan' : 'Bagikan',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isShared ? Colors.white : Color(0xFF6C63FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Icon Center dihapus untuk menghilangkan logo di tengah gambar organisasi
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  orgName,
                  style: TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 12),
                // Tampilkan tanggal event di sini
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                    SizedBox(width: 6),
                    Text(
                      DateFormat('MMM dd,EEEE').format(eventDate), // Tanggal yang diformat
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                ),
                SizedBox(height: 12), // Menambahkan spasi untuk baris tanggal baru
                Row(
                  children: [
                    _buildActivityStat(Icons.star, '$points pts', Color(0xFFFFD700)),
                    SizedBox(width: 16),
                    // Menggunakan ikon jam dan menampilkan durasi jam event.
                    _buildActivityStat(Icons.access_time, '${hours}h', Color(0xFF6C63FF)),
                    SizedBox(width: 16),
                    _buildActivityStat(Icons.people, '$maxParticipants', Color(0xFF10B981)),
                  ],
                ),
                SizedBox(height: 16),
                if (!isShared)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showShareDialog(activityRecord), // Teruskan record aktivitas
                      icon: Icon(Icons.share, size: 18),
                      label: Text('Bagikan Dampak Anda'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Berhasil Dibagikan',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStat(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
      ],
    );
  }

  Widget _buildSharingTips() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 24), // Menambahkan margin vertikal
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Color(0xFF6C63FF)),
              SizedBox(width: 8),
              Text(
                'Tips Berbagi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildTip('Bagikan pengalaman sukarelawan Anda untuk menginspirasi orang lain'),
          _buildTip('Gunakan hashtag seperti #VolunteerVibe #BuatPerbedaan'),
          _buildTip('Tag teman-teman yang mungkin tertarik untuk menjadi sukarelawan'),
          _buildTip('Bagikan foto dari aktivitas sukarelawan Anda'),
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Color(0xFF6C63FF),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: Color(0xFF4A5568),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(RecordModel activityRecord) { // Mengubah parameter menjadi RecordModel
    final String title = activityRecord.getStringValue('title', 'Tidak Ada Judul');
    final String orgName = activityRecord.expand['organization_id']?.first.getStringValue('name', 'Organisasi Tidak Dikenal') ?? 'Organisasi Tidak Dikenal';
    final int points = activityRecord.getIntValue('point_event', 0);
    // Menggunakan tanggal event yang sebenarnya untuk deskripsi
    final DateTime eventDate = DateFormat('yyyy-MM-dd').parse(activityRecord.getStringValue('date', DateTime.now().toIso8601String()));
    final String formattedDate = DateFormat('MMMM dd,EEEE').format(eventDate);
    
    final String description = activityRecord.getStringValue('description', 'Ini adalah pengalaman hebat berkontribusi untuk komunitas kami!');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Bagikan Dampak Anda',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildSharePreview(activityRecord), // Teruskan record aktivitas
                    SizedBox(height: 24),
                    _buildSharePlatforms(activityRecord), // Teruskan record aktivitas
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharePreview(RecordModel activityRecord) { // Mengubah parameter menjadi RecordModel
    final String title = activityRecord.getStringValue('title', 'Tidak Ada Judul');
    final String orgName = activityRecord.expand['organization_id']?.first.getStringValue('name', 'Organisasi Tidak Dikenal') ?? 'Organisasi Tidak Dikenal';
    final int points = activityRecord.getIntValue('point_event', 0);
    final DateTime eventDate = DateFormat('yyyy-MM-dd').parse(activityRecord.getStringValue('date', DateTime.now().toIso8601String()));
    final String formattedDate = DateFormat('MMMM dd,EEEE').format(eventDate);
    final String description = activityRecord.getStringValue('description', 'Ini adalah pengalaman hebat berkontribusi untuk komunitas kami!');


    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pratinjau',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF718096),
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🌟 Baru saja menyelesaikan "$title" dengan $orgName pada $formattedDate!', // Teks diperbarui dengan tanggal
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Saya mendapatkan $points poin untuk acara ini. ${description.isNotEmpty ? description : 'Ini adalah pengalaman hebat berkontribusi untuk komunitas kami!'} 💪', // Deskripsi diperbarui
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A5568),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '#VolunteerVibe #BuatPerbedaan #LayananKomunitas',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharePlatforms(RecordModel activityRecord) { // Mengubah parameter menjadi RecordModel
    final connectedPlatforms = _socialPlatforms.where((p) => p['connected']).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bagikan ke',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: connectedPlatforms.length,
          itemBuilder: (context, index) {
            final platform = connectedPlatforms[index];
            return _buildShareButton(platform, activityRecord); // Teruskan record aktivitas
          },
        ),
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _copyToClipboard(activityRecord), // Teruskan record aktivitas
            icon: Icon(Icons.copy),
            label: Text('Salin Tautan'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Color(0xFF6C63FF)),
              foregroundColor: Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShareButton(Map<String, dynamic> platform, RecordModel activityRecord) { // Mengubah parameter menjadi RecordModel
    return ElevatedButton(
      onPressed: () => _shareToplatform(platform, activityRecord), // Teruskan record aktivitas
      style: ElevatedButton.styleFrom(
        backgroundColor: platform['color'],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(platform['icon'], size: 18),
          SizedBox(width: 8),
          Text(
            platform['name'],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showSocialSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Pengaturan Sosial',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Selesai'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: _socialPlatforms.length,
                itemBuilder: (context, index) {
                  final platform = _socialPlatforms[index];
                  return _buildPlatformSetting(platform, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformSetting(Map<String, dynamic> platform, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: platform['color'],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              platform['icon'],
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Text(
                  platform['connected'] ? 'Terhubung' : 'Tidak Terhubung',
                  style: TextStyle(
                    fontSize: 14,
                    color: platform['connected'] ? Color(0xFF10B981) : Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: platform['connected'],
            onChanged: (value) {
              setState(() {
                _socialPlatforms[index]['connected'] = value;
              });
            },
            activeColor: Color(0xFF6C63FF),
          ),
        ],
      ),
    );
  }

  void _shareToplatform(Map<String, dynamic> platform, RecordModel activityRecord) async {
    Navigator.pop(context); // Tutup dialog berbagi terlebih dahulu

    final String title = activityRecord.getStringValue('title', 'Tidak Ada Judul');
    final String orgName = activityRecord.expand['organization_id']?.first.getStringValue('name', 'Organisasi Tidak Dikenal') ?? 'Organisasi Tidak Dikenal';
    final int points = activityRecord.getIntValue('point_event', 0);
    final DateTime eventDate = DateFormat('yyyy-MM-dd').parse(activityRecord.getStringValue('date', DateTime.now().toIso8601String()));
    final String formattedDate = DateFormat('MMMM dd,EEEE').format(eventDate);
    final String description = activityRecord.getStringValue('description', 'Ini adalah pengalaman hebat berkontribusi untuk komunitas kami!');

    // Buat teks berbagi generik
    final String genericShareText = '🌟 Baru saja menyelesaikan "$title" dengan $orgName pada $formattedDate! Saya mendapatkan $points poin untuk acara ini. ${description.isNotEmpty ? description : 'Ini adalah pengalaman hebat berkribusi untuk komunitas kami!'} 💪 #VolunteerVibe #BuatPerbedaan #LayananKomunitas';
    
    // Bangun tautan deep link dan tautan web menggunakan AppConstants
    final String appDeepLink = '${AppConstants.appDeepLinkScheme}://events?id=${activityRecord.id}';
    final String webLink = '${AppConstants.appWebDomain}/events/${activityRecord.id}'; // Contoh: https://www.yourdomain.com/events/event_id

    try {
      if (platform['name'] == 'Facebook') {
        // Berbagi resmi Facebook seringkali lebih suka URL web
        String facebookShareUrl = platform['share_url_template']
            .replaceAll('{link}', Uri.encodeComponent(webLink))
            .replaceAll('{text}', Uri.encodeComponent(genericShareText));
        
        if (await canLaunchUrl(Uri.parse(facebookShareUrl))) {
          await launchUrl(Uri.parse(facebookShareUrl), mode: LaunchMode.externalApplication);
          _updateActivitySharedStatus(activityRecord, platform['name']);
        } else {
          // Fallback ke berbagi generik jika peluncuran URL langsung gagal
          await Share.share(genericShareText);
          _updateActivitySharedStatus(activityRecord, platform['name']); 
        }
      } else if (platform['name'] == 'Instagram') {
        // Untuk Instagram, kami akan menggunakan Share.share.
        // Ini akan membuka dialog berbagi sistem dan Instagram akan menjadi salah satu pilihannya.
        // Pengguna mungkin perlu menempelkan teks secara manual.
        await Share.share(genericShareText);
        _updateActivitySharedStatus(activityRecord, platform['name']); 
      } else if (platform.containsKey('share_url_template')) {
        // Untuk platform lain yang mungkin menggunakan URL berbagi web (seperti Twitter, LinkedIn)
        String shareUrl = platform['share_url_template']
            .replaceAll('{link}', Uri.encodeComponent(webLink))
            .replaceAll('{text}', Uri.encodeComponent(genericShareText))
            .replaceAll('{title}', Uri.encodeComponent(title)) 
            .replaceAll('{description}', Uri.encodeComponent(description)); 

        if (await canLaunchUrl(Uri.parse(shareUrl))) {
          await launchUrl(Uri.parse(shareUrl), mode: LaunchMode.externalApplication);
          _updateActivitySharedStatus(activityRecord, platform['name']);
        } else {
          await Share.share(genericShareText); // Fallback ke berbagi generik
          _updateActivitySharedStatus(activityRecord, platform['name']);
        }
      } else {
        // Berbagi generik untuk platform lain yang tidak ditangani secara eksplisit
        await Share.share(genericShareText);
        _updateActivitySharedStatus(activityRecord, platform['name']);
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal berbagi ke ${platform['name']}: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Helper untuk memperbarui UI setelah berhasil berbagi
  void _updateActivitySharedStatus(RecordModel activityRecord, String platformName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Berhasil dibagikan ke $platformName!'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
    int index = _recentActivities.indexOf(activityRecord);
    if (index != -1) {
      RecordModel updatedRecord = RecordModel(
        collectionId: activityRecord.collectionId,
        collectionName: activityRecord.collectionName,
        id: activityRecord.id,
        created: activityRecord.created,
        updated: activityRecord.updated,
        data: Map<String, dynamic>.from(activityRecord.data)..['isShared'] = true,
        expand: activityRecord.expand,
      );
      setState(() {
        _recentActivities[index] = updatedRecord;
      });
    }
  }

  void _copyToClipboard(RecordModel activityRecord) { // Mengubah parameter menjadi RecordModel
    final String title = activityRecord.getStringValue('title', 'Tidak Ada Judul');
    final String orgName = activityRecord.expand['organization_id']?.first.getStringValue('name', 'Organisasi Tidak Dikenal') ?? 'Organisasi Tidak Dikenal';
    final int points = activityRecord.getIntValue('point_event', 0);
    final DateTime eventDate = DateFormat('yyyy-MM-dd').parse(activityRecord.getStringValue('date', DateTime.now().toIso8601String()));
    final String formattedDate = DateFormat('MMMM dd,EEEE').format(eventDate);
    final String description = activityRecord.getStringValue('description', 'Ini adalah pengalaman hebat berkontribusi untuk komunitas kami!');

    // Bangun tautan deep link dan tautan web menggunakan AppConstants
    final String appDeepLink = '${AppConstants.appDeepLinkScheme}://events?id=${activityRecord.id}';
    final String webLink = '${AppConstants.appWebDomain}/events/${activityRecord.id}'; // Contoh: https://www.yourdomain.com/events/event_id

    final textToCopy = '🌟 Baru saja menyelesaikan "$title" dengan $orgName pada $formattedDate! Saya mendapatkan $points poin untuk acara ini. ${description.isNotEmpty ? description : 'Ini adalah pengalaman hebat berkontribusi untuk komunitas kami!'} � #VolunteerVibe #BuatPerbedaan #LayananKomunitas\n\nLihat selengkapnya: $webLink'; // Menggunakan tautan web untuk salin

    Clipboard.setData(ClipboardData(text: textToCopy)); // Menggunakan textToCopy
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tautan disalin ke clipboard!'), // Pesan diperbarui
        backgroundColor: Color(0xFF6C63FF),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case 'Environment':
        return Icons.eco;
      case 'Education':
        return Icons.school;
      case 'Health':
        return Icons.health_and_safety;
      case 'Community':
        return Icons.people;
      case 'Animals':
        return Icons.pets;
      default:
        return Icons.volunteer_activism;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_rounded, size: 60, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              "Tidak Ada Aktivitas Saat Ini",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A5568),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Anda belum berpartisipasi dalam acara apa pun baru-baru ini. Mari beraksi dan buat perbedaan!",
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
�