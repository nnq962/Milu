import SwiftUI

/// A Vietnamese bank or e-wallet an account can belong to, with its logo in
/// `Assets.xcassets/Institutions`. Catalogue and search ported from the web app
/// (finance-tracker-v2 web/lib/institutions.ts); the most used come first.
struct Institution: Identifiable, Hashable {
    enum Kind { case bank, eWallet }

    let id: String
    let name: String
    let shortName: String
    let kind: Kind
    /// Image set name inside the Institutions folder of the asset catalog.
    let logo: String
    var keywords: [String] = []

    var logoImage: String { "Institutions/" + logo }

    static func bank(_ id: String, _ name: String, short: String, logo: String, keywords: [String] = []) -> Institution {
        Institution(id: id, name: name, shortName: short, kind: .bank, logo: logo, keywords: keywords)
    }

    static func wallet(_ id: String, _ name: String, short: String, logo: String, keywords: [String] = []) -> Institution {
        Institution(id: id, name: name, shortName: short, kind: .eWallet, logo: logo, keywords: keywords)
    }
}

extension Institution {
    static let banks: [Institution] = [
        .bank("vietcombank", "Ngân hàng TMCP Ngoại thương Việt Nam", short: "Vietcombank", logo: "vietcombank", keywords: ["vcb", "ngoai thuong"]),
        .bank("techcombank", "Ngân hàng TMCP Kỹ thương Việt Nam", short: "Techcombank", logo: "techcombank", keywords: ["tcb", "ky thuong"]),
        .bank("mb-bank", "Ngân hàng TMCP Quân đội", short: "MB Bank", logo: "mb-bank", keywords: ["mbbank", "quan doi"]),
        .bank("bidv", "Ngân hàng TMCP Đầu tư và Phát triển Việt Nam", short: "BIDV", logo: "bidv", keywords: ["dau tu phat trien"]),
        .bank("vietinbank", "Ngân hàng TMCP Công Thương Việt Nam", short: "VietinBank", logo: "vietinbank", keywords: ["ctg", "cong thuong"]),
        .bank("agribank", "Ngân hàng Nông nghiệp và Phát triển Nông thôn Việt Nam", short: "Agribank", logo: "agribank", keywords: ["agribank", "nong nghiep"]),
        .bank("acb", "Ngân hàng TMCP Á Châu", short: "ACB", logo: "acb", keywords: ["a chau"]),
        .bank("vpbank", "Ngân hàng TMCP Việt Nam Thịnh Vượng", short: "VPBank", logo: "vpbank", keywords: ["vpb", "viet nam thinh vuong"]),
        .bank("tpbank", "Ngân hàng TMCP Tiên Phong", short: "TPBank", logo: "tpbank", keywords: ["tpb", "tien phong"]),
        .bank("vib", "Ngân hàng TMCP Quốc tế Việt Nam", short: "VIB", logo: "vib", keywords: ["quoc te"]),
        .bank("hdbank", "Ngân hàng TMCP Phát triển Thành phố Hồ Chí Minh", short: "HDBank", logo: "hdbank", keywords: ["hdb", "phat trien tphcm"]),
        .bank("msb", "Ngân hàng TMCP Hàng Hải Việt Nam", short: "MSB", logo: "msb", keywords: ["maritime bank", "hang hai"]),
        .bank("ocb", "Ngân hàng TMCP Phương Đông", short: "OCB", logo: "ocb", keywords: ["phuong dong"]),
        .bank("shb", "Ngân hàng TMCP Sài Gòn - Hà Nội", short: "SHB", logo: "shb", keywords: ["sai gon ha noi"]),
        .bank("eximbank", "Ngân hàng TMCP Xuất Nhập khẩu Việt Nam", short: "Eximbank", logo: "eximbank", keywords: ["eib", "xuat nhap khau"]),
        .bank("scb", "Ngân hàng TMCP Sài Gòn", short: "SCB", logo: "scb", keywords: ["sai gon"]),
        .bank("seabank", "Ngân hàng TMCP Đông Nam Á", short: "SeABank", logo: "sea-bank", keywords: ["sea bank", "dong nam a"]),
        .bank("lpbank", "Ngân hàng TMCP Lộc Phát Việt Nam", short: "LPBank", logo: "lienviet-postbank", keywords: ["lienvietpostbank", "lien viet", "loc phat"]),
        .bank("pvcombank", "Ngân hàng TMCP Đại Chúng Việt Nam", short: "PVcomBank", logo: "pvcom-bank", keywords: ["pvcom", "dai chung"]),
        .bank("nam-a-bank", "Ngân hàng TMCP Nam Á", short: "Nam A Bank", logo: "nam-a-bank", keywords: ["namabank", "nam a"]),
        .bank("ncb", "Ngân hàng TMCP Quốc Dân", short: "NCB", logo: "ncb", keywords: ["quoc dan"]),
        .bank("abbank", "Ngân hàng TMCP An Bình", short: "ABBank", logo: "abbank", keywords: ["an binh"]),
        .bank("bac-a-bank", "Ngân hàng TMCP Bắc Á", short: "Bac A Bank", logo: "bac-a-bank", keywords: ["baca", "bac a"]),
        .bank("bao-viet-bank", "Ngân hàng TMCP Bảo Việt", short: "BaoViet Bank", logo: "baoviet-bank", keywords: ["bao viet"]),
        .bank("viet-a-bank", "Ngân hàng TMCP Việt Á", short: "VietABank", logo: "viet-a-bank", keywords: ["viet a"]),
        .bank("viet-capital-bank", "Ngân hàng TMCP Bản Việt", short: "BVBank", logo: "viet-capital-bank", keywords: ["viet capital bank", "ban viet"]),
        .bank("kienlong-bank", "Ngân hàng TMCP Kiên Long", short: "KienlongBank", logo: "kienlong-bank", keywords: ["kien long"]),
        .bank("pg-bank", "Ngân hàng TMCP Thịnh vượng và Phát triển", short: "PGBank", logo: "pg-bank", keywords: ["pgbank", "petrolimex"]),
        .bank("gpbank", "Ngân hàng TNHH MTV Dầu khí Toàn cầu", short: "GPBank", logo: "gpbank", keywords: ["dau khi toan cau"]),
        .bank("ocean-bank", "Ngân hàng TNHH MTV Đại Dương", short: "OceanBank", logo: "ocean-bank", keywords: ["dai duong"]),
        .bank("cb", "Ngân hàng Thương mại TNHH MTV Xây dựng Việt Nam", short: "CB", logo: "cb", keywords: ["construction bank", "xay dung"]),
        .bank("donga-bank", "Ngân hàng TMCP Đông Á", short: "DongA Bank", logo: "donga-bank", keywords: ["dong a"]),
        .bank("cake-by-vpbank", "Ngân hàng số Cake by VPBank", short: "Cake", logo: "cake-by-vpbank", keywords: ["cake vpbank", "digital bank"]),
        .bank("timo", "Ngân hàng số Timo", short: "Timo", logo: "timo", keywords: ["digital bank"]),
        .bank("tyme", "Ngân hàng số Tyme", short: "Tyme", logo: "tyme", keywords: ["digital bank"]),
        .bank("tymebank", "TymeBank", short: "TymeBank", logo: "tymebank"),
        .bank("hsbc", "Ngân hàng HSBC", short: "HSBC", logo: "hsbc"),
        .bank("standard-chartered", "Ngân hàng Standard Chartered", short: "Standard Chartered", logo: "standard-chartered", keywords: ["scb international"]),
        .bank("shinhan-bank", "Ngân hàng Shinhan", short: "Shinhan Bank", logo: "shinhan-bank"),
        .bank("woori-bank", "Ngân hàng Woori", short: "Woori Bank", logo: "woori-bank"),
        .bank("cimb", "Ngân hàng CIMB", short: "CIMB", logo: "cimb"),
        .bank("public-bank", "Ngân hàng Public Bank Việt Nam", short: "Public Bank", logo: "public-bank"),
        .bank("hong-leong-bank", "Ngân hàng Hong Leong Việt Nam", short: "Hong Leong Bank", logo: "hong-leong-bank"),
        .bank("maybank", "Ngân hàng Maybank", short: "Maybank", logo: "maybank"),
        .bank("anz", "Ngân hàng ANZ", short: "ANZ", logo: "anz"),
        .bank("citibank", "Ngân hàng Citibank", short: "Citibank", logo: "citibank", keywords: ["citi"]),
        .bank("commonwealth-bank", "Ngân hàng Commonwealth", short: "Commonwealth Bank", logo: "commonwealth-bank"),
        .bank("deutsche-bank", "Ngân hàng Deutsche Bank", short: "Deutsche Bank", logo: "deutsche-bank"),
        .bank("bank-of-china", "Ngân hàng Bank of China", short: "Bank of China", logo: "bank-of-china", keywords: ["boc"]),
        .bank("bangkok-bank", "Ngân hàng Bangkok Bank", short: "Bangkok Bank", logo: "bangkok-bank"),
        .bank("cathay-bank", "Ngân hàng Cathay United", short: "Cathay Bank", logo: "cathay-bank"),
        .bank("chase-bank", "Ngân hàng JPMorgan Chase", short: "Chase", logo: "chase-bank", keywords: ["jpmorgan"]),
        .bank("industrial-bank-of-korea", "Ngân hàng Công nghiệp Hàn Quốc", short: "IBK", logo: "industrial-bank-of-korea", keywords: ["industrial bank of korea"]),
        .bank("keb-hana-bank", "Ngân hàng KEB Hana", short: "KEB Hana Bank", logo: "keb-hana-bank"),
        .bank("kb", "Ngân hàng KB Kookmin", short: "KB Kookmin", logo: "kb"),
        .bank("ivb", "Ngân hàng Indovina", short: "IVB", logo: "ivb", keywords: ["indovina bank"]),
        .bank("bidc", "Ngân hàng Đầu tư và Phát triển Campuchia", short: "BIDC", logo: "bidc"),
        .bank("mega-international-commercial-bank", "Mega International Commercial Bank", short: "Mega ICBC", logo: "mega-international-commercial-bank"),
        .bank("mizuho", "Ngân hàng Mizuho", short: "Mizuho", logo: "mizuho"),
        .bank("smfg", "Sumitomo Mitsui Financial Group", short: "SMFG", logo: "smfg", keywords: ["smbc"]),
        .bank("scotiabank", "Ngân hàng Scotiabank", short: "Scotiabank", logo: "scotiabank"),
        .bank("ubs", "Ngân hàng UBS", short: "UBS", logo: "ubs", keywords: ["ubs"]),
        .bank("dsb", "Ngân hàng DSB", short: "DSB", logo: "dsb"),
    ]

