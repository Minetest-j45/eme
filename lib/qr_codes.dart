import 'package:app_settings/app_settings.dart';
import 'package:eme/identities.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'contacts.dart';

class QrDisplayPage extends StatefulWidget {
  const QrDisplayPage(
      {super.key,
      required this.pub,
      required this.name,
      required this.linkedIdentity,
      required this.toggleIndex});

  final String name;
  final String pub;
  final String linkedIdentity;
  final int toggleIndex;

  @override
  State<QrDisplayPage> createState() => _QrDisplayPageState();
}

class _QrDisplayPageState extends State<QrDisplayPage> {
  String _identityPub = '';

  Future<void> _getIdentites() async {
    var idList = await Identities().read();
    for (var id in idList) {
      if (id.name == widget.linkedIdentity) {
        _identityPub = id.pub;
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _getIdentites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("EME"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Scan the following:',
            ),
            QrImage(
              data: _identityPub,
              version: QrVersions.auto,
              size: MediaQuery.of(context).size.width,
            ),
            TextButton(
              child: const Text('Back'),
              onPressed: () {
                setState(() {
                  Navigator.pop(context);
                });
              },
            ),
            TextButton(
              child: const Text('Next'),
              onPressed: () {
                if (widget.toggleIndex == 0) {
                  //they scanned first, so are finished
                } else if (widget.toggleIndex == 1) {
                  //they displayed first, so they have to scan now
                  Contacts().add(Contact(
                      name: widget.name,
                      pub: widget.pub,
                      linkedIdentity: widget.linkedIdentity));
                  //todo: go to home page
                }
              },
            )
          ],
        ),
      ),
    );
  }
}

class QRScanPage extends StatefulWidget {
  const QRScanPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool _isDialogShowing = false;

  @override
  void reassemble() {
    super.reassemble();
    controller!.pauseCamera();
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 10, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: ElevatedButton(
                  onPressed: () async {
                    await controller?.flipCamera();
                    setState(() {});
                  },
                  child: const Text('Flip camera')),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = MediaQuery.of(context).size.width * 0.8;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.purple,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        print(result!.code);
      });
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      if (_isDialogShowing) {
        return;
      }
      _isDialogShowing = true;

      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Camera permission required'),
                content: const Text(
                    'Please allow camera access in your settings to scan QR codes.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Open settings'),
                    onPressed: () {
                      _isDialogShowing = false;
                      AppSettings.openAppSettings();
                      Navigator.of(context).pop();
                    },
                  )
                ],
              ));
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
