import 'package:flutter/material.dart';

enum AppLanguage { en, ar }

final ValueNotifier<AppLanguage> appLanguage = ValueNotifier<AppLanguage>(
  AppLanguage.en,
);

class Strings {
  final AppLanguage lang;
  const Strings(this.lang);

  static Strings of(BuildContext context) {
    return Strings(appLanguage.value);
  }

  bool get isAr => lang == AppLanguage.ar;
  TextDirection get direction => isAr ? TextDirection.rtl : TextDirection.ltr;

  // Common
  String get languageEnglish => 'English';
  String get languageArabic => 'العربية';
  String get add => isAr ? 'إضافة' : 'Add';
  String get cancel => isAr ? 'إلغاء' : 'Cancel';
  String get saveChanges => isAr ? 'حفظ التغييرات' : 'Save Changes';

  // App/Home
  String get appTitle => isAr ? 'تطبيق المزادات' : 'Auction App';
  String get featuredAuctions => isAr ? 'عقارات مميزة' : 'Featured Auctions';
  String get allAuctions => isAr ? 'كل المزادات' : 'All Auctions';

  // Profile
  String get profile => isAr ? 'الملف الشخصي' : 'Profile';
  String get editProfile => isAr ? 'تعديل' : 'Edit Profile';
  String get cancelEdit => isAr ? 'إلغاء' : 'Cancel';
  String get fullName => isAr ? 'الاسم الكامل' : 'Full Name';
  String get email => isAr ? 'البريد الإلكتروني' : 'Email';
  String get phone => isAr ? 'الهاتف' : 'Phone';
  String get address => isAr ? 'العنوان' : 'Address';
  String get company => isAr ? 'الشركة' : 'Company';
  String get license => isAr ? 'الترخيص' : 'License #';
  String get website => isAr ? 'الموقع' : 'Website';
  String get bio => isAr ? 'نبذة' : 'Bio';
  String get password => isAr ? 'كلمة المرور' : 'Password';
  String get change => isAr ? 'تغيير' : 'Change';
  String joined(String when) => isAr ? 'انضم في $when' : 'Joined $when';
  String get totalBids => isAr ? 'إجمالي المزايدات' : 'Total Bids';
  String get wonAuctions => isAr ? 'مزادات فاز بها' : 'Won Auctions';
  String get rating => isAr ? 'التقييم' : 'Rating';

  // Calendar
  String get installmentCalendar =>
      isAr ? 'تقويم الأقساط' : 'Installment Calendar';
  String get reminders => isAr ? 'التذكيرات' : 'Reminders';
  String remindersFor(DateTime d) => isAr
      ? 'التذكيرات ${d.day}/${d.month}/${d.year}'
      : 'Reminders for ${d.day}/${d.month}/${d.year}';
  String get addReminder => isAr ? 'إضافة تذكير' : 'Add Reminder';
  String get propertyName => isAr ? 'اسم العقار' : 'Property name';
  String get amountEgp => isAr ? 'المبلغ (EGP)' : 'Amount (EGP)';
  String get noReminders =>
      isAr ? 'لا توجد تذكيرات لهذا اليوم' : 'No reminders for this day';

  // Valuation
  String get valuation => isAr ? 'التقييم' : 'Valuation';
  String get yourProperties => isAr ? 'عقاراتك' : 'Your Properties';
  String get addNew => isAr ? 'إضافة جديد' : 'Add New';
  String get marketEstimate => isAr ? 'القيمة السوقية' : 'Market Estimate';
  String get purchasePrice => isAr ? 'سعر الشراء' : 'Purchase Price';
  String get estValue => isAr ? 'القيمة المقدرة' : 'Est. Value';
  String get gain => isAr ? 'الزيادة' : 'Gain';
  String get exportReport => isAr ? 'تصدير التقرير' : 'Export Report';
  String get share => isAr ? 'مشاركة' : 'Share';
  String get valuationBreakdown =>
      isAr ? 'تفاصيل التقييم' : 'Valuation Breakdown';
  String get categoryFactor => isAr ? 'عامل الفئة' : 'Category factor';
  String get holdingPeriod => isAr ? 'مدة الاحتفاظ' : 'Holding period';
  String get neighborhoodIndex => isAr ? 'مؤشر الحي' : 'Neighborhood index';
  String get demandScore => isAr ? 'مؤشر الطلب' : 'Demand score';
  String get comparablesUsed => isAr ? 'مقارَنات مستخدمة' : 'Comparables used';
  String get medianComparable => isAr ? 'الوسيط السعري' : 'Median comparable';
  String get pricePerSqm => isAr ? 'السعر لكل متر²' : 'Estimated price / sqm';
  String get assumedArea => isAr ? 'المساحة المفترضة' : 'Assumed area';
  String get rentalYield => isAr ? 'عائد الإيجار' : 'Rental yield';
  String get confidence => isAr ? 'درجة الثقة' : 'Confidence';
  String get suggestedRange =>
      isAr ? 'نطاق السعر المقترح' : 'Suggested list range';
  String get liquidityDom => isAr ? 'السيولة (أيام بالسوق)' : 'Liquidity (DOM)';
  String get riskScore => isAr ? 'مستوى المخاطر' : 'Risk score';

