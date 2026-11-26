import 'app_language.dart';

/// 5-language UI copy dictionary mirroring `kknutrivet-webapp`
/// (English, Hindi, Odia, Telugu, Tamil).
class AppStrings {
  const AppStrings({
    required this.locale,
    // Bottom nav
    required this.navHome,
    required this.navShop,
    required this.navCare,
    required this.navShots,
    required this.navAccount,
    // Header & greetings
    required this.goodMorning,
    required this.goodAfternoon,
    required this.goodEvening,
    required this.hey,
    required this.there,
    required this.setDeliveryLocation,
    required this.searchHint,
    required this.selectLanguage,
    required this.language,
    // Species tabs
    required this.speciesAll,
    required this.speciesDogs,
    required this.speciesCats,
    required this.speciesCattle,
    required this.speciesGoats,
    required this.speciesPoultry,
    required this.speciesSmallPets,
    // Common & product
    required this.add,
    required this.addToCart,
    required this.buyNow,
    required this.outOfStock,
    required this.seeAll,
    required this.viewCart,
    required this.checkout,
    required this.apply,
    required this.remove,
    required this.cancel,
    required this.confirmAndPlaceOrder,
    // Cart
    required this.cart,
    required this.yourCart,
    required this.orderSummary,
    required this.subtotal,
    required this.delivery,
    required this.deliveryFee,
    required this.free,
    required this.orderTotal,
    required this.unlockedFreeDelivery,
    required this.awayFromFreeDelivery,
    required this.couponCode,
    required this.availableOffers,
    required this.kkCoins,
    // Checkout
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.payOnlineTitle,
    required this.partialCodTitlePrefix,
    required this.partialCodAdvanceSuffix,
    required this.onDelivery,
    required this.payLaterTitle,
    required this.payLaterDesc,
    required this.emiTitle,
    required this.emiDesc,
    required this.codTitle,
    required this.placeOrder,
    required this.pay,
    // Account & Orders & Consultations
    required this.myAccount,
    required this.shoppingAndOrders,
    required this.myOrders,
    required this.myOrdersSubtitle,
    required this.savedAddresses,
    required this.savedAddressesSubtitle,
    required this.prescriptions,
    required this.myPets,
    required this.rewardsAndReferrals,
    required this.consultations,
    required this.trackYourOrder,
    required this.continueShopping,
  });

  final AppLocale locale;

  final String navHome;
  final String navShop;
  final String navCare;
  final String navShots;
  final String navAccount;

  final String goodMorning;
  final String goodAfternoon;
  final String goodEvening;
  final String hey;
  final String there;
  final String setDeliveryLocation;
  final String searchHint;
  final String selectLanguage;
  final String language;

  final String speciesAll;
  final String speciesDogs;
  final String speciesCats;
  final String speciesCattle;
  final String speciesGoats;
  final String speciesPoultry;
  final String speciesSmallPets;

  final String add;
  final String addToCart;
  final String buyNow;
  final String outOfStock;
  final String seeAll;
  final String viewCart;
  final String checkout;
  final String apply;
  final String remove;
  final String cancel;
  final String confirmAndPlaceOrder;

  final String cart;
  final String yourCart;
  final String orderSummary;
  final String subtotal;
  final String delivery;
  final String deliveryFee;
  final String free;
  final String orderTotal;
  final String unlockedFreeDelivery;
  final String awayFromFreeDelivery;
  final String couponCode;
  final String availableOffers;
  final String kkCoins;

  final String deliveryAddress;
  final String paymentMethod;
  final String payOnlineTitle;
  final String partialCodTitlePrefix;
  final String partialCodAdvanceSuffix;
  final String onDelivery;
  final String payLaterTitle;
  final String payLaterDesc;
  final String emiTitle;
  final String emiDesc;
  final String codTitle;
  final String placeOrder;
  final String pay;

