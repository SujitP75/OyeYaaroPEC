import 'dart:async';
import 'package:oye_yaaro_pec/Provider/SqlCool/database_creator.dart';

SqlQuery sqlQuery = new SqlQuery();

class SqlQuery {
  Future addContacts(Map<String, dynamic> row, isRegistered) async {
    Completer _c = Completer();
    int val;
    try {
      bool exists = await db.exists(
          table: "contactsTable",
          where: "contactsPhone=${row['contactsPhone']}");
      if (exists) {
        if (isRegistered) {
          print('${row['contactsPhone']} exist and reg');
          int val = await db.update(
              table: "contactsTable",
              row: row,
              where: "contactsPhone=${row['contactsPhone']}",
              verbose: false);
          _c.complete(val);
        } else {
          _c.complete(1);
        }
      } else {
        print('${row['contactsPhone']} not exist');
        val = await db.insert(table: "contactsTable", row: row, verbose: false);
        _c.complete(val);
      }
    } catch (e) {
      val = 1;
      print('Exception in addContacts($row) : $e');
      _c.complete(val);
    }
  }

  //deleteprivatechat table ids
  static Future<int> deletePrivateChatId(chatId) async {
    int val;
    print('in delete private chat sql query');
    try {
      val = await db.delete(
          table: "privateChatTable", where: "chatId='$chatId'", verbose: false);
      print('delete : $val');
      return val;
    } catch (e) {
      val = 1;
      print('delete error : $e');
      return val;
    }
  }

  //deleteGroupChat table ids
  static Future<int> deleteGroupChatId(chatId) async {
    int val;
    print('in delete private chat sql query');
    try {
      val = await db.delete(
          table: "groupChatTable", where: "chatId='$chatId'", verbose: false);
      print('delete : $val');
      return val;
    } catch (e) {
      val = 1;
      print('delete error : $e');
      return val;
    }
  }

  //deleteGroupMember from groupMember table
  static Future<int> deleteGroupMemberId(String chatId, String phone) async {
    int val;
    print('in delete deleteGroupMemberId sql query');
    try {
      val = await db.delete(
          table: "groupMembersTable",
          where: "chatId='$chatId' AND memberPhone='$phone'",
          verbose: false);
      print('delete : $val');
      return val;
    } catch (e) {
      val = 1;
      print('delete error : $e');
      return val;
    }
  }

  //delete whole groupMember table
  static Future<int> deleteGroupMemberTable(String chatId) async {
    int val;
    print('in  deleteGroupMemberTable sql query');
    try {
      val = await db.delete(
          table: "groupMembersTable",
          where: "chatId='$chatId'",
          verbose: false);
      print('delete : $val');
      return val;
    } catch (e) {
      val = 1;
      print('delete error : $e');
      return val;
    }
  }

  Future addPrivateChat(
      String chatId,
      String msgMedia,
      String msgType,
      String timestamp,
      String senderName,
      String senderPhone,
      String receiverPhone,
      String isUploaded,
      String mediaUrl,
      String thumbPath,
      String thumbUrl) async {
    Completer _completer = new Completer();
    try {
      Map<String, String> chatRow = {
        "chatId": chatId,
        "senderName": senderPhone, //senderName is getting null
        "msgMedia": msgMedia,
        "senderPhone": senderPhone,
        "msgType": msgType,
        "receiverPhone": receiverPhone,
        "timestamp": timestamp,
        "isUploaded": isUploaded,
        "mediaUrl": mediaUrl,
        "thumbPath": thumbPath,
        "thumbUrl": thumbUrl,
      };
      print('in add private chat');

      bool exists = await db.exists(
          table: "privateChatTable", where: "timestamp='$timestamp'");
      if (exists) {
        print('timestamp already exist');
        _completer.complete('exist');
      } else {
        final result = await db.insert(
            table: "privateChatTable", row: chatRow, verbose: false);

        print('inserted result: $result');
        _completer.complete('added');
      }
    } catch (e) {
      _completer.completeError(e);
    }
    return _completer.future;
  }

