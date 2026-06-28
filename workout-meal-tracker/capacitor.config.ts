import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.nyelbangash.gymbro',
  appName: 'Gym Bro',
  webDir: 'build',
  // Bundled mode: WKWebView loads from ios/App/App/public.
  // To switch to live-reload (Mac's React dev server), uncomment the `server`
  // block below and run `npm start` separately while iterating.
  // server: {
  //   url: 'http://Nyels-MacBook-Pro.local:3001',
  //   cleartext: true,
  // },
  ios: {
    // Smooth status-bar handling: we set color via theme so the bar matches.
    contentInset: 'always',
    // Allow plaintext HTTP to the backend on the LAN. We're in dev; production
    // would point at HTTPS and this should be removed.
    allowsLinkPreview: false,
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 600,
      backgroundColor: '#F4EFE6', // paper theme bg
      androidScaleType: 'CENTER_CROP',
      showSpinner: false,
    },
    StatusBar: {
      // We'll control style at runtime to match the active theme.
      overlaysWebView: false,
    },
  },
};

export default config;