  final String myAccount;
  final String shoppingAndOrders;
  final String myOrders;
  final String myOrdersSubtitle;
  final String savedAddresses;
  final String savedAddressesSubtitle;
  final String prescriptions;
  final String myPets;
  final String rewardsAndReferrals;
  final String consultations;
  final String trackYourOrder;
  final String continueShopping;

  String greetingForHour(int hour) {
    if (hour >= 4 && hour < 12) return goodMorning;
    if (hour >= 12 && hour < 17) return goodAfternoon;
    if (hour >= 17 && hour < 22) return goodEvening;
    return hey;
  }

  String speciesLabel(String key) {
    switch (key.toLowerCase()) {
      case 'all':
        return speciesAll;
      case 'dog':
      case 'dogs':
        return speciesDogs;
      case 'cat':
      case 'cats':
        return speciesCats;
      case 'cattle':
        return speciesCattle;
      case 'goat/sheep':
      case 'goats':
      case 'goat':
        return speciesGoats;
      case 'poultry':
        return speciesPoultry;
      case 'small pets':
      case 'small pet':
      case 'bird':
        return speciesSmallPets;
      default:
        return key;
    }
  }

  static AppStrings of(AppLocale locale) {
    switch (locale) {
      case AppLocale.en:
        return _en;
      case AppLocale.hi:
        return _hi;
      case AppLocale.or_:
        return _or;
      case AppLocale.te:
        return _te;
      case AppLocale.ta:
        return _ta;
    }
  }

  static const _en = AppStrings(
    locale: AppLocale.en,
    navHome: 'Home',
    navShop: 'Shop',
    navCare: 'Care',
    navShots: 'Shots',
    navAccount: 'Account',
    goodMorning: 'Good morning',
    goodAfternoon: 'Good afternoon',
    goodEvening: 'Good evening',
    hey: 'Hey',
    there: 'there',
    setDeliveryLocation: 'Set delivery location',
    searchHint: 'Search products, animals, or brands...',
    selectLanguage: 'Select Language',
    language: 'Language',
    speciesAll: 'All',
    speciesDogs: 'Dogs',
    speciesCats: 'Cats',
    speciesCattle: 'Cattle',
    speciesGoats: 'Goats',
    speciesPoultry: 'Poultry',
    speciesSmallPets: 'Small Pets',
    add: 'Add',
    addToCart: 'Add to Cart',
    buyNow: 'Buy Now',
    outOfStock: 'Out of stock',
    seeAll: 'See all',
    viewCart: 'View Cart',
    checkout: 'Checkout',
    apply: 'Apply',
    remove: 'Remove',
    cancel: 'Cancel',
    confirmAndPlaceOrder: 'Confirm & Place Order',
    cart: 'Cart',
    yourCart: 'Your Cart',
    orderSummary: 'Order Summary',
    subtotal: 'Subtotal',
    delivery: 'Delivery',
    deliveryFee: 'Delivery Fee',
    free: 'FREE',
    orderTotal: 'Order total',
    unlockedFreeDelivery: "You've unlocked FREE delivery",
    awayFromFreeDelivery: 'away from FREE delivery',
    couponCode: 'Coupon code',
    availableOffers: 'Available offers',
    kkCoins: 'KK Coins',
    deliveryAddress: 'Delivery address',
    paymentMethod: 'Payment method',
    payOnlineTitle: 'Pay online (UPI / Card / Netbanking)',
    partialCodTitlePrefix: 'Pay',
    partialCodAdvanceSuffix: 'advance now',
    onDelivery: 'on delivery',
    payLaterTitle: 'Pay Later (Buy Now, Pay Later)',
    payLaterDesc: 'Buy now and pay later via Cashfree Pay Later partners',
    emiTitle: 'EMI (Easy Installments)',
    emiDesc: 'Credit Card EMI, Debit Card EMI & Cardless EMI via Cashfree',
    codTitle: 'Cash on Delivery (COD)',
    placeOrder: 'Place Order',
    pay: 'Pay',
    myAccount: 'My Account',
    shoppingAndOrders: 'SHOPPING & ORDERS',
    myOrders: 'My Orders',
    myOrdersSubtitle: 'Track packages, view invoices & order history',
    savedAddresses: 'Saved Addresses',
    savedAddressesSubtitle: 'Manage delivery addresses & pincodes',
    prescriptions: 'Prescriptions',
    myPets: 'My Pets',
    rewardsAndReferrals: 'Rewards & Referrals',
    consultations: 'Consultations',
    trackYourOrder: 'Track your order',
    continueShopping: 'Continue shopping',
  );

