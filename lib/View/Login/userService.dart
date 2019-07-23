import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import '../../Models/sharedPref.dart';
import '../../Models/url.dart';

class UserService {
  static const platform = MethodChannel('com.plmlogix.oye_yaaro_pec/platform');

  static Future checkUser(String pin) async {
    Completer c = Completer();
    try {
      http.Response response = await http.post(
          "http://oyeyaaroapi.plmlogix.com/getProfile",
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"pin": '$pin'}));

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        print('result:$result');
        if (result['success'] == true) {
            // 1.setUser
          setUserToken(result,pin);
          //2.make invite 'true'
          await http.post("${url.api}setMember",
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({"pin": '$pin'}));

          //3.setUser verified phone number
          await http.post("${url.api}setNumber",
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(
                {"pin": '$pin', 'mobile': '${pref.phone.toString()}'},
              ));

          //4.Add user in instaClone
          CollectionReference ref =
              Firestore.instance.collection('insta_users');
          ref.document(pin).setData({
            "userId": pin,
            "username": result['data'][0]['Name'],
            "photoUrl":
                "http://oyeyaaroapi.plmlogix.com/profiles/now/" + pin + ".jpg",
            "email": result['data'][0]['Email'],
            "following": {
              "Public": true,
              result['data'][0]['College']: true,
              result['data'][0]['Groups'][0]['dialog_id']: true,
            },
          });

          //5.register to sinch
          //  await registerusersinch();
          c.complete('true');
        } else {
          c.complete('false');
        }
      } else {
        c.completeError('service failed.');
      }
    } catch (e) {
      print('Error in checkUser():$e');
      c.completeError(e);
    }
    return c.future;
  }

// functionality not working well
  // static Future<bool> registerusersinch() async {
  //   var sendMap = <String, dynamic>{
  //     'from': pref.phone.toString(),
  //   };
  //   try {
  //     String result = await platform.invokeMethod('registersinch', sendMap);
  //   } on PlatformException catch (e) {
  //     print(e);
  //   }
  //   return true;
  // }

 static setUserToken(result,String pin) async {
    pref.setPin(int.parse(pin));
    pref.setName(result['data'][0]['Name']);
    pref.setGroupId(result['data'][0]['Groups'][0]['dialog_id']);
    pref.setCollege(result['data'][0]['College']);
    pref.setProfile("${url.api}profile/now/" + pin + ".jpg");
  }
}