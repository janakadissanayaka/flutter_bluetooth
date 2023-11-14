import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:kt_session/bluetooth/communication_handler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:collection/collection.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SimpleLogger logger = SimpleLogger();
  CommunicationHandler? communicationHandler;
  bool isScanStarted = false;
  bool isConnected = false;
  List<DiscoveredDevice> discoveredDevices = List<DiscoveredDevice>.empty(growable: true);
  String connectedDeviceDetails = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("KT Session"),
        ),
        body: Column(
          children: [
            Center(
              child: TextButton(
                onPressed: () {
                  isScanStarted ? stopScan() : startScan();
                },
                child: Text(isScanStarted ? "Stop Scan" : "Start Scan"),
              ),
            ),
            SizedBox(
              height: 400,
              child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: discoveredDevices.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: const EdgeInsets.all(5),
                      child: Container(
                        height: 60,
                        color: Colors.greenAccent,
                        child: Center(
                            child: TextButton(
                          child: Text(discoveredDevices[index].name),
                          onPressed: () {
                            DiscoveredDevice selectedDevice = discoveredDevices[index];
                            connectToDevice(selectedDevice);
                          },
                        )),
                      ),
                    );
                  }),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(connectedDeviceDetails),
            )
          ],
        ));
  }

  @override
  void initState() {
    checkPermissions();
    super.initState();
  }

  void checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
      Permission.bluetoothAdvertise,
    ].request();

    logger.info("PermissionStatus -- $statuses");
  }

  void startScan() {
    communicationHandler ??= CommunicationHandler();
    communicationHandler?.startScan((scanDevice) {
      logger.info("Scan device: ${scanDevice.name}");
      if (discoveredDevices.firstWhereOrNull((val) => val.id == scanDevice.id) == null) {
        logger.info("Added new device to list: ${scanDevice.name}");
        setState(() {
          discoveredDevices.add(scanDevice);
        });
      }
    });

    setState(() {
      isScanStarted = true;
      discoveredDevices.clear();
    });
  }

  Future<void> stopScan() async {
    await communicationHandler?.stopScan();
    setState(() {
      isScanStarted = false;
    });
  }

  Future<void> connectToDevice(DiscoveredDevice selectedDevice) async {
    await stopScan();
    communicationHandler?.connectToDevice(selectedDevice, (isConnected) {
      this.isConnected = isConnected;
      if (isConnected) {
        connectedDeviceDetails = "Connected Device Details\n\n$selectedDevice";
      } else {
        connectedDeviceDetails = "";
      }
      setState(() {
        connectedDeviceDetails;
      });
    });
  }
}
