<?php

namespace App\Data;

use App\Support\Nation;

/**
 * [Sprint 27] Every country in the data: its Arabic name, a three-letter code, its colours and its confederation
 * (UEFA, CAF, AFC, CONMEBOL, CONCACAF, OFC). A national team is made from the players of one nationality
 * (`data:nations`); two spellings of one country (Holland and Netherlands) are one team.
 */
class Nations
{
    public const CONFEDERATIONS = ['UEFA', 'CAF', 'AFC', 'CONMEBOL', 'CONCACAF', 'OFC'];

    /** Other spellings in the data => the name the team goes by. */
    public const ALIASES = ['Holland' => 'Netherlands', 'Dr Congo' => 'Congo DR'];

    /** name => [Arabic, code, primary, secondary, confederation] */
    public const ALL = [
        'Afghanistan' => ['أفغانستان', 'AFG', '#D32011', '#000000', 'AFC'],
        'Albania' => ['ألبانيا', 'ALB', '#E41E20', '#000000', 'UEFA'],
        'Algeria' => ['الجزائر', 'ALG', '#FFFFFF', '#006633', 'CAF'],
        'Andorra' => ['أندورا', 'AND', '#10069F', '#FEDF00', 'UEFA'],
        'Angola' => ['أنغولا', 'ANG', '#CC092F', '#000000', 'CAF'],
        'Antigua and Barbuda' => ['أنتيغوا وباربودا', 'ATG', '#CE1126', '#000000', 'CONCACAF'],
        'Argentina' => ['الأرجنتين', 'ARG', '#75AADB', '#FFFFFF', 'CONMEBOL'],
        'Armenia' => ['أرمينيا', 'ARM', '#D90012', '#0033A0', 'UEFA'],
        'Australia' => ['أستراليا', 'AUS', '#FFCD00', '#00843D', 'AFC'],
        'Austria' => ['النمسا', 'AUT', '#ED2939', '#FFFFFF', 'UEFA'],
        'Azerbaijan' => ['أذربيجان', 'AZE', '#00B5E2', '#EF3340', 'UEFA'],
        'Bahrain' => ['البحرين', 'BHR', '#CE1126', '#FFFFFF', 'AFC'],
        'Bangladesh' => ['بنغلاديش', 'BAN', '#006A4E', '#F42A41', 'AFC'],
        'Barbados' => ['باربادوس', 'BRB', '#00267F', '#FFC726', 'CONCACAF'],
        'Belarus' => ['بيلاروسيا', 'BLR', '#C8313E', '#4AA657', 'UEFA'],
        'Belgium' => ['بلجيكا', 'BEL', '#E30613', '#000000', 'UEFA'],
        'Benin' => ['بنين', 'BEN', '#FCD116', '#008751', 'CAF'],
        'Bermuda' => ['برمودا', 'BER', '#C8102E', '#012169', 'CONCACAF'],
        'Bolivia' => ['بوليفيا', 'BOL', '#007934', '#FFFFFF', 'CONMEBOL'],
        'Bosnia and Herzegovina' => ['البوسنة والهرسك', 'BIH', '#002395', '#FECB00', 'UEFA'],
        'Botswana' => ['بوتسوانا', 'BOT', '#75AADB', '#000000', 'CAF'],
        'Brazil' => ['البرازيل', 'BRA', '#FEDD00', '#009739', 'CONMEBOL'],
        'Bulgaria' => ['بلغاريا', 'BUL', '#FFFFFF', '#00966E', 'UEFA'],
        'Burkina Faso' => ['بوركينا فاسو', 'BFA', '#009E49', '#EF2B2D', 'CAF'],
        'Burundi' => ['بوروندي', 'BDI', '#CE1126', '#1EB53A', 'CAF'],
        'Cameroon' => ['الكاميرون', 'CMR', '#007A5E', '#CE1126', 'CAF'],
        'Canada' => ['كندا', 'CAN', '#D80621', '#FFFFFF', 'CONCACAF'],
        'Cape Verde Islands' => ['الرأس الأخضر', 'CPV', '#003893', '#CF2027', 'CAF'],
        'Central African Republic' => ['أفريقيا الوسطى', 'CTA', '#003082', '#FFCE00', 'CAF'],
        'Chad' => ['تشاد', 'CHA', '#002664', '#FECB00', 'CAF'],
        'Chile' => ['تشيلي', 'CHI', '#D52B1E', '#0039A6', 'CONMEBOL'],
        'China PR' => ['الصين', 'CHN', '#DE2910', '#FFDE00', 'AFC'],
        'Chinese Taipei' => ['تايبيه الصينية', 'TPE', '#0033A0', '#FFFFFF', 'AFC'],
        'Colombia' => ['كولومبيا', 'COL', '#FCD116', '#003893', 'CONMEBOL'],
        'Comoros' => ['جزر القمر', 'COM', '#3A75C4', '#FFFFFF', 'CAF'],
        'Congo' => ['الكونغو', 'CGO', '#009543', '#DC241F', 'CAF'],
        'Congo DR' => ['الكونغو الديمقراطية', 'COD', '#007FFF', '#CE1021', 'CAF'],
        'Costa Rica' => ['كوستاريكا', 'CRC', '#CE1126', '#002B7F', 'CONCACAF'],
        'Croatia' => ['كرواتيا', 'CRO', '#FF0000', '#FFFFFF', 'UEFA'],
        'Cuba' => ['كوبا', 'CUB', '#CF142B', '#002A8F', 'CONCACAF'],
        'Curaçao' => ['كوراساو', 'CUW', '#002B7F', '#F9E814', 'CONCACAF'],
        'Cyprus' => ['قبرص', 'CYP', '#1E64C8', '#FFFFFF', 'UEFA'],
        'Czech Republic' => ['التشيك', 'CZE', '#D7141A', '#11457E', 'UEFA'],
        "Côte d'Ivoire" => ['كوت ديفوار', 'CIV', '#F77F00', '#009E60', 'CAF'],
        'Denmark' => ['الدنمارك', 'DEN', '#C60C30', '#FFFFFF', 'UEFA'],
        'Dominican Republic' => ['الدومينيكان', 'DOM', '#002D62', '#CE1126', 'CONCACAF'],
        'Ecuador' => ['الإكوادور', 'ECU', '#FFDD00', '#034EA2', 'CONMEBOL'],
        'Egypt' => ['مصر', 'EGY', '#CE1126', '#FFFFFF', 'CAF'],
        'El Salvador' => ['السلفادور', 'SLV', '#0F47AF', '#FFFFFF', 'CONCACAF'],
        'England' => ['إنجلترا', 'ENG', '#FFFFFF', '#CE1124', 'UEFA'],
        'Equatorial Guinea' => ['غينيا الاستوائية', 'EQG', '#E32118', '#3E9A00', 'CAF'],
        'Eritrea' => ['إريتريا', 'ERI', '#4189DD', '#EA0437', 'CAF'],
        'Estonia' => ['إستونيا', 'EST', '#0072CE', '#000000', 'UEFA'],
        'Faroe Islands' => ['جزر فارو', 'FRO', '#FFFFFF', '#0065BD', 'UEFA'],
        'Finland' => ['فنلندا', 'FIN', '#FFFFFF', '#003580', 'UEFA'],
        'France' => ['فرنسا', 'FRA', '#002395', '#FFFFFF', 'UEFA'],
        'Gabon' => ['الغابون', 'GAB', '#FCD116', '#009E60', 'CAF'],
        'Gambia' => ['غامبيا', 'GAM', '#CE1126', '#0C1C8C', 'CAF'],
        'Georgia' => ['جورجيا', 'GEO', '#FFFFFF', '#FF0000', 'UEFA'],
        'Germany' => ['ألمانيا', 'GER', '#FFFFFF', '#000000', 'UEFA'],
        'Ghana' => ['غانا', 'GHA', '#FFFFFF', '#006B3F', 'CAF'],
        'Gibraltar' => ['جبل طارق', 'GIB', '#DA000C', '#FFFFFF', 'UEFA'],
        'Greece' => ['اليونان', 'GRE', '#0D5EAF', '#FFFFFF', 'UEFA'],
        'Grenada' => ['غرينادا', 'GRN', '#CE1126', '#007A5E', 'CONCACAF'],
        'Guatemala' => ['غواتيمالا', 'GUA', '#4997D0', '#FFFFFF', 'CONCACAF'],
        'Guinea' => ['غينيا', 'GUI', '#CE1126', '#009460', 'CAF'],
        'Guinea-Bissau' => ['غينيا بيساو', 'GNB', '#CE1126', '#009E49', 'CAF'],
        'Guyana' => ['غيانا', 'GUY', '#009E49', '#FCD116', 'CONCACAF'],
        'Haiti' => ['هايتي', 'HAI', '#00209F', '#D21034', 'CONCACAF'],
        'Honduras' => ['هندوراس', 'HON', '#FFFFFF', '#00BCE4', 'CONCACAF'],
        'Hong Kong' => ['هونغ كونغ', 'HKG', '#DE2910', '#FFFFFF', 'AFC'],
        'Hungary' => ['المجر', 'HUN', '#CD2A3E', '#436F4D', 'UEFA'],
        'Iceland' => ['آيسلندا', 'ISL', '#02529C', '#DC1E35', 'UEFA'],
        'India' => ['الهند', 'IND', '#0B3D91', '#FF9933', 'AFC'],
        'Indonesia' => ['إندونيسيا', 'IDN', '#CE1126', '#FFFFFF', 'AFC'],
        'Iran' => ['إيران', 'IRN', '#FFFFFF', '#239F40', 'AFC'],
        'Iraq' => ['العراق', 'IRQ', '#007A3D', '#FFFFFF', 'AFC'],
        'Israel' => ['إسرائيل', 'ISR', '#0038B8', '#FFFFFF', 'UEFA'],
        'Italy' => ['إيطاليا', 'ITA', '#0066CC', '#FFFFFF', 'UEFA'],
        'Jamaica' => ['جامايكا', 'JAM', '#FED100', '#009B3A', 'CONCACAF'],
        'Japan' => ['اليابان', 'JPN', '#000080', '#FFFFFF', 'AFC'],
        'Jordan' => ['الأردن', 'JOR', '#FFFFFF', '#CE1126', 'AFC'],
        'Kenya' => ['كينيا', 'KEN', '#BB0000', '#006600', 'CAF'],
        'Korea Republic' => ['كوريا الجنوبية', 'KOR', '#CD2E3A', '#0047A0', 'AFC'],
        'Kosovo' => ['كوسوفو', 'KVX', '#244AA5', '#D0A650', 'UEFA'],
        'Latvia' => ['لاتفيا', 'LVA', '#9E3039', '#FFFFFF', 'UEFA'],
        'Lebanon' => ['لبنان', 'LBN', '#ED1C24', '#00A651', 'AFC'],
        'Liberia' => ['ليبيريا', 'LBR', '#002868', '#BF0A30', 'CAF'],
        'Libya' => ['ليبيا', 'LBY', '#000000', '#239E46', 'CAF'],
        'Liechtenstein' => ['ليختنشتاين', 'LIE', '#002B7F', '#CE1126', 'UEFA'],
        'Lithuania' => ['ليتوانيا', 'LTU', '#FDB913', '#006A44', 'UEFA'],
        'Luxembourg' => ['لوكسمبورغ', 'LUX', '#ED2939', '#00A1DE', 'UEFA'],
        'Madagascar' => ['مدغشقر', 'MAD', '#FC3D32', '#007E3A', 'CAF'],
        'Malawi' => ['مالاوي', 'MWI', '#CE1126', '#000000', 'CAF'],
        'Malaysia' => ['ماليزيا', 'MAS', '#FFCC00', '#010066', 'AFC'],
        'Mali' => ['مالي', 'MLI', '#14B53A', '#FCD116', 'CAF'],
        'Malta' => ['مالطا', 'MLT', '#CF142B', '#FFFFFF', 'UEFA'],
        'Mauritania' => ['موريتانيا', 'MTN', '#006233', '#FFC400', 'CAF'],
        'Mexico' => ['المكسيك', 'MEX', '#006847', '#FFFFFF', 'CONCACAF'],
        'Moldova' => ['مولدوفا', 'MDA', '#0046AE', '#FFD200', 'UEFA'],
        'Montenegro' => ['الجبل الأسود', 'MNE', '#C40308', '#D3AE3B', 'UEFA'],
        'Montserrat' => ['مونتسرات', 'MSR', '#012169', '#C8102E', 'CONCACAF'],
        'Morocco' => ['المغرب', 'MAR', '#C1272D', '#006233', 'CAF'],
        'Mozambique' => ['موزمبيق', 'MOZ', '#D21034', '#007168', 'CAF'],
        'Namibia' => ['ناميبيا', 'NAM', '#003580', '#D21034', 'CAF'],
        'Netherlands' => ['هولندا', 'NED', '#F36C21', '#FFFFFF', 'UEFA'],
        'New Zealand' => ['نيوزيلندا', 'NZL', '#FFFFFF', '#000000', 'OFC'],
        'Niger' => ['النيجر', 'NIG', '#E05206', '#0DB02B', 'CAF'],
        'Nigeria' => ['نيجيريا', 'NGA', '#008751', '#FFFFFF', 'CAF'],
        'North Macedonia' => ['مقدونيا الشمالية', 'MKD', '#D20000', '#FFE600', 'UEFA'],
        'Northern Ireland' => ['أيرلندا الشمالية', 'NIR', '#00A651', '#FFFFFF', 'UEFA'],
        'Norway' => ['النرويج', 'NOR', '#BA0C2F', '#00205B', 'UEFA'],
        'Oman' => ['عُمان', 'OMA', '#DB161B', '#008000', 'AFC'],
        'Pakistan' => ['باكستان', 'PAK', '#01411C', '#FFFFFF', 'AFC'],
        'Palestine' => ['فلسطين', 'PLE', '#000000', '#009736', 'AFC'],
        'Panama' => ['بنما', 'PAN', '#DA121A', '#072357', 'CONCACAF'],
        'Paraguay' => ['باراغواي', 'PAR', '#D52B1E', '#FFFFFF', 'CONMEBOL'],
        'Peru' => ['بيرو', 'PER', '#FFFFFF', '#D91023', 'CONMEBOL'],
        'Philippines' => ['الفلبين', 'PHI', '#0038A8', '#CE1126', 'AFC'],
        'Poland' => ['بولندا', 'POL', '#FFFFFF', '#DC143C', 'UEFA'],
        'Portugal' => ['البرتغال', 'POR', '#DA291C', '#046A38', 'UEFA'],
        'Qatar' => ['قطر', 'QAT', '#8A1538', '#FFFFFF', 'AFC'],
        'Republic of Ireland' => ['أيرلندا', 'IRL', '#169B62', '#FFFFFF', 'UEFA'],
        'Romania' => ['رومانيا', 'ROU', '#FCD116', '#002B7F', 'UEFA'],
        'Russia' => ['روسيا', 'RUS', '#FFFFFF', '#D52B1E', 'UEFA'],
        'Rwanda' => ['رواندا', 'RWA', '#00A1DE', '#FAD201', 'CAF'],
        'Saudi Arabia' => ['السعودية', 'KSA', '#006C35', '#FFFFFF', 'AFC'],
        'Scotland' => ['اسكتلندا', 'SCO', '#005EB8', '#FFFFFF', 'UEFA'],
        'Senegal' => ['السنغال', 'SEN', '#FFFFFF', '#00853F', 'CAF'],
        'Serbia' => ['صربيا', 'SRB', '#C6363C', '#0C4076', 'UEFA'],
        'Sierra Leone' => ['سيراليون', 'SLE', '#1EB53A', '#0072C6', 'CAF'],
        'Slovakia' => ['سلوفاكيا', 'SVK', '#0B4EA2', '#FFFFFF', 'UEFA'],
        'Slovenia' => ['سلوفينيا', 'SVN', '#FFFFFF', '#005DA4', 'UEFA'],
        'Somalia' => ['الصومال', 'SOM', '#4189DD', '#FFFFFF', 'CAF'],
        'South Africa' => ['جنوب أفريقيا', 'RSA', '#FFB612', '#007749', 'CAF'],
        'Spain' => ['إسبانيا', 'ESP', '#C60B1E', '#FFC400', 'UEFA'],
        'Sri Lanka' => ['سريلانكا', 'SRI', '#8D153A', '#FFBE29', 'AFC'],
        'St. Kitts and Nevis' => ['سانت كيتس ونيفيس', 'SKN', '#009E49', '#CE1126', 'CONCACAF'],
        'St. Lucia' => ['سانت لوسيا', 'LCA', '#66CCFF', '#FCD116', 'CONCACAF'],
        'Sudan' => ['السودان', 'SDN', '#D21034', '#007229', 'CAF'],
        'Suriname' => ['سورينام', 'SUR', '#377E3F', '#B40A2D', 'CONCACAF'],
        'Sweden' => ['السويد', 'SWE', '#FECC02', '#006AA7', 'UEFA'],
        'Switzerland' => ['سويسرا', 'SUI', '#FF0000', '#FFFFFF', 'UEFA'],
        'Syria' => ['سوريا', 'SYR', '#CE1126', '#FFFFFF', 'AFC'],
        'Tajikistan' => ['طاجيكستان', 'TJK', '#CC0000', '#006600', 'AFC'],
        'Tanzania' => ['تنزانيا', 'TAN', '#1EB53A', '#00A3DD', 'CAF'],
        'Thailand' => ['تايلاند', 'THA', '#2D2A4A', '#A51931', 'AFC'],
        'Togo' => ['توغو', 'TOG', '#FFCE00', '#006A4E', 'CAF'],
        'Trinidad and Tobago' => ['ترينيداد وتوباغو', 'TRI', '#DA1A35', '#000000', 'CONCACAF'],
        'Tunisia' => ['تونس', 'TUN', '#E70013', '#FFFFFF', 'CAF'],
        'Turkey' => ['تركيا', 'TUR', '#E30A17', '#FFFFFF', 'UEFA'],
        'Uganda' => ['أوغندا', 'UGA', '#FCDC04', '#D90000', 'CAF'],
        'Ukraine' => ['أوكرانيا', 'UKR', '#FFD500', '#005BBB', 'UEFA'],
        'United Arab Emirates' => ['الإمارات', 'UAE', '#FFFFFF', '#00732F', 'AFC'],
        'United States' => ['الولايات المتحدة', 'USA', '#FFFFFF', '#0A3161', 'CONCACAF'],
        'Uruguay' => ['الأوروغواي', 'URU', '#5CBFEB', '#000000', 'CONMEBOL'],
        'Uzbekistan' => ['أوزبكستان', 'UZB', '#0099B5', '#FFFFFF', 'AFC'],
        'Vanuatu' => ['فانواتو', 'VAN', '#D21034', '#009543', 'OFC'],
        'Venezuela' => ['فنزويلا', 'VEN', '#7B1E3A', '#FFCC00', 'CONMEBOL'],
        'Wales' => ['ويلز', 'WAL', '#C8102E', '#00B140', 'UEFA'],
        'Yemen' => ['اليمن', 'YEM', '#CE1126', '#000000', 'AFC'],
        'Zambia' => ['زامبيا', 'ZAM', '#198A00', '#EF7D00', 'CAF'],
        'Zimbabwe' => ['زيمبابوي', 'ZIM', '#FFD200', '#006400', 'CAF'],
    ];

    /** The team's name for a nationality as the data spells it (one spelling per country). */
    public static function canonical(?string $nationality): ?string
    {
        $name = Nation::name($nationality);
        if ($name === null || $name === '') {
            return null;
        }

        return self::ALIASES[$name] ?? $name;
    }

    /** Every spelling in the data that belongs to this team. */
    public static function spellings(string $name): array
    {
        $all = [$name, mb_strtoupper($name)];
        foreach (self::ALIASES as $other => $to) {
            if ($to === $name) {
                $all[] = $other;
                $all[] = mb_strtoupper($other);
            }
        }

        return array_values(array_unique($all));
    }

    public static function info(string $name): array
    {
        $row = self::ALL[$name] ?? [$name, strtoupper(substr(preg_replace('/[^A-Za-z]/', '', $name), 0, 3)), '#FFFFFF', '#1B2A3A', null];

        return ['ar' => $row[0], 'code' => $row[1], 'colors' => [$row[2], $row[3]], 'confederation' => $row[4]];
    }

    /** The Arabic name of a national team, or the name as it is. */
    public static function arabic(string $name): string
    {
        return self::ALL[$name][0] ?? $name;
    }
}
