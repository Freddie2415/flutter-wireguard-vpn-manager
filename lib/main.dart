import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WireGuard Flutter App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(title: 'WireGuard Flutter App'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isConnected = false;
  VPNStatus? status;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton(
              onPressed: connect,
              child: const Text("Connect"),
            ),
            ElevatedButton(
              onPressed: disconnect,
              child: const Text("Disconnect"),
            ),
            ElevatedButton(
              onPressed: checkStatus,
              child: Text("${status ?? "Check VPN Status"}"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> connect() async {
    await WireGuardVPNManager.connect(
      serverAddress: "85.192.63.233:51820",
      wgQuickConfig: """
            [Interface]
            PrivateKey = 0LQ0FnQ1WcxSKDDvdoKOkmjwQOnpzHORw7H1VDp/+XQ=
            Address = 10.66.66.134/32
            DNS = 8.8.8.8,8.8.4.4

            [Peer]
            PublicKey = NymTNQkcPDotMLu4b+Sf/OOcGnQYb8nTfQQaQ02T3WM=
            PresharedKey = zxPN2FiKzYfd+ZwDKnva5Soh9+81fV03Q5rfk1BZQss=
            AllowedIPs = 0.0.0.0/0
            Endpoint = 85.192.63.233:51820
            PersistentKeepalive = 16
            """,
    );
  }

  Future<void> disconnect() async {
    await WireGuardVPNManager.disconnect();
  }

  Future<void> checkStatus() async {
    status = await WireGuardVPNManager.getStatus();
    setState(() {});
  }
}

class WireGuardVPNManager {
  static const MethodChannel _channel =
      MethodChannel('net.caspians.app/wireguard');

  static Future<bool> connect({
    required String serverAddress,
    required String wgQuickConfig,
  }) async {
    try {
      final bool result = await _channel.invokeMethod('connect', {
        'serverAddress': serverAddress,
        'wgQuickConfig': wgQuickConfig,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error: ${e.message}');
      return Future.error('Error: ${e.message}');
    }
  }

  static Future<bool> disconnect() async {
    try {
      final bool result = await _channel.invokeMethod('disconnect');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error: ${e.message}');
      return Future.error('Error: ${e.message}');
    }
  }

  static Future<VPNStatus> getStatus() async {
    try {
      final int statusCode = await _channel.invokeMethod('getStatus');
      return VPNStatus.fromInt(statusCode);
    } on PlatformException catch (e) {
      print('Error: ${e.message}');
      return Future.error('Error: ${e.message}');
    }
  }
}

enum VPNStatus {
  /// @const NEVPNStatusInvalid The VPN is not configured.
  invalid,

  /// @const NEVPNStatusDisconnected The VPN is disconnected.
  disconnected,

  /// @const NEVPNStatusConnecting The VPN is connecting.
  connecting,

  /// @const NEVPNStatusConnected The VPN is connected.
  connected,

  /// @const NEVPNStatusReasserting The VPN is reconnecting following loss of underlying network connectivity.
  reasserting,

  /// @const NEVPNStatusDisconnecting The VPN is disconnecting.
  disconnecting;

  static VPNStatus fromInt(int index) {
    return switch (index) {
      0 => invalid,
      1 => disconnected,
      2 => connecting,
      3 => connected,
      4 => reasserting,
      5 => disconnecting,
      _ => invalid,
    };
  }
}