    static let eWallets: [Institution] = [
        .wallet("momo", "Ví điện tử MoMo", short: "MoMo", logo: "momo"),
        .wallet("zalopay", "Ví điện tử ZaloPay", short: "ZaloPay", logo: "zalopay", keywords: ["zalo pay"]),
        .wallet("vnpay", "Ví điện tử VNPAY", short: "VNPAY", logo: "vnpay"),
        .wallet("vnpay-money", "Ví điện tử VNPAY Money", short: "VNPAY Money", logo: "vnpay-money"),
        .wallet("shopeepay", "Ví điện tử ShopeePay", short: "ShopeePay", logo: "shopeepay", keywords: ["airpay", "shopee pay"]),
        .wallet("viettel-money", "Ví điện tử Viettel Money", short: "Viettel Money", logo: "viettel-money"),
        .wallet("moca", "Ví điện tử Moca", short: "Moca", logo: "moca"),
        .wallet("grabpay-by-moca", "GrabPay by Moca", short: "GrabPay", logo: "grabpay-by-moca", keywords: ["grab pay", "moca"]),
        .wallet("payoo", "Ví điện tử Payoo", short: "Payoo", logo: "payoo"),
        .wallet("payme", "Ví điện tử PayME", short: "PayME", logo: "payme"),
        .wallet("vtcpay", "Ví điện tử VTC Pay", short: "VTC Pay", logo: "vtcpay"),
        .wallet("ngan-luong", "Ví điện tử Ngân Lượng", short: "Ngân Lượng", logo: "ngan-luong", keywords: ["nganluong"]),
        .wallet("baokim", "Ví điện tử Bảo Kim", short: "Bảo Kim", logo: "baokim"),
        .wallet("truemoney", "Ví điện tử TrueMoney", short: "TrueMoney", logo: "truemoney"),
        .wallet("nextpay", "Ví điện tử NextPay", short: "NextPay", logo: "nextpay"),
        .wallet("ecpay", "Ví điện tử ECPay", short: "ECPay", logo: "ecpay"),
        .wallet("vimo", "Ví điện tử Vimo", short: "Vimo", logo: "vimo"),
        .wallet("vinid", "Ví điện tử VinID Pay", short: "VinID Pay", logo: "vinid", keywords: ["vin id"]),
        .wallet("appota", "Ví điện tử AppotaPay", short: "AppotaPay", logo: "appota", keywords: ["appota"]),
    ]