  Future updatePrivateChat(
      chatId,
      senderName,
      imgPath,
      senderPhone,
      msgType,
      receiverPhone,
      timestamp,
      isUploaded,
      firebaseUrl,
      thumbPath,
      thumbUrl) async {
    Completer _completer = new Completer();
    Map<String, String> chatRow = {
      "chatId": chatId,
      "senderName": senderName,
      "msgMedia": imgPath,
      "senderPhone": senderPhone,
      "msgType": msgType,
      "receiverPhone": receiverPhone,
      "timestamp": timestamp,
      "isUploaded": isUploaded,
      "mediaUrl": firebaseUrl,
      "thumbPath": thumbPath,
      "thumbUrl": thumbUrl,
    };
    try {
      int updated = await db.update(
          table: "privateChatTable",
          row: chatRow,
          where: "timestamp='$timestamp'",
          verbose: false);
      print('updated result priavteChat 2nd: $updated');
      print('new path :$imgPath');
      _completer.complete(updated);
    } catch (e) {
      print('err while updating chat value :$e');
      _completer.completeError(e);
    }
    return _completer.future;
  }

  //add into chatlist table
  Future addPrivateChatList(
      String chatId,
      String msg,
      String senderPhone,
      String recPhone,
      String timestamp,
      String count,
      String profileUrl) async {
    Completer _completer = new Completer();
    try {
      Map<String, String> chatListRow = {
        "chatId": chatId,
        "chatListLastMsg": msg,
        "chatListSenderPhone": senderPhone,
        "chatListRecPhone": recPhone,
        "chatListLastMsgTime": timestamp,
        "chatListMsgCount": count,
        "chatListProfile": profileUrl
      };
      // print('in add private chat list');

      bool exists = await db.exists(
          table: "privateChatListTable", where: "chatId='$chatId'");

      if (exists) {
         await db.update(
            table: "privateChatListTable",
            row: chatListRow,
            where: "chatId='$chatId'",
            verbose: false);
        _completer.complete('added');
      } else {
         await db.insert(
            table: "privateChatListTable", row: chatListRow, verbose: false);
        _completer.complete('added');
      }
    } catch (e) {
      _completer.completeError(e);
    }
    return _completer.future;
  }

  // add private chat list History
  Future addPrivateChatListHistory(
      String chatId,
      String msg,
      String senderPhone,
      String recPhone,
      String timestamp,
      String count,
      String profileUrl) async {
    Completer _completer = new Completer();
    try {
      Map<String, String> chatListRow = {
        "chatId": chatId,
        "chatListLastMsg": msg,
        "chatListSenderPhone": senderPhone,
        "chatListRecPhone": recPhone,
        "chatListLastMsgTime": timestamp,
        "chatListMsgCount": count,
        "chatListProfile": profileUrl
      };
      print('in add private chat list');

      bool exists = await db.exists(
          table: "privateChatListTable", where: "chatId='$chatId'");

      if (exists) {
        print('chatExist');
        final selectRes = await db.select(
            table: "privateChatListTable",
            columns: 'chatListProfile',
            where: "chatId='$chatId'",
            verbose: false);
        print(
            'selected privatechatlist profile result: ${selectRes[0]['chatListProfile']}');
        if (selectRes[0]['chatListProfile'] != profileUrl) {
          // print('profile url is not same so update new one');
          int updated = await db.update(
              table: "privateChatListTable",
              row: chatListRow,
              where: "chatId='$chatId'",
              verbose: false);
          // print('profile pic url updated in privatechatlist table : $updated');
        } else {
          // print('profile url is same so dont update');
        }
        _completer.complete('exist');
      } else {
        final result = await db.insert(
            table: "privateChatListTable", row: chatListRow, verbose: false);
        print('inserted result chatlist: $result');
        _completer.complete('added');
      }
    } catch (e) {
      _completer.completeError(e);
    }
    return _completer.future;
  }

