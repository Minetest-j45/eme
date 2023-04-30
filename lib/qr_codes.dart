import 'package:app_settings/app_settings.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'colours.dart';
import 'newcontact.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({
    super.key,
    required this.name,
    required this.linkedIdentity,
  });

  final String name;
  final String linkedIdentity;

  @override
  State<StatefulWidget> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void reassemble() {
    super.reassemble();
    controller!.pauseCamera();
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: Colours.theme,
      home: Scaffold(
        body: Column(
          children: <Widget>[
            Expanded(flex: 10, child: _buildQrView(context)),
            Expanded(
              flex: 1,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Row(
                  children: <Widget>[
                    ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colours.slateGray)),
                        onPressed: () async {
                          await controller?.flipCamera();
                          setState(() {});
                        },
                        child: const Text('Flip camera',
                            style: TextStyle(color: Colours.mintCream))),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.05,
                    ),
                    ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colours.slateGray)),
                        onPressed: () async {
                          setState(() {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ManualAddPage(
                                        name: widget.name,
                                        linkedIdentity: widget.linkedIdentity,
                                      )),
                            );
                          });
                        },
                        child: const Text('Paste instead',
                            style: TextStyle(color: Colours.mintCream))),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = MediaQuery.of(context).size.width * 0.8;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colours.raisinBlack,
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
        setState(() {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmContactPage(
                name: widget.name,
                linkedIdentity: widget.linkedIdentity,
                theirPub: result!.code.toString(),
              ),
            ),
          );
        });
      });
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      setState(() {
        Navigator.pop(context);
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ManualAddPage(
                name: widget.name,
                linkedIdentity: widget.linkedIdentity,
              ),
            ));
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

class ManualAddPage extends StatefulWidget {
  const ManualAddPage({
    super.key,
    required this.name,
    required this.linkedIdentity,
  });

  final String name;
  final String linkedIdentity;

  @override
  State<StatefulWidget> createState() => _ManualAddPageState();
}

class _ManualAddPageState extends State<ManualAddPage> {
  final _pubController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: Colours.theme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("EME"),
        ),
        body: Center(
            child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(children: <Widget>[
            TextButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colours.slateGray),
                  foregroundColor: MaterialStateProperty.all(Colours.mintCream),
                ),
                onPressed: () => AppSettings.openAppSettings(),
                child: const Text(
                    "Go to settings and enable camera permissions to allow for QR code scanning")),
            TextButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colours.slateGray),
                  foregroundColor: MaterialStateProperty.all(Colours.mintCream),
                ),
                onPressed: () => setState(() {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => QRScanPage(
                                  name: widget.name,
                                  linkedIdentity: widget.linkedIdentity,
                                )),
                      );
                    }),
                child: const Text("Try scanning QR codes again")),
            TextFormField(
              controller: _pubController,
              maxLines: null,
              decoration: InputDecoration(
                  filled: true,
                  fillColor: Colours.jet,
                  border: const OutlineInputBorder(),
                  hintText: 'Paste the public key here',
                  hintStyle: const TextStyle(
                      color: Colours.mintCream, overflow: TextOverflow.visible),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.paste,
                      color: Colours.slateGray,
                    ),
                    onPressed: () {
                      FlutterClipboard.paste().then((value) => setState(() {
                            _pubController.text = value;
                          }));
                    },
                  )),
            ),
            TextButton(
              style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all(Colours.slateGray)),
              child: const Text(
                'Next',
                style: TextStyle(color: Colours.mintCream),
              ),
              onPressed: () {
                setState(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConfirmContactPage(
                        name: widget.name,
                        linkedIdentity: widget.linkedIdentity,
                        theirPub: _pubController.text,
                      ),
                    ),
                  );
                });
              },
            )
          ]),
        )),
      ),
    );
  }
}
