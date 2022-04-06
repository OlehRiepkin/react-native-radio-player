import { NativeModules, NativeEventEmitter } from 'react-native';

type RadioPlayerType = {
  radioURL(url: string): Promise<void>;
  radioURLWithMetadataSeparator(url: string, metadataSeparator: string): Promise<void>;
  play(): Promise<void>;
  stop(): Promise<void>;
  setVolume(volume: number): Promise<void>;
};

export type RadioPlayerMetadata = {
  artistName: string;
  trackName: string;
};

const { RadioPlayer } = NativeModules;
const RadioPlayerEvents = new NativeEventEmitter(NativeModules.RadioPlayer);

export default RadioPlayer as RadioPlayerType;
export { RadioPlayerEvents };