  static const _hi = AppStrings(
    locale: AppLocale.hi,
    navHome: 'होम',
    navShop: 'शॉप',
    navCare: 'केयर',
    navShots: 'शॉट्स',
    navAccount: 'अकाउंट',
    goodMorning: 'सुप्रभात',
    goodAfternoon: 'नमस्ते',
    goodEvening: 'शुभ संध्या',
    hey: 'नमस्ते',
    there: 'जी',
    setDeliveryLocation: 'डिलीवरी लोकेशन चुनें',
    searchHint: 'प्रोडक्ट, पशु या ब्रांड खोजें...',
    selectLanguage: 'भाषा चुनें',
    language: 'भाषा',
    speciesAll: 'सभी',
    speciesDogs: 'कुत्ते',
    speciesCats: 'बिल्लियाँ',
    speciesCattle: 'मवेशी',
    speciesGoats: 'बकरियाँ',
    speciesPoultry: 'पोल्ट्री',
    speciesSmallPets: 'छोटे पेट्स',
    add: 'जोड़ें',
    addToCart: 'कार्ट में जोड़ें',
    buyNow: 'अभी खरीदें',
    outOfStock: 'स्टॉक समाप्त',
    seeAll: 'सभी देखें',
    viewCart: 'कार्ट देखें',
    checkout: 'चेकआउट',
    apply: 'लागू करें',
    remove: 'हटाएँ',
    cancel: 'रद्द करें',
    confirmAndPlaceOrder: 'ऑर्डर कन्फर्म करें',
    cart: 'कार्ट',
    yourCart: 'आपका कार्ट',
    orderSummary: 'ऑर्डर सारांश',
    subtotal: 'उप-योग',
    delivery: 'डिलीवरी',
    deliveryFee: 'डिलीवरी शुल्क',
    free: 'मुफ़्त',
    orderTotal: 'कुल राशि',
    unlockedFreeDelivery: 'आपको मुफ़्त डिलीवरी मिल गई है',
    awayFromFreeDelivery: 'और जोड़ें मुफ़्त डिलीवरी के लिए',
    couponCode: 'कूपन कोड',
    availableOffers: 'उपलब्ध ऑफर',
    kkCoins: 'KK कॉइन्स',
    deliveryAddress: 'डिलीवरी पता',
    paymentMethod: 'भुगतान का तरीका',
    payOnlineTitle: 'ऑनलाइन भुगतान (UPI / कार्ड / नेटबैंकिंग)',
    partialCodTitlePrefix: 'अभी',
    partialCodAdvanceSuffix: 'एडवांस भुगतान करें',
    onDelivery: 'डिलीवरी पर',
    payLaterTitle: 'पे लेटर (बाद में भुगतान)',
    payLaterDesc: 'अभी खरीदें और Cashfree पे-लेटर पार्टनर्स के ज़रिए बाद में भुगतान करें',
    emiTitle: 'EMI (आसान किश्तें)',
    emiDesc: 'क्रेडिट कार्ड, डेबिट कार्ड और कार्डलेस EMI विकल्प',
    codTitle: 'कैश ऑन डिलीवरी (COD)',
    placeOrder: 'ऑर्डर करें',
    pay: 'भुगतान करें',
    myAccount: 'मेरा अकाउंट',
    shoppingAndOrders: 'शॉपिंग और ऑर्डर',
    myOrders: 'मेरे ऑर्डर',
    myOrdersSubtitle: 'पैकेज ट्रैक करें, इनवॉइस और ऑर्डर हिस्ट्री देखें',
    savedAddresses: 'सहेजे गए पते',
    savedAddressesSubtitle: 'डिलीवरी पते और पिनकोड प्रबंधित करें',
    prescriptions: 'प्रिस्क्रिप्शन',
    myPets: 'मेरे पशु',
    rewardsAndReferrals: 'रिवॉर्ड और रेफरल',
    consultations: 'डॉक्टर सलाह',
    trackYourOrder: 'ऑर्डर ट्रैक करें',
    continueShopping: 'खरीदारी जारी रखें',
  );