  // delete empty chatlist from chatlist table
  Future deleteEmptyChatList(String chatId) async {
    //
    Completer _completer = new Completer();
    try {
      List<Map<String, dynamic>> rows = await db.select(
          table: "privateChatTable",
          columns: "chatId",
          where: "chatId='$chatId'",
          verbose: false);
      print('*******************$rows');
      if (rows.length == 0) {
        print('chatLength 0');
        int res = await db.delete(
            table: "privateChatListTable",
            where: "chatId='$chatId'",
            verbose: false);
        print('delete empty chat : $res');
      } else {
        print('chatLength !0');
      }
      _completer.complete('delete return');
    } catch (e) {
      _completer.completeError(e);
    }
    return _completer.future;
  }

  // select * from privateChat
  Future selectprivateChat() async {
    //
    Completer _completer = new Completer();
    try {
      List<Map<String, dynamic>> rows = await db.select(
          table: "privateChatTable",
          columns: "*",
          orderBy: "timestamp",
          verbose: false);
      print('selsct * from  privateChatTable :$rows');
      _completer.complete(rows);
    } catch (e) {
      _completer.completeError(e);
    }
    return _completer.future;
  }

  // select * from privateChatListTable
  Future selectprivateChatListTable() async {
    Completer _completer = new Completer();
    try {
      List<Map<String, dynamic>> rows = await db.select(
          table: "privateChatListTable",
          columns: "*",
          orderBy: "chatListLastMsgTime",
          verbose: false);
      print('selsct * from  privateChatListTable :$rows');
      _completer.complete(rows);
    } catch (e) {
      _completer.completeError(e);
    }
    return _completer.future;
  }

  // select * from groupChatListTable
  Future selectGroupChatListTable() async {
    Completer _completer = new Completer();
    try {
      List<Map<String, dynamic>> rows = await db.select(
          table: "groupChatListTable",
          columns: "*",
          orderBy: "chatListLastMsgTime",
          verbose: false);
      print('selsct * from  groupChatListTable :$rows');
      _completer.complete(rows);
    } catch (e) {
      _completer.completeError(e);
    }
    return _completer.future;
  }

  //get phones name
  Future getContactName(String phone) async {
    Completer _completer = new Completer();
    try {
      print(phone);
      List<Map<String, dynamic>> rows = await db.select(
          table: "contactsTable",
          columns: "contactsName",
          where: "contactsPhone='$phone'",
          verbose: false);
      print('select contactsName from  contactsTable :$rows');
      _completer.complete(rows);
    } catch (e) {
      _completer.completeError(e);
      print('err while getting name :$e');
    }
    return _completer.future;
  }

  //get conatcts row
  Future getContactRow(String phone) async {
    Completer _completer = new Completer();
    try {
      // check is phone exists logic(need to change wayfor groupInfo.dart and privatechatlist.dart)
      List<Map<String, dynamic>> rows = await db.select(
          table: "contactsTable",
          columns: "*",
          where: "contactsPhone='$phone'",
          verbose: false);
      // print('select contactsName from  contactsTable :$rows');
      _completer.complete(rows);
    } catch (e) {
      _completer.completeError(e);
      print('err while getting name :$e');
    }
    return _completer.future;
  }

  //update conatcts row
  Future updateContactRow(Map<String, dynamic> row) async {
    Completer _completer = new Completer();
    try {
      int val = await db.update(
          table: "contactsTable",
          row: row,
          where: "contactsPhone='${row['contactsPhone']}'",
          verbose: false
          );
      print('updated res-- :$val');
      _completer.complete(1);
    } catch (e) {
      _completer.completeError(e);
      print('err while updating conatct :$e');
    }
    return _completer.future;
  }

