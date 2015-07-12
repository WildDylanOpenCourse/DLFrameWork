
///----------------------------------
///  @name 字体扩展类
///----------------------------------

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, FamilyFontName)
{
    FamilyFontNameAcademyEngravedLET = 0,
    FamilyFontNameAlNile,
    FamilyFontNameAmericanTypewriter,
    FamilyFontNameAppleColorEmoji,
    FamilyFontNameAppleSDGothicNeo,
    FamilyFontNameArial,
    FamilyFontNameArialHebrew,
    FamilyFontNameArialRoundedMTBold,
    FamilyFontNameAvenir,
    FamilyFontNameAvenirNext,
    FamilyFontNameAvenirNextCondensed,
    FamilyFontNameBanglaSangamMN,
    FamilyFontNameBaskerville,
    FamilyFontNameBodoni72,
    FamilyFontNameBodoni72Oldstyle,
    FamilyFontNameBodoni72Smallcaps,
    FamilyFontNameBodoniOrnaments,
    FamilyFontNameBradleyHand,
    FamilyFontNameChalkboardSE,
    FamilyFontNameChalkduster,
    FamilyFontNameCochin,
    FamilyFontNameCopperplate,
    FamilyFontNameCourier,
    FamilyFontNameCourierNew,
    FamilyFontNameDamascus,
    FamilyFontNameDevanagariSangamMN,
    FamilyFontNameDidot,
    FamilyFontNameDINAlternate,
    FamilyFontNameDINCondensed,
    FamilyFontNameEuphemiaUCAS,
    FamilyFontNameFarah,
    FamilyFontNameFutura,
    FamilyFontNameGeezaPro,
    FamilyFontNameGeorgia,
    FamilyFontNameGillSans,
    FamilyFontNameGujaratiSangemMN,
    FamilyFontNameGurmukhiMN,
    FamilyFontNameHeitiSC,
    FamilyFontNameHeitiTC,
    FamilyFontNameHelvetica,
    FamilyFontNameHelveticaNeue,
    FamilyFontNameHiraginoKakuGothicProN,
    FamilyFontNameHiraginoMinchoProN,
    FamilyFontNameHoeflerText,
    FamilyFontNameIowanOldStyle,
    FamilyFontNameKailasa,
    FamilyFontNameKannadaSangamMN,
    FamilyFontNameKhmerSangamMN NS_ENUM_AVAILABLE_IOS(8_0),
    FamilyFontNameKohinoorDevanagari NS_ENUM_AVAILABLE_IOS(8_0),
    FamilyFontNameLaoSangamMN NS_ENUM_AVAILABLE_IOS(8_0),
    FamilyFontNameMalayamSangamMN,
    FamilyFontNameMarion,
    FamilyFontNameMarkerFelt,
    FamilyFontNameMenlo,
    FamilyFontNameMishafi,
    FamilyFontNameNoteworthy,
    FamilyFontNameOptima,
    FamilyFontNameOriyaSangemMN,
    FamilyFontNamePalatino,
    FamilyFontNamePapyrus,
    FamilyFontNamePartyLET,
    FamilyFontNameSavoyeLET,
    FamilyFontNameSinhalaSangamMN,
    FamilyFontNameSnellRoundhand,
    FamilyFontNameSuperclarendon,
    FamilyFontNameSymbol,
    FamilyFontNameTamilSangamMN,
    FamilyFontNameTeluguSangamMN,
    FamilyFontNameThonburi,
    FamilyFontNameTimesNewRoman,
    FamilyFontNameTrebuchetMS,
    FamilyFontNameVerdana,
    FamilyFontNameZapfDingBats,
    FamilyFontNameZapfino
};

