//lib/ads_page/ads_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_menu.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart'; // لاستيراد kIsWeb


bool isNotNullOrEmpty(dynamic value) {
  return value != null && value.toString().isNotEmpty;
}

class AdsPage extends StatefulWidget {
  @override
  _AdsPageState createState() => _AdsPageState();
}

class _AdsPageState extends State<AdsPage> {
  final CollectionReference adsCollection = FirebaseFirestore.instance.collection('created ads');
  String searchQuery = "";
  DateTime? selectedDate;
  int _currentPage = 0;
  static const int _rowsPerPage = 10;
  final TextEditingController searchController = TextEditingController();
  final format = DateFormat("yyyy-MM-dd");
  final adFormat = DateFormat("yyyy-MM-dd HH:mm");
  int? _expandedIndex;
  String userName = "";
  bool canEditStatus = false;

  QueryDocumentSnapshot? lastDocument; // لحفظ آخر إعلان من الصفحة الحالية
  List<QueryDocumentSnapshot> ads = []; // لحفظ الإعلانات المحملة
  void _loadAds({bool isNextPage = false}) async {
    Query query = adsCollection.orderBy('timestamp', descending: true).limit(_rowsPerPage);

    // لو بجيب الصفحة اللي بعدها استخدم `startAfter`
    if (isNextPage && lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }

    // نفذ الطلب للبيانات
    final querySnapshot = await query.get();

    // لو فيه بيانات، حدث البيانات وحدث آخر وثيقة
    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        ads.addAll(querySnapshot.docs);
        lastDocument = querySnapshot.docs.last;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAds(); // تحميل الصفحة الأولى من الإعلانات
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkUserPermissions();
  }

  void _fetchUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUsername = prefs.getString('saved_username');
    if (savedUsername != null) {
      FirebaseFirestore.instance
          .collection('admin users')
          .where('user_name', isEqualTo: savedUsername)
          .get()
          .then((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            userName = querySnapshot.docs.first['name'];
          });
        }
      });
    }
  }

  Future<void> _checkUserPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUsername = prefs.getString('saved_username');

    if (savedUsername != null) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('admin users')
          .where('user_name', isEqualTo: savedUsername)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = querySnapshot.docs.first;
        setState(() {
          canEditStatus = (doc.data() as Map<String, dynamic>)['permissions_ads_edit'] ?? false;
        });
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String formatTimestamp(Timestamp timestamp) {
    var date = timestamp.toDate();
    var formatter = DateFormat('yyyy-MM-dd HH:mm');
    return formatter.format(date);
  }

  bool isValidImageUrl(String url) {
    return url.endsWith(".jpg") || url.endsWith(".jpeg") || url.endsWith(".png") || url.endsWith(".gif");
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _downloadDetails(String content, String fileName) {
    try {
      if (kIsWeb) {
        // استخدام dart:html لحفظ الملف في حال تشغيل التطبيق على الويب
        final bytes = utf8.encode(content);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // استخدام مكتبة share على منصات الموبايل (iOS و Android)
        Share.share(content, subject: 'Ad Details');
      }
    } catch (e) {
      // التعامل مع الخطأ بشكل مناسب
      print('حدث خطأ أثناء تحميل الملف: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text('الإعلانات - مرحبًا بك يا $userName'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'بحث بالإسم أو البريد الإلكتروني',
                      labelStyle: TextStyle(color: textColor),
                      suffixIcon: Icon(Icons.search, color: textColor),
                    ),
                    style: TextStyle(color: textColor),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DateTimeField(
                    format: format,
                    decoration: InputDecoration(
                      labelText: 'اختر التاريخ',
                      labelStyle: TextStyle(color: textColor),
                      suffixIcon: Icon(Icons.calendar_today, color: textColor),
                    ),
                    style: TextStyle(color: textColor),
                    onChanged: (date) {
                      setState(() {
                        selectedDate = date;
                      });
                    },
                    onShowPicker: (context, currentValue) async {
                      final date = await showDatePicker(
                        context: context,
                        firstDate: DateTime(1900),
                        initialDate: currentValue ?? DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      return date;
                    },
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      searchController.clear();
                      searchQuery = "";
                      selectedDate = null;
                    });
                  },
                  child: Text('إلغاء البحث'),
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: adsCollection.orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('حدث خطأ ما: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('لا توجد بيانات متاحة'));
                  }

                  final data = snapshot.requireData.docs.where((doc) {
                    final adData = doc.data() as Map<String, dynamic>;
                    final matchesQuery = adData['first name'].toString().contains(searchQuery) ||
                        adData['email'].toString().contains(searchQuery);
                    final matchesDate = selectedDate == null ||
                        format.format((adData['timestamp'] as Timestamp).toDate()) == format.format(selectedDate!);
                    return matchesQuery && matchesDate;
                  }).toList();

                  final paginatedData = data.skip(_currentPage * _rowsPerPage).take(_rowsPerPage).toList();

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginatedData.length,
                          itemBuilder: (context, index) {
                            final ad = paginatedData[index];
                            final adData = ad.data() as Map<String, dynamic>;
                            final adIndex = data.length - (_currentPage * _rowsPerPage + index);

                            return AdTile(
                              ad: ad,
                              adData: adData,
                              index: adIndex,
                              isOpen: _expandedIndex == index,
                              onTileTap: () {
                                setState(() {
                                  _expandedIndex = _expandedIndex == index ? null : index;
                                });
                              },
                              launchURL: _launchURL,
                              downloadDetails: _downloadDetails,
                              canEditStatus: canEditStatus, // تعديل هنا لإضافة قيمة canEditStatus
                            );
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          (data.length / _rowsPerPage).ceil(),
                              (index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              label: Text('${index + 1}'),
                              selected: _currentPage == index,
                              onSelected: (selected) {
                                setState(() {
                                  _currentPage = index;
                                });
                              },
                              selectedColor: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              if (_currentPage > 0) {
                                setState(() {
                                  _currentPage--;
                                  lastDocument = null; // إعادة التعيين لتحميل الصفحة السابقة
                                  _loadAds(); // تحميل الصفحة الحالية مرة أخرى
                                });
                              }
                            },
                            child: Text('السابق'),
                          ),
                          TextButton(
                            onPressed: () {
                              _loadAds(isNextPage: true);
                            },
                            child: Text('التالي'),
                          )
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      drawer: MainMenu(),
    );
  }
}