  //get all conatcts
  Future selectContact() async {
    Completer _completer = new Completer();
    try {
      print('in select contact query');
      List<Map<String, dynamic>> rows = await db.select(
          table: "contactsTable",
          columns: "*",
          // where: "contactsPhone='$phone'",
          orderBy: "contactsName",
          verbose: false);
      // print('select * from  contactsTable :$rows');
      _completer.complete(rows);
    } catch (e) {
      _completer.completeError(e);
      print('err while getting name :$e');
    }
    return _completer.future;
  }

  // get only phones from contacts
   Future getPhonesfromContact() async {
    Completer _completer = new Completer();
    try {
      List<Map<String, dynamic>> rows = await db.select(
          table: "contactsTable",
          columns: "contactsPhone",
          orderBy: "contactsName",
          verbose: false);
      // print('select * from  contactsTable :$rows');
      _completer.complete(rows);
    } catch (e) {
      _completer.completeError(e);
      print('err while getting name :$e');
    }
    return _completer.future;
  }

  //add into Groupchatlist table
  Future addGroupChatList(String chatId, String lastMsg, String senderPhone,
      String timestamp, String count, String gName) async {
    Completer _completer = new Completer();
    try {
      Map<String, String> chatListRow = {
        "chatId": chatId,
        "chatListLastMsg": lastMsg,
        "chatListSenderPhone": senderPhone,
        "chatListLastMsgTime": timestamp,
        "chatListMsgCount": count,
        "chatGroupName": gName
      };
      print('in add group chat list');

      bool exists = await db.exists(
          table: "groupChatListTable", where: "chatId='$chatId'");

      if (exists) {
        final result = await db.update(
            table: "groupChatListTable",
            row: chatListRow,
            where: "chatId='$chatId'",
            verbose: false);
        print('updated result grouplist: $result');
        _completer.complete('added');
      } else {
        final result = await db.insert(
            table: "groupChatListTable", row: chatListRow, verbose: false);
        print('inserted result grouplist: $result');
        _completer.complete('added');
      }
    } catch (e) {
      _completer.completeError(e);
    }
    return _completer.future;
  }

//add into GroupchatlistHistory table
  Future addGroupChatListHistory(String chatId, String lastMsg,
      String senderPhone, String timestamp, String count, String gName) async {
    Completer _completer = new Completer();
    try {
      Map<String, String> chatListRow = {
        "chatId": chatId,
        "chatListLastMsg": lastMsg,
        "chatListSenderPhone": senderPhone,
        "chatListLastMsgTime": timestamp,
        "chatListMsgCount": count,
        "chatGroupName": gName
      };
      print('in add group chat list history');

      bool exists = await db.exists(
          table: "groupChatListTable", where: "chatId='$chatId'");

      if (exists) {
        _completer.complete('exist');
      } else {
        final result = await db.insert(
            table: "groupChatListTable", row: chatListRow, verbose: false);
        print('inserted result grouplist by history: $result');
        _completer.complete('added');
      }
    } catch (e) {
      _completer.completeError(e);
    }
    return _completer.future;
  }

//add into groupsMembers table
  Future addGroupsMember(Map<String, String> addMember) async {
    Completer _completer = new Completer();
    try {
      print(
          'in add group member():${addMember['chatId']}, ${addMember['memberPhone']}');

      bool exists = await db.exists(
          table: "groupMembersTable",
          where:
              "chatId='${addMember['chatId']}' AND memberPhone='${addMember['memberPhone']}'");

      if (exists) {
        print('${addMember['memberPhone']} already exist');
        _completer.complete('exist');
      } else {
        final result = await db.insert(
            table: "groupMembersTable", row: addMember, verbose: false);
        // print('${addMember['memberPhone']} added successfully');

        // print('inserted result groupMembRow: $result');
        _completer.complete(result);
      }
    } catch (e) {
      _completer.completeError(e);
    }
    return _completer.future;
  }