    static let all = banks + eWallets

    static func list(for type: AccountType) -> [Institution] {
        switch type {
        case .eWallet: eWallets
        case .bank, .credit: banks
        case .cash: []
        }
    }

    static func find(_ id: String?) -> Institution? {
        guard let id else { return nil }
        return all.first { $0.id == id }
    }

    /// The institutions matching `query`, best first, as a bank app's search: the short name or an
    /// alias exactly ("mb", "vcb"), then a short name starting with it, then every typed word
    /// starting a word of the short name or an alias ("nam a"), then of the full name ("quan doi"),
    /// and last the text anywhere. Ties keep the catalogue order. Accents and case are ignored.
    static func search(_ query: String, in institutions: [Institution]) -> [Institution] {
        let typed = searchKey(query.trimmingCharacters(in: .whitespaces))
        guard !typed.isEmpty else { return institutions }
        let typedWords = words(typed)
        let typedCompact = compact(typed)
        func startsWords(_ text: String) -> Bool {
            let own = words(text)
            return typedWords.allSatisfy { typedWord in own.contains { $0.hasPrefix(typedWord) } }
        }
        func rank(_ institution: Institution) -> Int? {
            let short = searchKey(institution.shortName)
            let aliases = ([institution.id] + institution.keywords).map(searchKey)
            let full = searchKey(institution.name)
            if ([short] + aliases).contains(where: { compact($0) == typedCompact }) { return 0 }
            if compact(short).hasPrefix(typedCompact) { return 1 }
            if ([short] + aliases).contains(where: startsWords) { return 2 }
            if startsWords(full) { return 3 }
            if ([short, full] + aliases).contains(where: { $0.contains(typed) || compact($0).contains(typedCompact) }) { return 4 }
            return nil
        }
        return institutions.enumerated()
            .compactMap { index, institution in rank(institution).map { (institution: institution, index: index, rank: $0) } }
            .sorted { ($0.rank, $0.index) < ($1.rank, $1.index) }
            .map(\.institution)
    }

    private static func searchKey(_ text: String) -> String {
        text.replacingOccurrences(of: "đ", with: "d").replacingOccurrences(of: "Đ", with: "d")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .vietnam)
    }

    private static func words(_ text: String) -> [String] {
        text.split(whereSeparator: { $0 == " " || $0 == "-" }).map(String.init)
    }

    private static func compact(_ text: String) -> String {
        text.filter { $0 != " " && $0 != "-" }
    }
}