  // Add Property
  String get addProperty => isAr ? 'إضافة عقار' : 'Add Property';
  String get propertyNameField => isAr ? 'اسم العقار' : 'Property Name';
  String get categoryField => isAr ? 'الفئة' : 'Category';
  String get startPriceField => isAr ? 'السعر الأولي (\$)' : 'Start Price (\$)';
  String get imageUrlField => isAr ? 'رابط الصورة' : 'Image URL';
  String get postedByField => isAr ? 'نشر بواسطة' : 'Posted By';
  String get descriptionField => isAr ? 'الوصف' : 'Description';
  String get listProperty => isAr ? 'إدراج العقار' : 'List Property';
  String get enterPropertyName =>
      isAr ? 'أدخل اسم العقار' : 'Enter property name';
  String get enterStartPrice =>
      isAr ? 'أدخل السعر الأولي' : 'Enter start price';
  String get enterImageUrl => isAr ? 'أدخل رابط الصورة' : 'Enter image URL';
  String get enterPosterName =>
      isAr ? 'أدخل اسم الناشر' : 'Enter poster\'s name';
  String get enterAddress => isAr ? 'أدخل العنوان' : 'Enter address';
  String get enterDescription => isAr ? 'أدخل الوصف' : 'Enter description';
  String get propertyListedSuccess =>
      isAr ? 'تم إدراج العقار بنجاح!' : 'Property listed successfully!';

  // Bid Page
  String get auctionDetails => isAr ? 'تفاصيل المزاد' : 'Auction Details';
  String get bidHistory => isAr ? 'تاريخ المزايدة' : 'Bid History';
  String get topBidders => isAr ? 'أفضل 5 مزايدين' : 'Top 5 Bidders';
  String get propertyDetails => isAr ? 'تفاصيل العقار' : 'Property Details';
  String get placeBid => isAr ? 'وضع مزايدة' : 'Place Bid';
  String get bidPlaced => isAr ? 'تم وضع المزايدة!' : 'Bid placed!';
  String get beds => isAr ? 'غرف النوم' : 'Beds';
  String get bathrooms => isAr ? 'الحمامات' : 'Bathrooms';
  String get payment => isAr ? 'الدفع' : 'Payment';
  String get cashOrInstallment => isAr ? 'نقد أو أقساط' : 'Cash or Installment';
  String get currentPrice => isAr ? 'السعر الحالي' : 'Current Price';
  String get bidders => isAr ? 'المزايدين' : 'Bidders';
  String get location => isAr ? 'الموقع' : 'Location';
  String get primeArea =>
      isAr ? 'منطقة راقية، قريبة من المرافق' : 'Prime area, close to amenities';
  String get spaciousModern => isAr
      ? 'واسع، عصري، ومثالي لاحتياجاتك.'
      : 'Spacious, modern, and perfect for your needs.';
  String get startPrice => isAr ? 'السعر الأولي' : 'Start Price';
  String get category => isAr ? 'الفئة' : 'Category';
  String get postedBy => isAr ? 'نشر بواسطة' : 'Posted By';
  String get description => isAr ? 'الوصف' : 'Description';

  // Auctions Page
  String get auctions => isAr ? 'المزادات' : 'Auctions';
  String get searchProperties =>
      isAr ? 'البحث في العقارات...' : 'Search properties...';
  String get filters => isAr ? 'المرشحات' : 'Filters';
  String get symbol => isAr ? 'الرمز' : 'Symbol';
  String get name => isAr ? 'الاسم' : 'Name';
  String get percentage => isAr ? 'النسبة' : 'Percentage';
  String get changePercent => isAr ? 'تغيير %' : 'Change %';
  String get apply => isAr ? 'تطبيق' : 'Apply';
  String get clear => isAr ? 'مسح' : 'Clear';
  String get minBeds => isAr ? 'أقل عدد غرف نوم' : 'Min Beds';
  String get minBaths => isAr ? 'أقل عدد حمامات' : 'Min Baths';
  String get minBidders => isAr ? 'أقل عدد مزايدين' : 'Min Bidders';
  String get all => isAr ? 'الكل' : 'All';

  // Home Page
  String get discountOff => isAr ? 'خصم 20%' : '20% OFF';
  String get discountsOnAuctions =>
      isAr ? 'خصومات على المزادات' : 'Discounts on Auctions';
}