  static const _or = AppStrings(
    locale: AppLocale.or_,
    navHome: 'ହୋମ୍',
    navShop: 'ସପ୍',
    navCare: 'କେୟାର',
    navShots: 'ସଟ୍ସ',
    navAccount: 'ଆକାଉଣ୍ଟ',
    goodMorning: 'ଶୁଭ ସକାଳ',
    goodAfternoon: 'ନମସ୍କାର',
    goodEvening: 'ଶୁଭ ସନ୍ଧ୍ୟା',
    hey: 'ନମସ୍କାର',
    there: 'ବନ୍ଧୁ',
    setDeliveryLocation: 'ଡେଲିଭରି ଠିକଣା ବାଛନ୍ତୁ',
    searchHint: 'ପ୍ରଡକ୍ଟ, ପଶୁ କିମ୍ବା ବ୍ରାଣ୍ଡ ଖୋଜନ୍ତୁ...',
    selectLanguage: 'ଭାଷା ବାଛନ୍ତୁ',
    language: 'ଭାଷା',
    speciesAll: 'ସବୁ',
    speciesDogs: 'କୁକୁର',
    speciesCats: 'ବିଲେଇ',
    speciesCattle: 'ଗୋରୁଗାଈ',
    speciesGoats: 'ଛେଳି',
    speciesPoultry: 'କୁକୁଡ଼ା',
    speciesSmallPets: 'ଛୋଟ ପଶୁ',
    add: 'ଯୋଡନ୍ତୁ',
    addToCart: 'କାର୍ଟରେ ଯୋଡନ୍ତୁ',
    buyNow: 'ଏବେ କିଣନ୍ତୁ',
    outOfStock: 'ଷ୍ଟକ୍ ନାହିଁ',
    seeAll: 'ସବୁ ଦେଖନ୍ତୁ',
    viewCart: 'କାର୍ଟ ଦେଖନ୍ତୁ',
    checkout: 'ଚେକ୍ଆଉଟ୍',
    apply: 'ଲାଗୁ କରନ୍ତୁ',
    remove: 'ହଟାନ୍ତୁ',
    cancel: 'ବାତିଲ୍',
    confirmAndPlaceOrder: 'ଅର୍ଡର ନିଶ୍ଚିତ କରନ୍ତୁ',
    cart: 'କାର୍ଟ',
    yourCart: 'ଆପଣଙ୍କ କାର୍ଟ',
    orderSummary: 'ଅର୍ଡର ସାରାଂଶ',
    subtotal: 'ମୋଟ ମୂଲ୍ୟ',
    delivery: 'ଡେଲିଭରି',
    deliveryFee: 'ଡେଲିଭରି ଶୁଳ୍କ',
    free: 'ମାଗଣା',
    orderTotal: 'ସର୍ବମୋଟ',
    unlockedFreeDelivery: 'ଆପଣ ମାଗଣା ଡେଲିଭରି ପାଇଛନ୍ତି',
    awayFromFreeDelivery: 'ଆହୁରି ଯୋଡନ୍ତୁ ମାଗଣା ଡେଲିଭରି ପାଇଁ',
    couponCode: 'କୁପନ୍ କୋଡ୍',
    availableOffers: 'ଉପଲବ୍ଧ ଅଫର୍',
    kkCoins: 'KK କଏନ୍',
    deliveryAddress: 'ଡେଲିଭରି ଠିକଣା',
    paymentMethod: 'ପେମେଣ୍ଟ ପଦ୍ଧତି',
    payOnlineTitle: 'ଅନଲାଇନ୍ ପେମେଣ୍ଟ (UPI / କାର୍ଡ / ନେଟବ୍ୟାଙ୍କିଙ୍ଗ)',
    partialCodTitlePrefix: 'ଏବେ',
    partialCodAdvanceSuffix: 'ଅଗ୍ରିମ ଦିଅନ୍ତୁ',
    onDelivery: 'ଡେଲିଭରି ସମୟରେ',
    payLaterTitle: 'ପେ ଲେଟର୍ (ପରେ ଦିଅନ୍ତୁ)',
    payLaterDesc: 'ଏବେ କିଣନ୍ତୁ ଏବଂ Cashfree ପାର୍ଟନର ମାଧ୍ୟମରେ ପରେ ଦିଅନ୍ତୁ',
    emiTitle: 'EMI (ସହଜ କିସ୍ତି)',
    emiDesc: 'କ୍ରେଡିଟ୍ କାର୍ଡ, ଡେବିଟ୍ କାର୍ଡ ଏବଂ କାର୍ଡଲେସ୍ EMI',
    codTitle: 'କ୍ୟାଶ୍ ଅନ୍ ଡେଲିଭରି (COD)',
    placeOrder: 'ଅର୍ଡର କରନ୍ତୁ',
    pay: 'ପେମେଣ୍ଟ କରନ୍ତୁ',
    myAccount: 'ମୋ ଆକାଉଣ୍ଟ',
    shoppingAndOrders: 'ସପିଂ ଏବଂ ଅର୍ଡର',
    myOrders: 'ମୋ ଅର୍ଡର',
    myOrdersSubtitle: 'ପ୍ୟାକେଜ୍ ଟ୍ରାକ୍ କରନ୍ତୁ ଏବଂ ଇନଭଏସ୍ ଦେଖନ୍ତୁ',
    savedAddresses: 'ସଂରକ୍ଷିତ ଠିକଣା',
    savedAddressesSubtitle: 'ଡେଲିଭରି ଠିକଣା ଏବଂ ପିନକୋଡ୍ ପରିଚାଳନା କରନ୍ତୁ',
    prescriptions: 'ପ୍ରେସକ୍ରିପସନ୍',
    myPets: 'ମୋ ପଶୁ',
    rewardsAndReferrals: 'ରିୱାର୍ଡ ଏବଂ ରେଫରାଲ୍',
    consultations: 'ଡାକ୍ତର ପରାମର୍ଶ',
    trackYourOrder: 'ଅର୍ଡର ଟ୍ରାକ୍ କରନ୍ତୁ',
    continueShopping: 'କିଣାକିଣି ଜାରି ରଖନ୍ତୁ',
  );

