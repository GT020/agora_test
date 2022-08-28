import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as rtx_local_view;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as rtc_remote_view;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

const appId = "62af337194f042a6807daf50e5e05ec9";
const token =
    "007eJxTYPg9W9O/oiVbMTFNd99Ogzl6nlPcFk49uu967/lPZfeUTtQoMJgZJaYZG5sbWpqkGZgYJZpZGJinJKaZGqSaphqYpiZbxl7iSn6szJO8qqiSiZEBAkF8HoaS1OKS+OSMxLy81BwGBgCzhCSt";
const channel = "test_channel";

final rtcEngineProvider = FutureProvider<RtcEngine>((ref) async {
  await [Permission.microphone, Permission.camera].request();
  final engine = await RtcEngine.create(appId);
  engine.enableVideo();
  engine.setEventHandler(
    RtcEngineEventHandler(
      joinChannelSuccess: (channel, uid, elapsed) => {
        ref.read(userJoinedProvider.notifier).update((state) => true),
      },
      userJoined: (uid, elapsed) {
        ref.read(remoteUserIdProvider.notifier).update((state) => uid);
      },
      userOffline: (uid, reason) {
        ref.read(remoteUserIdProvider.notifier).update((state) => null);
      },
    ),
  );
  engine.joinChannel(token, channel, null, 0);
  return engine;
});

final remoteUserIdProvider = StateProvider<int?>((ref) {
  ref.read(rtcEngineProvider);
  return null;
});

final userJoinedProvider = StateProvider<bool>((ref) {
  return false;
});

void main() {
  runApp(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(appBar: AppBar(), body: const AgoraAssignment()),
      ),
    ),
  );
}

class AgoraAssignment extends ConsumerWidget {
  const AgoraAssignment({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRtcEngine = ref.watch(rtcEngineProvider);
    return asyncRtcEngine.when(
        data: (data) {
          return VideoChatView(
            engine: data,
          );
        },
        error: (error, stackTrace) {
          return Text(error.toString());
        },
        loading: () => const LinearProgressIndicator());
  }
}

class VideoChatView extends ConsumerWidget {
  final RtcEngine engine;
  const VideoChatView({
    super.key,
    required this.engine,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remoteUserID = ref.watch(remoteUserIdProvider);
    final isUserJoined = ref.watch(userJoinedProvider);

    return Stack(
      children: [
        Center(child: RemoteVideoWidget(remoteUid: remoteUserID)),
        Container(
          width: 100,
          height: 150,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: LocalVideoWidget(localUserJoined: isUserJoined),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Wrap(
            children: [
              MaterialButton(
                onPressed: () async {
                  await engine.switchCamera();
                },
                child: const Icon(Icons.cameraswitch_outlined),
              ),
              MaterialButton(
                onPressed: () async {
                  await engine.muteLocalVideoStream(true);
                },
                child: const Icon(Icons.tv_off),
              ),
              MaterialButton(
                onPressed: () async {
                  await engine.muteLocalVideoStream(false);
                },
                child: const Icon(Icons.tv_outlined),
              ),
              MaterialButton(
                onPressed: () async {
                  await engine.muteLocalAudioStream(true);
                },
                child: const Icon(Icons.mic_off),
              ),
              MaterialButton(
                onPressed: () async {
                  await engine.muteLocalAudioStream(false);
                },
                child: const Icon(Icons.mic),
              ),
            ],
          ),
        )
      ],
    );
  }
}

class RemoteVideoWidget extends StatelessWidget {
  final int? remoteUid;
  const RemoteVideoWidget({super.key, required this.remoteUid});

  @override
  Widget build(BuildContext context) {
    return remoteUid == null
        ? const Text(
            'User not Joined',
            textAlign: TextAlign.center,
          )
        : rtc_remote_view.SurfaceView(
            uid: remoteUid!,
            channelId: channel,
          );
  }
}

class LocalVideoWidget extends StatelessWidget {
  final bool localUserJoined;
  const LocalVideoWidget({super.key, required this.localUserJoined});

  @override
  Widget build(BuildContext context) {
    return localUserJoined
        ? const rtx_local_view.SurfaceView()
        : const CircularProgressIndicator();
  }
}
