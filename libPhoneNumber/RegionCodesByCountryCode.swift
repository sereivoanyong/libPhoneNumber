//
//  RegionCodesByCountryCode.swift
//
//  Created by Sereivoan Yong on 12/4/20.
//

import Foundation

enum RegionCodesByCountryCode {
  
  // A mapping from a country code to the region codes which denote the
  // country/region represented by that country code. In the case of multiple
  // countries sharing a calling code, such as the NANPA countries, the one
  // indicated with "isMainCountryForCode" in the metadata should be first.
  static func regionCodesByCountryCode() -> [Int32: [String]] {
    // The capacity is set to 286 as there are 215 different entries,
    // and this offers a load factor of roughly 0.75.
    var regionCodesByCountryCode = [Int32: [String]](minimumCapacity: 286)
    
    var regionCodes: [String]
    
    regionCodes = []
    regionCodes.append("US")
    regionCodes.append("AG")
    regionCodes.append("AI")
    regionCodes.append("AS")
    regionCodes.append("BB")
    regionCodes.append("BM")
    regionCodes.append("BS")
    regionCodes.append("CA")
    regionCodes.append("DM")
    regionCodes.append("DO")
    regionCodes.append("GD")
    regionCodes.append("GU")
    regionCodes.append("JM")
    regionCodes.append("KN")
    regionCodes.append("KY")
    regionCodes.append("LC")
    regionCodes.append("MP")
    regionCodes.append("MS")
    regionCodes.append("PR")
    regionCodes.append("SX")
    regionCodes.append("TC")
    regionCodes.append("TT")
    regionCodes.append("VC")
    regionCodes.append("VG")
    regionCodes.append("VI")
    regionCodesByCountryCode[1] = regionCodes
    
    regionCodes = []
    regionCodes.append("RU")
    regionCodes.append("KZ")
    regionCodesByCountryCode[7] = regionCodes
    
    regionCodes = []
    regionCodes.append("EG")
    regionCodesByCountryCode[20] = regionCodes
    
    regionCodes = []
    regionCodes.append("ZA")
    regionCodesByCountryCode[27] = regionCodes
    
    regionCodes = []
    regionCodes.append("GR")
    regionCodesByCountryCode[30] = regionCodes
    
    regionCodes = []
    regionCodes.append("NL")
    regionCodesByCountryCode[31] = regionCodes
    
    regionCodes = []
    regionCodes.append("BE")
    regionCodesByCountryCode[32] = regionCodes
    
    regionCodes = []
    regionCodes.append("FR")
    regionCodesByCountryCode[33] = regionCodes
    
    regionCodes = []
    regionCodes.append("ES")
    regionCodesByCountryCode[34] = regionCodes
    
    regionCodes = []
    regionCodes.append("HU")
    regionCodesByCountryCode[36] = regionCodes
    
    regionCodes = []
    regionCodes.append("IT")
    regionCodes.append("VA")
    regionCodesByCountryCode[39] = regionCodes
    
    regionCodes = []
    regionCodes.append("RO")
    regionCodesByCountryCode[40] = regionCodes
    
    regionCodes = []
    regionCodes.append("CH")
    regionCodesByCountryCode[41] = regionCodes
    
    regionCodes = []
    regionCodes.append("AT")
    regionCodesByCountryCode[43] = regionCodes
    
    regionCodes = []
    regionCodes.append("GB")
    regionCodes.append("GG")
    regionCodes.append("IM")
    regionCodes.append("JE")
    regionCodesByCountryCode[44] = regionCodes
    
    regionCodes = []
    regionCodes.append("DK")
    regionCodesByCountryCode[45] = regionCodes
    
    regionCodes = []
    regionCodes.append("SE")
    regionCodesByCountryCode[46] = regionCodes
    
    regionCodes = []
    regionCodes.append("NO")
    regionCodes.append("SJ")
    regionCodesByCountryCode[47] = regionCodes
    
    regionCodes = []
    regionCodes.append("PL")
    regionCodesByCountryCode[48] = regionCodes
    
    regionCodes = []
    regionCodes.append("DE")
    regionCodesByCountryCode[49] = regionCodes
    
    regionCodes = []
    regionCodes.append("PE")
    regionCodesByCountryCode[51] = regionCodes
    
    regionCodes = []
    regionCodes.append("MX")
    regionCodesByCountryCode[52] = regionCodes
    
    regionCodes = []
    regionCodes.append("CU")
    regionCodesByCountryCode[53] = regionCodes
    
    regionCodes = []
    regionCodes.append("AR")
    regionCodesByCountryCode[54] = regionCodes
    
    regionCodes = []
    regionCodes.append("BR")
    regionCodesByCountryCode[55] = regionCodes
    
    regionCodes = []
    regionCodes.append("CL")
    regionCodesByCountryCode[56] = regionCodes
    
    regionCodes = []
    regionCodes.append("CO")
    regionCodesByCountryCode[57] = regionCodes
    
    regionCodes = []
    regionCodes.append("VE")
    regionCodesByCountryCode[58] = regionCodes
    
    regionCodes = []
    regionCodes.append("MY")
    regionCodesByCountryCode[60] = regionCodes
    
    regionCodes = []
    regionCodes.append("AU")
    regionCodes.append("CC")
    regionCodes.append("CX")
    regionCodesByCountryCode[61] = regionCodes
    
    regionCodes = []
    regionCodes.append("ID")
    regionCodesByCountryCode[62] = regionCodes
    
    regionCodes = []
    regionCodes.append("PH")
    regionCodesByCountryCode[63] = regionCodes
    
    regionCodes = []
    regionCodes.append("NZ")
    regionCodesByCountryCode[64] = regionCodes
    
    regionCodes = []
    regionCodes.append("SG")
    regionCodesByCountryCode[65] = regionCodes
    
    regionCodes = []
    regionCodes.append("TH")
    regionCodesByCountryCode[66] = regionCodes
    
    regionCodes = []
    regionCodes.append("JP")
    regionCodesByCountryCode[81] = regionCodes
    
    regionCodes = []
    regionCodes.append("KR")
    regionCodesByCountryCode[82] = regionCodes
    
    regionCodes = []
    regionCodes.append("VN")
    regionCodesByCountryCode[84] = regionCodes
    
    regionCodes = []
    regionCodes.append("CN")
    regionCodesByCountryCode[86] = regionCodes
    
    regionCodes = []
    regionCodes.append("TR")
    regionCodesByCountryCode[90] = regionCodes
    
    regionCodes = []
    regionCodes.append("IN")
    regionCodesByCountryCode[91] = regionCodes
    
    regionCodes = []
    regionCodes.append("PK")
    regionCodesByCountryCode[92] = regionCodes
    
    regionCodes = []
    regionCodes.append("AF")
    regionCodesByCountryCode[93] = regionCodes
    
    regionCodes = []
    regionCodes.append("LK")
    regionCodesByCountryCode[94] = regionCodes
    
    regionCodes = []
    regionCodes.append("MM")
    regionCodesByCountryCode[95] = regionCodes
    
    regionCodes = []
    regionCodes.append("IR")
    regionCodesByCountryCode[98] = regionCodes
    
    regionCodes = []
    regionCodes.append("SS")
    regionCodesByCountryCode[211] = regionCodes
    
    regionCodes = []
    regionCodes.append("MA")
    regionCodes.append("EH")
    regionCodesByCountryCode[212] = regionCodes
    
    regionCodes = []
    regionCodes.append("DZ")
    regionCodesByCountryCode[213] = regionCodes
    
    regionCodes = []
    regionCodes.append("TN")
    regionCodesByCountryCode[216] = regionCodes
    
    regionCodes = []
    regionCodes.append("LY")
    regionCodesByCountryCode[218] = regionCodes
    
    regionCodes = []
    regionCodes.append("GM")
    regionCodesByCountryCode[220] = regionCodes
    
    regionCodes = []
    regionCodes.append("SN")
    regionCodesByCountryCode[221] = regionCodes
    
    regionCodes = []
    regionCodes.append("MR")
    regionCodesByCountryCode[222] = regionCodes
    
    regionCodes = []
    regionCodes.append("ML")
    regionCodesByCountryCode[223] = regionCodes
    
    regionCodes = []
    regionCodes.append("GN")
    regionCodesByCountryCode[224] = regionCodes
    
    regionCodes = []
    regionCodes.append("CI")
    regionCodesByCountryCode[225] = regionCodes
    
    regionCodes = []
    regionCodes.append("BF")
    regionCodesByCountryCode[226] = regionCodes
    
    regionCodes = []
    regionCodes.append("NE")
    regionCodesByCountryCode[227] = regionCodes
    
    regionCodes = []
    regionCodes.append("TG")
    regionCodesByCountryCode[228] = regionCodes
    
    regionCodes = []
    regionCodes.append("BJ")
    regionCodesByCountryCode[229] = regionCodes
    
    regionCodes = []
    regionCodes.append("MU")
    regionCodesByCountryCode[230] = regionCodes
    
    regionCodes = []
    regionCodes.append("LR")
    regionCodesByCountryCode[231] = regionCodes
    
    regionCodes = []
    regionCodes.append("SL")
    regionCodesByCountryCode[232] = regionCodes
    
    regionCodes = []
    regionCodes.append("GH")
    regionCodesByCountryCode[233] = regionCodes
    
    regionCodes = []
    regionCodes.append("NG")
    regionCodesByCountryCode[234] = regionCodes
    
    regionCodes = []
    regionCodes.append("TD")
    regionCodesByCountryCode[235] = regionCodes
    
    regionCodes = []
    regionCodes.append("CF")
    regionCodesByCountryCode[236] = regionCodes
    
    regionCodes = []
    regionCodes.append("CM")
    regionCodesByCountryCode[237] = regionCodes
    
    regionCodes = []
    regionCodes.append("CV")
    regionCodesByCountryCode[238] = regionCodes
    
    regionCodes = []
    regionCodes.append("ST")
    regionCodesByCountryCode[239] = regionCodes
    
    regionCodes = []
    regionCodes.append("GQ")
    regionCodesByCountryCode[240] = regionCodes
    
    regionCodes = []
    regionCodes.append("GA")
    regionCodesByCountryCode[241] = regionCodes
    
    regionCodes = []
    regionCodes.append("CG")
    regionCodesByCountryCode[242] = regionCodes
    
    regionCodes = []
    regionCodes.append("CD")
    regionCodesByCountryCode[243] = regionCodes
    
    regionCodes = []
    regionCodes.append("AO")
    regionCodesByCountryCode[244] = regionCodes
    
    regionCodes = []
    regionCodes.append("GW")
    regionCodesByCountryCode[245] = regionCodes
    
    regionCodes = []
    regionCodes.append("IO")
    regionCodesByCountryCode[246] = regionCodes
    
    regionCodes = []
    regionCodes.append("AC")
    regionCodesByCountryCode[247] = regionCodes
    
    regionCodes = []
    regionCodes.append("SC")
    regionCodesByCountryCode[248] = regionCodes
    
    regionCodes = []
    regionCodes.append("SD")
    regionCodesByCountryCode[249] = regionCodes
    
    regionCodes = []
    regionCodes.append("RW")
    regionCodesByCountryCode[250] = regionCodes
    
    regionCodes = []
    regionCodes.append("ET")
    regionCodesByCountryCode[251] = regionCodes
    
    regionCodes = []
    regionCodes.append("SO")
    regionCodesByCountryCode[252] = regionCodes
    
    regionCodes = []
    regionCodes.append("DJ")
    regionCodesByCountryCode[253] = regionCodes
    
    regionCodes = []
    regionCodes.append("KE")
    regionCodesByCountryCode[254] = regionCodes
    
    regionCodes = []
    regionCodes.append("TZ")
    regionCodesByCountryCode[255] = regionCodes
    
    regionCodes = []
    regionCodes.append("UG")
    regionCodesByCountryCode[256] = regionCodes
    
    regionCodes = []
    regionCodes.append("BI")
    regionCodesByCountryCode[257] = regionCodes
    
    regionCodes = []
    regionCodes.append("MZ")
    regionCodesByCountryCode[258] = regionCodes
    
    regionCodes = []
    regionCodes.append("ZM")
    regionCodesByCountryCode[260] = regionCodes
    
    regionCodes = []
    regionCodes.append("MG")
    regionCodesByCountryCode[261] = regionCodes
    
    regionCodes = []
    regionCodes.append("RE")
    regionCodes.append("YT")
    regionCodesByCountryCode[262] = regionCodes
    
    regionCodes = []
    regionCodes.append("ZW")
    regionCodesByCountryCode[263] = regionCodes
    
    regionCodes = []
    regionCodes.append("NA")
    regionCodesByCountryCode[264] = regionCodes
    
    regionCodes = []
    regionCodes.append("MW")
    regionCodesByCountryCode[265] = regionCodes
    
    regionCodes = []
    regionCodes.append("LS")
    regionCodesByCountryCode[266] = regionCodes
    
    regionCodes = []
    regionCodes.append("BW")
    regionCodesByCountryCode[267] = regionCodes
    
    regionCodes = []
    regionCodes.append("SZ")
    regionCodesByCountryCode[268] = regionCodes
    
    regionCodes = []
    regionCodes.append("KM")
    regionCodesByCountryCode[269] = regionCodes
    
    regionCodes = []
    regionCodes.append("SH")
    regionCodes.append("TA")
    regionCodesByCountryCode[290] = regionCodes
    
    regionCodes = []
    regionCodes.append("ER")
    regionCodesByCountryCode[291] = regionCodes
    
    regionCodes = []
    regionCodes.append("AW")
    regionCodesByCountryCode[297] = regionCodes
    
    regionCodes = []
    regionCodes.append("FO")
    regionCodesByCountryCode[298] = regionCodes
    
    regionCodes = []
    regionCodes.append("GL")
    regionCodesByCountryCode[299] = regionCodes
    
    regionCodes = []
    regionCodes.append("GI")
    regionCodesByCountryCode[350] = regionCodes
    
    regionCodes = []
    regionCodes.append("PT")
    regionCodesByCountryCode[351] = regionCodes
    
    regionCodes = []
    regionCodes.append("LU")
    regionCodesByCountryCode[352] = regionCodes
    
    regionCodes = []
    regionCodes.append("IE")
    regionCodesByCountryCode[353] = regionCodes
    
    regionCodes = []
    regionCodes.append("IS")
    regionCodesByCountryCode[354] = regionCodes
    
    regionCodes = []
    regionCodes.append("AL")
    regionCodesByCountryCode[355] = regionCodes
    
    regionCodes = []
    regionCodes.append("MT")
    regionCodesByCountryCode[356] = regionCodes
    
    regionCodes = []
    regionCodes.append("CY")
    regionCodesByCountryCode[357] = regionCodes
    
    regionCodes = []
    regionCodes.append("FI")
    regionCodes.append("AX")
    regionCodesByCountryCode[358] = regionCodes
    
    regionCodes = []
    regionCodes.append("BG")
    regionCodesByCountryCode[359] = regionCodes
    
    regionCodes = []
    regionCodes.append("LT")
    regionCodesByCountryCode[370] = regionCodes
    
    regionCodes = []
    regionCodes.append("LV")
    regionCodesByCountryCode[371] = regionCodes
    
    regionCodes = []
    regionCodes.append("EE")
    regionCodesByCountryCode[372] = regionCodes
    
    regionCodes = []
    regionCodes.append("MD")
    regionCodesByCountryCode[373] = regionCodes
    
    regionCodes = []
    regionCodes.append("AM")
    regionCodesByCountryCode[374] = regionCodes
    
    regionCodes = []
    regionCodes.append("BY")
    regionCodesByCountryCode[375] = regionCodes
    
    regionCodes = []
    regionCodes.append("AD")
    regionCodesByCountryCode[376] = regionCodes
    
    regionCodes = []
    regionCodes.append("MC")
    regionCodesByCountryCode[377] = regionCodes
    
    regionCodes = []
    regionCodes.append("SM")
    regionCodesByCountryCode[378] = regionCodes
    
    regionCodes = []
    regionCodes.append("UA")
    regionCodesByCountryCode[380] = regionCodes
    
    regionCodes = []
    regionCodes.append("RS")
    regionCodesByCountryCode[381] = regionCodes
    
    regionCodes = []
    regionCodes.append("ME")
    regionCodesByCountryCode[382] = regionCodes
    
    regionCodes = []
    regionCodes.append("XK")
    regionCodesByCountryCode[383] = regionCodes
    
    regionCodes = []
    regionCodes.append("HR")
    regionCodesByCountryCode[385] = regionCodes
    
    regionCodes = []
    regionCodes.append("SI")
    regionCodesByCountryCode[386] = regionCodes
    
    regionCodes = []
    regionCodes.append("BA")
    regionCodesByCountryCode[387] = regionCodes
    
    regionCodes = []
    regionCodes.append("MK")
    regionCodesByCountryCode[389] = regionCodes
    
    regionCodes = []
    regionCodes.append("CZ")
    regionCodesByCountryCode[420] = regionCodes
    
    regionCodes = []
    regionCodes.append("SK")
    regionCodesByCountryCode[421] = regionCodes
    
    regionCodes = []
    regionCodes.append("LI")
    regionCodesByCountryCode[423] = regionCodes
    
    regionCodes = []
    regionCodes.append("FK")
    regionCodesByCountryCode[500] = regionCodes
    
    regionCodes = []
    regionCodes.append("BZ")
    regionCodesByCountryCode[501] = regionCodes
    
    regionCodes = []
    regionCodes.append("GT")
    regionCodesByCountryCode[502] = regionCodes
    
    regionCodes = []
    regionCodes.append("SV")
    regionCodesByCountryCode[503] = regionCodes
    
    regionCodes = []
    regionCodes.append("HN")
    regionCodesByCountryCode[504] = regionCodes
    
    regionCodes = []
    regionCodes.append("NI")
    regionCodesByCountryCode[505] = regionCodes
    
    regionCodes = []
    regionCodes.append("CR")
    regionCodesByCountryCode[506] = regionCodes
    
    regionCodes = []
    regionCodes.append("PA")
    regionCodesByCountryCode[507] = regionCodes
    
    regionCodes = []
    regionCodes.append("PM")
    regionCodesByCountryCode[508] = regionCodes
    
    regionCodes = []
    regionCodes.append("HT")
    regionCodesByCountryCode[509] = regionCodes
    
    regionCodes = []
    regionCodes.append("GP")
    regionCodes.append("BL")
    regionCodes.append("MF")
    regionCodesByCountryCode[590] = regionCodes
    
    regionCodes = []
    regionCodes.append("BO")
    regionCodesByCountryCode[591] = regionCodes
    
    regionCodes = []
    regionCodes.append("GY")
    regionCodesByCountryCode[592] = regionCodes
    
    regionCodes = []
    regionCodes.append("EC")
    regionCodesByCountryCode[593] = regionCodes
    
    regionCodes = []
    regionCodes.append("GF")
    regionCodesByCountryCode[594] = regionCodes
    
    regionCodes = []
    regionCodes.append("PY")
    regionCodesByCountryCode[595] = regionCodes
    
    regionCodes = []
    regionCodes.append("MQ")
    regionCodesByCountryCode[596] = regionCodes
    
    regionCodes = []
    regionCodes.append("SR")
    regionCodesByCountryCode[597] = regionCodes
    
    regionCodes = []
    regionCodes.append("UY")
    regionCodesByCountryCode[598] = regionCodes
    
    regionCodes = []
    regionCodes.append("CW")
    regionCodes.append("BQ")
    regionCodesByCountryCode[599] = regionCodes
    
    regionCodes = []
    regionCodes.append("TL")
    regionCodesByCountryCode[670] = regionCodes
    
    regionCodes = []
    regionCodes.append("NF")
    regionCodesByCountryCode[672] = regionCodes
    
    regionCodes = []
    regionCodes.append("BN")
    regionCodesByCountryCode[673] = regionCodes
    
    regionCodes = []
    regionCodes.append("NR")
    regionCodesByCountryCode[674] = regionCodes
    
    regionCodes = []
    regionCodes.append("PG")
    regionCodesByCountryCode[675] = regionCodes
    
    regionCodes = []
    regionCodes.append("TO")
    regionCodesByCountryCode[676] = regionCodes
    
    regionCodes = []
    regionCodes.append("SB")
    regionCodesByCountryCode[677] = regionCodes
    
    regionCodes = []
    regionCodes.append("VU")
    regionCodesByCountryCode[678] = regionCodes
    
    regionCodes = []
    regionCodes.append("FJ")
    regionCodesByCountryCode[679] = regionCodes
    
    regionCodes = []
    regionCodes.append("PW")
    regionCodesByCountryCode[680] = regionCodes
    
    regionCodes = []
    regionCodes.append("WF")
    regionCodesByCountryCode[681] = regionCodes
    
    regionCodes = []
    regionCodes.append("CK")
    regionCodesByCountryCode[682] = regionCodes
    
    regionCodes = []
    regionCodes.append("NU")
    regionCodesByCountryCode[683] = regionCodes
    
    regionCodes = []
    regionCodes.append("WS")
    regionCodesByCountryCode[685] = regionCodes
    
    regionCodes = []
    regionCodes.append("KI")
    regionCodesByCountryCode[686] = regionCodes
    
    regionCodes = []
    regionCodes.append("NC")
    regionCodesByCountryCode[687] = regionCodes
    
    regionCodes = []
    regionCodes.append("TV")
    regionCodesByCountryCode[688] = regionCodes
    
    regionCodes = []
    regionCodes.append("PF")
    regionCodesByCountryCode[689] = regionCodes
    
    regionCodes = []
    regionCodes.append("TK")
    regionCodesByCountryCode[690] = regionCodes
    
    regionCodes = []
    regionCodes.append("FM")
    regionCodesByCountryCode[691] = regionCodes
    
    regionCodes = []
    regionCodes.append("MH")
    regionCodesByCountryCode[692] = regionCodes
    
    regionCodes = []
    regionCodes.append("001")
    regionCodesByCountryCode[800] = regionCodes
    
    regionCodes = []
    regionCodes.append("001")
    regionCodesByCountryCode[808] = regionCodes
    
    regionCodes = []
    regionCodes.append("KP")
    regionCodesByCountryCode[850] = regionCodes
    
    regionCodes = []
    regionCodes.append("HK")
    regionCodesByCountryCode[852] = regionCodes
    
    regionCodes = []
    regionCodes.append("MO")
    regionCodesByCountryCode[853] = regionCodes
    
    regionCodes = []
    regionCodes.append("KH")
    regionCodesByCountryCode[855] = regionCodes
    
    regionCodes = []
    regionCodes.append("LA")
    regionCodesByCountryCode[856] = regionCodes
    
    regionCodes = []
    regionCodes.append("001")
    regionCodesByCountryCode[870] = regionCodes
    
    regionCodes = []
    regionCodes.append("001")
    regionCodesByCountryCode[878] = regionCodes
    
    regionCodes = []
    regionCodes.append("BD")
    regionCodesByCountryCode[880] = regionCodes
    
    regionCodes = []
    regionCodes.append("001")
    regionCodesByCountryCode[881] = regionCodes
    
    regionCodes = []
    regionCodes.append("001")
    regionCodesByCountryCode[882] = regionCodes
    
    regionCodes = []
    regionCodes.append("001")
    regionCodesByCountryCode[883] = regionCodes
    
    regionCodes = []
    regionCodes.append("TW")
    regionCodesByCountryCode[886] = regionCodes
    
    regionCodes = []
    regionCodes.append("001")
    regionCodesByCountryCode[888] = regionCodes
    
    regionCodes = []
    regionCodes.append("MV")
    regionCodesByCountryCode[960] = regionCodes
    
    regionCodes = []
    regionCodes.append("LB")
    regionCodesByCountryCode[961] = regionCodes
    
    regionCodes = []
    regionCodes.append("JO")
    regionCodesByCountryCode[962] = regionCodes
    
    regionCodes = []
    regionCodes.append("SY")
    regionCodesByCountryCode[963] = regionCodes
    
    regionCodes = []
    regionCodes.append("IQ")
    regionCodesByCountryCode[964] = regionCodes
    
    regionCodes = []
    regionCodes.append("KW")
    regionCodesByCountryCode[965] = regionCodes
    
    regionCodes = []
    regionCodes.append("SA")
    regionCodesByCountryCode[966] = regionCodes
    
    regionCodes = []
    regionCodes.append("YE")
    regionCodesByCountryCode[967] = regionCodes
    
    regionCodes = []
    regionCodes.append("OM")
    regionCodesByCountryCode[968] = regionCodes
    
    regionCodes = []
    regionCodes.append("PS")
    regionCodesByCountryCode[970] = regionCodes
    
    regionCodes = []
    regionCodes.append("AE")
    regionCodesByCountryCode[971] = regionCodes
    
    regionCodes = []
    regionCodes.append("IL")
    regionCodesByCountryCode[972] = regionCodes
    
    regionCodes = []
    regionCodes.append("BH")
    regionCodesByCountryCode[973] = regionCodes
    
    regionCodes = []
    regionCodes.append("QA")
    regionCodesByCountryCode[974] = regionCodes
    
    regionCodes = []
    regionCodes.append("BT")
    regionCodesByCountryCode[975] = regionCodes
    
    regionCodes = []
    regionCodes.append("MN")
    regionCodesByCountryCode[976] = regionCodes
    
    regionCodes = []
    regionCodes.append("NP")
    regionCodesByCountryCode[977] = regionCodes
    
    regionCodes = []
    regionCodes.append("001")
    regionCodesByCountryCode[979] = regionCodes
    
    regionCodes = []
    regionCodes.append("TJ")
    regionCodesByCountryCode[992] = regionCodes
    
    regionCodes = []
    regionCodes.append("TM")
    regionCodesByCountryCode[993] = regionCodes
    
    regionCodes = []
    regionCodes.append("AZ")
    regionCodesByCountryCode[994] = regionCodes
    
    regionCodes = []
    regionCodes.append("GE")
    regionCodesByCountryCode[995] = regionCodes
    
    regionCodes = []
    regionCodes.append("KG")
    regionCodesByCountryCode[996] = regionCodes
    
    regionCodes = []
    regionCodes.append("UZ")
    regionCodesByCountryCode[998] = regionCodes
    
    return regionCodesByCountryCode
  }
}
