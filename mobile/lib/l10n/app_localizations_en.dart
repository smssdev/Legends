// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Game Legend Manager';

  @override
  String get tagline => 'A free online football manager';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInTitle => 'Welcome back';

  @override
  String get signInLead => 'Sign in to carry on your season';

  @override
  String get emailOrUsername => 'Email or username';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot it?';

  @override
  String get noAccount => 'No account yet?';

  @override
  String get createAccount => 'Create one';

  @override
  String get haveAccount => 'Have an account?';

  @override
  String get registerTitle => 'Your new account';

  @override
  String get registerLead =>
      'Three fields and you start: your name, a username and a password';

  @override
  String get displayName => 'Your display name';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'English letters and digits, 3 to 20';

  @override
  String get emailOptional => 'Email (optional, to get your password back)';

  @override
  String get passwordHint => 'At least 8 characters';

  @override
  String get acceptTerms => 'I accept the terms and the privacy policy';

  @override
  String get termsAndPrivacy => 'Terms and privacy policy';

  @override
  String get mustAcceptTerms => 'Accept the terms and the privacy policy first';

  @override
  String get register => 'Create the account';

  @override
  String get forgotTitle => 'Get your password back';

  @override
  String get forgotLead =>
      'Type your account\'s email and we send you a link for a new password';

  @override
  String get email => 'Email';

  @override
  String get sendLink => 'Send the link';

  @override
  String get linkSent =>
      'If the email belongs to an account, the link is on its way. Open it from your inbox.';

  @override
  String get required => 'Required';

  @override
  String get google => 'Continue with Google';

  @override
  String get googleSoon => 'Google sign-in is coming to the app soon';

  @override
  String get orWord => 'or';

  @override
  String get orByEmail => 'or by email';

  @override
  String get updateTitle => 'Update the app';

  @override
  String get updateBody =>
      'A new version of the game is out, and this one no longer works with it. Update the app to carry on.';

  @override
  String get update => 'Update now';

  @override
  String get offlineTitle => 'No connection';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundBody => 'This link is wrong or no longer exists.';

  @override
  String get keeperSlotOnly => 'The goal is for a goalkeeper only';

  @override
  String get retry => 'Try again';

  @override
  String get greetingMorning => 'Good morning, coach';

  @override
  String get greetingEvening => 'Good evening, coach';

  @override
  String get coins => 'coins';

  @override
  String get myTeams => 'My teams';

  @override
  String slotsOpen(int open, int total) {
    return '$open of $total';
  }

  @override
  String get slotFree => 'Free slot';

  @override
  String get slotWaiting => 'A join request waits for its answer';

  @override
  String get slotLocked => 'Locked';

  @override
  String slotOpensIn(String time) {
    return 'Opens free in $time';
  }

  @override
  String get createLeague => 'Make a league';

  @override
  String get joinByCode => 'Join with a code';

  @override
  String get openClub => 'Open the club';

  @override
  String get nextMatch => 'Next match';

  @override
  String vs(String club) {
    return 'vs $club';
  }

  @override
  String position(int n, int of) {
    return 'Place $n of $of';
  }

  @override
  String waitsForYou(int n) {
    return '$n waiting for you';
  }

  @override
  String record(int w, int d, int l) {
    return '$w won · $d drawn · $l lost';
  }

  @override
  String get onWebForNow => 'Opens on the site until it reaches the app';

  @override
  String get settings => 'Settings';

  @override
  String get look => 'Look';

  @override
  String get lookAuto => 'Automatic';

  @override
  String get lookNight => 'Night';

  @override
  String get lookDay => 'Day';

  @override
  String get language => 'Language';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirm => 'Sign out on this phone?';

  @override
  String get cancel => 'Cancel';

  @override
  String accountNo(int n) {
    return 'Your account number $n';
  }

  @override
  String days(int n) {
    return '$n d';
  }

  @override
  String hours(int n) {
    return '$n h';
  }

  @override
  String minutes(int n) {
    return '$n min';
  }

  @override
  String version(String v) {
    return 'Version $v';
  }

  @override
  String get tierProspect => 'Prospect';

  @override
  String get tierTactician => 'Tactician';

  @override
  String get tierProfessional => 'Professional';

  @override
  String get tierElite => 'Elite';

  @override
  String get tierMastermind => 'Mastermind';

  @override
  String get tierIcon => 'Icon';

  @override
  String get tierLegend => 'Legend';

  @override
  String get myLeagues => 'My leagues';

  @override
  String get noLeagues =>
      'No league yet. Make one for your friends or join with a code.';

  @override
  String get newLeague => 'New league';

  @override
  String get freeLeagueLead =>
      'The free league: all the league\'s clubs, a round a day at 9 pm, two days to get ready. The paid options are on the site.';

  @override
  String get pickTemplate => 'Pick the league';

  @override
  String get pickClub => 'Pick your team';

  @override
  String get leagueName => 'League name (optional)';

  @override
  String get create => 'Make the league';

  @override
  String clubsCount(int n) {
    return '$n clubs';
  }

  @override
  String get joinTitle => 'Join a league';

  @override
  String get joinLead =>
      'Ask your friend for their league\'s code and type it here; then the creator approves your request.';

  @override
  String get code => 'League code';

  @override
  String get sendRequest => 'Send the request';

  @override
  String get requestPending => 'Your request waits for the creator.';

  @override
  String get requestApproved => 'The creator said yes. Pick your team now.';

  @override
  String get requestRejected => 'The creator turned your request down.';

  @override
  String get cancelRequest => 'Cancel the request';

  @override
  String get takeClub => 'Take this team';

  @override
  String get goalTitle => 'Objective: the title';

  @override
  String goalPlace(int n) {
    return 'Objective: place $n or better';
  }

  @override
  String goalSurvive(int n) {
    return 'Objective: stay up, place $n or better';
  }

  @override
  String strength(int n) {
    return 'Strength $n';
  }

  @override
  String get tabClub => 'Club';

  @override
  String get tabTable => 'Table';

  @override
  String get tabFixtures => 'Matches';

  @override
  String get tabCoaches => 'Coaches';

  @override
  String waitingStart(String when) {
    return 'The league starts $when';
  }

  @override
  String round(int n) {
    return 'Round $n';
  }

  @override
  String get cup => 'Cup';

  @override
  String get invite => 'Invite your friends';

  @override
  String inviteText(String name, String url) {
    return 'Join «$name» on Game Legend Manager and pick your club: $url';
  }

  @override
  String get requests => 'Join requests';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Turn down';

  @override
  String get creator => 'Creator';

  @override
  String get onHoliday => 'On holiday';

  @override
  String get home => 'Home';

  @override
  String get away => 'Away';

  @override
  String get nextMatchShort => 'Your next match';

  @override
  String get lineupReady => 'The lineup is ready';

  @override
  String get lineupAuto => 'Automatic lineup';

  @override
  String get board => 'The board';

  @override
  String get noMatches => 'No matches yet.';

  @override
  String get openOnSite => 'Open on the site';

  @override
  String get copied => 'Copied';

  @override
  String get share => 'Share';

  @override
  String get pts => 'pts';

  @override
  String get sign => 'Sign';

  @override
  String get squad => 'Squad';

  @override
  String get lineup => 'Lineup';

  @override
  String get tactics => 'Tactics';

  @override
  String get lineGk => 'Goalkeepers';

  @override
  String get lineDef => 'Defence';

  @override
  String get lineMid => 'Midfield';

  @override
  String get lineAtt => 'Attack';

  @override
  String get starter => 'Starter';

  @override
  String get bench => 'Bench';

  @override
  String get reserve => 'Reserve';

  @override
  String injuredFor(int n) {
    return 'Injured, $n matches';
  }

  @override
  String suspendedFor(int n) {
    return 'Suspended, $n matches';
  }

  @override
  String age(int n) {
    return 'Age $n';
  }

  @override
  String potential(int n) {
    return 'Potential $n';
  }

  @override
  String get fitness => 'Fitness';

  @override
  String morale(int n) {
    return 'Morale $n';
  }

  @override
  String get squadValue => 'Squad value';

  @override
  String get formation => 'Formation';

  @override
  String get autoLineup => 'Automatic';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get swapWith => 'Swap with';

  @override
  String get tapToSwap => 'Tap a player on the pitch, then his replacement';

  @override
  String get plan => 'Attacking plan';

  @override
  String get tackling => 'Tackling';

  @override
  String get pressing => 'Pressing';

  @override
  String get style => 'Style';

  @override
  String get tempo => 'Tempo';

  @override
  String get trap => 'Offside trap';

  @override
  String get marking => 'Marking';

  @override
  String get markZone => 'Zonal';

  @override
  String get markMan => 'Man to man';

  @override
  String get planCounter => 'Counter';

  @override
  String get planShots => 'Long shots';

  @override
  String get planLong => 'Long balls';

  @override
  String get planPassing => 'Passing';

  @override
  String get planWings => 'Wings';

  @override
  String get tackle0 => 'Clean';

  @override
  String get tackle1 => 'Normal';

  @override
  String get tackle2 => 'Eager';

  @override
  String get tackle3 => 'Hard';

  @override
  String get attBack => 'Drop back';

  @override
  String get attSupport => 'Support midfield';

  @override
  String get attOnly => 'Attack only';

  @override
  String get midDef => 'Support defence';

  @override
  String get midStay => 'Stay';

  @override
  String get midPush => 'Push on';

  @override
  String get defStay => 'Stay';

  @override
  String get defFullbacks => 'Full-backs attack';

  @override
  String get defMid => 'Support midfield';

  @override
  String get low => 'Low';

  @override
  String get high => 'High';

  @override
  String get defensive => 'Defensive';

  @override
  String get attacking => 'Attacking';

  @override
  String get calm => 'Calm';

  @override
  String get fast => 'Fast';

  @override
  String get savesItself => 'Saved by itself with every change';

  @override
  String get attributes => 'Attributes';

  @override
  String get value => 'Value';

  @override
  String get ratingWord => 'Rating';

  @override
  String get potentialWord => 'Potential';

  @override
  String get watchLive => 'Watch the match';

  @override
  String get liveNow => 'Live';

  @override
  String get fullTime => 'Full time';

  @override
  String get notStarted => 'Not started yet';

  @override
  String get matchReport => 'Match report';

  @override
  String get commentary => 'Commentary';

  @override
  String get assistantNotes => 'Your assistant\'s notes';

  @override
  String get substitute => 'Substitute';

  @override
  String get subOut => 'Off';

  @override
  String get subIn => 'On';

  @override
  String subsLeft(int used, int max) {
    return '$used of $max subs';
  }

  @override
  String get ordersHint =>
      'Orders go in during the windows: before kick-off, at half-time and after minutes 15, 30, 60 and 75.';

  @override
  String get windowOpen => 'The window is open: give your orders now';

  @override
  String get imReady => 'I\'m ready';

  @override
  String get readyWaiting => 'Waiting for the other coach';

  @override
  String get breakTime => 'Break';

  @override
  String get orderSent => 'Order received: it goes in next minute';

  @override
  String get send => 'Send';

  @override
  String get possession => 'Possession';

  @override
  String get shots => 'Shots';

  @override
  String get onTarget => 'On target';

  @override
  String get corners => 'Corners';

  @override
  String get fouls => 'Fouls';

  @override
  String get saves => 'Saves';

  @override
  String get manOfMatch => 'Man of the match';

  @override
  String get toImprove => 'To improve';

  @override
  String get whyResult => 'Why this result';

  @override
  String get keyMoments => 'Key moments';

  @override
  String get gameSounds => 'Game sounds';

  @override
  String get matchStats => 'Match stats';

  @override
  String get bestPlayers => 'The best';

  @override
  String get resultWin => 'Win';

  @override
  String get resultDraw => 'Draw';

  @override
  String get resultLoss => 'Loss';

  @override
  String get pitchView => 'Pitch';

  @override
  String kickoffAt(String time) {
    return 'Kick-off $time';
  }

  @override
  String get inbox => 'Messages';

  @override
  String get noMessages => 'No messages yet';

  @override
  String get readAll => 'Mark all read';

  @override
  String get more => 'More';

  @override
  String get finance => 'Finance';

  @override
  String get balance => 'Balance';

  @override
  String get seasonIncome => 'Season income';

  @override
  String get seasonExpenses => 'Season expenses';

  @override
  String get wagesPerRound => 'Wages per round';

  @override
  String inDebt(int rounds, int limit) {
    return 'The club is in debt: no buying or building until the balance is positive ($rounds of $limit rounds)';
  }

  @override
  String get ticketPrice => 'Ticket price';

  @override
  String perMatch(String amount) {
    return '$amount a match';
  }

  @override
  String attendance(int pct) {
    return 'Attendance $pct%';
  }

  @override
  String get sponsors => 'Sponsors';

  @override
  String perWin(String amount) {
    return '+$amount a win';
  }

  @override
  String get signSponsorConfirm => 'Sign this offer for the whole season?';

  @override
  String get signed => 'Signed';

  @override
  String get transactions => 'Transactions';

  @override
  String get stadium => 'Stadium';

  @override
  String stadiumProgress(int done, int total) {
    return '$done of $total parts';
  }

  @override
  String get capacity => 'Capacity';

  @override
  String get homeAdvantage => 'Home advantage';

  @override
  String get sectionSeats => 'Seats and tickets';

  @override
  String get sectionPitch => 'The pitch';

  @override
  String get sectionTraining => 'Training centre';

  @override
  String stageOf(int stage) {
    return 'Stage $stage of 3';
  }

  @override
  String partOf(int part) {
    return 'Part $part of 5';
  }

  @override
  String buildPart(String cost) {
    return 'Build ($cost)';
  }

  @override
  String get sectionDone => 'Complete';

  @override
  String buildingNow(String section) {
    return 'Building now: $section';
  }

  @override
  String endsIn(String time) {
    return 'Ends in $time';
  }

  @override
  String finishNow(int coins) {
    return 'Finish now ($coins coins)';
  }

  @override
  String finishNowConfirm(int coins) {
    return 'Finish the part now for $coins coins?';
  }

  @override
  String partTime(String time) {
    return 'Each part takes $time';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get market => 'Market';

  @override
  String get tabBuy => 'Buy';

  @override
  String get tabSell => 'Sell';

  @override
  String get tabOffers => 'Offers';

  @override
  String get marketClosed => 'The market is closed now';

  @override
  String renewsAt(String time) {
    return 'The list renews $time';
  }

  @override
  String get fitsYou => 'Improves your team';

  @override
  String get sellerWorld => 'From outside the league';

  @override
  String buyFor(String price) {
    return 'Buy for $price';
  }

  @override
  String regFee(int coins) {
    return 'Registration $coins coins';
  }

  @override
  String compensateWith(int coins) {
    return 'Cover the rest with $coins coins';
  }

  @override
  String get bought => 'He is in your team';

  @override
  String get price => 'Price';

  @override
  String listedAt(String price) {
    return 'Listed at $price';
  }

  @override
  String sellsIn(String time) {
    return 'Sells around $time';
  }

  @override
  String get listForSale => 'List for sale';

  @override
  String get unlist => 'Take off the list';

  @override
  String sellNowFor(String pays, String fee) {
    return 'Sell now: $pays in, for $fee';
  }

  @override
  String get sellNowConfirm => 'Sell him now? There is no undo.';

  @override
  String priceRange(String floor, String cap) {
    return 'Between $floor and $cap';
  }

  @override
  String waitAbout(int hours) {
    return 'A buyer in about $hours hours';
  }

  @override
  String listingsOf(int listed, int max) {
    return '$listed of $max listed';
  }

  @override
  String get noOffers => 'No offers now';

  @override
  String offerFrom(String club) {
    return 'Offer from $club';
  }

  @override
  String offerTo(String club) {
    return 'Your offer to $club';
  }

  @override
  String get theyWant => 'Asks for';

  @override
  String get theyGive => 'And gives';

  @override
  String get accept => 'Accept';

  @override
  String get cancelOffer => 'Withdraw';

  @override
  String get offersOnWeb =>
      'Making an offer or a counter is on the site for now';

  @override
  String coinsWord(int n) {
    return '$n coins';
  }

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusOther => 'Closed';

  @override
  String get scout => 'Scout';

  @override
  String get scoutLead =>
      'The scout finds you five players from outside the league to your terms, held for you until the market renews.';

  @override
  String get minOverall => 'Lowest rating';

  @override
  String get maxAge => 'Oldest age';

  @override
  String get anyLine => 'Any line';

  @override
  String get nationality => 'Nationality';

  @override
  String get fromLeague => 'From league';

  @override
  String get any => 'Any';

  @override
  String askScout(String cost, int hours) {
    return 'Search ($cost, $hours hours)';
  }

  @override
  String searching(String time) {
    return 'Searching… report $time';
  }

  @override
  String get scoutReports => 'Reports';

  @override
  String get nobodyFound => 'Nobody found; the money came back';

  @override
  String get stateMine => 'In your team';

  @override
  String get stateGone => 'Gone';

  @override
  String get training => 'Training';

  @override
  String get trainingLead =>
      'One player per line trains; each session raises his progress until his rating goes up.';

  @override
  String sessionCost(String cost, String time) {
    return 'A session costs $cost every $time';
  }

  @override
  String get nobodyTraining => 'Nobody is training';

  @override
  String get pickToTrain => 'Choose who trains';

  @override
  String get recommended => 'Suggested';

  @override
  String nextSession(String time) {
    return 'Next session $time';
  }

  @override
  String sessionsDone(int n) {
    return '$n sessions';
  }

  @override
  String get stopTraining => 'Stop';

  @override
  String get maxed => 'Maxed out';

  @override
  String lineCoach(String name, int stars) {
    return '$name: $stars stars';
  }

  @override
  String get specialists => 'Specialists';

  @override
  String specialistsLead(int days) {
    return 'A specialist for each line speeds its training, for $days days.';
  }

  @override
  String get hire => 'Hire';

  @override
  String hiredUntil(String time) {
    return 'Until $time';
  }

  @override
  String hireConfirm(String cost) {
    return 'Hire for $cost?';
  }

  @override
  String get spy => 'Spy';

  @override
  String get spyLead =>
      'Your spy reveals your next opponent\'s lineup, shape and fitness before the lock.';

  @override
  String sendSpy(String cost) {
    return 'Send the spy ($cost)';
  }

  @override
  String get noNextMatch => 'No match coming';

  @override
  String spyReportOn(String club) {
    return 'Report on $club';
  }

  @override
  String get form => 'Form';

  @override
  String get quests => 'Quests';

  @override
  String questsRenew(String time) {
    return 'Renew $time';
  }

  @override
  String get questFriendly => 'Play a friendly';

  @override
  String get questWins => 'Win matches';

  @override
  String get questStadium => 'Build a stadium part';

  @override
  String get questTraining => 'Train a player';

  @override
  String get questUnbeaten => 'Stay unbeaten';

  @override
  String get claim => 'Claim';

  @override
  String get claimed => 'Claimed';

  @override
  String get honours => 'Honours';

  @override
  String seasonN(int n) {
    return 'Season $n';
  }

  @override
  String get noTitles => 'No titles yet';

  @override
  String get resign => 'Resign from the league';

  @override
  String get resignConfirm =>
      'Resign from this league? Your team goes back to the computer, with no undo.';

  @override
  String get wallet => 'Wallet';

  @override
  String dailyCoins(int n) {
    return 'Today\'s coins: $n';
  }

  @override
  String get claimDaily => 'Claim today\'s coins';

  @override
  String get dailyClaimed => 'Today\'s coins claimed';

  @override
  String get store => 'Store';

  @override
  String get buyOnWhatsapp => 'Order on WhatsApp';

  @override
  String endsOn(String time) {
    return 'Ends $time';
  }

  @override
  String get competitionLeague => 'League';

  @override
  String get coachProfile => 'Coach profile';

  @override
  String accountNumber(int n) {
    return 'Account no. $n';
  }

  @override
  String get seasonsPlayed => 'Seasons';

  @override
  String get played => 'Played';

  @override
  String get won => 'Won';

  @override
  String get drawn => 'Drawn';

  @override
  String get lost => 'Lost';

  @override
  String get titles => 'Titles';

  @override
  String objectivesMet(int met, int total) {
    return 'Board objectives: $met of $total';
  }

  @override
  String get notifications => 'Notifications';

  @override
  String get pushReady => 'Notifications reach this phone';

  @override
  String get pushNotReady =>
      'Phone notifications are not switched on on the server yet; every message is in your inbox';

  @override
  String get kindReferee => 'Your next match\'s referee';

  @override
  String get kindMatchSoon => 'Your match soon, and moves';

  @override
  String get kindOffers => 'Offers, sales and loans';

  @override
  String get kindDone => 'Training, stadium and scout done';

  @override
  String get kindNews => 'Game news and the developers\' messages';

  @override
  String get kindAbsence => 'Absence and holidays';

  @override
  String get emailMatch => 'Match summary by email';

  @override
  String get emailOffers => 'Store offers by email';

  @override
  String get emailNeeded => 'Needs a confirmed email on your account';

  @override
  String get newOffer => 'New offer';

  @override
  String get counterOffer => 'Counter';

  @override
  String get pickCoachClub => 'To which club?';

  @override
  String get noCoachClubs => 'No other coaches in the league yet';

  @override
  String offerTitleTo(String club) {
    return 'Offer to $club';
  }

  @override
  String get youWant => 'You ask for (up to 5)';

  @override
  String get youGive => 'And you give (optional)';

  @override
  String get youPay => 'And you pay';

  @override
  String offerValues(String want, String give) {
    return 'Value asked $want, value given $give';
  }

  @override
  String fairHint(int min, int max) {
    return 'A fair deal is between $min% and $max% of the value you ask for';
  }

  @override
  String get sendOffer => 'Send the offer';

  @override
  String get offerSent => 'The offer reached its coach';

  @override
  String get askLoan => 'Ask to borrow him';

  @override
  String loanRounds(int n) {
    return 'Loan rounds: $n';
  }

  @override
  String get loanFee => 'Loan fee';

  @override
  String get loans => 'Loans';

  @override
  String loanOf(String player, String owner, String borrower) {
    return '$player: from $owner to $borrower';
  }

  @override
  String loanTerms(int rounds, String fee) {
    return '$rounds rounds · $fee';
  }

  @override
  String get loanSent => 'The loan request was sent';

  @override
  String get academy => 'Academy';

  @override
  String academyLead(int signed, int per) {
    return 'Young talents for this period; the potential is a range until you sign one. $signed of $per this season.';
  }

  @override
  String signProspect(String price) {
    return 'Sign for $price';
  }

  @override
  String signProspectConfirm(String name, String price) {
    return 'Sign $name for $price?';
  }

  @override
  String potentialRange(int from, int to) {
    return 'Potential $from–$to';
  }

  @override
  String get friendlies => 'Friendlies';

  @override
  String friendlyLead(int fit) {
    return 'A quick friendly against any club: fitness +$fit and chemistry, not in the table.';
  }

  @override
  String friendlyCost(int coins) {
    return 'A friendly costs $coins coins';
  }

  @override
  String get friendlyFree => 'The first is free';

  @override
  String get playFriendly => 'Play';

  @override
  String get suggestedOpponent => 'Suggested';

  @override
  String get playedToday => 'Played today';

  @override
  String get recentFriendlies => 'Recent friendlies';

  @override
  String get skip => 'Skip';

  @override
  String get bestOfMatch => 'Best on the pitch';

  @override
  String get kGoal => 'Goal';

  @override
  String get kSaved => 'Saved';

  @override
  String get kMissed => 'Missed';

  @override
  String get kCorner => 'Corner';

  @override
  String get kYellow => 'Yellow';

  @override
  String get kRed => 'Red';

  @override
  String get kAttack => 'Attack';

  @override
  String get predictions => 'Predictions';

  @override
  String predictionsLead(int round, String reward) {
    return 'Predict round $round; each right pick pays your club $reward.';
  }

  @override
  String get draw => 'Draw';

  @override
  String get predictionClosed => 'Closed';

  @override
  String get newspaper => 'Newspaper';

  @override
  String get noEdition => 'No edition yet: it comes out after the first round';

  @override
  String roundResults(int round) {
    return 'Round $round results';
  }

  @override
  String get playerOfRound => 'Player of the round';

  @override
  String get coachOfRound => 'Coach of the round';

  @override
  String get articles => 'Coaches\' articles';

  @override
  String get writeArticle => 'Write an article';

  @override
  String get articleTitle => 'Title';

  @override
  String get articleBody => 'Article';

  @override
  String get articleSent =>
      'Your article went to the league\'s creator for publishing';

  @override
  String get pendingArticles => 'Waiting to publish';

  @override
  String get publish => 'Publish';

  @override
  String get groups => 'Groups';

  @override
  String get noGroups => 'No groups yet';

  @override
  String get typeMessage => 'Type a message';

  @override
  String get messageDeleted => 'This message was deleted';

  @override
  String get mediaOnWeb => 'Picture or voice: open it on the site';

  @override
  String get profile => 'My account';

  @override
  String get displayNameSaved => 'Saved';

  @override
  String get coachLook => 'Your look on the touchline';

  @override
  String get changePassword => 'Change the password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get inviteFriends => 'Invite your friends';

  @override
  String inviteReward(int coins, int paid, int max) {
    return '$coins coins for each friend who plays; $paid of $max paid';
  }

  @override
  String get achievements => 'Badges';

  @override
  String get tierBeginner => 'Beginner';

  @override
  String get tierIntermediate => 'Intermediate';

  @override
  String get tierPro => 'Pro';

  @override
  String get aFirstWin => 'First win';

  @override
  String aMatches(int n) {
    return '$n matches';
  }

  @override
  String aWins(int n) {
    return '$n wins';
  }

  @override
  String get aFirstTitle => 'First title';

  @override
  String get aLeagueTitle => 'League champion';

  @override
  String get aCupTitle => 'Cup winner';

  @override
  String get aProfessional => 'Professional rank';

  @override
  String get aLegend => 'Legend rank';

  @override
  String aFriendlies(int n) {
    return '$n friendlies';
  }

  @override
  String get aIdea => 'An idea adopted';

  @override
  String aInvites(int n) {
    return '$n friends';
  }

  @override
  String aTitles(int n) {
    return '$n titles';
  }

  @override
  String get stats => 'Stats';

  @override
  String get scorers => 'Top scorers';

  @override
  String get assistsTitle => 'Top assists';

  @override
  String get squadValues => 'Squad values';

  @override
  String get goalsShort => 'goals';

  @override
  String get assistsShort => 'assists';

  @override
  String get noStatsYet => 'Stats appear after the first round';

  @override
  String get ideas => 'Your ideas for the developers';

  @override
  String ideasLead(int n) {
    return 'An accepted idea earns coins and puts you on the honour roll. $n left today.';
  }

  @override
  String get suggest => 'Send the idea';

  @override
  String get suggestionSent => 'Your idea was sent';

  @override
  String get polls => 'Polls';

  @override
  String get vote => 'Vote';

  @override
  String votes(int n) {
    return '$n votes';
  }

  @override
  String get honourRoll => 'Honour roll';

  @override
  String get statusPending => 'Under review';

  @override
  String get statusBuilt => 'Built';

  @override
  String get support => 'Support';

  @override
  String get supportLead => 'Write to the game\'s team; the answer comes here.';

  @override
  String get fromTeam => 'The game\'s team';

  @override
  String get announcements => 'Announcements';

  @override
  String get noAnnouncements => 'No announcements';

  @override
  String get guide => 'How to play';

  @override
  String get tournaments => 'Tournaments';

  @override
  String get noTournaments => 'No tournaments yet';

  @override
  String get newTournament => 'New tournament';

  @override
  String get tplWorldCup => 'World Cup (32)';

  @override
  String get tplWorldCup48 => 'World Cup (48)';

  @override
  String get tplClubWorldCup => 'Club World Cup';

  @override
  String get tplAfcon => 'Africa Cup of Nations';

  @override
  String get tplEuro => 'European Championship';

  @override
  String get tplAsianCup => 'Asian Cup';

  @override
  String get startsOn => 'Starts';

  @override
  String get entryPick => 'Each coach picks his team';

  @override
  String get entryDraw => 'The draw gives the teams to the coaches';

  @override
  String tournamentCost(int coins) {
    return 'Costs $coins coins';
  }

  @override
  String get tournamentCode => 'Join code';

  @override
  String teamsCount(int n) {
    return '$n teams';
  }

  @override
  String get enter => 'Enter';

  @override
  String get leaveEntry => 'Withdraw';

  @override
  String get watchDraw => 'Watch the draw';

  @override
  String drawAt(String time) {
    return 'The draw $time';
  }

  @override
  String get drawNotSet => 'The draw is not scheduled';

  @override
  String get scheduleDraw => 'Schedule the draw';

  @override
  String drawnBalls(int n, int total) {
    return '$n of $total';
  }

  @override
  String groupN(String g) {
    return 'Group $g';
  }

  @override
  String pot(int n) {
    return 'Pot $n';
  }

  @override
  String get openLeague => 'Open the league';

  @override
  String get alliance => 'Alliance tournament';

  @override
  String get allianceLead =>
      'Two alliances of the league\'s coaches; in each tie its two coaches agree who goes on.';

  @override
  String get createAlliance => 'Create it';

  @override
  String get captainA => 'First alliance\'s captain';

  @override
  String get captainB => 'Second alliance\'s captain';

  @override
  String allianceSize(int n) {
    return 'Coaches per alliance: $n';
  }

  @override
  String get firstRound => 'First round';

  @override
  String get goesOn => 'Goes on';

  @override
  String get noAlliance => 'No alliance tournament in this league';

  @override
  String get newGroup => 'New group';

  @override
  String get groupName => 'Group name';

  @override
  String get groupMembers => 'Usernames (comma separated)';

  @override
  String get joinGroup => 'Join by code';

  @override
  String get groupCode => 'Group code';

  @override
  String get openIt => 'Open';

  @override
  String get matchday => 'Match day';

  @override
  String get referee => 'Referee';

  @override
  String get moveMatch => 'Move the match';

  @override
  String moveLead(int n) {
    return 'On its own day, if the other coach agrees. $n left.';
  }

  @override
  String moveTo(String time) {
    return 'To $time';
  }

  @override
  String movePendingMine(String time) {
    return 'You asked to move it to $time; waiting for the answer';
  }

  @override
  String movePendingTheirs(String time) {
    return 'He asks to move it to $time';
  }

  @override
  String get moveSent => 'Your request went to the other coach';

  @override
  String hoursEarlier(int n) {
    return '${n}h earlier';
  }

  @override
  String hoursLater(int n) {
    return '${n}h later';
  }

  @override
  String get press => 'Press conference';

  @override
  String pressOpensAt(String time) {
    return 'Opens $time';
  }

  @override
  String chances(int home, int draw, int away) {
    return 'Chances: win $home% · draw $draw% · loss $away%';
  }

  @override
  String stakes(int win, int draw, int loss) {
    return 'Morale: win $win · draw $draw · loss $loss';
  }

  @override
  String get youSaid => 'You said';

  @override
  String get integrity => 'Behind the scenes';

  @override
  String bribe(String money, String extra) {
    return 'Pay the referee ($money + $extra)';
  }

  @override
  String bribeNote(int pct) {
    return 'The VAR catches it $pct% of the time';
  }

  @override
  String get bribePaid => 'You paid the referee';

  @override
  String securityCheck(String cost) {
    return 'Security check ($cost)';
  }

  @override
  String get spiesOnMe => 'Spies on your match';

  @override
  String get noSpies => 'No spies so far';

  @override
  String turnSpy(String cost) {
    return 'Turn him ($cost)';
  }

  @override
  String get accuse => 'Accuse';

  @override
  String get contracts => 'Contracts';

  @override
  String contractsLead(String wages, String cap) {
    return 'Wages $wages a round, cap $cap';
  }

  @override
  String untilSeason(int n) {
    return 'Until season $n';
  }

  @override
  String get renew => 'Renew';

  @override
  String renewSeasons(int n, String cost) {
    return 'Renew $n seasons ($cost)';
  }

  @override
  String releasePlayer(String cost) {
    return 'Release ($cost)';
  }

  @override
  String releaseConfirm(String name) {
    return 'Release $name? He leaves your team.';
  }

  @override
  String get renewEnding => 'Renew every ending contract';

  @override
  String get cheerTickets => 'Cheer tickets';

  @override
  String cheerLead(int boost, String price) {
    return 'Cheer a side in another match: +$boost to its spirit; a ticket costs $price.';
  }

  @override
  String get cheer => 'Cheer';

  @override
  String get matchChat => 'Chat';

  @override
  String get reactionSent => 'Reaction sent';

  @override
  String missedMatches(int n) {
    return 'You missed $n matches';
  }

  @override
  String get missedTitle => 'What you missed';

  @override
  String get markSeen => 'Mark all seen';

  @override
  String get squadChanges => 'Squad changes';

  @override
  String get injured => 'injured';

  @override
  String get sentOff => 'sent off';

  @override
  String unlockSlot(int coins) {
    return 'Open it now ($coins coins)';
  }

  @override
  String unlockConfirm(int n, int coins) {
    return 'Open slot $n now for $coins coins? It stays open for good.';
  }

  @override
  String starterGift(int coins) {
    return 'Starter gift: $coins coins';
  }

  @override
  String get claimGift => 'Claim it';

  @override
  String get ranking => 'Coaches\' ranking';

  @override
  String trophiesShort(int n) {
    return '$n titles';
  }

  @override
  String get holiday => 'Holiday';

  @override
  String get holidayLeague => 'Ask for a holiday in this league';

  @override
  String get holidayAccount => 'A long holiday for the whole account';

  @override
  String holidayDays(int n) {
    return 'Days: $n';
  }

  @override
  String get holidayReason => 'Reason';

  @override
  String get holidaySent => 'Holiday request sent';

  @override
  String get endHoliday => 'End the holiday';

  @override
  String vacationAsk(int days, String reason) {
    return 'Asks for $days days off: $reason';
  }

  @override
  String get kick => 'Remove';

  @override
  String get kickReason => 'Reason (everyone sees it)';

  @override
  String verifyAccount(int coins) {
    return 'Verify your account and get $coins coins';
  }

  @override
  String get sendCode => 'Send the code to my email';

  @override
  String get codeSent => 'Code sent';

  @override
  String get verifyCode => 'The code';

  @override
  String get verified => 'Your account is verified';

  @override
  String get resendEmail => 'Resend the email confirmation';

  @override
  String get deleteAccount => 'Delete my account';

  @override
  String get deleteAccountLead =>
      'Your teams go back to the computer, with no undo. Type «احذف» to confirm.';

  @override
  String get startLeague => 'Start the league now';

  @override
  String get changePhoto => 'Change the picture';

  @override
  String get removePhoto => 'Remove the picture';

  @override
  String get sendPhoto => 'Send a picture';

  @override
  String get leagueSettings => 'League settings';

  @override
  String get settingsLocked => 'Settings are locked since the league started';

  @override
  String get customTeams => 'Teams of your choice';

  @override
  String get searchClubs => 'Search a club';

  @override
  String get nationsTab => 'National teams';

  @override
  String get clubsTab => 'Clubs';

  @override
  String chosenTeams(int n) {
    return '$n teams chosen';
  }

  @override
  String get formatLeague => 'League';

  @override
  String get formatGroups => 'Groups';

  @override
  String get formatKnockout => 'Knockout';

  @override
  String groupsCount(int n) {
    return 'Groups: $n';
  }

  @override
  String swapPlayers(int n) {
    return 'Swap players (up to $n)';
  }

  @override
  String get swapGive => 'You give';

  @override
  String get swapTake => 'You take';

  @override
  String get recordVoice => 'Record a voice note';

  @override
  String get stopAndSend => 'Stop and send';

  @override
  String voiceNote(int n) {
    return 'Voice note ${n}s';
  }

  @override
  String get micDenied =>
      'Allow the app to use the microphone in the phone\'s settings';

  @override
  String get navClub => 'My club';

  @override
  String get navTeam => 'Team';

  @override
  String get navMatches => 'Matches';

  @override
  String get navMarket => 'Market';

  @override
  String get navMore => 'More';

  @override
  String get secPlayers => 'Players';

  @override
  String get secDevelop => 'Development';

  @override
  String get secDeals => 'Deals';

  @override
  String get secMoney => 'Money and stadium';

  @override
  String get secCompete => 'Competition';

  @override
  String get secCommunity => 'Community';

  @override
  String get secLeague => 'The league';

  @override
  String get subSquad => 'Players, fitness and cards';

  @override
  String get subLineup => 'The eleven and the bench';

  @override
  String get subTactics => 'Plan, pressing and style';

  @override
  String get subTraining => 'One player per line';

  @override
  String get subSpecialists => 'Faster training per line';

  @override
  String get subContracts => 'Renewals and releases';

  @override
  String get subMarket => 'Buy, sell, offers, academy';

  @override
  String get subScout => 'Five players to your terms';

  @override
  String get subFinance => 'Balance, sponsors, tickets';

  @override
  String get subStadium => 'Seats, pitch, training';

  @override
  String get subTickets => 'Cheer in other matches';

  @override
  String get subMatchday => 'Moving, press, behind the scenes';

  @override
  String get subFriendlies => 'A quick friendly with any club';

  @override
  String get subQuests => 'This week\'s rewards';

  @override
  String get subSpy => 'Reveal your next opponent';

  @override
  String get subNewspaper => 'The round\'s news and articles';

  @override
  String get subPredictions => 'Predict and win';

  @override
  String get subStats => 'Scorers and squad values';

  @override
  String get subGroups => 'The coaches\' chats';

  @override
  String get subHonours => 'Each season\'s champions';

  @override
  String get subAlliance => 'Two alliances of coaches';

  @override
  String get subTournaments => 'Tournaments with a live draw';

  @override
  String countdownIn(String time) {
    return 'In $time';
  }

  @override
  String get liveBadge => 'Live now';

  @override
  String get navOffice => 'Office';

  @override
  String get officeHello => 'The manager\'s office';

  @override
  String get strengthCompare => 'Team strength';

  @override
  String get needsYou => 'Needs you now';

  @override
  String get allClear => 'All set: get ready for the match';

  @override
  String get needWindow => 'Your match is open for orders';

  @override
  String get needLineup => 'Unavailable players in your lineup';

  @override
  String get needOffers => 'Offers waiting for you';

  @override
  String get needRequests => 'Requests to join the league';

  @override
  String get needTrainingEmpty => 'Lines with no training';

  @override
  String get needTrainingDone => 'Training finished: pick the next player';

  @override
  String tileSquadSub(int n) {
    return '$n players';
  }

  @override
  String get tileReady => 'Ready';

  @override
  String get tileAuto => 'Automatic';

  @override
  String get tileFixtures => 'Fixtures and results';

  @override
  String get colPos => 'Pos';

  @override
  String get colName => 'Player';

  @override
  String get colAge => 'Age';

  @override
  String get colOvr => 'Ovr';

  @override
  String get colPot => 'Pot';

  @override
  String get colFit => 'Fit';

  @override
  String get colValue => 'Value';

  @override
  String get filterAll => 'All';

  @override
  String get dragHint => 'Drag a player into place, or tap two to swap';

  @override
  String get leagueTable => 'Table';

  @override
  String get matchPrep => 'Match preparation';

  @override
  String get prepReady => 'Lineup ready';

  @override
  String get prepAuto => 'Automatic lineup';

  @override
  String get prepMissing => 'Players missing';

  @override
  String get quickFriendly => 'Quick friendly';

  @override
  String get quickFriendlySub => 'Play a friendly with the league\'s clubs';

  @override
  String get questsSub => 'Claim it';

  @override
  String get trainingSub => 'Develop your players';

  @override
  String get marketRenews => 'The list renews';

  @override
  String get homeAway => 'At home';

  @override
  String get awayGame => 'Away';

  @override
  String get coachFile => 'Manager profile';

  @override
  String get coachSlots => 'Manager slots';

  @override
  String get newLeagueShort => 'New league';

  @override
  String get statWon => 'Wins';

  @override
  String get statDrawn => 'Draws';

  @override
  String get statLost => 'Losses';

  @override
  String get statPoints => 'Points';

  @override
  String get shopTile => 'Shop';

  @override
  String get shopSub => 'Coins and offers';

  @override
  String get leaguePlace => 'League position';

  @override
  String get boardGoal => 'Board objective';

  @override
  String get teamRating => 'Team';

  @override
  String get bestRated => 'Top rated';

  @override
  String get starPlayer => 'Star';

  @override
  String get bestProspect => 'Prospect';

  @override
  String get lineGkShort => 'GK';

  @override
  String get lineDefShort => 'DEF';

  @override
  String get lineMidShort => 'MID';

  @override
  String get lineAttShort => 'ATT';

  @override
  String get groupAtt => 'Forwards';

  @override
  String get groupMid => 'Midfielders';

  @override
  String get groupDef => 'Defenders';

  @override
  String get groupGk => 'Goalkeepers';

  @override
  String get colNat => 'Nat.';

  @override
  String get colState => 'Status';

  @override
  String get benchPanel => 'The bench';

  @override
  String get improve => 'Improve';

  @override
  String get modeFitness => 'Fitness';

  @override
  String get modeAge => 'Age';

  @override
  String get modeValue => 'Value';

  @override
  String get shareLineup => 'Share';

  @override
  String get prepareTactics => 'Set your tactics for the next match';

  @override
  String get balancedWord => 'Balanced';

  @override
  String get positioning => 'Positioning';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get pointsWord => 'points';

  @override
  String get positionWord => 'Place';

  @override
  String slotN(int n) {
    return 'Slot $n';
  }

  @override
  String get simQuickTitle => 'A quick match in the simulator';

  @override
  String get simQuickLead => 'Against the computer or a friend';

  @override
  String get simPlay => 'Play';

  @override
  String get simTitle => 'Simulator';

  @override
  String get simLead => 'A trial match apart from your leagues';

  @override
  String get simFree => 'Free';

  @override
  String get simVsCpu => 'Vs the computer';

  @override
  String get simVsCpuLead => 'Start now and test your plan';

  @override
  String get simVsFriend => 'Vs a friend';

  @override
  String get simVsFriendLead => 'Invite them with a link, play live';

  @override
  String get simYourTeam => 'Your team';

  @override
  String get simOpponent => 'Opponent';

  @override
  String get simSearch => 'Search a club';

  @override
  String get simStart => 'Start the match';

  @override
  String get simOpenRoom => 'Open the room, invite a friend';

  @override
  String get simInvite => 'Send the invite';

  @override
  String simInviteText(String link) {
    return 'Take me on in a match on Game Legend Manager: $link';
  }

  @override
  String get simWaitingFriend => 'Waiting for your friend…';

  @override
  String get simComputer => 'The computer';

  @override
  String get simKickoff => 'Kick-off';

  @override
  String get simOff => 'The simulator is not switched on on the server yet';

  @override
  String simStrength(int n) {
    return 'Strength $n';
  }

  @override
  String get simRandom => 'A random opponent';

  @override
  String get simAttack => 'Attack';

  @override
  String get simMidfield => 'Midfield';

  @override
  String get simDefence => 'Defence';
}
