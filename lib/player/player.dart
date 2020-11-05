import 'package:flutter_radio_player/flutter_radio_player.dart';

const kUrl = "https://radio.criminaltribe.com:8443/radio_stream";

enum PlayerState { playing, loading, paused, stoped }

class Player {
  FlutterRadioPlayer _player;

  Player() {
    _player = new FlutterRadioPlayer();
  }

  get playerStateStream => _player.isPlayingStream;

  get trackStream =>
      _player.metaDataStream.map((event) => _formatMetaData(event));

  Future<bool> playOrPause(PlayerState playerState) {
    return playerState == PlayerState.stoped
        ? playerInit().then((value) => _player.play())
        : _player.playOrPause();
  }

  Future<void> playerInit() {
    return _player.init("Criminal Tribe App", "Radio", kUrl, "false");
  }

  Future<bool> stop() {
    return _player.stop();
  }

  String _formatMetaData(String metadata) {
    RegExp exp = new RegExp(r'(?<=title=")(.*)(?=", url)',
        multiLine: false, caseSensitive: false);
    RegExpMatch match = exp.firstMatch(metadata);
    return match?.group(0) ?? "";
  }
}
