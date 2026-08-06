/// User choice when uploading on mobile data (Ask Every Time policy).
enum CellularUploadChoice {
  wifiOnly,
  mobileData,
  later,
}

/// Bridges upload policy to UI for per-upload cellular data prompts.
///
/// Registered on the overtime screen; no-op when unregistered (queues upload).
class OvertimeCellularUploadPromptService {
  Future<CellularUploadChoice> Function()? _handler;

  void register(Future<CellularUploadChoice> Function() handler) {
    _handler = handler;
  }

  void unregister() {
    _handler = null;
  }

  Future<CellularUploadChoice> prompt() async {
    final handler = _handler;
    if (handler == null) {
      return CellularUploadChoice.later;
    }
    return handler();
  }
}
