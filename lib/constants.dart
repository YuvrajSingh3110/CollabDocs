import 'package:flutter_dotenv/flutter_dotenv.dart';

final host = 'http://${dotenv.env['IP_ADDRESS']}:3001';