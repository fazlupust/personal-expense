part of 'prayer_tasbih_controller.dart';

const List<ZikirItem> _presetZikirs = [
  ZikirItem(
    id: 'subhanallah',
    arabic: 'سُبْحَانَ اللَّهِ',
    titleBn: 'সুবহানাল্লাহ',
    titleEn: 'SubhanAllah',
    meaningBn: 'আল্লাহ পরম পবিত্র ও সকল ত্রুটিমুক্ত',
    meaningEn: 'Glory be to Allah',
    defaultTarget: 33,
    benefitBn: 'নামাজ পরবর্তী মাসনুন আমল। জান্নাতে একটি বৃক্ষ রোপণ করা হয়।',
    category: ZikirCategory.prayer,
  ),
  ZikirItem(
    id: 'alhamdulillah',
    arabic: 'الْحَمْدُ لِلَّهِ',
    titleBn: 'আলহামদুলিল্লাহ',
    titleEn: 'Alhamdulillah',
    meaningBn: 'সকল প্রশংসা ও স্তুতি একমাত্র আল্লাহর জন্য',
    meaningEn: 'All praise is due to Allah',
    defaultTarget: 33,
    benefitBn: 'মিজানের পাল্লাকে নেকি দিয়ে ভরপুর করে দেয়।',
    category: ZikirCategory.prayer,
  ),
  ZikirItem(
    id: 'allahu_akbar',
    arabic: 'اللَّهُ أَكْبَرُ',
    titleBn: 'আল্লাহু আকবার',
    titleEn: 'Allahu Akbar',
    meaningBn: 'আল্লাহ সর্বশ্রেষ্ঠ ও মহান',
    meaningEn: 'Allah is the Greatest',
    defaultTarget: 34,
    benefitBn: 'আসমান ও জমিনের মধ্যবর্তী স্থান নেকিতে পূর্ণ করে।',
    category: ZikirCategory.prayer,
  ),
  ZikirItem(
    id: 'la_ilaha_illallah',
    arabic: 'لَا إِلٰهَ إِلَّا اللَّهُ',
    titleBn: 'লা ইলাহা ইল্লাল্লাহ',
    titleEn: 'La ilaha illallah',
    meaningBn: 'আল্লাহ ছাড়া সত্য কোনো উপাস্য নেই',
    meaningEn: 'There is no god but Allah',
    defaultTarget: 100,
    benefitBn: 'সর্বোত্তম জিকির (আফজালুজ জিকির) এবং জান্নাতের চাবিকাঠি।',
    category: ZikirCategory.prayer,
  ),
  ZikirItem(
    id: 'subhanallahi_wa_bihamdihi',
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    titleBn: 'সুবহানাল্লাহি ওয়া বিহামদিহি',
    titleEn: 'SubhanAllahi wa bihamdihi',
    meaningBn: 'আল্লাহর প্রশংসাসহ পবিত্রতা ঘোষণা করি',
    meaningEn: 'Glory be to Allah and all praise is His',
    defaultTarget: 100,
    benefitBn:
        'দিনে ১০০ বার পাঠে সমুদ্রের ফেনা পরিমাণ গুনাহ হলেও ক্ষমা করে দেওয়া হয়।',
    category: ZikirCategory.morningEvening,
  ),
  ZikirItem(
    id: 'astaghfirullah',
    arabic: 'أَسْتَغْفِرُ اللَّهَ',
    titleBn: 'আস্তাগফিরুল্লাহ',
    titleEn: 'Astaghfirullah',
    meaningBn: 'আমি আল্লাহর কাছে ক্ষমা প্রার্থনা করছি',
    meaningEn: 'I seek forgiveness from Allah',
    defaultTarget: 100,
    benefitBn: 'রিজিকে প্রাচুর্য, বিপদমুক্তি ও মনের প্রশান্তি এনে দেয়।',
    category: ZikirCategory.forgiveness,
  ),
  ZikirItem(
    id: 'subhanallahi_wa_bihamdihi_azim',
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
    titleBn: 'সুবহানাল্লাহি ওয়া বিহামদিহি সুবহানাল্লাহিল আজিম',
    titleEn: 'SubhanAllahi wa bihamdihi SubhanAllahil Azeem',
    meaningBn: 'আল্লাহর প্রশংসাসহ পবিত্রতা ঘোষণা করি, মহান আল্লাহ পরম পবিত্র',
    meaningEn:
        'Glory be to Allah and all praise is His, Glory be to Allah the Almighty',
    defaultTarget: 100,
    benefitBn:
        'মুখে উচ্চারণে সহজ, মিজানের পাল্লায় অতি ভারী এবং রহমানের কাছে অতি প্রিয় (সহীহ বুখারী: ৬৪০৬)।',
    category: ZikirCategory.morningEvening,
  ),
  ZikirItem(
    id: 'hasbunallah',
    arabic: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
    titleBn: 'হাসবুনাল্লাহু ওয়া নি\'মাল ওয়াকিল',
    titleEn: 'Hasbunallahu wa ni\'mal wakeel',
    meaningBn: 'আল্লাহই আমাদের জন্য যথেষ্ট এবং তিনিই সর্বোত্তম কর্মবিধায়ক',
    meaningEn:
        'Sufficient for us is Allah, and He is the best Disposer of affairs',
    defaultTarget: 100,
    benefitBn: 'বিপদ-আপদ, মানসিক চাপ ও শত্রুর ভয় থেকে পরম নিরাপত্তা (সূরা আলে ইমরান: ১৭৩)।',
    category: ZikirCategory.dua,
  ),
  ZikirItem(
    id: 'la_hawla',
    arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    titleBn: 'লা হাওলা ওয়ালা কুওয়াতা ইল্লা বিল্লাহ',
    titleEn: 'La hawla wa la quwwata illa billah',
    meaningBn: 'আল্লাহর সাহায্য ছাড়া কোনো শক্তি বা ক্ষমতা নেই',
    meaningEn: 'There is no power nor strength except with Allah',
    defaultTarget: 100,
    benefitBn: 'জান্নাতের অমূল্য রত্নভাণ্ডারের অন্যতম (সহীহ বুখারী: ৬৩৮৪)।',
    category: ZikirCategory.dua,
  ),
  ZikirItem(
    id: 'bismika_amootu_wa_ahya',
    arabic: 'اللَّهُمَّ بِاسْمِكَ أَمُوتُ وَأَحْيَا',
    titleBn: 'আল্লাহুম্মা বিসমিকা আমূতু ওয়া আহয়া (ঘুমানোর দোয়া)',
    titleEn: 'Allahumma Bismika Amootu wa Ahya (Sleeping Dua)',
    meaningBn:
        'হে আল্লাহ! আপনার নাম নিয়ে আমি মৃত্যুবরণ করছি (ঘুমাচ্ছি) এবং জীবিত হচ্ছি (জাগ্রত হচ্ছি)। (উচ্চারণ: আল্লা-হুম্মা বিসমিকা আমূতু ওয়া আহ্ইয়া)',
    meaningEn: 'O Allah, in Your name I die and I live.',
    defaultTarget: 3,
    benefitBn:
        'রাতের ঘুমের পূর্বে ডান কাতে শয়ন করে এই দোয়া পাঠের সুন্নত আমল (সহীহ বুখারী: ৬৩১২, ৬৩২৪)।',
    category: ZikirCategory.dua,
  ),
  ZikirItem(
    id: 'alhamdulillah_alladhi_ahyana',
    arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
    titleBn: 'ঘুম থেকে উঠার দোয়া (আলহামদুলিল্লাহিল্লাজি আহইয়ানা)',
    titleEn: 'Dua Upon Waking Up',
    meaningBn:
        'সকল প্রশংসা আল্লাহর জন্য, যিনি আমাদেরকে মৃত্যু (ঘুম) দেওয়ার পর পুনরায় জীবন দান করলেন এবং তাঁরই কাছে পুনরুত্থান।',
    meaningEn:
        'All praise is for Allah who gave us life after having taken it from us, and unto Him is the resurrection.',
    defaultTarget: 1,
    benefitBn:
        'ঘুম থেকে জাগ্রত হওয়ার পর নবীজি (সাঃ) এই দোয়া পাঠ করতেন (সহীহ বুখারী: ৬৩১২)।',
    category: ZikirCategory.dua,
  ),
  ZikirItem(
    id: 'astaghfirullah_wa_atubu_ilaih',
    arabic: 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
    titleBn: 'আস্তাগফিরুল্লাহ ওয়া আতুবু ইলাইহি',
    titleEn: 'Astaghfirullaha wa Atubu Ilayh',
    meaningBn: 'আমি আল্লাহর কাছে ক্ষমা চাই এবং তাঁর দিকে প্রত্যাবর্তন করি',
    meaningEn: 'I seek forgiveness from Allah and repent to Him',
    defaultTarget: 100,
    benefitBn:
        'নবীজি (সাঃ) দিনে ৭০ থেকে ১০০ বার এই তাওবা ও ইস্তিগফার পাঠ করতেন।',
    category: ZikirCategory.forgiveness,
  ),

  ZikirItem(
    id: 'ayatul_kursi',
    arabic:
        'اللَّهُ لَا إِلٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
    titleBn: 'আয়াতুল কুরসী',
    titleEn: 'Ayatul Kursi',
    pronunciationBn:
        'আল্লা-হু লা- ইলা-হা ইল্লা- হুওয়াল হাইয়্যুল ক্বাইয়্যূম, লা- তা’খুযুহূ সিনাতুঁও ওয়ালা- নাওম, লাহূ মা- ফিস্ সামা-ওয়া-তি ওয়া মা- ফিল আরদ্ব, মান যাল্লাযী ইয়াশফা‘উ ‘ইনদাহূ ইল্লা- বিইযনিহ, ইয়া‘লামু মা- বাইনা আইদীহিম ওয়া মা- খলফাহুম, ওয়ালা- ইউহীতূনা বিশাইয়িম মিন ‘ইলমিহী ইল্লা- বিমা- শা-আ, ওয়াসি‘আ কুরসিয়্যুহুস্ সামা-ওয়া-তি ওয়াল আরদ্ব, ওয়ালা- ইয়াউদুহূ হিফযুহুমা-, ওয়া হুওয়াল ‘আলিইয়্যুল ‘আযীম।',
    meaningBn:
        'আল্লাহ, তিনি ছাড়া সত্য কোনো উপাস্য নেই, তিনি চিরঞ্জীব ও সর্বসত্তার ধারক। তাঁকে তন্দ্রাও স্পর্শ করতে পারে না এবং নিদ্রাও নয়। আকাশ ও পৃথিবীতে যা কিছু আছে সবই তাঁর। কে আছে যে তাঁর অনুমতি ছাড়া তাঁর কাছে সুপারিশ করবে? তাদের সামনে ও পেছনে যা কিছু আছে তা তিনি জানেন। আর তাঁর জ্ঞানের কোনো অংশই তারা আয়ত্ত করতে পারে না তাঁর ইচ্ছা ব্যতীত। তাঁর কুরসী সমস্ত আকাশ ও পৃথিবীকে পরিবেষ্টন করে আছে, আর এ দুটির রক্ষণাবেক্ষণ তাঁকে পরিশ্রান্ত করে না। তিনি পরম উচ্চ, সর্বশ্রেষ্ঠ।',
    meaningEn:
        'Allah! There is no deity except Him, the Ever-Living, the Sustainer of all existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great.',
    defaultTarget: 7,
    benefitBn:
        'কুরআনের শ্রেষ্ঠ আয়াত। প্রতিটি ফরজ নামাজের পর পাঠে জান্নাত সুনিশ্চিত (নাসায়ী)।',
    category: ZikirCategory.prayer,
  ),
  ZikirItem(
    id: 'four_kalimas',
    arabic:
        'سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلَا إِلٰهَ إِلَّا اللَّهُ وَاللَّهُ أَكْبَرُ',
    titleBn: 'চার তাসবীহ (কালেমা তামজিদ)',
    titleEn: 'SubhanAllah wal-Hamdulillah',
    meaningBn:
        'আল্লাহ পরম পবিত্র, সকল প্রশংসা আল্লাহর, আল্লাহ ছাড়া সত্য উপাস্য নেই এবং আল্লাহ সর্বশ্রেষ্ঠ',
    meaningEn:
        'Glory be to Allah, all praise to Allah, no god but Allah, Allah is the Greatest',
    defaultTarget: 100,
    benefitBn:
        'হযরত ইব্রাহিম (আঃ) জান্নাতের বৃক্ষ রোপণের জন্য এই জিকির উপহার দিয়েছিলেন।',
    category: ZikirCategory.prayer,
  ),
  ZikirItem(
    id: 'la_ilaha_wahdahu',
    arabic:
        'لَا إِلٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    titleBn: 'লা ইলাহা ইল্লাল্লাহু ওয়াহদাহু',
    titleEn: 'La ilaha illallahu Wahdahu',
    meaningBn:
        'আল্লাহ ছাড়া সত্য কোনো উপাস্য নেই, তিনি একক, কোনো শরিক নেই; রাজত্ব ও প্রশংসা একমাত্র তাঁরই...',
    meaningEn:
        'There is no god but Allah alone with no partner, to Him belongs dominion and praise...',
    defaultTarget: 100,
    benefitBn:
        'দিনে ১০০ বার পাঠে ১০টি গোলাম মুক্ত করার সওয়াব ও ১০০টি গুনাহ মাফ হয়।',
    category: ZikirCategory.prayer,
  ),
  ZikirItem(
    id: 'allahumma_ajirni',
    arabic: 'اللَّهُمَّ أَجِرْنِي مِنَ النَّارِ',
    titleBn: 'জাহান্নাম মুক্তির দোয়া',
    titleEn: 'Allahumma Ajirni Minan Naar',
    meaningBn: 'হে আল্লাহ! আমাকে জাহান্নামের আগুন থেকে রক্ষা করুন',
    meaningEn: 'O Allah, save me from the fire of Hell',
    defaultTarget: 7,
    benefitBn:
        'ফজর ও মাগরিবের পর ৭ বার পাঠ করলে জাহান্নাম থেকে মুক্তির পরোয়ানা মেলে।',
    category: ZikirCategory.prayer,
  ),
  ZikirItem(
    id: 'sayyidul_istighfar',
    arabic:
        'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلٰهَ إِلَّا أَنْتَ ، خَلَقْتَنِي وَأَنَا عَبْدُكَ ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ ، أَعُوْذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ ، أَبُوْءُ لَكَ بِنِعْمَتِكَ عَلَيَّ ، وَأَبُوْءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
    titleBn: 'সাইয়্যিদুল ইস্তিগফার',
    titleEn: 'Sayyidul Istighfar',
    pronunciationBn:
        'আল্লা-হুম্মা আনতা রব্বী লা- ইলা-হা ইল্লা- আনতা, খলাক্বতানী ওয়া আনা ‘আবদুকা, ওয়া আনা ‘আলা- ‘আহদিকা ওয়া ওয়া‘দিকা মাসতাত্বা‘তু, আ‘ঊযু বিকা মিন শাররি মা- সনা‘তু, আবূউ লাকা বিনি‘মাতিকা ‘আলাইয়্যা, ওয়া আবূউ বিযাম্বী ফাগফির লী, ফাইন্নাহূ লা- ইয়াগফিরুয যুনূবা ইল্লা- আনতা।',
    meaningBn:
        'হে আল্লাহ! আপনি আমার রব, আপনি ছাড়া সত্য কোনো উপাস্য নেই। আপনি আমাকে সৃষ্টি করেছেন এবং আমি আপনার বান্দা। আমি সাধ্যমতো আপনার অঙ্গীকার ও প্রতিশ্রতির ওপর আছি। আমি আমার কৃতকর্মের অনিষ্ট থেকে আপনার আশ্রয় চাই। আমার ওপর আপনার নিয়ামত স্বীকার করছি এবং আমার গুনাহও স্বীকার করছি। অতএব আমাকে ক্ষমা করে দিন, নিশ্চয়ই আপনি ছাড়া গুনাহ ক্ষমা করার কেউ নেই।',
    meaningEn:
        'O Allah, You are my Lord, there is no deity except You. You created me and I am Your servant, and I abide by Your covenant and promise as best I can. I seek refuge in You from the evil of what I have done. I acknowledge Your favor upon me, and I acknowledge my sin, so forgive me, for none forgives sins except You.',
    defaultTarget: 3,
    benefitBn:
        'ক্ষমা প্রার্থনার শ্রেষ্ঠতম দোয়া। সকালে বা সন্ধ্যায় একনিষ্ঠভাবে পাঠে জান্নাত প্রাপ্তির সুসংবাদ (সহীহ বুখারী: ৬৩০৬)।',
    category: ZikirCategory.forgiveness,
  ),
  ZikirItem(
    id: 'dua_yunus',
    arabic:
        'لَا إِلٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
    titleBn: 'দোয়া ইউনুস (বিপদ মুক্তি)',
    titleEn: 'Dua Yunus',
    meaningBn:
        'আপনি ছাড়া সত্য কোনো উপাস্য নেই, আপনি পরম পবিত্র, নিশ্চয় আমি অপরাধীদের অন্তর্ভুক্ত',
    meaningEn:
        'There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers',
    defaultTarget: 100,
    benefitBn:
        'যেকোনো কঠিন বিপদ, দুশ্চিন্তা ও রোগ-শোক মুক্তির জন্য পরীক্ষিত দোয়া।',
    category: ZikirCategory.forgiveness,
  ),
  ZikirItem(
    id: 'durood_sharif',
    arabic: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ',
    titleBn: 'দুরুদ শরীফ',
    titleEn: 'Durood Sharif',
    meaningBn:
        'হে আল্লাহ! হযরত মুহাম্মদ (সাঃ) ও তাঁর পরিবারের ওপর রহমত বর্ষণ করুন',
    meaningEn: 'O Allah, send blessings upon Muhammad and his family',
    defaultTarget: 100,
    benefitBn: 'একবার পাঠে ১০টি রহমত, ১০টি গুনাহ মাফ ও ১০টি মর্যাদা বৃদ্ধি।',
    category: ZikirCategory.salawat,
  ),
  ZikirItem(
    id: 'durood_ibrahim',
    arabic:
        'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ ، اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ',
    titleBn: 'দুরুদে ইব্রাহিম',
    titleEn: 'Durood-e-Ibrahim',
    pronunciationBn:
        'আল্লা-হুম্মা সাল্লি ‘আলা- মুহাম্মাদিঁও ওয়া ‘আলা- আ-লি মুহাম্মাদ, কামা- সাল্লাইতা ‘আলা- ইবরা-হীমা ওয়া ‘আলা- আ-লি ইবরা-হীম, ইন্নাকা হামীদুম মাজীদ। আল্লা-হুম্মা বা-রিক ‘আলা- মুহাম্মাদিঁও ওয়া ‘আলা- আ-লি মুহাম্মাদ, কামা- বা-রকতা ‘আলা- ইবরা-হীমা ওয়া ‘আলা- আ-লি ইবরা-হীম, ইন্নাকা হামীদুম মাজীদ।',
    meaningBn:
        'হে আল্লাহ! মুহাম্মদ (সাঃ) এবং তাঁর পরিবারের ওপর রহমত বর্ষণ করুন, যেমন আপনি ইব্রাহিম (আঃ) এবং তাঁর পরিবারের ওপর রহমত বর্ষণ করেছিলেন। নিশ্চয়ই আপনি প্রশংসিত ও সম্মানিত। হে আল্লাহ! মুহাম্মদ (সাঃ) এবং তাঁর পরিবারের ওপর বরকত বর্ষণ করুন, যেমন আপনি ইব্রাহিম (আঃ) এবং তাঁর পরিবারের ওপর বরকত বর্ষণ করেছিলেন। নিশ্চয়ই আপনি প্রশংসিত ও সম্মানিত।',
    meaningEn:
        'O Allah, send blessings upon Muhammad and upon the family of Muhammad, as You sent blessings upon Ibrahim and upon the family of Ibrahim; indeed, You are Praiseworthy and Glorious. O Allah, bless Muhammad and the family of Muhammad, as You blessed Ibrahim and the family of Ibrahim; indeed, You are Praiseworthy and Glorious.',
    defaultTarget: 10,
    benefitBn: 'নামাজের তাশাহহুদে পঠিত সর্বোত্তম ও সর্বাধিক বরকতপূর্ণ দুরুদ।',
    category: ZikirCategory.salawat,
  ),
  ZikirItem(
    id: 'adada_khalqihi',
    arabic:
        'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ عَدَدَ خَلْقِهِ وَرِضَا نَفْسِهِ وَزِنَةَ عَرْشِهِ وَمِدَادَ كَلِمَاتِهِ',
    titleBn: 'কোটি নেকির জিকির (আদাদা খালকিহি)',
    titleEn: 'SubhanAllahi Adada Khalqihi',
    meaningBn:
        'আল্লাহর পবিত্রতা ঘোষণা করি তাঁর সৃষ্টির সংখ্যার সমপরিমাণ, তাঁর সন্তুষ্টির সমপরিমাণ, আরশের ওজনের সমপরিমাণ...',
    meaningEn:
        'Glory be to Allah and His is the praise, according to the number of His creation...',
    defaultTarget: 3,
    benefitBn:
        'সকালে মাত্র ৩ বার পাঠ করলে সারাদিনের সব জিকিরের সমান সওয়াব অর্জিত হয়।',
    category: ZikirCategory.morningEvening,
  ),
  ZikirItem(
    id: 'bismillahillazi',
    arabic:
        'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ',
    titleBn: 'ক্ষতি ও অনিষ্ট থেকে বাঁচার দোয়া',
    titleEn: 'Bismillahillazi La Yadurru',
    meaningBn:
        'আল্লাহর নামে, যাঁর নামের সাথে আসমান ও জমিনের কোনো কিছুই ক্ষতি করতে পারে না, তিনি সর্বশ্রোতা ও সর্বজ্ঞ',
    meaningEn:
        'In the Name of Allah, with Whose Name nothing upon earth or in the heavens can cause harm...',
    defaultTarget: 3,
    benefitBn:
        'সকালে ও সন্ধ্যায় ৩ বার পাঠ করলে বিষাক্ত প্রাণী বা কোনো অনিষ্ট ক্ষতি করতে পারে না।',
    category: ZikirCategory.morningEvening,
  ),
  ZikirItem(
    id: 'hasbiyallahu',
    arabic:
        'حَسْبِيَ اللَّهُ لَا إِلٰهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
    titleBn: 'সকল দুশ্চিন্তা মুক্তির দোয়া',
    titleEn: 'Hasbiyallahu La Ilaha Illa Hu',
    meaningBn:
        'আল্লাহই আমার জন্য যথেষ্ট, তিনি ছাড়া সত্য উপাস্য নেই, তাঁরই ওপর ভরসা করি এবং তিনি মহা আরশের মালিক',
    meaningEn:
        'Sufficient for me is Allah; there is no deity except Him. On Him I have relied, Lord of the Great Throne',
    defaultTarget: 7,
    benefitBn:
        'সকাল ও সন্ধ্যায় ৭ বার পাঠ করলে দুনিয়া ও আখিরাতের সকল দুশ্চিন্তার জন্য আল্লাহই যথেষ্ট হয়ে যান।',
    category: ZikirCategory.morningEvening,
  ),
  ZikirItem(
    id: 'ask_jannah',
    arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْجَنَّةَ',
    titleBn: 'জান্নাত প্রার্থনার দোয়া',
    titleEn: 'Allahumma Inni As\'alukal Jannah',
    meaningBn: 'হে আল্লাহ! আমি আপনার নিকট জান্নাতুল ফিরদাউস প্রার্থনা করছি',
    meaningEn: 'O Allah, I ask You for Paradise',
    defaultTarget: 7,
    benefitBn:
        'প্রতিদিন পাঠ করলে জান্নাত নিজেই আল্লাহর কাছে সেই বান্দার জন্য সুপারিশ করে।',
    category: ZikirCategory.morningEvening,
  ),
  ZikirItem(
    id: 'kalima_tayyibah',
    arabic: 'لَا إِلٰهَ إِلَّا اللَّهُ مُحَمَّدٌ رَسُولُ اللَّهِ',
    titleBn: 'কালেমা তাইয়্যেবা',
    titleEn: 'Kalima Tayyibah',
    meaningBn: 'আল্লাহ ছাড়া সত্য কোনো উপাস্য নেই, মুহাম্মদ (সাঃ) আল্লাহর রাসুল',
    meaningEn: 'There is no god but Allah, Muhammad is the Messenger of Allah',
    defaultTarget: 100,
    benefitBn: 'ঈমানের মূল ভিত্তি ও সর্বোত্তম জিকির।',
    category: ZikirCategory.dua,
  ),

  ZikirItem(
    id: 'ya_hayyu_ya_qayyum',
    arabic: 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ',
    titleBn: 'ইয়া হাইয়্যু ইয়া কাইয়্যুম',
    titleEn: 'Ya Hayyu Ya Qayyum',
    meaningBn: 'হে চিরঞ্জীব! হে সর্বনিয়ন্তা! আপনার রহমতের আশ্রয় চাই',
    meaningEn: 'O Ever Living, O Sustainer, by Your mercy I seek help',
    defaultTarget: 100,
    benefitBn: 'যে কোনো কঠিন সমস্যা সমাধানের শক্তিশালী দোয়া।',
    category: ZikirCategory.dua,
  ),
  ZikirItem(
    id: 'rabbana_atina',
    arabic:
        'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    titleBn: 'রাব্বানা আতিনা ফিদ দুনিয়া',
    titleEn: 'Rabbana Atina Fid Dunya',
    meaningBn:
        'হে আমাদের রব! আমাদের দুনিয়াতে কল্যাণ দিন, আখিরাতেও কল্যাণ দিন এবং আগুনের শাস্তি থেকে বাঁচান',
    meaningEn:
        'Our Lord, give us in this world good and in the Hereafter good, and save us from the fire',
    defaultTarget: 33,
    benefitBn: 'রাসুলুল্লাহ (সাঃ) এই দোয়াটি সবচেয়ে বেশি পাঠ করতেন।',
    category: ZikirCategory.dua,
  ),
  ZikirItem(
    id: 'rabbish_rahli',
    arabic:
        'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي وَاحْلُلْ عُقْدَةً مِنْ لِسَانِي',
    titleBn: 'রাব্বিশ রাহলি সাদরি (সহজ হওয়ার দোয়া)',
    titleEn: 'Rabbish Rahli Sadri',
    meaningBn:
        'হে আমার পালনকর্তা! আমার বক্ষ প্রশস্ত করে দিন, কাজ সহজ করে দিন এবং জিহ্বার জড়তা দূর করে দিন',
    meaningEn:
        'My Lord, expand for me my breast, ease for me my task, and untie the knot from my tongue',
    defaultTarget: 33,
    benefitBn:
        'পরীক্ষা, ইন্টারভিউ বা কঠিন কাজের পূর্বে মানসিক স্থিরতা ও সফলতার দোয়া।',
    category: ZikirCategory.dua,
  ),
  ZikirItem(
    id: 'dua_for_parents',
    arabic: 'رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
    titleBn: 'পিতা-মাতার জন্য দোয়া',
    titleEn: 'Dua for Parents',
    meaningBn:
        'হে আমার প্রতিপালক! তাঁদের (পিতা-মাতা) উভয়ের প্রতি দয়া করুন, যেভাবে শৈশবে তাঁরা আমাকে লালন-পালন করেছিলেন',
    meaningEn:
        'My Lord, have mercy upon them as they brought me up when I was small',
    defaultTarget: 33,
    benefitBn:
        'পিতা-মাতার জীবিত বা মৃত অবস্থায় তাঁদের জন্য শ্রেষ্ঠ কুরআনিক দোয়া।',
    category: ZikirCategory.dua,
  ),
  ZikirItem(
    id: 'shifa_body_pain',
    arabic:
        'بِسْمِ اللَّهِ (৩ বার) ✦ أَعُوْذُ بِاللهِ وَقُدْرَتِهِ مِنْ شَرِّ مَا أَجِدُ وَأُحَاذِرُ (৭ বার)',
    titleBn: '[১২৪] শরীরে কোনো ব্যথা অনুভব করলে যা করবে ও বলবে',
    titleEn: 'Dua for Body Pain (Bismillah 3x & Shifa Dua 7x)',
    pronunciationBn:
        'বিসমিল্লাহ (৩ বার) ও আ‘ঊযু বিল্লা-হি ওয়া ক্বুদরাতিহী মিন শাররি মা আজিদু ওয়া উহা-যিরু (৭ বার)',
    meaningBn:
        'আপনার দেহের যে স্থানে আপনি ব্যথা অনুভব করছেন, সেখানে আপনার হাত রেখে তিনবার বলুন: বিসমিল্লাহ (আল্লাহর নামে)। আর সাতবার বলুন: আ‘ঊযু বিল্লা-হি ওয়া ক্বুদরাতিহী মিন শাররি মা আজিদু ওয়া উহা-যিরু (এই যে ব্যথা আমি অনুভব করছি এবং যার আমি আশঙ্কা করছি, তা থেকে আমি আল্লাহ্ এবং তাঁর কুদরতের আশ্রয় প্রার্থনা করছি)।',
    meaningEn:
        'Place your hand where you feel pain and say 3 times: Bismillah (In the Name of Allah). And say 7 times: I seek refuge in Allah and in His power from the evil of what I find and of what I guard against.',
    defaultTarget: 10,
    benefitBn:
        '[১২৪] শরীরের ব্যথার স্থানে হাত রেখে ৩ বার "বিসমিল্লাহ" বলে এরপর ৭ বার এই দোয়াটি পাঠ করবে (সহীহ মুসলিম: ৪/১৭২৮, নং ২২০২)।',
    category: ZikirCategory.dua,
  ),
  ZikirItem(
    id: 'post_prayer_sea_foam',
    arabic:
        'سُبْحَانَ اللهِ، وَالْحَمْدُ لِلَّهِ، وَاللهُ أَكْبَرُ\n✦\nلَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    titleBn: 'হিসনুল মুসলিম ২৫.৪',
    titleEn: 'Hisnul Muslim 25.4 (Post-Prayer 100x)',
    pronunciationBn: 'সুবহা-নাল্লাহ, আলহামদুলিল্লাহ, আল্লা-হু আকবার',
    meaningBn:
        'প্রত্যেকটি ৩৩ বার করে বলবে:\nআল্লাহ কতই না পবিত্র-মহান। সকল প্রশংসা আল্লাহ্ জন্য। আল্লাহ সবচেয়ে বড়।\n\nতারপর বলবে:\nএকমাত্র আল্লাহ ছাড়া কোনো হক্ব ইলাহ নেই, তাঁর কোনো শরীক নেই, রাজত্ব তাঁরই, সকল প্রশংসা তাঁরই এবং তিনি সবকিছুর উপর ক্ষমতাবান।',
    meaningEn:
        'Recite each 33 times:\nGlory be to Allah, All praise is due to Allah, Allah is the Greatest.\n\nThen say (100th):\nThere is no true deity except Allah alone, with no partner. His is the dominion and His is the praise, and He has power over all things.',
    defaultTarget: 100,
    benefitBn:
        '[২৫.৪] প্রত্যেকটি ৩৩ বার করে মোট ৯৯ বার পাঠ করার পর ১০০তম পূর্ণ করতে এই দোয়া পাঠ করলে সমুদ্রের ফেনার মতো পাপরাশিও ক্ষমা করে দেওয়া হয় (সহীহ মুসলিম: ১/৪১৮, নং ৫৯৭)।',
    category: ZikirCategory.prayer,
  ),
];
