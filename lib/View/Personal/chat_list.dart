import 'dart:async';
import 'package:oye_yaaro_pec/Models/sharedPref.dart';
import 'package:oye_yaaro_pec/Provider/ChatService/common.dart';
import 'package:oye_yaaro_pec/Provider/SqlCool/database_creator.dart';
import 'package:oye_yaaro_pec/Provider/SqlCool/sql_queries.dart';
import 'package:oye_yaaro_pec/Theme/flexAppBar.dart';
import 'package:oye_yaaro_pec/View/Contacts/contactPage.dart';
import 'package:oye_yaaro_pec/View/Personal/personal_chatScreen.dart';
import 'package:oye_yaaro_pec/View/Profile/myProfile.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqlcool/sqlcool.dart';

class ChatList extends StatefulWidget {
  final ScrollController hideButtonController;
  //  bool isBottomBarVisible;
  ChatList({@required this.hideButtonController, Key key}) : super(key: key);

  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  SelectBloc bloc;

  DatabaseReference _privateListReference;
  StreamSubscription<Event> _privateListChildChangedSubscription;
  StreamSubscription<Event> _privateListChildAddedSubscription;

  // get profile url
  DatabaseReference _profileReference;
  StreamSubscription<Event> _profileSubscription;

  @override
  void initState() {
    this.bloc = SelectBloc(
      table: "privateChatListTable",
      orderBy: "chatListLastMsgTime",
      verbose: false,
      database: db,
      reactive: true,
    );


    // get data from firebase chatlist event(.onChildChanged)
    _privateListReference = database.reference().child('privateChatList');
    _privateListReference.keepSynced(true);
    _privateListChildChangedSubscription =
        _privateListReference.onChildChanged.listen((Event event) async {
      print('onChildChanged : ${event.snapshot.value['recPhone']} and me : ${pref.phone}');

      // check is msg for me
      if (event.snapshot.value['recPhone'] == pref.phone.toString()) {
        _profileReference = database
            .reference()
            .child('profiles')
            .child(event.snapshot.value['senderPhone']);
        _profileReference.keepSynced(true);
        _profileSubscription =
            _profileReference.onValue.listen((Event prof) async {
          print('event data ${prof.snapshot.value['profileImg']}');

          sqlQuery
              .addPrivateChatList(
                  event.snapshot.value['chatId'],
                  event.snapshot.value['msg'],
                  event.snapshot.value['senderPhone'],
                  event.snapshot.value['recPhone'],
                  event.snapshot.value['timestamp'],
                  event.snapshot.value['count'],
                  prof.snapshot.value['profileImg'])
              .then((onValue) {
            print('entry added in sqflite addchatlist');
          }, onError: (e) {
            print('show error message if addChatlist fails : $e');
          });
        }, onError: (e) {
          print('Error in profile reference listen : $e');
        });
      } else {
        print('this msg is not for me');
      }
    });

    // new chat created(.onChildAdded)
    _privateListReference = database.reference().child('privateChatList');
    _privateListReference.keepSynced(true);
    _privateListChildAddedSubscription =
        _privateListReference.onChildAdded.listen((Event event) async {
      print('onChildAdded: ${event.snapshot.value['recPhone']}, me: ${pref.phone}, ${pref.getPrivateChatHistory},');

      // getprivateChatHistory
      // no need of fetchPrivateChatHistory service
      try {
        if (pref.getPrivateChatHistory == null) {
          if (event.snapshot.value['recPhone'] == pref.phone.toString() ||
              event.snapshot.value['senderPhone'] == pref.phone.toString()) {
            // 1.get profile url from contact
            String oppositPhn =
                event.snapshot.value['recPhone'] == pref.phone.toString()
                    ? event.snapshot.value['senderPhone']
                    : event.snapshot.value['recPhone'];

            List<Map<String, dynamic>> row =
                await sqlQuery.getContactRow(oppositPhn);
            print('row to get profile url: $row');

            //2.add data in sql.addPrivateChatList
            await sqlQuery.addPrivateChatList(
                event.snapshot.value['chatId'],
                event.snapshot.value['msg'],
                event.snapshot.value['senderPhone'],
                event.snapshot.value['recPhone'],
                event.snapshot.value['timestamp'],
                event.snapshot.value['count'],
                row.length > 0 ? row[0]['profileUrl'] : '');
          }
        }
      } catch (e) {
        print('Error while getprivateChatHistory..');
      }

      if (event.snapshot.value['recPhone'] == pref.phone.toString()) {
        _profileReference = database
            .reference()
            .child('profiles')
            .child(event.snapshot.value['senderPhone']);
        _profileReference.keepSynced(true);
        _profileSubscription =
            _profileReference.onValue.listen((Event prof) async {
          print('event data ${prof.snapshot.value['profileImg']}');

          sqlQuery
              .addPrivateChatList(
                  event.snapshot.value['chatId'],
                  event.snapshot.value['msg'],
                  event.snapshot.value['senderPhone'],
                  event.snapshot.value['recPhone'],
                  event.snapshot.value['timestamp'],
                  event.snapshot.value['count'],
                  prof.snapshot.value['profileImg'])
              .then((onValue) {
            print('entry added in sqflite addchatlist');
          }, onError: (e) {
            print('show error message if addChatlist fails : $e');
          });
        }, onError: (e) {
          print('Error in profile reference listen : $e');
        });
      } else {
        print('this added msg is not for me');
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _privateListChildChangedSubscription.cancel();
    _privateListChildAddedSubscription.cancel();
    _profileSubscription.cancel();
    pref.setPrivateChatHistory(true);
    print('dispose');
  }

  deleteEmptyChatList(chatId) {
    sqlQuery.deleteEmptyChatList(chatId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Oye Yaaro"),
          flexibleSpace: FlexAppbar(),
        ),
        body: StreamBuilder<List<Map>>(
            stream: bloc.items,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                // the select query has not found anything
                if (snapshot.data.length == 0) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      // crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Image(
                          image: new AssetImage("assets/CHAT.png"),
                          width: 150.0,
                          height: 150.0,
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                        ),
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            'Start New Chat',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 25),
                          ),
                        ),
                        Padding(
                          padding:
                              EdgeInsets.only(left: 50, right: 50, top: 10),
                          child: Text(
                            'By tapping on below floating button, you can start a new chat with your contacts.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16.0,
                                color: Colors.black.withOpacity(0.50)),
                          ),
                        )
                      ],
                    ),
                  );
                }

                // if (!scrolled) {
                //   Future.delayed(Duration(milliseconds: 200)).then((v) {
                //     widget.hideButtonController.jumpTo(0.0);
                //     scrolled = true;
                //   });
                // }
                // the select query has results
                return ListView.builder(
                    controller: widget.hideButtonController,
                    reverse: false,
                    // shrinkWrap: true,
                    itemCount: snapshot.data.length,
                    itemBuilder: (BuildContext context, int index) {
                      var item =
                          snapshot.data[(snapshot.data.length - 1) - index];
                      // snapshot.data[index]; //(snapshot.data.length -1) -
                      return _buildListTile(item);
                    });
              } else {
                // the select query is still running
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // CircularProgressIndicator(),
                      Padding(
                        padding: EdgeInsets.all(10),
                      )
                    ],
                  ),
                );
              }
            }),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Color(0xffb00bae3),
          child: Icon(
            Icons.chat,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Contacts(),
              ),
            );
          },
        ));
  }

  Widget _buildListTile(Map<String, dynamic> chatList) {
    // widget.hideButtonController.jumpTo(0.0);
    return Column(
      children: <Widget>[
        ListTile(
          onTap: () {
            chat(chatList);
          },
          leading: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyProfile(
                        phone: pref.phone.toString() ==
                                chatList['chatListSenderPhone']
                            ? int.parse(chatList['chatListRecPhone'])
                            : int.parse(chatList['chatListSenderPhone']),
                      ),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                  color: Color(0xffb00bae3), shape: BoxShape.circle),
              child: chatList['chatListProfile'] == ''
                  ? CircleAvatar(
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 35,
                      ),
                      backgroundColor: Colors.grey[300],
                      radius: 25,
                    )
                  : CircleAvatar(
                      backgroundImage:
                          NetworkImage(chatList['chatListProfile']),
                      backgroundColor: Colors.grey[300],
                      radius: 25,
                    ),
            ),
          ),
          title: FutureBuilder<dynamic>(
            future: sqlQuery.getContactName(
                pref.phone.toString() == chatList['chatListSenderPhone']
                    ? chatList['chatListRecPhone']
                    : chatList['chatListSenderPhone']),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return Text(
                      pref.phone.toString() == chatList['chatListSenderPhone']
                          ? chatList['chatListRecPhone']
                          : chatList['chatListSenderPhone']);
                case ConnectionState.active:
                case ConnectionState.waiting:
                  return Text(
                      pref.phone.toString() == chatList['chatListSenderPhone']
                          ? chatList['chatListRecPhone']
                          : chatList['chatListSenderPhone']);
                case ConnectionState.done:
                  if (snapshot.hasError)
                    return Text(
                        pref.phone.toString() == chatList['chatListSenderPhone']
                            ? chatList['chatListRecPhone']
                            : chatList['chatListSenderPhone']);
                  return snapshot.data.length == 0
                      ? Text(pref.phone.toString() ==
                              chatList['chatListSenderPhone']
                          ? chatList['chatListRecPhone']
                          : chatList['chatListSenderPhone'])
                      : Text('${snapshot.data[0]['contactsName']}'); //show
              }
              return Text(
                  pref.phone.toString() == chatList['chatListSenderPhone']
                      ? chatList['chatListRecPhone']
                      : chatList['chatListSenderPhone']); // unreachable
            },
          ),
          subtitle: Text(chatList['chatListLastMsg'],
              overflow: TextOverflow.ellipsis),
          trailing: chatList['chatListLastMsgTime'] == ''
              ? Text('')
              : Column(
                  children: <Widget>[
                    FutureBuilder<String>(
                      future: Common.getTime(
                          int.parse(chatList['chatListLastMsgTime'])),
                      builder: (BuildContext context,
                          AsyncSnapshot<String> snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.none:
                            return Text(
                                DateFormat('dd MMM kk:mm').format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        int.parse(
                                            chatList['chatListLastMsgTime']))),
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12.0,
                                    fontStyle: FontStyle.normal));
                          case ConnectionState.active:
                          case ConnectionState.waiting:
                            return Text(
                                DateFormat('dd MMM kk:mm').format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        int.parse(
                                            chatList['chatListLastMsgTime']))),
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12.0,
                                    fontStyle: FontStyle.normal));
                          case ConnectionState.done:
                            if (snapshot.hasError)
                              return Text(
                                  DateFormat('dd MMM kk:mm').format(DateTime
                                      .fromMillisecondsSinceEpoch(int.parse(
                                          chatList['chatListLastMsgTime']))),
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12.0,
                                      fontStyle: FontStyle.normal));
                            return Text(
                              snapshot.data,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12.0,
                                  fontStyle: FontStyle.normal),
                            );
                        }
                        return Text(
                            DateFormat('dd MMM kk:mm').format(
                                DateTime.fromMillisecondsSinceEpoch(int.parse(
                                    chatList['chatListLastMsgTime']))),
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 12.0,
                                fontStyle: FontStyle.normal)); // unreachable
                      },
                    ),
                    // Padding(
                    //   padding: EdgeInsets.only(top: 10),
                    //   child:
                    //   chatList['chatListMsgCount'] == '1' ?
                    //   Icon(Icons.brightness_1,size: 10,color: Colors.green,)
                    //  : SizedBox()
                    // )
                  ],
                ),
        ),
        Divider(height: 0.0, indent: 75.0)
      ],
    );
  }

  chat(Map<String, dynamic> chatList) async {
    print('opposite user profile pic url :${chatList['chatListProfile']}');
    List<Map<String, dynamic>> data = await sqlQuery.getContactName(
        pref.phone.toString() == chatList['chatListSenderPhone']
            ? chatList['chatListRecPhone']
            : chatList['chatListSenderPhone']);
    // print('get data in chatlist: ${data[0]['contactsName']}');
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
              chatId: chatList['chatId'],
              chatType: 'private',
              receiverName: data.length == 0
                  ? pref.phone.toString() == chatList['chatListSenderPhone']
                      ? chatList['chatListRecPhone']
                      : chatList['chatListSenderPhone']
                  : data[0]['contactsName'],
              receiverPhone:
                  pref.phone.toString() == chatList['chatListSenderPhone']
                      ? chatList['chatListRecPhone']
                      : chatList['chatListSenderPhone'],
              profileUrl: chatList['chatListProfile']),
        ));
  }
}