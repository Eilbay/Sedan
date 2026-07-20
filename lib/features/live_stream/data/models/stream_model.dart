// class StreamModel {
//   final String id;
//   final bool isLive;
//   final String status;
//   final String streamKey;
//   final String hlsUrl;
//   final String webrtcApiUrl;
//   final String webrtcApp;
//   final String webrtcStream;
//   final String webrtcUrl;

//   StreamModel({
//     required this.id,
//     required this.isLive,
//     required this.status,
//     required this.streamKey,
//     required this.hlsUrl,
//     required this.webrtcApiUrl,
//     required this.webrtcApp,
//     required this.webrtcStream,
//     required this.webrtcUrl,
//   });

//   factory StreamModel.fromJson(Map<String, dynamic> json) {
//     final webrtc = (json['webrtc'] as Map?)?.cast<String, dynamic>() ?? {};
//     return StreamModel(
//       id: (json['id'] ?? '').toString(),
//       isLive: json['is_live'] == true,
//       status: (json['status'] ?? '').toString(),
//       streamKey: (json['stream_key'] ?? '').toString(),
//       hlsUrl: (json['hls_url'] ?? '').toString(),
//       webrtcApiUrl: (webrtc['api_url'] ?? '').toString(),
//       webrtcApp: (webrtc['app'] ?? '').toString(),
//       webrtcStream: (webrtc['stream'] ?? '').toString(),
//       webrtcUrl: (webrtc['url'] ?? '').toString(),
//     );
//   }
// }