  static const _te = AppStrings(
    locale: AppLocale.te,
    navHome: 'హోమ్',
    navShop: 'షాప్',
    navCare: 'కేర్',
    navShots: 'షాట్స్',
    navAccount: 'ఖాతా',
    goodMorning: 'శుభోదయం',
    goodAfternoon: 'నమస్కారం',
    goodEvening: 'శుభ సాయంత్రం',
    hey: 'నమస్కారం',
    there: 'గారు',
    setDeliveryLocation: 'డెలివరీ లొకేషన్ ఎంచుకోండి',
    searchHint: 'ఉత్పత్తులు, జంతువులు లేదా బ్రాండ్లు వెతకండి...',
    selectLanguage: 'భాషను ఎంచుకోండి',
    language: 'భాష',
    speciesAll: 'అన్నీ',
    speciesDogs: 'కుక్కలు',
    speciesCats: 'పిల్లులు',
    speciesCattle: 'పశువులు',
    speciesGoats: 'మేకలు',
    speciesPoultry: 'కోళ్లు',
    speciesSmallPets: 'చిన్న పెంపుడు జంతువులు',
    add: 'చేర్చు',
    addToCart: 'కార్ట్‌లో చేర్చు',
    buyNow: 'ఇప్పుడే కొనండి',
    outOfStock: 'స్టాక్ లేదు',
    seeAll: 'అన్నీ చూడండి',
    viewCart: 'కార్ట్ చూడండి',
    checkout: 'చెక్అవుట్',
    apply: 'వర్తింపజేయి',
    remove: 'తొలగించు',
    cancel: 'రద్దు చేయి',
    confirmAndPlaceOrder: 'ఆర్డర్ నిర్ధారించండి',
    cart: 'కార్ట్',
    yourCart: 'మీ కార్ట్',
    orderSummary: 'ఆర్డర్ సారాంశం',
    subtotal: 'ఉపమొత్తం',
    delivery: 'డెలివరీ',
    deliveryFee: 'డెలివరీ ఛార్జీ',
    free: 'ఉచితం',
    orderTotal: 'మొత్తం',
    unlockedFreeDelivery: 'మీకు ఉచిత డెలివరీ లభించింది',
    awayFromFreeDelivery: 'ఉచిత డెలివరీ కోసం ఇంకా',
    couponCode: 'కూపన్ కోడ్',
    availableOffers: 'అందుబాటులో ఉన్న ఆఫర్లు',
    kkCoins: 'KK కాయిన్స్',
    deliveryAddress: 'డెలివరీ చిరునామా',
    paymentMethod: 'చెల్లింపు విధానం',
    payOnlineTitle: 'ఆన్‌లైన్ చెల్లింపు (UPI / కార్డ్ / నెట్‌బ్యాంకింగ్)',
    partialCodTitlePrefix: 'ఇప్పుడు',
    partialCodAdvanceSuffix: 'అడ్వాన్స్ చెల్లించండి',
    onDelivery: 'డెలివరీ సమయంలో',
    payLaterTitle: 'పే లేటర్ (తర్వాత చెల్లించండి)',
    payLaterDesc: 'ఇప్పుడు కొని Cashfree పార్టనర్స్ ద్వారా తర్వాత చెల్లించండి',
    emiTitle: 'EMI (సులభ వాయిదాలు)',
    emiDesc: 'క్రెడిట్ కార్డ్, డెబిట్ కార్డ్ మరియు కార్డ్‌లెస్ EMI',
    codTitle: 'క్యాష్ ఆన్ డెలివరీ (COD)',
    placeOrder: 'ఆర్డర్ చేయండి',
    pay: 'చెల్లించండి',
    myAccount: 'నా ఖాతా',
    shoppingAndOrders: 'షాపింగ్ & ఆర్డర్లు',
    myOrders: 'నా ఆర్డర్లు',
    myOrdersSubtitle: 'ప్యాకేజీలను ట్రాక్ చేయండి & ఇన్‌వాయిస్‌లు చూడండి',
    savedAddresses: 'సేవ్ చేసిన చిరునామాలు',
    savedAddressesSubtitle: 'డెలివరీ చిరునామాలు & పిన్‌కోడ్‌లను నిర్వహించండి',
    prescriptions: 'ప్రిస్క్రిప్షన్లు',
    myPets: 'నా పెంపుడు జంతువులు',
    rewardsAndReferrals: 'రివార్డ్స్ & రిఫరల్స్',
    consultations: 'వైద్య సలహా',
    trackYourOrder: 'ఆర్డర్ ట్రాక్ చేయండి',
    continueShopping: 'షాపింగ్ కొనసాగించండి',
  );

