import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum PlayerState { stopped, playing, paused }

class PlayerWidget extends StatefulWidget {
  final String url;
  final bool isLocal;
  final PlayerMode mode;

  PlayerWidget ({
    @required this.url,
    this.isLocal = false,
    this.mode = PlayerMode.MEDIA_PLAYER
  });

  @override
  State<StatefulWidget> createState() {
    return new _PlayerWidgetState(url, isLocal, mode);
  }

}

class _PlayerWidgetState extends State<PlayerWidget>
{
  String url;
  bool isLocal;
  PlayerMode mode;

  AudioPlayer _audioPlayer;
  AudioPlayerState _audioPlayerState;
  Duration _duration;
  Duration _position;

  StreamSubscription _durationSubscription;
  StreamSubscription _positionSubscription;
  StreamSubscription _playerCompleteSubscription;
  StreamSubscription _playerErrorSubscription;
  StreamSubscription _playerStateSubscription;

  PlayerState _playerState = PlayerState.stopped;

  get _isPlaying => _playerState == PlayerState.playing;
  get _isPaused => _playerState == PlayerState.paused;
  get _durationText => _duration?.toString()?.split('.')?.first ?? '';
  get _positionText => _position?.toString()?.split('.')?.first ?? '';

  _PlayerWidgetState(this.url, this.isLocal, this.mode);

  @override
  void initState() {
    super.initState();
    AudioPlayer.logEnabled = true;
    _intAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerErrorSubscription?.cancel();
    _playerStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Column(
      children: <Widget>[
          new IconButton(
              icon: new Icon( Icons.play_arrow, color: Colors.pink, size: 30.0),
              onPressed: () => _play())
      ],
    );
  }

  void _intAudioPlayer() {
    _audioPlayer = AudioPlayer(mode: mode);

    _positionSubscription =
        _audioPlayer.onAudioPositionChanged.listen((p) => setState(() {
          print('audioPlayer position: $p');
          _position = p;
        }));

    _playerCompleteSubscription =
        _audioPlayer.onPlayerCompletion.listen((event) {
          print('audioPlayer onComplete');
          _onComplete();
          setState(() {
            _position = _duration;
          });
        });

    _playerErrorSubscription = _audioPlayer.onPlayerError.listen((msg) {
      print('audioPlayer error : $msg');
      setState(() {
        _playerState = PlayerState.stopped;
        _duration = Duration(seconds: 0);
        _position = Duration(seconds: 0);
      });
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      print('audioPlayer state changed: $state');
      if (!mounted) return;
      setState(() {
        _audioPlayerState = state;
      });
    });
  }

  void _onComplete() {
    setState(() => _playerState = PlayerState.stopped);
  }

  Future<int> _play() async {
    final playPosition = (_position != null &&
        _duration != null &&
        _position.inMilliseconds > 0 &&
        _position.inMilliseconds < _duration.inMilliseconds)
        ? _position
        : null;
    final result =
    await _audioPlayer.play(url, isLocal: isLocal, position: playPosition);
    if (result == 1) setState(() => _playerState = PlayerState.playing);
    return result;
  }
}

