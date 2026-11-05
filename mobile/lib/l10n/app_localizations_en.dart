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
}
