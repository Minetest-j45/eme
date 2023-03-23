import 'package:adler32/adler32.dart';
import 'package:app_settings/app_settings.dart';
import 'package:clipboard/clipboard.dart';
import 'package:eme/home.dart';
import 'package:eme/identities.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'contacts.dart';

class QrDisplayPage extends StatefulWidget {
  const QrDisplayPage(
      {super.key,
      required this.name,
      required this.linkedIdentity,
      required this.toggleIndex});

  final String name;
  final String linkedIdentity;
  final int toggleIndex;

  @override
  State<QrDisplayPage> createState() => _QrDisplayPageState();
}

class _QrDisplayPageState extends State<QrDisplayPage> {
  String _identityPub = '';

  void _getIdentites() async {
    var id = await Identities().get(widget.linkedIdentity);
    _identityPub = id!.pub;
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
              'Scan (or copy and send) the following:',
            ),
            QrImage(
              data: _identityPub,
              version: QrVersions.auto,
              size: MediaQuery.of(context).size.width,
            ),
            Text(Adler32.str(_identityPub).toString()),
            ElevatedButton(
                onPressed: () {
                  FlutterClipboard.copy(_identityPub);
                },
                child: Icon(Icons.copy)),
            TextButton(
              child: const Text('Next'),
              onPressed: () {
                if (widget.toggleIndex == 0) {
                  //they scanned first, so are finished
                  setState(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(
                          currIdentity: widget.linkedIdentity,
                        ),
                      ),
                    );
                  });
                } else if (widget.toggleIndex == 1) {
                  //they displayed first, so they have to scan now
                  setState(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QRScanPage(
                            name: widget.name,
                            linkedIdentity: widget.linkedIdentity,
                            toggleIndex: widget.toggleIndex),
                      ),
                    );
                  });
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
  const QRScanPage(
      {super.key,
      required this.name,
      required this.linkedIdentity,
      required this.toggleIndex});

  final String name;
  final String linkedIdentity;
  final int toggleIndex;

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
              child: Row(
                children: <Widget>[
                  ElevatedButton(
                      onPressed: () async {
                        await controller?.flipCamera();
                        setState(() {});
                      },
                      child: const Text('Flip camera')),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.05,
                  ),
                  ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ManualAddPage(
                                    name: widget.name,
                                    linkedIdentity: widget.linkedIdentity,
                                    toggleIndex: widget.toggleIndex)),
                          );
                        });
                      },
                      child: const Text('Paste instead')),
                ],
              ),
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
        //todo: checksum checking (on new confirmation page)
        Contacts().add(Contact(
            name: widget.name,
            pub: result!.code.toString(),
            linkedIdentity: widget.linkedIdentity));
        if (widget.toggleIndex == 0) {
          //they scanned first, so have to display now
          setState(() {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QrDisplayPage(
                    name: widget.name,
                    linkedIdentity: widget.linkedIdentity,
                    toggleIndex: widget.toggleIndex),
              ),
            );
          });
        } else if (widget.toggleIndex == 1) {
          //they displayed first, so are finished
          setState(() {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(
                  currIdentity: widget.linkedIdentity, //or empty string
                ),
              ),
            );
          });
        }
      });
    });
  }

  bool manual = false;
  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p && !manual) {
      manual = true;
      setState(() {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ManualAddPage(
                  name: widget.name,
                  linkedIdentity: widget.linkedIdentity,
                  toggleIndex: widget.toggleIndex)),
        );
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
  const ManualAddPage(
      {super.key,
      required this.name,
      required this.linkedIdentity,
      required this.toggleIndex});

  final String name;
  final String linkedIdentity;
  final int toggleIndex;

  @override
  State<StatefulWidget> createState() => _ManualAddPageState();
}

class _ManualAddPageState extends State<ManualAddPage> {
  final _pubController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("EME"),
      ),
      body: Center(
          child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(children: <Widget>[
          TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.purple),
                foregroundColor: MaterialStateProperty.all(Colors.white),
              ),
              onPressed: () => AppSettings.openAppSettings(),
              child: const Text(
                  "Go to settings and enable camera permissions to allow for QR code scanning")),
          TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.purple),
                foregroundColor: MaterialStateProperty.all(Colors.white),
              ),
              onPressed: () => setState(() {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => QRScanPage(
                              name: widget.name,
                              linkedIdentity: widget.linkedIdentity,
                              toggleIndex: widget.toggleIndex)),
                    );
                  }),
              child: const Text("Try scanning QR codes again")),
          TextFormField(
            controller: _pubController,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Paste the public key here',
            ),
          ),
          TextButton(
            child: const Text('Next'),
            onPressed: () {
              Contacts().add(Contact(
                  name: widget.name,
                  pub: _pubController.text,
                  linkedIdentity: widget.linkedIdentity));

              if (widget.toggleIndex == 0) {
                //they scanned first, so have to display now
                setState(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QrDisplayPage(
                          name: widget.name,
                          linkedIdentity: widget.linkedIdentity,
                          toggleIndex: widget.toggleIndex),
                    ),
                  );
                });
              } else if (widget.toggleIndex == 1) {
                //they displayed first, so are finished
                setState(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomePage(
                        currIdentity: widget.linkedIdentity,
                      ),
                    ),
                  );
                });
              }
            },
          )
        ]),
      )),
    );
  }
}