  static const _ta = AppStrings(
    locale: AppLocale.ta,
    navHome: 'முகப்பு',
    navShop: 'கடை',
    navCare: 'பராமரிப்பு',
    navShots: 'ஷாட்ஸ்',
    navAccount: 'கணக்கு',
    goodMorning: 'காலை வணக்கம்',
    goodAfternoon: 'வணக்கம்',
    goodEvening: 'மாலை வணக்கம்',
    hey: 'வணக்கம்',
    there: 'நண்பரே',
    setDeliveryLocation: 'டெலிவரி இடத்தைத் தேர்ந்தெடுக்கவும்',
    searchHint: 'பொருட்கள், விலங்குகள் அல்லது பிராண்ட் தேடுங்கள்...',
    selectLanguage: 'மொழியைத் தேர்ந்தெடுக்கவும்',
    language: 'மொழி',
    speciesAll: 'அனைத்தும்',
    speciesDogs: 'நாய்கள்',
    speciesCats: 'பூனைகள்',
    speciesCattle: 'கால்நடைகள்',
    speciesGoats: 'ஆடுகள்',
    speciesPoultry: 'கோழிகள்',
    speciesSmallPets: 'சிறிய செல்லப்பிராணிகள்',
    add: 'சேர்',
    addToCart: 'கார்ட்டில் சேர்',
    buyNow: 'இப்போது வாங்கு',
    outOfStock: 'கையிருப்பு இல்லை',
    seeAll: 'அனைத்தையும் பார்',
    viewCart: 'கார்ட் பார்',
    checkout: 'செக்அவுட்',
    apply: 'பயன்படுத்து',
    remove: 'நீக்கு',
    cancel: 'ரத்து செய்',
    confirmAndPlaceOrder: 'ஆர்டரை உறுதி செய்',
    cart: 'கார்ட்',
    yourCart: 'உங்கள் கார்ட்',
    orderSummary: 'ஆர்டர் சுருக்கம்',
    subtotal: 'துணை மொத்தம்',
    delivery: 'டெலிவரி',
    deliveryFee: 'டெலிவரி கட்டணம்',
    free: 'இலவசம்',
    orderTotal: 'மொத்த தொகை',
    unlockedFreeDelivery: 'உங்களுக்கு இலவச டெலிவரி கிடைத்துள்ளது',
    awayFromFreeDelivery: 'இலவச டெலிவரிக்கு இன்னும்',
    couponCode: 'கூப்பன் குறியீடு',
    availableOffers: 'கிடைக்கும் சலுகைகள்',
    kkCoins: 'KK நாணயங்கள்',
    deliveryAddress: 'டெலிவரி முகவரி',
    paymentMethod: 'கட்டண முறை',
    payOnlineTitle: 'ஆன்லைன் கட்டணம் (UPI / கார்டு / நெட்பேங்கிங்)',
    partialCodTitlePrefix: 'இப்போது',
    partialCodAdvanceSuffix: 'முன்பணம் செலுத்துங்கள்',
    onDelivery: 'டெலிவரியில்',
    payLaterTitle: 'பே லேட்டர் (பின்னர் செலுத்துங்கள்)',
    payLaterDesc: 'இப்போது வாங்கி Cashfree பார்ட்னர்கள் மூலம் பின்னர் செலுத்துங்கள்',
    emiTitle: 'EMI (எளிய தவணைகள்)',
    emiDesc: 'கிரெடிட் கார்டு, டெபிட் கார்டு & கார்டில்லாத EMI',
    codTitle: 'கேஷ் ஆன் டெலிவரி (COD)',
    placeOrder: 'ஆர்டர் செய்',
    pay: 'செலுத்து',
    myAccount: 'என் கணக்கு',
    shoppingAndOrders: 'ஷாப்பிங் & ஆர்டர்கள்',
    myOrders: 'என் ஆர்டர்கள்',
    myOrdersSubtitle: 'ஆர்டர்களைக் கண்காணித்து இன்வாய்ஸ் பார்க்கவும்',
    savedAddresses: 'சேமித்த முகவரிகள்',
    savedAddressesSubtitle: 'டெலிவரி முகவரிகள் மற்றும் பின்கோடுகளை நிர்வகிக்கவும்',
    prescriptions: 'மருந்துச்சீட்டுகள்',
    myPets: 'என் செல்லப்பிராணிகள்',
    rewardsAndReferrals: 'வெகுமதிகள் & பரிந்துரைகள்',
    consultations: 'மருத்துவர் ஆலோசனை',
    trackYourOrder: 'ஆர்டரைக் கண்காணிக்கவும்',
    continueShopping: 'ஷாப்பிங்கைத் தொடரவும்',
  );
}
