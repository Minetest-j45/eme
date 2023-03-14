import 'package:app_settings/app_settings.dart';
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
                    'Please allow camera access in your settings to scan the QR code containing the public key of the person you want to add to your contacts.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Manually paste the public key instead'),
                    onPressed: () {
                      _isDialogShowing = false;

                      setState(() {
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
                  ),
                  TextButton(
                    child: const Text('Open settings to allow camera access'),
                    onPressed: () {
                      AppSettings.openAppSettings();
                      _isDialogShowing = false;
                      //make it not display the dialog when they come back
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
