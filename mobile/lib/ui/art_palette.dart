import 'package:flutter/painting.dart';

// [Sprint 60 F2] The colours the app draws with, by what they draw: no screen writes a `Color(0x…)` of its own
// (tool/design.dart). The screens' colours are the palette (context.palette, tokens.json); the match broadcast's own
// signals are GlmBroadcast; these are the pictures' colours (the people, the ball, the boards, the dials), as the
// site's drawings keep theirs in their own modules (web/src/match/feed/art.ts and clips/). Same values as before.

/// The broadcast's drawings: the people, the ball, the stadium, the clips' signs.
abstract final class GlmArt {
  /// Skin, light to dark (one per player by his id).
  static const skins = [Color(0xFFF2C6A0), Color(0xFFD9A37A), Color(0xFFB5794F), Color(0xFF7A4A2C)];

  /// Hair: dark brown, brown, black, fair.
  static const hairs = [Color(0xFF2A1B12), Color(0xFF5A3A1E), black, Color(0xFFB8862E)];
  static const skin = Color(0xFFD9A37A);

  /// The darkest ink: black shorts, the shirt numbers' dark ink, a referee in black.
  static const black = Color(0xFF111111);

  /// The eyes, the bursts' word.
  static const ink = Color(0xFF1A1A1A);
  static const mouth = Color(0xFF5A1414);
  static const boot = Color(0xFF1B1B1B);
  static const gloves = Color(0xFFF7F7F2);
  static const ballShade = Color(0xFFD7D7D7);
  static const ballPatch = Color(0xFF1C1C1C);
  static const boards = [Color(0xFF0E1B2B), Color(0xFF15304A), Color(0xFF0E1B2B)];

  /// The cartoon word bursts (BLOCK!, OUCH!, #@!).
  static const burst = Color(0xFFFF8A65);

  /// The weather: rain's shade, a splash's drops, the dust cloud and its core.
  static const rain = Color(0xFF203040);
  static const splash = Color(0xFFBFE3FF);
  static const water = Color(0xFF81D4FA);
  static const dust = Color(0xFFD9CDB5);
  static const dustCore = Color(0xFFE6DCC7);

  /// The cards in a referee's hand, and the VAR's «no goal».
  static const redCard = Color(0xFFE53935);
  static const yellowCard = Color(0xFFFFD600);

  /// The fourth official's LED board: its frame and its two numbers (off: the alarm red, also the offside line; on).
  static const ledBoard = Color(0xFF101010);
  static const alarm = Color(0xFFFF5252);
  static const ledIn = Color(0xFF69F0AE);

  /// The VAR's and the stats' panel over the pitch.
  static const panel = Color(0xFF0B1220);

  /// A keeper's kit in the corner clip, and the substitutes' bibs.
  static const keeperShirt = Color(0xFFF3F3F3);
  static const keeperShorts = Color(0xFF2E7D32);
  static const bib = Color(0xFF1E2A3A);
  static const boardFace = Color(0xFFE0E0E0);

  /// The flares in the stands: their glow and their core; the smoke.
  static const flare = Color(0xFFFF5722);
  static const flareCore = Color(0xFFFFF3E0);
  static const smoke = Color(0xFFFF6D00);

  /// The coaches on the touchline, by look (C1, C2, C3), and the tunnel.
  static const coachC1 = Color(0xFF15233A);
  static const coachC2 = Color(0xFF3A2A1A);
  static const coachC3 = Color(0xFF263238);
  static const coachBrown = Color(0xFF3E2723);
  static const tear = Color(0xFF4FC3F7);
  static const tunnel = Color(0xFF05080D);
  static const tunnelSky = Color(0xFF0A1628);
  static const studio = [Color(0xFF1E3550), Color(0xFF0B1A2C)];

  /// The other kits a keeper or a referee may wear, the one farthest from both teams' shirts.
  static const keeperKits = [Color(0xFF7CB342), Color(0xFFFF8F00), Color(0xFF8E24AA), Color(0xFF00ACC1)];
  static const refereeKits = [black, yellowCard, Color(0xFF00BFA5)];

  /// The away side's colour when its club has none.
  static const awayFallback = Color(0xFF2F6FDB);

  /// The floodlights' warm light (the opening and the face-off).
  static const floodlight = Color(0xFFFFF0C8);
  static const lamp = Color(0xFFFFF3D4);
  static const floodlightGlow = [Color(0x47FFF0C8), Color(0x00FFF0C8)];

  /// The stadium's earth under the grass, and its sky glow on the squad's pitch.
  static const earth = Color(0xFF6E431B);
  static const skyGlow = Color(0xFF55D6F2);
}

/// The squad's paper sheet and the lineup's cards: a light sheet over the night, as the approved drafts draw it.
abstract final class GlmSheet {
  static const paper = Color(0xFFEFF2F7);
  static const label = Color(0xFF8C96A8);
  static const ink = Color(0xFF14203A);
  static const soft = Color(0xFFA2ABBB);
  static const chip = Color(0xFFE3E7EE);
  static const bench = Color(0xFF9AA4B5);
  static const reserve = Color(0xFFD9DEE6);
  static const captainTrim = Color(0xFFF3B71F);

  /// A starter's green edge and his fitness bar.
  static const starter = Color(0xFF6BE04A);
  static const fit = Color(0xFF8BE04E);

  /// The sorted column, and a card's caption and glow.
  static const sortOn = Color(0xFFFFE36E);
  static const caption = Color(0xFFB9C7E3);
  static const glow = Color(0xFFFFE9B0);
}

/// The tactics' dials: their pictures (the pitch, the boot, the cards) and the lines' colours.
abstract final class GlmTacticsArt {
  static const title = Color(0xFF7FC4FF);
  static const gold = Color(0xFFFFE36E);
  static const goldDeep = Color(0xFFC08A0C);
  static const attack = Color(0xFFFF7A3D);
  static const mid = Color(0xFFFFB13D);
  static const press = Color(0xFFFF6A2B);
  static const zone = Color(0xFF4FA3FF);
  static const mine = Color(0xFF2B7ED3);
  static const theirs = Color(0xFFE53935);
  static const flag = Color(0xFFFF6D00);
  static const grass = [Color(0xFF2FA046), Color(0xFF1E7A34)];
  static const turf = Color(0xFF4CAF35);
  static const boot = Color(0xFF1B1B1B);
  static const studs = Color(0xFFCFD8E6);
  static const ball = Color(0xFF1C1C1C);
  static const earth = Color(0xFF6E431B);
}