class AdTile extends StatefulWidget {
  final QueryDocumentSnapshot ad;
  final Map<String, dynamic> adData;
  final int index;
  final bool isOpen;
  final Function onTileTap;
  final Function(String) launchURL;
  final Function(String, String) downloadDetails;
  final bool canEditStatus; // إضافة السطر ده

  AdTile({
    required this.ad,
    required this.adData,
    required this.index,
    required this.isOpen,
    required this.onTileTap,
    required this.launchURL,
    required this.downloadDetails,
    required this.canEditStatus, // إضافة السطر ده
  });

  @override
  _AdTileState createState() => _AdTileState();
}


class _AdTileState extends State<AdTile> {
  late String dropdownValue;

  @override
  void initState() {
    super.initState();
    final statusItems = [
      'في المراجعة من الادارة',
      'تم انشاء الاعلان وفي مرحلة المراجعة',
      'تم رفض الاعلان من الادارة',
      'تم الايقاف من العميل',
      'جاري العمل علي الاعلان',
      'الاعلان نشط',
      'الاعلان مكتمل',

    ];
    dropdownValue = statusItems.contains(widget.adData['status']) ? widget.adData['status'] : 'في المراجعة من الادارة';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    Color rowColor;
    switch (dropdownValue) {
      case 'الاعلان نشط':
        rowColor = Colors.green;
        break;
      case 'الاعلان مكتمل':
        rowColor = Colors.indigo; // لون للإعلان المكتمل
        break;
      case 'تم رفض الاعلان من الادارة':
        rowColor = Colors.red;
        break;
      case 'تم الايقاف من العميل':
        rowColor = Colors.lightBlueAccent;
        break;
      case 'جاري العمل علي الاعلان':
        rowColor = Colors.orange; // لون مميز لحالة جاري العمل على الإعلان
        break;
      case 'تم انشاء الاعلان وفي مرحلة المراجعة':
        rowColor = Colors.yellow;
        break;
      default:
        rowColor = isDarkMode ? Colors.grey[800]! : (widget.index % 2 == 0 ? Colors.white : Colors.grey[200]!);
    }

    final imageUrl = widget.adData['image post'];
    final linkPost = widget.adData['Link post'];

    String adDetails = '''
الإعلان رقم: ${widget.index} - ${widget.adData['ad name'] ?? 'بدون اسم'}
UID: ${widget.ad.id}
${isNotNullOrEmpty(widget.adData['first name']) ? 'الاسم الأول: ${widget.adData['first name']}\n' : ''}
${isNotNullOrEmpty(widget.adData['last name']) ? 'الاسم الأخير: ${widget.adData['last name']}\n' : ''}
${isNotNullOrEmpty(widget.adData['email']) ? 'البريد الإلكتروني: ${widget.adData['email']}\n' : ''}
${isNotNullOrEmpty(widget.adData['phone']) ? 'رقم الهاتف: ${widget.adData['phone']}\n' : ''}
${isNotNullOrEmpty(widget.adData['google phone']) ? 'رقم الهاتف للإعلان: ${widget.adData['google phone']}\n' : ''}
${isNotNullOrEmpty(widget.adData['whatsApp']) ? 'واتس اب الإعلان: ${widget.adData['whatsApp']}\n' : ''}
Link post: $linkPost
${isNotNullOrEmpty(widget.adData['ad goal']) ? 'هدف الحملة: ${widget.adData['ad goal']}\n' : ''}
${isNotNullOrEmpty(widget.adData['budget']) ? 'الميزانية: ${widget.adData['budget']}\n' : ''}
${isNotNullOrEmpty(widget.adData['duration']) ? 'المدة: ${widget.adData['duration']}\n' : ''}
${isNotNullOrEmpty(widget.adData['location']) ? 'الموقع: ${widget.adData['location']}\n' : ''}
${isNotNullOrEmpty(widget.adData['gender']) ? 'الجنس: ${widget.adData['gender']}\n' : ''}
${isNotNullOrEmpty(widget.adData['age from']) && isNotNullOrEmpty(widget.adData['age to']) ? 'العمر: من ${widget.adData['age from']} إلى ${widget.adData['age to']}\n' : ''}
${isNotNullOrEmpty(widget.adData['text post']) ? 'نص الإعلان: ${widget.adData['text post']}\n' : ''}
${isNotNullOrEmpty(widget.adData['interests']) ? 'الاهتمامات: ${widget.adData['interests']}\n' : ''}
${isNotNullOrEmpty(widget.adData['demographics']) ? 'الديموغرافية: ${widget.adData['demographics']}\n' : ''}
${isNotNullOrEmpty(widget.adData['behavior']) ? 'السلوك: ${widget.adData['behavior']}\n' : ''}
${isNotNullOrEmpty(widget.adData['website']) ? 'الموقع الإلكتروني: ${widget.adData['website']}\n' : ''}
${isNotNullOrEmpty(widget.adData['tiktok code']) ? 'كود تيك توك: ${widget.adData['tiktok code']}\n' : ''}
${isNotNullOrEmpty(widget.adData['link fb page']) ? 'رابط صفحة الفيسبوك: ${widget.adData['link fb page']}\n' : ''}
${isNotNullOrEmpty(widget.adData['keywords google']) ? 'الكلمات المفتاحية لجوجل: ${widget.adData['keywords google']}\n' : ''}
${isNotNullOrEmpty(widget.adData['google notes']) ? 'ملاحظات جوجل: ${widget.adData['google notes']}\n' : ''}
${isNotNullOrEmpty(widget.adData['google type']) ? 'نوع حملة جوجل: ${widget.adData['google type']}\n' : ''}
${isNotNullOrEmpty(widget.adData['detailsForm']) ? 'تفاصيل النموذج: ${widget.adData['detailsForm']}\n' : ''}
${isNotNullOrEmpty(widget.adData['exclude area']) ? 'المناطق المستبعدة: ${widget.adData['exclude area']}\n' : ''}
التوقيت: ${formatTimestamp(widget.adData['timestamp'] as Timestamp)}
حالة الإعلان: ${widget.adData['status'] ?? 'في المراجعة من الادارة'}
''';

    return Container(
      color: rowColor,
      margin: EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExpansionTile(
            title: Text(
              'الإعلان رقم: ${widget.index} - ${widget.adData['ad name'] ?? 'بدون اسم'}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            initiallyExpanded: widget.isOpen,
            onExpansionChanged: (expanded) {
              setState(() {
                widget.onTileTap();
              });
            },
            trailing: Icon(widget.isOpen ? Icons.expand_less : Icons.expand_more, color: textColor),
            children: [
              // ضع هنا باقي التفاصيل اللي عايز تعرضها بعد فتح الطلب
            ],
          ),


          if (widget.isOpen) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('بيانات العميل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  SizedBox(height: 8.0),
                  if (isNotNullOrEmpty(widget.adData['first name']))
                    Row(
                      children: [
                        Text('الاسم الأول:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['first name']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ الاسم الأول')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['first name']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),
                  if (isNotNullOrEmpty(widget.adData['last name']))
                    Row(
                      children: [
                        Text('الاسم الأخير:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['last name']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ الاسم الأخير')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['last name']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),
                  if (isNotNullOrEmpty(widget.adData['email']))
                    Row(
                      children: [
                        Text('البريد الإلكتروني:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['email']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ البريد الإلكتروني')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['email']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),
                  if (isNotNullOrEmpty(widget.adData['phone']))
                    Row(
                      children: [
                        Text('رقم الهاتف:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['phone']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ رقم الهاتف')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['phone']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),

                  SizedBox(height: 16.0),
                  Text('تفاصيل الإعلان', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  SizedBox(height: 8.0),
                  if (isNotNullOrEmpty(linkPost))
                    Row(
                      children: [
                        Text('Link post:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: linkPost));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ الرابط')),
                            );
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => widget.launchURL(linkPost),
                            child: Text(
                              '$linkPost',
                              style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (isNotNullOrEmpty(widget.adData['google phone']))
                    Row(
                      children: [
                        Text('رقم الهاتف للإعلان:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['google phone']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ رقم الهاتف للإعلان')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['google phone']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),
                  if (isNotNullOrEmpty(widget.adData['whatsApp']))
                    Row(
                      children: [
                        Text('واتس اب الإعلان:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['whatsApp']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ رقم الواتس اب للإعلان')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['whatsApp']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),
                  if (isNotNullOrEmpty(imageUrl))
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: imageUrl.split(' | ').asMap().entries.map<Widget>((entry) {
                        int idx = entry.key + 1;
                        String url = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: GestureDetector(
                            onTap: () => widget.launchURL(url),
                            child: Row(
                              children: [
                                Text('$idx-', style: TextStyle(color: Colors.red, fontSize: 16)),
                                IconButton(
                                  icon: Icon(Icons.copy, color: textColor),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: url));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('تم نسخ الرابط')),
                                    );
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    url,
                                    style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  if (isNotNullOrEmpty(widget.adData['budget']))
                    Row(
                      children: [
                        Text('الميزانية:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['budget'].toString()));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ الميزانية')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['budget']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),
                  if (isNotNullOrEmpty(widget.adData['duration']))
                    Row(
                      children: [
                        Text('المدة:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['duration'].toString()));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ المدة')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['duration']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),
                  if (isNotNullOrEmpty(widget.adData['location']))
                    Row(
                      children: [
                        Text('الموقع:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['location']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ الموقع')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['location']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),
                  if (isNotNullOrEmpty(widget.adData['gender']))
                    Row(
                      children: [
                        Text('الجنس:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['gender']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ الجنس')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['gender']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),
                  if (isNotNullOrEmpty(widget.adData['age from']) && isNotNullOrEmpty(widget.adData['age to']))
                    Row(
                      children: [
                        Text('العمر: من', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: '${widget.adData['age from']} إلى ${widget.adData['age to']}'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ العمر')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['age from']} إلى ${widget.adData['age to']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),
                  if (isNotNullOrEmpty(widget.adData['text post']))
                    Row(
                      children: [
                        Text('نص الإعلان:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['text post']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ نص الإعلان')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['text post']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),
                  if (isNotNullOrEmpty(widget.adData['interests']))
                    Row(
                      children: [
                        Text('الاهتمامات:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['interests']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ الاهتمامات')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['interests']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),
                  if (isNotNullOrEmpty(widget.adData['demographics']))
                    Row(
                      children: [
                        Text('الديموغرافية:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['demographics']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ الديموغرافية')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['demographics']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),
                  if (isNotNullOrEmpty(widget.adData['behavior']))
                    Row(
                      children: [
                        Text('السلوك:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['behavior']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ السلوك')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['behavior']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),
                  if (isNotNullOrEmpty(widget.adData['website']))
                    Row(
                      children: [
                        Text('الموقع الإلكتروني:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['website']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ الموقع الإلكتروني')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['website']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),
                  if (isNotNullOrEmpty(widget.adData['tiktok code']))
                    Row(
                      children: [
                        Text('كود تيك توك:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['tiktok code']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ كود تيك توك')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['tiktok code']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),
                  if (isNotNullOrEmpty(widget.adData['link fb page']))
                    Row(
                      children: [
                        Text('رابط صفحة الفيسبوك:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['link fb page']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ رابط صفحة الفيسبوك')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['link fb page']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),
                  // إضافة حقل 'هدف الحملة' بعد الكلمات المفتاحية لجوجل
                  if (isNotNullOrEmpty(widget.adData['keywords google']))
                    Row(
                      children: [
                        Text('الكلمات المفتاحية لجوجل:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['keywords google']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ الكلمات المفتاحية لجوجل')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['keywords google']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),

                  if (isNotNullOrEmpty(widget.adData['ad goal']))
                    Row(
                      children: [
                        Text('هدف الحملة:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['ad goal']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ هدف الحملة')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['ad goal']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),

                  if (isNotNullOrEmpty(widget.adData['google notes']))
                    Row(
                      children: [
                        Text('ملاحظات جوجل:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['google notes']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ ملاحظات جوجل')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['google notes']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),
                  if (isNotNullOrEmpty(widget.adData['google type']))
                    Row(
                      children: [
                        Text('نوع حملة جوجل:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['google type']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ نوع حملة جوجل')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['google type']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),
                  if (isNotNullOrEmpty(widget.adData['detailsForm']))
                    Row(
                      children: [
                        Text('تفاصيل النموذج:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['detailsForm']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ تفاصيل النموذج')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['detailsForm']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),
                  if (isNotNullOrEmpty(widget.adData['exclude area']))
                    Row(
                      children: [
                        Text('المناطق المستبعدة:', style: TextStyle(fontSize: 16, color: textColor)),
                        IconButton(
                          icon: Icon(Icons.copy, color: textColor),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.adData['exclude area']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ المناطق المستبعدة')),
                            );
                          },
                        ),
                        Expanded(
                          child: Text('${widget.adData['exclude area']}', style: TextStyle(fontSize: 16, color: textColor)),
                        ),
                      ],
                    ),
                  Row(
                    children: [
                      Text('التوقيت:', style: TextStyle(fontSize: 16, color: textColor)),
                      IconButton(
                        icon: Icon(Icons.copy, color: textColor),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: formatTimestamp(widget.adData['timestamp'] as Timestamp)));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تم نسخ التوقيت')),
                          );
                        },
                      ),
                      Expanded(
                        child: Text('${formatTimestamp(widget.adData['timestamp'] as Timestamp)}', style: TextStyle(fontSize: 16, color: textColor)),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  Row(
                    children: [
                      Text('حالة الإعلان:', style: TextStyle(fontSize: 16, color: textColor)),
                      DropdownButton<String>(
                        value: dropdownValue,
                        items: [
                          'في المراجعة من الادارة',
                          'تم انشاء الاعلان وفي مرحلة المراجعة',
                          'تم رفض الاعلان من الادارة',
                          'تم الايقاف من العميل',
                          'جاري العمل علي الاعلان',
                          'الاعلان نشط',
                          'الاعلان مكتمل',

                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: widget.canEditStatus
                            ? (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              dropdownValue = newValue;
                            });
                            FirebaseFirestore.instance.collection('created ads').doc(widget.ad.id).update({'status': newValue});
                          }
                        }
                            : null,
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  ElevatedButton(
                    onPressed: () => widget.downloadDetails(adDetails, 'ad_details_${widget.index}.txt'),
                    child: Text('تحميل التفاصيل'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String formatTimestamp(Timestamp timestamp) {
  var date = timestamp.toDate();
  var formatter = DateFormat('yyyy-MM-dd HH:mm');
  return formatter.format(date);
}