  // select * from selectGroupMembers
  Future selectGroupMembers(String chatId) async {
    Completer _completer = new Completer();
    try {
      List<Map<String, dynamic>> rows = await db.select(
          table: "groupMembersTable",
          columns: "*",
          where: "chatId='$chatId'",
          verbose: false);
      print('selected members from  groupMembersTable :$rows');
      _completer.complete(rows);
    } catch (e) {
      _completer.completeError(e);
    }
    return _completer.future;
  }

  //gp
  Future addGroupChat(
      String chatId,
      String msgMedia,
      String msgType,
      String timestamp,
      String senderName,
      String senderPhone,
      String isUploaded,
      String mediaUrl,
      String thumbPath,
      String thumbUrl,
      String profileUrl) async {
    Completer _completer = new Completer();
    try {
      Map<String, String> chatRow = {
        "chatId": chatId,
        "senderName": senderPhone,
        "msgMedia": msgMedia,
        "senderPhone": senderPhone,
        "msgType": msgType,
        "timestamp": timestamp,
        "isUploaded": isUploaded,
        "mediaUrl": mediaUrl,
        "thumbPath": thumbPath,
        "thumbUrl": thumbUrl,
        "profileImg": profileUrl
      };
      // print('in add group chat');

      bool exists = await db.exists(
          table: "groupChatTable", where: "timestamp='$timestamp'");

      if (exists) {
        // print('timestamp already exist');
        final selectRes = await db.select(
            table: "groupChatTable",
            columns: 'profileImg',
            where: "timestamp='$timestamp'",
            verbose: false);
        // print(
        //     'selected groupChatTable profile result: ${selectRes[0]['profileImg']}'); //
        if (selectRes[0]['chatListProfile'] != profileUrl) {
          // print('profile url is not same so update new one');
          // int updated =
          await db.update(
              table: "groupChatTable",
              row: chatRow,
              where: "chatId='$chatId' AND timestamp='$timestamp'",
              verbose: false);
          // print('profile pic url updated in privatechatlist table : $updated');
        }
        // else {
        // print('profile url is same so dont update');
        // }

        _completer.complete('exist');
      } else {
        // not exist
        // if (chatRow['msgType'] == '1' || chatRow['msgType'] == '2') {
        //   downloadTumb
        // } else {
          final result = await db.insert(
              table: "groupChatTable", row: chatRow, verbose: false);
          print('inserted result: $result');
        // }
        _completer.complete('added');
      }
    } catch (e) {
      _completer.completeError(e);
    }
    return _completer.future;
  }

  // update group chat
  Future updateGroupChat(chatId, senderName, imgPath, senderPhone, msgType,
      timestamp, isUploaded, firebaseUrl, thumbPath, thumbUrl) async {
    Completer _completer = new Completer();
    Map<String, String> chatRow = {
      "chatId": chatId,
      "senderName": senderName,
      "msgMedia": imgPath,
      "senderPhone": senderPhone,
      "msgType": msgType,
      "timestamp": timestamp,
      "isUploaded": isUploaded,
      "mediaUrl": firebaseUrl,
      "thumbPath": thumbPath,
      "thumbUrl": thumbUrl,
    };
    try {
      int updated = await db.update(
          table: "groupChatTable",
          row: chatRow,
          where: "timestamp='$timestamp'",
          verbose: false);
      _completer.complete(updated);
    } catch (e) {
      print('err while updating chat value :$e');
      _completer.completeError(e);
    }
    return _completer.future;
  }

  Future getMediaFiles(int mediaType, String chatId, String chat) async {
    Completer _c = new Completer();
    try {
      List<Map<String, dynamic>> chatMedia = await db.select(
          table: chat,
          columns: "*",
          where: "chatId='$chatId' AND msgType='$mediaType'",
          orderBy: "timestamp ASC",
          verbose: false);

      _c.complete(chatMedia);
    } catch (e) {
      print('Error in getMediaFiles() function: $e');
      _c.completeError(e);
    }
    print('mediaType:$mediaType , chat:$chat');
    return _c.future;
  }
}