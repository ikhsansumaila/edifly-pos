import 'package:http/http.dart' as http;
import 'package:requests_inspector/requests_inspector.dart';

class InspectorHttpClient {
  static final http.Client _client = http.Client();

  static Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) async {
    final response = await _client.post(url, headers: headers, body: body);

    InspectorController().addNewRequest(
      RequestDetails(
        requestName: url.path,
        requestMethod: RequestMethod.POST,
        url: url.toString(),
        headers: headers,
        requestBody: body,
        responseBody: response.body,
        statusCode: response.statusCode,
      ),
    );

    return response;
  }

  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final response = await _client.get(url, headers: headers);

    InspectorController().addNewRequest(
      RequestDetails(
        requestName: url.path,
        requestMethod: RequestMethod.GET,
        url: url.toString(),
        headers: headers,
        responseBody: response.body,
        statusCode: response.statusCode,
      ),
    );

    return response;
  }
}
