import os, re

def extract_map(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # regex to match: 'key': 'value' or "key": "value"
    # Note: values might be multiline or contain escaped quotes
    items = {}
    pattern = re.compile(r"^\s*['\"]([^'\"]+)['\"]\s*:\s*(?:'((?:\\'|[^'])*)'|\"((?:\\\"|[^\"])*)\")\s*,?", re.MULTILINE)
    for match in pattern.finditer(content):
        key = match.group(1)
        val = match.group(2) if match.group(2) is not None else match.group(3)
        # unescape escaped quotes if needed
        val = val.replace(r"\'", "'").replace(r'\"', '"').replace(r'\n', '\n')
        items[key] = val
    return items

def main():
    base_dir = r'c:\Users\Ferdi Ahyana yusri\Downloads\hajicare new\hajicare'
    locales_dir = os.path.join(base_dir, 'lib', 'core', 'locales')
    
    # Load current maps
    id_map = extract_map(os.path.join(locales_dir, 'id.dart'))
    en_map = extract_map(os.path.join(locales_dir, 'en.dart'))
    jv_map = extract_map(os.path.join(locales_dir, 'jv.dart'))
    su_map = extract_map(os.path.join(locales_dir, 'su.dart'))
    
    print(f"Loaded: id={len(id_map)}, en={len(en_map)}, jv={len(jv_map)}, su={len(su_map)}")

    # Specific keys we used in login_screen.dart & login_controller.dart & register
    required_auth_keys = {
        'auth.officialSafe': {
            'id': 'Aman & Resmi',
            'en': 'Safe & Official',
            'jv': 'Aman & Resmi',
            'su': 'Aman & Resmi',
        },
        'auth.welcomeHeading': {
            'id': 'Selamat datang,\n',
            'en': 'Welcome,\n',
            'jv': 'Sugeng rawuh,\n',
            'su': 'Wilujeng sumping,\n',
        },
        'auth.welcomeGreeting': {
            'id': 'Ahlan wa Sahlan.',
            'en': 'Ahlan wa Sahlan.',
            'jv': 'Ahlan wa Sahlan.',
            'su': 'Ahlan wa Sahlan.',
        },
        'auth.welcomeDesc': {
            'id': 'Satu tempat untuk mendampingi perjalanan ibadah Anda tetap aman, terhubung, dan khusyuk.',
            'en': 'One place to keep your pilgrimage safe, connected, and solemn.',
            'jv': 'Satunggal papan kagem ndampingi lampah ibadah panjenengan tetep aman, kasambung, lan khusyuk.',
            'su': 'Hiji tempat pikeun ngaping lalampahan ibadah anjeun tetep aman, nyambung, sareng khusyuk.',
        },
        'auth.demoBadge': {
            'id': 'Teman Perjalanan Jamaah (Demo)',
            'en': 'Pilgrim Travel Companion (Demo)',
            'jv': 'Rencang Lampah Jamaah (Demo)',
            'su': 'Rerencangan Lampah Jamaah (Demo)',
        },
        'auth.featureSafe': {
            'id': 'Aman',
            'en': 'Safe',
            'jv': 'Aman',
            'su': 'Aman',
        },
        'auth.featureConnected': {
            'id': 'Terhubung',
            'en': 'Connected',
            'jv': 'Kasambung',
            'su': 'Kanyambung',
        },
        'auth.featureInclusive': {
            'id': 'Inklusif',
            'en': 'Inclusive',
            'jv': 'Inklusif',
            'su': 'Inklusif',
        },
        'auth.loginCardTitle': {
            'id': 'Masuk ke Akun',
            'en': 'Sign In to Account',
            'jv': 'Mlebet dhateng Akun',
            'su': 'Lebet ka Akun',
        },
        'auth.loginCardSubtitle': {
            'id': 'Gunakan email yang sudah terdaftar',
            'en': 'Use your registered email',
            'jv': 'Ginakaken email ingkang sampun kadaftar',
            'su': 'Anggo surélék anu parantos kadaptar',
        },
        'auth.email': {
            'id': 'Email',
            'en': 'Email',
            'jv': 'Email',
            'su': 'Surélék',
        },
        'auth.emailHint': {
            'id': 'nama@email.com',
            'en': 'name@email.com',
            'jv': 'nama@email.com',
            'su': 'nami@email.com',
        },
        'auth.password': {
            'id': 'Kata Sandi / PIN',
            'en': 'Password / PIN',
            'jv': 'Tembung Sandi / PIN',
            'su': 'Kecap Sandi / PIN',
        },
        'auth.passwordHint': {
            'id': 'Masukkan PIN / kata sandi',
            'en': 'Enter PIN / password',
            'jv': 'Lebetaken PIN / tembung sandi',
            'su': 'Lebetkeun PIN / kecap sandi',
        },
        'auth.forgotPassword': {
            'id': 'Lupa kata sandi?',
            'en': 'Forgot password?',
            'jv': 'Kesupen tembung sandi?',
            'su': 'Hilap kecap sandi?',
        },
        'auth.showPassword': {
            'id': 'Tampilkan kata sandi',
            'en': 'Show password',
            'jv': 'Tingalaken tembung sandi',
            'su': 'Témbongkeun kecap sandi',
        },
        'auth.hidePassword': {
            'id': 'Sembunyikan kata sandi',
            'en': 'Hide password',
            'jv': 'Singgahaken tembung sandi',
            'su': 'Sumputkeun kecap sandi',
        },
        'auth.rememberMe': {
            'id': 'Ingat saya di perangkat ini',
            'en': 'Remember me on this device',
            'jv': 'Émut kula ing piranti menika',
            'su': 'Émutan sim kuring dina parangkat ieu',
        },
        'auth.loginLoading': {
            'id': 'Memproses Masuk...',
            'en': 'Processing Login...',
            'jv': 'Saweg Mlebet...',
            'su': 'Nuju Lebet...',
        },
        'auth.loginBtn': {
            'id': 'Masuk ke Aplikasi',
            'en': 'Sign In to App',
            'jv': 'Mlebet dhateng Aplikasi',
            'su': 'Lebet ka Aplikasi',
        },
        'auth.orDivider': {
            'id': 'atau',
            'en': 'or',
            'jv': 'utawi',
            'su': 'atanapi',
        },
        'auth.googleSignIn': {
            'id': 'Masuk dengan Google',
            'en': 'Sign in with Google',
            'jv': 'Mlebet kaliyan Google',
            'su': 'Lebet nganggo Google',
        },
        'auth.noAccount': {
            'id': 'Belum memiliki akun?',
            'en': "Don't have an account?",
            'jv': 'Dèrèng gadhah akun?',
            'su': 'Teu acan gaduh akun?',
        },
        'auth.registerNow': {
            'id': 'Daftar sekarang',
            'en': 'Register now',
            'jv': 'Daftar sakmenika',
            'su': 'Daptar ayeuna',
        },
        'auth.helpTitle': {
            'id': 'Butuh bantuan masuk?',
            'en': 'Need help signing in?',
            'jv': 'Betah pitulungan mlebet?',
            'su': 'Peryogi bantosan lebet?',
        },
        'auth.helpSubtitle': {
            'id': 'Petugas Maktab & Pos Kesehatan siap memandu.',
            'en': 'Maktab officers & Health posts are ready to guide you.',
            'jv': 'Petugas Maktab & Pos Kasarasan sumadya nuntun.',
            'su': 'Petugas Maktab & Pos Kaséhatan sayaga ngabingbing.',
        },
        'auth.encryptedNote': {
            'id': 'Kerahasiaan data jamaah terenkripsi dan terlindungi',
            'en': 'Pilgrim data is encrypted and protected',
            'jv': 'Wadosipun data jamaah kaenkripsi lan karerigen',
            'su': 'Rusiah data jamaah kaénkripsi sareng kajaga',
        },
        'auth.demoModeBtn': {
            'id': 'Masuk Mode Pengujian (Demo Jamaah)',
            'en': 'Enter Testing Mode (Pilgrim Demo)',
            'jv': 'Mlebet Mode Panaliten (Demo Jamaah)',
            'su': 'Lebet Mode Tés (Demo Jamaah)',
        },
        'auth.errorFillEmailPassword': {
            'id': 'Harap isi email dan kata sandi terlebih dahulu.',
            'en': 'Please enter email and password first.',
            'jv': 'Kersaa ngisi email lan tembung sandi rumiyin.',
            'su': 'Punten eusian surélék sareng kecap sandi heula.',
        },
        'auth.errorUserNotFound': {
            'id': 'Data pengguna tidak ditemukan.',
            'en': 'User data not found.',
            'jv': 'Data pamanggih mboten kapanggih.',
            'su': 'Data pangguna henteu kapendak.',
        },
        'auth.loginSuccessTitle': {
            'id': 'Berhasil Masuk',
            'en': 'Login Successful',
            'jv': 'Kasil Mlebet',
            'su': 'Hasil Lebet',
        },
        'auth.loginSuccessMessage': {
            'id': 'Selamat datang kembali di HajiCare.',
            'en': 'Welcome back to HajiCare.',
            'jv': 'Sugeng rawuh malih wonten ing HajiCare.',
            'su': 'Wilujeng sumping deui di HajiCare.',
        },
        'auth.loginFailedTitle': {
            'id': 'Belum Bisa Masuk',
            'en': 'Unable to Sign In',
            'jv': 'Dèrèng Saged Mlebet',
            'su': 'Teu Tiasa Lebet',
        },
        'auth.tryAgain': {
            'id': 'Coba Lagi',
            'en': 'Try Again',
            'jv': 'Cobi Malih',
            'su': 'Cobi Deui',
        },
        'auth.loginGeneralError': {
            'id': 'Terjadi kesalahan saat masuk. Silakan coba beberapa saat lagi.',
            'en': 'An error occurred while signing in. Please try again shortly.',
            'jv': 'Wonten kalepatan nalika mlebet. Cobi sawetawis malih.',
            'su': 'Aya kasalahan nalika lebet. Mangga cobi sakedap deui.',
        },
        'auth.googleUserNotFound': {
            'id': 'Data akun Google tidak ditemukan.',
            'en': 'Google account data not found.',
            'jv': 'Data akun Google mboten kapanggih.',
            'su': 'Data akun Google henteu kapendak.',
        },
        'auth.googleSuccessTitle': {
            'id': 'Selamat Datang!',
            'en': 'Welcome!',
            'jv': 'Sugeng Rawuh!',
            'su': 'Wilujeng Sumping!',
        },
        'auth.googleSuccessMessage': {
            'id': 'Anda berhasil masuk dengan Google.',
            'en': 'You have successfully signed in with Google.',
            'jv': 'Panjenengan kasil mlebet kaliyan Google.',
            'su': 'Anjeun hasil lebet nganggo Google.',
        },
        'auth.googleSuccessOk': {
            'id': 'Masuk Sekarang',
            'en': 'Enter Now',
            'jv': 'Mlebet Sakmenika',
            'su': 'Lebet Ayeuna',
        },
        'auth.errGoogleCanceled': {
            'id': 'Masuk dengan Google dibatalkan. Jika Anda sudah memilih akun, coba lagi atau restart aplikasi.',
            'en': 'Google sign in was canceled. If you already chose an account, retry or restart the app.',
            'jv': 'Mlebet Google kabatalaken. Menawi sampun milih akun, cobi malih utawi wiwiti malih aplikasi.',
            'su': 'Lebet Google dibolaykeun. Upami anjeun parantos milih akun, cobi deui atanapi pareuman-hurungkeun deui aplikasi.',
        },
        'auth.errGoogleConn': {
            'id': 'Gagal masuk dengan Google. Periksa koneksi internet Anda.',
            'en': 'Failed to sign in with Google. Check your internet connection.',
            'jv': 'Gagal mlebet kaliyan Google. Priksa sambungan internet panjenengan.',
            'su': 'Gagal lebet nganggo Google. Pariksa sambungan internét anjeun.',
        },
        'auth.errGoogleConfig': {
            'id': 'Konfigurasi login Google belum lengkap. Hubungi developer.',
            'en': 'Google sign in configuration is incomplete. Contact developer.',
            'jv': 'Konfigurasi login Google dèrèng jangkep. Hubungi pangembang.',
            'su': 'Konfigurasi login Google teu acan lengkep. Kontak pamekar.',
        },
        'auth.errGoogleDefault': {
            'id': 'Gagal masuk dengan Google. Silakan coba lagi.',
            'en': 'Failed to sign in with Google. Please try again.',
            'jv': 'Gagal mlebet kaliyan Google. Mangga cobi malih.',
            'su': 'Gagal lebet nganggo Google. Mangga cobi deui.',
        },
        'auth.errWrongCredentials': {
            'id': 'Email atau kata sandi yang Anda masukkan salah.',
            'en': 'The email or password you entered is incorrect.',
            'jv': 'Email utawi tembung sandi ingkang dipunlebetaken lepat.',
            'su': 'Surélék atanapi kecap sandi anu dilebetkeun lepat.',
        },
        'auth.errUserNotFound': {
            'id': 'Akun dengan email ini tidak ditemukan.',
            'en': 'Account with this email was not found.',
            'jv': 'Akun mawi email menika mboten kapanggih.',
            'su': 'Akun nganggo surélék ieu henteu kapendak.',
        },
        'auth.errInvalidEmail': {
            'id': 'Format email tidak valid. Pastikan penulisan email sudah benar.',
            'en': 'Invalid email format. Please check the spelling.',
            'jv': 'Format email mboten leres. Priksa malih panyeratanipun.',
            'su': 'Format surélék teu luyu. Pariksa deui panyeratanna.',
        },
        'auth.errUserDisabled': {
            'id': 'Akun ini telah dinonaktifkan. Silakan hubungi administrator.',
            'en': 'This account has been disabled. Please contact administrator.',
            'jv': 'Akun menika sampun dipuntutup. Mangga hubungi pangurus.',
            'su': 'Akun ieu parantos dinonaktipkeun. Mangga kontak kuncén.',
        },
        'auth.errTooManyRequests': {
            'id': 'Terlalu banyak percobaan masuk yang gagal. Silakan coba beberapa saat lagi.',
            'en': 'Too many failed login attempts. Please try again later.',
            'jv': 'Kathahen nyobi mlebet ingkang gagal. Mangga cobi mangkih malih.',
            'su': 'Seueur teuing percobaan lebet anu gagal. Mangga cobi sakedap deui.',
        },
        'auth.errNetworkFailed': {
            'id': 'Sambungan internet bermasalah. Periksa internet, lalu coba lagi.',
            'en': 'Internet connection problem. Check your internet, then try again.',
            'jv': 'Sambungan internet risak. Priksa internet, lajeng cobi malih.',
            'su': 'Sambungan internét aya gangguan. Pariksa internét, lajeng cobi deui.',
        },
        'auth.errOpNotAllowed': {
            'id': 'Metode masuk ini sedang dinonaktifkan.',
            'en': 'This sign in method is currently disabled.',
            'jv': 'Cara mlebet menika saweg dipunpejahi.',
            'su': 'Metode lebet ieu nuju pareum.',
        },
        'auth.errChannelError': {
            'id': 'Harap isi semua kolom email dan kata sandi.',
            'en': 'Please fill in all email and password fields.',
            'jv': 'Kersaa ngisi sedaya kolom email lan tembung sandi.',
            'su': 'Punten eusian sadaya kolom surélék sareng kecap sandi.',
        },
        'auth.errAccountDiffCredential': {
            'id': 'Akun sudah terdaftar dengan metode masuk yang berbeda.',
            'en': 'Account already registered with a different sign-in method.',
            'jv': 'Akun sampun kadaftar mawi cara mlebet ingkang benten.',
            'su': 'Akun parantos kadaptar nganggo cara lebet anu bénten.',
        },
        'auth.errDefaultLogin': {
            'id': 'Gagal masuk. Periksa kembali email dan kata sandi Anda.',
            'en': 'Failed to sign in. Please verify your email and password.',
            'jv': 'Gagal mlebet. Priksa malih email lan tembung sandi panjenengan.',
            'su': 'Gagal lebet. Pariksa deui surélék sareng kecap sandi anjeun.',
        },
        'auth.selectRoleTitle': {
            'id': 'Pilih Peran Anda',
            'en': 'Choose Your Role',
            'jv': 'Pilih Peran Panjenengan',
            'su': 'Pilih Peran Anjeun',
        },
        'auth.selectRoleDesc': {
            'id': 'Peran ini akan disimpan permanen ke akun Anda dan tidak dapat diubah.',
            'en': 'This role will be permanently saved to your account and cannot be changed.',
            'jv': 'Peran menika badhe kasimpen langgeng lan mboten saged dipunowahi.',
            'su': 'Peran ieu baris disimpen permanén sareng teu tiasa dirobih.',
        },
        'auth.roleJamaahTitle': {
            'id': 'Jamaah Haji / Umrah',
            'en': 'Hajj / Umrah Pilgrim',
            'jv': 'Jamaah Kaji / Umrah',
            'su': 'Jamaah Haji / Umrah',
        },
        'auth.roleJamaahSubtitle': {
            'id': 'Akses panduan ibadah, peta, jadwal sholat & monitoring pendamping',
            'en': 'Access worship guide, maps, prayer times & companion monitoring',
            'jv': 'Akses pitedah ibadah, peta, wekdal sholat & panjagan pendamping',
            'su': 'Aksés pituduh ibadah, peta, jadwal sholat & pangawasan pendamping',
        },
        'auth.roleCompanionTitle': {
            'id': 'Pendamping / Muthawif',
            'en': 'Companion / Muthawif',
            'jv': 'Pendamping / Muthawif',
            'su': 'Pendamping / Muthawif',
        },
        'auth.roleCompanionSubtitle': {
            'id': 'Kelola room, undang jamaah & pantau pergerakan radar realtime',
            'en': 'Manage room, invite pilgrims & monitor realtime radar',
            'jv': 'Ngatur room, ngajak jamaah & mantau obahe radar realtime',
            'su': 'Atur room, ngondang jamaah & pantau gerak radar realtime',
        },
        'auth.registerScreenTitle': {
            'id': 'Buat Akun HajiCare',
            'en': 'Create HajiCare Account',
            'jv': 'Damel Akun HajiCare',
            'su': 'Damel Akun HajiCare',
        },
        'auth.registerScreenSubtitle': {
            'id': 'Lengkapi data untuk memulai perjalanan Anda',
            'en': 'Complete your details to start your journey',
            'jv': 'Jangkepi data kagem miwiti lampah panjenengan',
            'su': 'Lengkepan data pikeun ngamimitian lalampahan anjeun',
        },
        'auth.travelFriendTitle': {
            'id': 'Teman Perjalanan Ibadah Anda',
            'en': 'Your Pilgrimage Travel Companion',
            'jv': 'Rencang Lampah Ibadah Panjenengan',
            'su': 'Rerencangan Lampah Ibadah Anjeun',
        },
        'auth.travelFriendDesc': {
            'id': 'Daftar sekali untuk mendapatkan pengalaman HajiCare yang aman, terpantau, dan inklusif.',
            'en': 'Register once for a safe, monitored, and inclusive HajiCare experience.',
            'jv': 'Daftar sepisan kagem pikantuk pengalaman HajiCare ingkang aman, kapantau, lan inklusif.',
            'su': 'Daptar sakali pikeun kéngingkeun pangalaman HajiCare anu aman, kapantau, sareng inklusif.',
        },
        'auth.registerAs': {
            'id': 'Saya mendaftar sebagai',
            'en': 'I am registering as',
            'jv': 'Kula daftar minangka',
            'su': 'Sim kuring daptar salaku',
        },
        'auth.chooseRoleSubtitle': {
            'id': 'Pilih peran yang paling sesuai dengan Anda',
            'en': 'Choose the role that best fits you',
            'jv': 'Pilih peran ingkang paling trep kaliyan panjenengan',
            'su': 'Pilih peran anu paling cocog sareng anjeun',
        },
        'auth.roleHajjUmrah': {
            'id': 'Haji & Umrah',
            'en': 'Hajj & Umrah',
            'jv': 'Kaji & Umrah',
            'su': 'Haji & Umrah',
        },
        'auth.roleCompanion': {
            'id': 'Pendamping',
            'en': 'Companion',
            'jv': 'Pendamping',
            'su': 'Pendamping',
        },
        'auth.roleFamilyMuthawif': {
            'id': 'Keluarga / Muthawif',
            'en': 'Family / Muthawif',
            'jv': 'Kulawarga / Muthawif',
            'su': 'Kulawarga / Muthawif',
        },
        'auth.personalData': {
            'id': 'Data Diri',
            'en': 'Personal Data',
            'jv': 'Data Dhiri',
            'su': 'Data Pribadi',
        },
        'auth.personalDataDesc': {
            'id': 'Gunakan data sesuai identitas resmi Anda',
            'en': 'Use data corresponding to your official ID',
            'jv': 'Ginakaken data trep kaliyan idhentitas resmi',
            'su': 'Anggo data saluyu sareng idéntitas resmi',
        },
        'auth.fullNameHint': {
            'id': 'Contoh: Ahmad Dahlan',
            'en': 'e.g. Ahmad Dahlan',
            'jv': 'Tuladha: Ahmad Dahlan',
            'su': 'Conto: Ahmad Dahlan',
        },
        'auth.porsiOrNikLabel': {
            'id': 'Nomor Porsi Haji / NIK',
            'en': 'Hajj Portion / ID Number',
            'jv': 'Nomer Porsi Kaji / NIK',
            'su': 'Nomer Porsi Haji / NIK',
        },
        'auth.porsiOrNikHint': {
            'id': 'Masukkan nomor porsi atau NIK',
            'en': 'Enter portion number or ID',
            'jv': 'Lebetaken nomer porsi utawi NIK',
            'su': 'Lebetkeun nomer porsi atanapi NIK',
        },
        'auth.porsiOrNikInfo': {
            'id': 'Data ini membantu HajiCare mengaitkan rombongan dan maktab secara akurat.',
            'en': 'This data helps HajiCare accurately link your group and maktab.',
            'jv': 'Data menika mbiyantu HajiCare ngubungaken rombongan lan maktab kanthi trep.',
            'su': 'Data ieu mantuan HajiCare ngahubungkeun rombongan sareng maktab kalayan akurat.',
        },
        'auth.accountInfo': {
            'id': 'Informasi Akun',
            'en': 'Account Information',
            'jv': 'Katrangan Akun',
            'su': 'Émbaran Akun',
        },
        'auth.accountInfoDesc': {
            'id': 'Gunakan email aktif dan kata sandi yang aman',
            'en': 'Use an active email and a secure password',
            'jv': 'Ginakaken email aktif lan tembung sandi ingkang aman',
            'su': 'Anggo surélék aktip sareng kecap sandi anu aman',
        },
        'auth.activeEmail': {
            'id': 'Email Aktif',
            'en': 'Active Email',
            'jv': 'Email Aktif',
            'su': 'Surélék Aktip',
        },
        'auth.passwordMin6Hint': {
            'id': 'Minimal 6 karakter',
            'en': 'Minimum 6 characters',
            'jv': 'Paling sakedhik 6 karakter',
            'su': 'Sahenteuna 6 karakter',
        },
        'auth.passwordMin6Desc': {
            'id': 'Gunakan kombinasi minimal 6 karakter agar akun tetap aman.',
            'en': 'Use a combination of at least 6 characters to keep account secure.',
            'jv': 'Ginakaken campuran paling sakedhik 6 karakter supados akun aman.',
            'su': 'Anggo kombinasi sahenteuna 6 karakter supados akun tetep aman.',
        },
        'auth.registering': {
            'id': 'Mendaftarkan Akun...',
            'en': 'Registering Account...',
            'jv': 'Saweg Ndaptaraken Akun...',
            'su': 'Nuju Daptarkeun Akun...',
        },
        'auth.createAccountNow': {
            'id': 'Buat Akun Sekarang',
            'en': 'Create Account Now',
            'jv': 'Damel Akun Sakmenika',
            'su': 'Damel Akun Ayeuna',
        },
        'auth.privacyNote': {
            'id': 'Informasi pribadi Anda terenkripsi dan hanya digunakan untuk kebutuhan navigasi & keselamatan ibadah.',
            'en': 'Your personal information is encrypted and only used for navigation & safety.',
            'jv': 'Katrangan pribadi panjenengan kaenkripsi lan namung kagem kaperluan pandhu & kaslametan.',
            'su': 'Émbaran pribadi anjeun kaénkripsi sareng ngan dianggo pikeun kabutuhan navigasi & kasalametan.',
        },
        'auth.alreadyHaveAccount': {
            'id': 'Sudah memiliki akun? ',
            'en': 'Already have an account? ',
            'jv': 'Sampun gadhah akun? ',
            'su': 'Parantos gaduh akun? ',
        },
        'auth.loginNow': {
            'id': 'Masuk sekarang',
            'en': 'Sign in now',
            'jv': 'Mlebet sakmenika',
            'su': 'Lebet ayeuna',
        },
        'auth.taglineFull': {
            'id': 'HajiCare • Aman • Terhubung • Khusyuk',
            'en': 'HajiCare • Safe • Connected • Solemn',
            'jv': 'HajiCare • Aman • Kasambung • Khusyuk',
            'su': 'HajiCare • Aman • Nyambung • Khusyuk',
        },
        'auth.errFillAllRegister': {
            'id': 'Isi nama, email, dan kata sandi terlebih dahulu.',
            'en': 'Please enter name, email, and password first.',
            'jv': 'Kersaa ngisi asma, email, lan tembung sandi rumiyin.',
            'su': 'Eusian nami, surélék, sareng kecap sandi heula.',
        },
        'auth.errCreateUserFailed': {
            'id': 'Gagal membuat pengguna baru.',
            'en': 'Failed to create new user.',
            'jv': 'Gagal damel pangguna enggal.',
            'su': 'Gagal ngadamel pangguna énggal.',
        },
        'auth.errRegisterFailed': {
            'id': 'Pendaftaran belum berhasil. Silakan coba lagi.',
            'en': 'Registration failed. Please try again.',
            'jv': 'Pandaptaran dèrèng kasil. Mangga cobi malih.',
            'su': 'Pendaftaran teu acan hasil. Mangga cobi deui.',
        },
        'auth.errEmailAlreadyInUse': {
            'id': 'Email ini sudah terdaftar. Silakan masuk atau gunakan email lain.',
            'en': 'This email is already registered. Please log in or use another email.',
            'jv': 'Email menika sampun kadaftar. Mangga mlebet utawi ginakaken email sanes.',
            'su': 'Surélék ieu parantos kadaptar. Mangga lebet atanapi anggo surélék sanés.',
        },
        'auth.errWeakPassword': {
            'id': 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.',
            'en': 'Password is too weak. Use at least 6 characters.',
            'jv': 'Tembung sandi ringkih sanget. Ginakaken paling sakedhik 6 karakter.',
            'su': 'Kecap sandi lemah teuing. Anggo sahenteuna 6 karakter.',
        },
        'auth.errInvalidEmailRegister': {
            'id': 'Penulisan email belum benar. Periksa kembali email Anda.',
            'en': 'Email format is incorrect. Please check your email.',
            'jv': 'Panyeratan email dèrèng leres. Priksa malih email panjenengan.',
            'su': 'Panyeratan surélék teu acan leres. Pariksa deui surélék anjeun.',
        },
        'auth.errRegisterDisabled': {
            'id': 'Pendaftaran akun sedang dinonaktifkan.',
            'en': 'Account registration is currently disabled.',
            'jv': 'Pandaptaran akun saweg dipunpejahi.',
            'su': 'Pendaftaran akun nuju dipareuman.',
        },
        'auth.errRegisterGeneral': {
            'id': 'Pendaftaran gagal. Periksa kembali data yang Anda masukkan.',
            'en': 'Registration failed. Please check the entered data.',
            'jv': 'Pandaptaran gagal. Priksa malih data ingkang dipunlebetaken.',
            'su': 'Pendaftaran gagal. Pariksa deui data anu dilebetkeun.',
        },
        'auth.registerFailedTitle': {
            'id': 'Pendaftaran Belum Berhasil',
            'en': 'Registration Failed',
            'jv': 'Pandaptaran Dèrèng Kasil',
            'su': 'Pendaftaran Teu Acan Hasil',
        },
        # Common
        'common.next': {
            'id': 'Lanjut',
            'en': 'Next',
            'jv': 'Lajeng',
            'su': 'Lajeng',
        },
        'common.optional': {
            'id': 'Opsional',
            'en': 'Optional',
            'jv': 'Pilihan',
            'su': 'Opsional',
        },
        'common.and': {
            'id': 'dan',
            'en': 'and',
            'jv': 'lan',
            'su': 'sareng',
        },
        'common.or': {
            'id': 'atau',
            'en': 'or',
            'jv': 'utawi',
            'su': 'atanapi',
        },
    }

    # Merge required_auth_keys into each map
    for k, v in required_auth_keys.items():
        id_map[k] = v['id']
        en_map[k] = v['en']
        jv_map[k] = v['jv']
        su_map[k] = v['su']

    # Now make sure all keys that exist in id_map exist in en, jv, su (fallback to id if missing)
    all_keys = sorted(list(id_map.keys()))
    for k in all_keys:
        if k not in en_map:
            en_map[k] = id_map[k]
        if k not in jv_map:
            jv_map[k] = id_map[k]
        if k not in su_map:
            su_map[k] = id_map[k]

    # Write out cleanly formatted files
    def write_catalog(path, var_name, data):
        lines = [f"const Map<String, String> {var_name} = {{"]
        current_prefix = None
        for k in sorted(data.keys()):
            prefix = k.split('.')[0] if '.' in k else 'core'
            if prefix != current_prefix:
                current_prefix = prefix
                lines.append(f"\n  // --- {prefix.upper()} ---")
            val_escaped = data[k].replace("'", "\\'").replace("\n", "\\n")
            lines.append(f"  '{k}': '{val_escaped}',")
        lines.append("};\n")
        with open(path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))
        print(f"Wrote {path} with {len(data)} keys.")

    write_catalog(os.path.join(locales_dir, 'id.dart'), 'idTranslations', id_map)
    write_catalog(os.path.join(locales_dir, 'en.dart'), 'enTranslations', en_map)
    write_catalog(os.path.join(locales_dir, 'jv.dart'), 'jvTranslations', jv_map)
    write_catalog(os.path.join(locales_dir, 'su.dart'), 'suTranslations', su_map)
    print("Catalog reconciliation complete!")

if __name__ == '__main__':
    main()
