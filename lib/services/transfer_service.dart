import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class TransferRequest {
  final String filename;
  final int size;
  final Socket socket;
  final List<int> initialData;
  TransferRequest(this.filename, this.size, this.socket, this.initialData);
}

class TransferService {
  SecureServerSocket? _serverSocket;
  ServerSocket? _basicServerSocket;
  final int port = 45678;
  SecurityContext? _securityContext;

  Future<void> _initSecurityContext() async {
    _securityContext = SecurityContext();
  }

  Future<void> startServer(Function(TransferRequest) onReceiveRequest) async {
    await _initSecurityContext();
    try {
      try {
        _serverSocket = await SecureServerSocket.bind(
          InternetAddress.anyIPv4,
          port,
          _securityContext!,
        );
        _serverSocket!.listen((SecureSocket socket) {
          _handleConnection(socket, onReceiveRequest);
        });
      } catch (e) {
        print('Secure socket failed, falling back to basic socket for now: $e');
        _basicServerSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
        _basicServerSocket!.listen((Socket socket) {
          _handleConnection(socket, onReceiveRequest);
        });
      }
      print('Transfer server listening on port $port');
    } catch (e) {
      print('Failed to start server: $e');
    }
  }

  Future<void> stopServer() async {
    if (_serverSocket != null) {
      await _serverSocket!.close();
      _serverSocket = null;
    }
    if (_basicServerSocket != null) {
      await _basicServerSocket!.close();
      _basicServerSocket = null;
    }
  }

  void _handleConnection(Socket socket, Function(TransferRequest) onReceiveRequest) async {
    print('Connection from ${socket.remoteAddress.address}:${socket.remotePort}');

    List<int> buffer = [];
    bool headerParsed = false;
    StreamSubscription<Uint8List>? subscription;

    subscription = socket.listen((data) {
      if (!headerParsed) {
         buffer.addAll(data);
         int nlIndex = buffer.indexOf(10); // \n
         if (nlIndex != -1) {
            String headerStr = utf8.decode(buffer.sublist(0, nlIndex));
            try {
               var header = jsonDecode(headerStr);
               headerParsed = true;

               List<int> remainder = buffer.sublist(nlIndex + 1);
               subscription?.pause();

               TransferRequest req = TransferRequest(
                 header['filename'] ?? 'unknown',
                 header['size'] ?? 0,
                 socket,
                 remainder
               );
               onReceiveRequest(req);

            } catch(e) {
               socket.close();
               print('Invalid header: $e');
            }
         }
      }
    }, onDone: () {
      print('Connection closed.');
    }, onError: (e) {
      print('Connection error: $e');
    });
  }

  Future<void> acceptTransfer(TransferRequest req, String destinationPath) async {
     File file = File(destinationPath);
     IOSink sink = file.openWrite();
     if (req.initialData.isNotEmpty) {
        sink.add(req.initialData);
     }

     req.socket.listen((data) {
        sink.add(data);
     }, onDone: () async {
        await sink.close();
        req.socket.close();
        print('File saved to $destinationPath');
     }, onError: (e) {
        sink.close();
        req.socket.close();
     });
  }

  void declineTransfer(TransferRequest req) {
     req.socket.close();
  }

  Future<void> sendFile(String ip, int targetPort, File file) async {
    try {
      Socket socket;
      try {
         socket = await SecureSocket.connect(ip, targetPort, onBadCertificate: (cert) => true);
      } catch (e) {
         socket = await Socket.connect(ip, targetPort);
      }
      print('Connected to $ip:$targetPort');

      String header = jsonEncode({
        'filename': file.path.split('/').last,
        'size': await file.length()
      }) + '\n';

      socket.add(utf8.encode(header));
      await file.openRead().pipe(socket);
      print('File sent');

      socket.close();
    } catch (e) {
      print('Failed to send file: $e');
    }
  }
}
