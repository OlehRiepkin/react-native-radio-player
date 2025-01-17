import FRadioPlayer

@objc(RadioPlayer)
class RadioPlayer: RCTEventEmitter, FRadioPlayerDelegate {

    var hasListeners: Bool = false;
    let player: FRadioPlayer
    var radioURL: URL?
    
    var playerState: FRadioPlayerState = .urlNotSet;
    var playbackState: FRadioPlaybackState = .stopped;
    var state: PlayerState = .stopped;
    
    var metadataSeparator: String = "-"
        
    enum PlayerState: String {
        case error = "error"
        case stopped = "stopped"
        case playing = "playing"
        case paused = "paused"
        case buffering = "buffering"
    }

    override init() {
        player = FRadioPlayer.shared
        super.init()
                
        player.isAutoPlay = true
        player.enableArtwork = false
        player.delegate = self
    }

    @objc
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    /// Base overide for RCTEventEmitter.
    ///
    /// - Returns: all supported events
    override func supportedEvents() -> [String] {
        return [
            "StateDidChange",
            "MetadataDidChange"
        ]
    }
    
    // Will be called when this module's first listener is added.
    override func startObserving() {
        hasListeners = true;
        // Set up any upstream listeners or background tasks as necessary
    }

    // Will be called when this module's last listener is removed, or on dealloc.
    override func stopObserving() {
        hasListeners = false;
        // Remove upstream listeners, stop unnecessary background tasks
    }
    
    @objc(radioURL:withResolver:withRejecter:)
    func radioURL(url: String, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        radioURL = URL(string: url)
        resolve(1)
    }
    
    @objc(radioURLWithMetadataSeparator:metadataSeparator:withResolver:withRejecter:)
    func radioURL(url: String, withMetadataSeparator: String, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        self.metadataSeparator = withMetadataSeparator
        radioURL = URL(string: url)
        resolve(1)
    }
    
    @objc(play:withRejecter:)
    func play(resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        if (radioURL == nil) {
            print("radioURL not set")
            return
        }
        player.radioURL = radioURL
        resolve(1)
    }
    
    @objc(stop:withRejecter:)
    func stop(resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        player.stop()
        resolve(1)
    }
  
    @objc(setVolume:withResolver:withRejecter:)
    func setVolume(volume: NSNumber, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        player.volume = volume.floatValue
        resolve(1)
    }
    
    func computeAndSendStateEvent() {
        let previousState = self.state
        
        if (self.playerState == .error) {
            self.state = .error
        }
        if (self.playerState == .urlNotSet) {
            self.state = .error
        }
        if (self.playerState == .loading) {
            self.state = .buffering
        }
        if (self.playbackState == .playing && self.playerState == .loadingFinished) {
            self.state = .playing
        }
        if (self.playbackState == .paused && self.playerState == .readyToPlay) {
            self.state = .paused
        }
        if (self.playbackState == .stopped && self.playerState == .loadingFinished) {
            self.state = .stopped
        }
        
        print("\(self.playbackState.description) + \(self.playerState.description) = \(self.state)")
        if self.state == previousState {
            print("Same state as previously. Skipping sending event")
            return
        }
        if (hasListeners) {
            print("Sending \"\(self.state)\" event...")
            let eventBody = ["state": self.state.rawValue]
            sendEvent(withName: "StateDidChange", body: eventBody)
        }
    }
    
    func radioPlayer(_ player: FRadioPlayer, playerStateDidChange state: FRadioPlayerState) {
        self.playerState = state
        computeAndSendStateEvent();
    }
    
    func radioPlayer(_ player: FRadioPlayer, playbackStateDidChange state: FRadioPlaybackState) {
        self.playbackState = state;
        computeAndSendStateEvent();
    }
    
    func radioPlayer(_ player: FRadioPlayer, metadataDidChange rawValue: String?) {
        if (hasListeners) {
            let parts = rawValue?.components(separatedBy: self.metadataSeparator)
            var artistName: String? = nil
            var trackName: String? = rawValue
            if (parts != nil && parts!.count >= 2) {
                artistName = parts?[0].trimmingCharacters(in: .whitespacesAndNewlines)
                trackName = parts?[1].trimmingCharacters(in: .whitespacesAndNewlines)
            }
            sendEvent(withName: "MetadataDidChange", body: ["artistName": artistName, "trackName": trackName])
        }
    }
}
