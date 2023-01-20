import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:scoreboard/src/models/kriti_models/kriti_event_model.dart';
import '../functions/auth_user_helper.dart';
import '../globals/constants.dart';
import '../globals/enums.dart';
import '../models/event_model.dart';
import '../models/kriti_models/kriti_result_model.dart';
import '../models/result_model.dart';
import '../models/standing_model.dart';
import '../screens/login/admin_login.dart';
import '../stores/common_store.dart';

class APIService {
  final dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment('SERVER-URL'),
      connectTimeout: 15000,
      receiveTimeout: 15000,
      headers: {'Security-Key': const String.fromEnvironment('SECURITY-KEY')}));

  APIService(BuildContext buildContext) {
    dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) async {
      options.headers["Authorization"] =
          "Bearer ${await AuthUserHelpers.getAccessToken()}";
      handler.next(options);
    }, onError: (error, handler) async {
      var response = error.response;
      // print(response.statusCode ?? "no status code");

      if (response != null && response.statusCode == 401) {
        bool couldRegenerate = await regenerateAccessToken();
        var commStore = buildContext.read<CommonStore>();
        if (couldRegenerate) {
          // retry
          return handler.resolve(await retryRequest(response));
        } else if (!commStore.isAdmin) {
          // normal user
          await generateTokens(commStore);
          // retry
          return handler.resolve(await retryRequest(response));
        } else {
          // show login screen to admin if only he has internet connection
          var connectivityResult = await (Connectivity().checkConnectivity());

          if (connectivityResults.contains(connectivityResult) &&
              await Navigator.pushNamed(buildContext, LoginView.id) == true) {
            // retry for admin
            return handler.resolve(await retryRequest(response));
          }
        }
      }
      // admin user with expired tokens
      return handler.next(error);
    }));
  }

  Future<Response<dynamic>> retryRequest(Response response) async {
    RequestOptions requestOptions = response.requestOptions;
    response.requestOptions.headers[DatabaseRecords.authorization] =
        "Bearer ${await AuthUserHelpers.getAccessToken()}";
    final options =
        Options(method: requestOptions.method, headers: requestOptions.headers);
    Dio retryDio = Dio(BaseOptions(
        baseUrl: const String.fromEnvironment('SERVER-URL'),
        connectTimeout: 5000,
        receiveTimeout: 5000,
        headers: {
          'Security-Key': const String.fromEnvironment('SECURITY-KEY')
        }));
    if (requestOptions.method == "GET") {
      return retryDio.request(requestOptions.path,
          queryParameters: requestOptions.queryParameters, options: options);
    } else {
      return retryDio.request(requestOptions.path,
          queryParameters: requestOptions.queryParameters,
          data: requestOptions.data,
          options: options);
    }
  }

  Future<dynamic> generateTokens(CommonStore commStore) async {
    Map<String, String> userData = await AuthUserHelpers.getUserData();
    Response<Map<String, dynamic>> resp = await dio.post("/gc/login",
        data: {DatabaseRecords.useremail: userData[DatabaseRecords.useremail]});
    var data = resp.data!;
    if (data["success"] == true) {
      print(data);
      commStore.setAdminNone();
      data[DatabaseRecords.authevents].forEach((element) => {
            if (element == "spardha")
              {commStore.setSpardhaAdmin(true)}
            else if (element == "kriti")
              {commStore.setKritiAdmin(true)}
            else if (element == "manthan")
              {commStore.setManthanAdmin(true)}
          });
      await AuthUserHelpers.setAdmin(data[DatabaseRecords.isadmin]);
      await AuthUserHelpers.setAccessToken(data[DatabaseRecords.accesstoken]);
      await AuthUserHelpers.setRefreshToken(data[DatabaseRecords.refreshtoken]);
    }
  }

  Future<bool> regenerateAccessToken() async {
    String refreshToken = await AuthUserHelpers.getRefreshToken();
    try {
      Dio regenDio = Dio(BaseOptions(
          baseUrl: const String.fromEnvironment('SERVER-URL'),
          connectTimeout: 5000,
          receiveTimeout: 5000,
          headers: {
            'Security-Key': const String.fromEnvironment('SECURITY-KEY')
          }));
      Response<Map<String, dynamic>> resp = await regenDio.post(
          "/gc/gen-accesstoken",
          options: Options(headers: {"authorization": "Bearer $refreshToken"}));
      var data = resp.data!;
      await AuthUserHelpers.setAccessToken(data["token"]);
      return true;
    } catch (err) {
      return false;
    }
  }

  Future<void> postSpardhaEventSchedule(Map<String, dynamic> data) async {
    try {
      print(data);
      var resp = await dio.post("/gc/spardha/event-schedule", data: data);
      print(resp.data);
    } on DioError catch (err) {
      return Future.error(err);
    }
  }

  Future<List<String>> getAllSpardhaEvents() async {
    try {
      Response resp = await dio.get("/gc/spardha/all-events");
      return List<String>.from(resp.data["details"]);
    } on DioError catch (err) {
      return Future.error(err);
    }
  }

  Future<List<EventModel>> getSpardhaSchedule(ViewType v) async {
    try {
      if (v == ViewType.admin) {
        dio.options.queryParameters["forAdmin"] = "true";
      }
      Response resp = await dio.get("/gc/spardha/event-schedule");
      List<EventModel> output = [];
      for (var e in List<dynamic>.from(resp.data["details"])) {
        {
          output.add(EventModel.fromJson(e));
        }
      }
      return output;
    } on DioError catch (err) {
      return Future.error(err);
    }
  }

  Future<List<EventModel>> getSpardhaResults(ViewType v) async {
    try {
      if (v == ViewType.admin) {
        dio.options.queryParameters["forAdmin"] = "true";
      }
      Response resp = await dio.get("/gc/spardha/event-schedule/results");
      List<EventModel> output = [];
      for (var e in List<dynamic>.from(resp.data["details"])) {
        {
          output.add(EventModel.fromJson(e));
        }
      }
      return output;
    } on DioError catch (err) {
      return Future.error(err);
    }
  }

  Future<void> addUpdateSpardhaResult(String eventID,
      List<List<ResultModel>> data, String victoryStatement) async {
    try {
      List<List<Map>> results = [];
      for (var positionResults in data) {
        List<Map> addResults = [];
        for (var result in positionResults) {
          addResults.add(result.toJson());
        }
        results.add(addResults);
      }
      Response resp = await dio.patch(
          '/gc/spardha/event-schedule/result/$eventID',
          data: {'victoryStatement': victoryStatement, 'results': results});
    } on DioError catch (err) {
      return Future.error(err);
    }
  }

  Future<void> deleteSpardhaEvent(String eventID) async {
    try {
      Response resp = await dio.delete('/gc/spardha/event-schedule/$eventID');
    } on DioError catch (err) {
      return Future.error(err);
    }
  }

  Future<void> updateSpardhaEvent(EventModel event) async {
    try {
      Response resp = await dio.patch('/gc/spardha/event-schedule/${event.id!}',
          data: event.toJson());
    } on DioError catch (err) {
      return Future.error(err);
    }
  }

  Future<void> deleteSpardhaEventResult(String eventID) async {
    try {
      Response resp =
          await dio.delete('/gc/spardha/event-schedule/result/$eventID');
    } on DioError catch (err) {
      return Future.error(err);
    }
  }

  Future<Map<String, dynamic>> getSpardhaStandings() async {
    try {
      Response resp1 = await dio.get("/gc/spardha/standings/all-events");
      Response resp2 = await dio.get("/gc/spardha/standings");
      return {
        "overall": resp2.data["details"],
        "event-wise": resp1.data["details"]
      };
    } on DioError catch (err) {
      return Future.error(err);
    }
  }

  Future<List<dynamic>> getGCStandings() async {
    try {
      Response resp = await dio.get("/gc/overall/standings");
      return resp.data['details'];
    } on DioError catch (err) {
      return Future.error(err);
    }
  }

  Future<void> postSpardhaStanding(Map<String, dynamic> data) async {
    try {
      Response resp = await dio.post("/gc/spardha/standings", data: data);
    } on DioError catch (err) {
      return Future.error(err);
    }
  }

  Future<void> updateSpardhaStanding(StandingModel standingModel) async {
    try {
      Response resp = await dio.patch(
          "/gc/spardha/standings/${standingModel.id}",
          data: standingModel.toJson());
    } on DioError catch (err) {
      return Future.error(err);
    }
  }

  Future<bool> deleteSpardhaStanding(String standingID) async {
    try {
      Response resp = await dio.delete("/gc/spardha/standings/$standingID");
      return resp.data['success'];
    } on DioError catch (err) {
      return Future.error(err);
    }
  }

  // kriti

  Future<void> postKritiEventSchedule(Map<String, dynamic> data) async {
    try {
      print(data);
      var resp = await dio.post("/gc/kriti/event-schedule", data: data);
      print(resp.data);
    } on DioError catch (err) {
      return Future.error(err);
    }
  }

  Future<void> deleteKritiEvent(String eventID) async {
    try {
      Response resp = await dio.delete('/gc/kriti/event-schedule/$eventID');
    } on DioError catch (err) {
      return Future.error(err);
    }
  }

  Future<void> updateKritiEvent(EventModel event) async {
    try {
      Response resp = await dio.patch('/gc/kriti/event-schedule/${event.id!}',
          data: event.toJson());
    } on DioError catch (err) {
      return Future.error(err);
    }
  }

  Future<List<String>> getAllKritiEvents() async {
    try {
      Response resp = await dio.get("/gc/kriti/all-events");
      return List<String>.from(resp.data["details"]);
    } on DioError catch (err) {
      return Future.error(err);
    }
  }

  Future<List<KritiEventModel>> getKritiSchedule(ViewType v) async {
    try {
      if (v == ViewType.admin) {
        dio.options.queryParameters["forAdmin"] = "true";
      }
      Response resp = await dio.get("/gc/kriti/event-schedule");
      List<KritiEventModel> output = [];
      for (var e in List<dynamic>.from(resp.data["details"])) {
        {
          output.add(KritiEventModel.fromJson(e));
        }
      }
      return output;
    } on DioError catch (err) {
      return Future.error(err);
    }
  }

  Future<List<KritiEventModel>> getKritiResults(ViewType v) async {
    try {
      if (v == ViewType.admin) {
        dio.options.queryParameters["forAdmin"] = "true";
      }
      Response resp = await dio.get("/gc/kriti/event-schedule/results");
      List<KritiEventModel> output = [];
      for (var e in List<dynamic>.from(resp.data["details"])) {
        {
          output.add(KritiEventModel.fromJson(e));
        }
      }
      return output;
    } on DioError catch (err) {
      return Future.error(err);
    }
  }

  Future<void> addUpdateKritiResult(String eventID, List<KritiResultModel> data,
      String victoryStatement) async {
    try {
      List<Map> results = [];
      for (var result in data) {
        results.add(result.toJson());
      }

      Response resp = await dio.patch(
          '/gc/kriti/event-schedule/result/$eventID',
          data: {'victoryStatement': victoryStatement, 'results': results});
    } on DioError catch (err) {
      return Future.error(err);
    }
  }

  Future<void> deleteKritiEventResult(String eventID) async {
    try {
      Response resp =
          await dio.delete('/gc/kriti/event-schedule/result/$eventID');
    } on DioError catch (err) {
      return Future.error(err);
    }
  }
}