typedef NS_ENUM(NSInteger, FontName)
{
    FontNameAcademyEngravedLetPlain = 0,
    FontNameAlNile,
    FontNameAlNileBold,
    FontNameAmericanTypewriter,
    FontNameAmericanTypewriterBold,
    FontNameAmericanTypewriterCondensed,
    FontNameAmericanTypewriterCondensedBold,
    FontNameAmericanTypewriterCondensedLight,
    FontNameAmericanTypewriterLight,
    FontNameAppleColorEmoji,
    FontNameAppleSDGohticNeoBold,
    FontNameAppleSDGohticNeoLight,
    FontNameAppleSDGohticNeoMedium,
    FontNameAppleSDGohticNeoRegular,
    FontNameAppleSDGohticNeoSemiBold,
    FontNameAppleSDGohticNeoThin,
    FontNameArialBoldItalicMT,
    FontNameArialBoldMT,
    FontNameArialHebrew,
    FontNameArialHebrewBold,
    FontNameArialHebrewLight,
    FontNameArialItalicMT,
    FontNameArialMT,
    FontNameArialRoundedMTBold,
    FontNameASTHeitiLight,
    FontNameASTHeitiMedium,
    FontNameAvenirBlack,
    FontNameAvenirBlackOblique,
    FontNameAvenirBook,
    FontNameAvenirBookOblique,
    FontNameAvenirHeavtOblique,
    FontNameAvenirHeavy,
    FontNameAvenirLight,
    FontNameAvenirLightOblique,
    FontNameAvenirMedium,
    FontNameAvenirMediumOblique,
    FontNameAvenirNextBold,
    FontNameAvenirNextBoldItalic,
    FontNameAvenirNextCondensedBold,
    FontNameAvenirNextCondensedBoldItalic,
    FontNameAvenirNextCondensedDemiBold,
    FontNameAvenirNextCondensedDemiBoldItalic,
    FontNameAvenirNextCondensedHeavy,
    FontNameAvenirNextCondensedHeavyItalic,
    FontNameAvenirNextCondensedItalic,
    FontNameAvenirNextCondensedMedium,
    FontNameAvenirNextCondensedMediumItalic,
    FontNameAvenirNextCondensedRegular,
    FontNameAvenirNextCondensedUltraLight,
    FontNameAvenirNextCondensedUltraLightItalic,
    FontNameAvenirNextDemiBold,
    FontNameAvenirNextDemiBoldItalic,
    FontNameAvenirNextHeavy,
    FontNameAvenirNextItalic,
    FontNameAvenirNextMedium,
    FontNameAvenirNextMediumItalic,
    FontNameAvenirNextRegular,
    FontNameAvenirNextUltraLight,
    FontNameAvenirNextUltraLightItalic,
    FontNameAvenirOblique,
    FontNameAvenirRoman,
    FontNameBanglaSangamMN,
    FontNameBanglaSangamMNBold,
    FontNameBaskerville,
    FontNameBaskervilleBold,
    FontNameBaskervilleBoldItalic,
    FontNameBaskervilleItalic,
    FontNameBaskervilleSemiBold,
    FontNameBaskervilleSemiBoldItalic,
    FontNameBodoniOrnamentsITCTT,
    FontNameBodoniSvtyTwoITCTTBold,
    FontNameBodoniSvtyTwoITCTTBook,
    FontNameBodoniSvtyTwoITCTTBookIta,
    FontNameBodoniSvtyTwoOSITCTTBold,
    FontNameBodoniSvtyTwoOSITCTTBook,
    FontNameBodoniSvtyTwoOSITCTTBookIt,
    FontNameBodoniSvtyTwoSCITCTTBook,
    FontNameBradleyHandITCTTBold,
    FontNameChalkboardSEBold,
    FontNameChalkboardSELight,
    FontNameChalkboardSERegular,
    FontNameChalkduster,
    FontNameCochin,
    FontNameCochinBold,
    FontNameCochinBoldItalic,
    FontNameCochinItalic,
    FontNameCopperplate,
    FontNameCopperplateBold,
    FontNameCopperplateLight,
    FontNameCourier,
    FontNameCourierBold,
    FontNameCourierBoldOblique,
    FontNameCourierNewPSBoldItalicMT,
    FontNameCourierNewPSBoldMT,
    FontNameCourierNewPSItalicMT,
    FontNameCourierNewPSMT,
    FontNameCourierOblique,
    FontNameDamascus,
    FontNameDamascusBold,
    FontNameDamascusMedium,
    FontNameDamascusSemiBold,
    FontNameDevanagariSangamMN,
    FontNameDevanagariSangamMNBold,
    FontNameDidot,
    FontNameDidotBold,
    FontNameDidotItalic,
    FontNameDINAlternateBold,
    FontNameDINCondensedBold,
    FontNameDiwanMishafi,
    FontNameEuphemiaUCAS,
    FontNameEuphemiaUCASBold,
    FontNameEuphemiaUCASItalic,
    FontNameFarah,
    FontNameFuturaCondensedExtraBold,
    FontNameFuturaCondensedMedium,
    FontNameFuturaMedium,
    FontNameFuturaMediumItalicm,
    FontNameGeezaPro,
    FontNameGeezaProBold,
    FontNameGeezaProLight,
    FontNameGeorgia,
    FontNameGeorgiaBold,
    FontNameGeorgiaBoldItalic,
    FontNameGeorgiaItalic,
    FontNameGillSans,
    FontNameGillSansBold,
    FontNameGillSansBoldItalic,
    FontNameGillSansItalic,
    FontNameGillSansLight,
    FontNameGillSansLightItalic,
    FontNameGujaratiSangamMN,
    FontNameGujaratiSangamMNBold,
    FontNameGurmukhiMN,
    FontNameGurmukhiMNBold,
    FontNameHelvetica,
    FontNameHelveticaBold,
    FontNameHelveticaBoldOblique,
    FontNameHelveticaLight,
    FontNameHelveticaLightOblique,
    FontNameHelveticaNeue,
    FontNameHelveticaNeueBold,
    FontNameHelveticaNeueBoldItalic,
    FontNameHelveticaNeueCondensedBlack,
    FontNameHelveticaNeueCondensedBold,
    FontNameHelveticaNeueItalic,
    FontNameHelveticaNeueLight,
    FontNameHelveticaNeueMedium,
    FontNameHelveticaNeueMediumItalic,
    FontNameHelveticaNeueThin,
    FontNameHelveticaNeueThinItalic,
    FontNameHelveticaNeueUltraLight,
    FontNameHelveticaNeueUltraLightItalic,
    FontNameHelveticaOblique,
    FontNameHiraKakuProNW3,
    FontNameHiraKakuProNW6,
    FontNameHiraMinProNW3,
    FontNameHiraMinProNW6,
    FontNameHoeflerTextBlack,
    FontNameHoeflerTextBlackItalic,
    FontNameHoeflerTextItalic,
    FontNameHoeflerTextRegular,
    FontNameIowanOldStyleBold,
    FontNameIowanOldStyleBoldItalic,
    FontNameIowanOldStyleItalic,
    FontNameIowanOldStyleRoman,
    FontNameKailasa,
    FontNameKailasaBold,
    FontNameKannadaSangamMN,
    FontNameKannadaSangamMNBold,
    FontNameKhmerSangamMN NS_ENUM_AVAILABLE_IOS(8_0),
    FontNameKohinoorDevanagariLight NS_ENUM_AVAILABLE_IOS(8_0),
    FontNameKohinoorDevanagariMedium NS_ENUM_AVAILABLE_IOS(8_0),
    FontNameKohinoorDevanagariBook NS_ENUM_AVAILABLE_IOS(8_0),
    FontNameLaoSangamMN NS_ENUM_AVAILABLE_IOS(8_0),
    FontNameMalayalamSangamMN,
    FontNameMalayalamSangamMNBold,
    FontNameMarionBold,
    FontNameMarionItalic,
    FontNameMarionRegular,
    FontNameMarkerFeltThin,
    FontNameMarkerFeltWide,
    FontNameMenloBold,
    FontNameMenloBoldItalic,
    FontNameMenloItalic,
    FontNameMenloRegular,
    FontNameNoteworthyBold,
    FontNameNoteworthyLight,
    FontNameOptimaBold,
    FontNameOptimaBoldItalic,
    FontNameOptimaExtraBlack,
    FontNameOptimaItalic,
    FontNameOptimaRegular,
    FontNameOriyaSangamMN,
    FontNameOriyaSangamMNBold,
    FontNamePalatinoBold,
    FontNamePalatinoBoldItalic,
    FontNamePalatinoItalic,
    FontNamePalatinoRoman,
    FontNamePapyrus,
    FontNamePapyrusCondensed,
    FontNamePartyLetPlain,
    FontNameSavoyeLetPlain,
    FontNameSinhalaSangamMN,
    FontNameSinhalaSangamMNBold,
    FontNameSnellRoundhand,
    FontNameSnellRoundhandBlack,
    FontNameSnellRoundhandBold,
    FontNameSTHeitiSCLight,
    FontNameSTHeitiSCMedium,
    FontNameSTHeitiTCLight,
    FontNameSTHeitiTCMedium,
    FontNameSuperclarendonBlack,
    FontNameSuperclarendonBlackItalic,
    FontNameSuperclarendonBold,
    FontNameSuperclarendonBoldItalic,
    FontNameSuperclarendonItalic,
    FontNameSuperclarendonLight,
    FontNameSuperclarendonLightItalic,
    FontNameSuperclarendonRegular,
    FontNameSymbol,
    FontNameTamilSangamMN,
    FontNameTamilSangamMNBold,
    FontNameTeluguSangamMN,
    FontNameTeluguSangamMNBold,
    FontNameThonburi,
    FontNameThonburiBold,
    FontNameThonburiLight,
    FontNameTimesNewRomanPSBoldItalicMT,
    FontNameTimesNewRomanPSBoldMT,
    FontNameTimesNewRomanPSItalicMT,
    FontNameTimesNewRomanPSMT,
    FontNameTrebuchetBoldItalic,
    FontNameTrebuchetMS,
    FontNameTrebuchetMSBold,
    FontNameTrebuchetMSItalic,
    FontNameVerdana,
    FontNameVerdanaBold,
    FontNameVerdanaBoldItalic,
    FontNameVerdanaItalic,
    FontNameZapfDingbatsITC,
    FontNameZapfino
};

@interface UIFont (DLExtension)

+ (void)allFamilyAndFonts;

+ (NSArray *)fontsNameForFamilyName:(FamilyFontName)familyFontName;


/*!
 *  常用方法
 */
+ (UIFont *)fontForFontName:(FontName)fontName
                       size:(CGFloat)fontSize;


@end
