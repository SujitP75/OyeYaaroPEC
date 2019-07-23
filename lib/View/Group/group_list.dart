import 'dart:async';
import 'package:oye_yaaro_pec/Models/sharedPref.dart';
import 'package:oye_yaaro_pec/Provider/ChatService/common.dart';
import 'package:oye_yaaro_pec/Provider/ChatService/group.dart';
import 'package:oye_yaaro_pec/Provider/SqlCool/database_creator.dart';
import 'package:oye_yaaro_pec/Provider/SqlCool/sql_queries.dart';
import 'package:oye_yaaro_pec/Theme/flexAppBar.dart';
import 'package:oye_yaaro_pec/View/Contacts/contactGroup.dart';
import 'package:oye_yaaro_pec/View/Group/group_chatScreen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqlcool/sqlcool.dart';

class GroupList extends StatefulWidget {
  final ScrollController hideButtonController;

  GroupList({@required this.hideButtonController, Key key}) : super(key: key);

  @override
  _GroupListState createState() => _GroupListState();
}

class _GroupListState extends State<GroupList> {
  SelectBloc bloc;
  DatabaseReference _groupListReference;
  StreamSubscription<Event> _groupListChildChangedSubscription;
  StreamSubscription<Event> _groupListChildCreatedSubscription;

  @override
  void initState() {
    this.bloc = SelectBloc(
      table: "groupChatListTable",
      orderBy: "chatListLastMsgTime",
      verbose: false,
      database: db,
      reactive: true,
    );

    // problem stmt
    // im passing members[] along with fbchatlist. and adding members[] in sql gmebertable at the time
    // crating group(remember its  happening only at group creaters side not at participans side)

    // i can get updated group members[] from group chat array
    // but when admin adds new members should notify and changes should be added to all
    // create gmembers[] at firebase side , create new msg type (--added--).

    // check and get chatlist history service
    checkHistory();

    //check privateChatListTable data
    // sqlQuery.selectGroupChatListTable();

    // get data from firebase chatlist
    //while createing group or sending msg
    // create members arrays String a long string with space ex.' 7040470678 7972241516 xyz..'
    // now if 'event.snapshot.value['membs'].contains('pref.phone.toString')'

    _groupListReference = database.reference().child('groupChatList');
    _groupListReference.keepSynced(true);

    _groupListChildChangedSubscription =
        _groupListReference.onChildChanged.listen((Event event) {
      print(
          'onChildChanged : ${event.snapshot.value['members']} and me : ${pref.phone}');
      if (event.snapshot.value['members'].contains(pref.phone.toString())
          //  ||
          //     event.snapshot.value['admin'] != pref.phone.toString()
          ) {
        //chek condition
        print('conatains');
        sqlQuery
            .addGroupChatList(//obj
                event.snapshot.value['chatId'],
                event.snapshot.value['msg'],
                event.snapshot.value['senderPhone'],
                event.snapshot.value['timestamp'],
                event.snapshot.value['count'],
                event.snapshot.value['groupName'])
            .then((onValue) {
          print('entry added in sqflite addchatlist');
        }, onError: (e) {
          print('show error message if addChatlist fails : $e');
        });

        // add members[] in sql
        // event.snapshot.value['members'].forEach((memb) { //no need
        //   print('member:$memb');
        //   sqlQuery
        //       .addGroupsMember(event.snapshot.value['chatId'], memb,
        //           event.snapshot.value['admin'])
        //       .then((onValue) {
        //     print('$memb added in group members sql');
        //   }, onError: (e) {
        //     print('Error while adding group members in sql:$e');
        //   });
        // });

      } else {
        print('this msg is not for me');
      }
    });

// group created
    _groupListChildCreatedSubscription =
        _groupListReference.onChildAdded.listen((Event event) {
      print('event : ${event.snapshot.value}');
      if (event.snapshot.value['members'].contains(pref.phone.toString()) ||
          event.snapshot.value['admin'] == pref.phone.toString()) {
        print('conatains');
        sqlQuery
            .addGroupChatList(
                event.snapshot.value['chatId'],
                event.snapshot.value['msg'],
                event.snapshot.value['senderPhone'],
                event.snapshot.value['timestamp'],
                event.snapshot.value['count'],
                event.snapshot.value['groupName'])
            .then((onValue) {
          print('entry added in sqflite addchatlist');
        }, onError: (e) {
          print('show error message if addChatlist fails : $e');
        });

        // add members[] in sql
        // addNewMembers(event.snapshot.value['members']) //make one function//rm
        // event.snapshot.value['members'].forEach((memb) {//no need
        //   print('member:$memb');
        //   sqlQuery
        //       .addGroupsMember(event.snapshot.value['chatId'], memb,
        //           event.snapshot.value['admin'])
        //       .then((onValue) {
        //     print('$memb added in group members sql');
        //   }, onError: (e) {
        //     print('Error while adding group members in sql:$e');
        //   });
        // });

      } else {
        print('this group is not for me');
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _groupListChildChangedSubscription.cancel();
    _groupListChildCreatedSubscription.cancel();
    print('dispose');
  }

  checkHistory() async {
    try {
      Group.fetchGroupChat().then((onValue) {
        print("Got history :$onValue");
        onValue.forEach((f) {
          print('g_id:${f['dialog_id']}');
          print('admin:${f['admin_id']}');
          print('g_name:${f['name']}');
// add to list
          sqlQuery
              .addGroupChatListHistory(
                  f['dialog_id'], '', '', '', '0', f['name'])
              .then((onValue) {
            print('entry added in sqflite addGroupchatlist:$onValue');
          }, onError: (e) {
            print('show error message if addgroupChatlist fails : $e');
          });

          // add members[] in sql
          // f['occupants_ids'].forEach((memb) { //no need
          //   print('member:${memb['pin']}');
          //   sqlQuery
          //       .addGroupsMember(f['dialog_id'], memb['pin'], f['admin_id'])
          //       .then((onValue) {
          //     print('${memb['pin']} added in group members sql');
          //   }, onError: (e) {
          //     print('Error while adding group members in sql:$e');
          //   });
          // });
        });
      }, onError: (e) {
        print(
            "Got Error while getting User's chat list hostory in service: $e");
      });
    } catch (e) {
      print(
          "Got Error while getting User's chat list hostory in function : $e");
    }
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
                          'Group Chat',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 25),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.only(left: 50, right: 50, top: 10),
                        child: Text(
                          'All your groups will appear here, or \n By tapping on below floating button, you can create new group from your contacts.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.black.withOpacity(0.50)),
                        ),
                      )
                    ],
                  ),
                );
              } else
                // the select query has results
                return ListView.builder(
                    controller: widget.hideButtonController,
                    reverse: false,
                    itemCount: snapshot.data.length,
                    itemBuilder: (BuildContext context, int index) {
                      var item =
                          snapshot.data[(snapshot.data.length - 1) - index];
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
          Icons.group_add,
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContactsGroup(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListTile(Map<String, dynamic> chatList) {
    return Column(
      children: <Widget>[
        ListTile(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => GroupChatScreen(
                            chatId: chatList['chatId'],
                            chatType: 'group',
                            groupName: chatList['chatGroupName'],
                          )));
            },
            leading: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                  color: Color(0xffb00bae3), shape: BoxShape.circle),
              child: CircleAvatar(
                child: Icon(
                  Icons.group,
                  color: Colors.white,
                  size: 35,
                ),
                backgroundColor: Colors.grey[300],
                radius: 25,
              ),
            ),
            title: Text(chatList['chatGroupName']),
            subtitle: chatList['chatListLastMsg'] == ''
                ? Text('send a new message')
                : Text(chatList['chatListLastMsg'],
                    overflow: TextOverflow.ellipsis),
            trailing: Column(
              children: <Widget>[
                chatList['chatListLastMsgTime'] == ''
                    ? Text('')
                    : FutureBuilder<String>(
                        future: Common.getTime(
                            int.parse(chatList['chatListLastMsgTime'])),
                        builder: (BuildContext context,
                            AsyncSnapshot<String> snapshot) {
                          switch (snapshot.connectionState) {
                            case ConnectionState.none:
                              return Text(
                                  DateFormat('dd MMM kk:mm').format(DateTime
                                      .fromMillisecondsSinceEpoch(int.parse(
                                          chatList['chatListLastMsgTime']))),
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12.0,
                                      fontStyle: FontStyle.normal));
                            case ConnectionState.active:
                            case ConnectionState.waiting:
                              return Text(
                                  DateFormat('dd MMM kk:mm').format(DateTime
                                      .fromMillisecondsSinceEpoch(int.parse(
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
                // show count funactionality
                // Padding(
                //   padding: EdgeInsets.only(top: 10),
                //   child:
                //   chatList['chatListMsgCount'] == '1' ?
                //   Icon(Icons.brightness_1,size: 10,color: Colors.green,)
                //  : SizedBox()
                // )
              ],
            )),
        Divider(height: 0.0, indent: 75.0)
      ],
    );
  }

  // Widget _menuBuilder() {
  //   return PopupMenuButton<String>(
  //     icon: Icon(
  //       Icons.more_vert,
  //       color: Colors.white,
  //     ),
  //     tooltip: "Menu",
  //     onSelected: _onMenuItemSelect,
  //     itemBuilder: (BuildContext context) => [
  //           PopupMenuItem<String>(
  //             value: 'Logout',
  //             child: Padding(
  //               padding: EdgeInsets.symmetric(horizontal: 5.0),
  //               child: Row(
  //                 children: <Widget>[
  //                   Text("Logout"),
  //                   Spacer(),
  //                   Icon(Icons.person),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ],
  //   );
  // }

  // _onMenuItemSelect(String option) {
  //   switch (option) {
  //     case 'Logout':
  //       logout();
  //       break;
  //   }
  // }

  // //confirm logout //make one
  // logout() {
  //   showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return SimpleDialog(
  //           contentPadding:
  //               EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
  //           children: <Widget>[
  //             Container(
  //               color: Color(0xffb00bae3),
  //               margin: EdgeInsets.all(0.0),
  //               padding: EdgeInsets.only(bottom: 10.0, top: 10.0),
  //               height: 80.0,
  //               child: Column(
  //                 children: <Widget>[
  //                   Text(
  //                     'Logout',
  //                     style: TextStyle(
  //                         color: Colors.white,
  //                         fontSize: 20.0,
  //                         fontWeight: FontWeight.bold),
  //                   ),
  //                   Padding(
  //                     padding: EdgeInsets.only(bottom: 10),
  //                   ),
  //                   Text(
  //                     'Are you sure to logout from app?',
  //                     style: TextStyle(color: Colors.white70, fontSize: 14.0),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             Container(
  //               height: 50,
  //               child: Row(
  //                 children: <Widget>[
  //                   SimpleDialogOption(
  //                     onPressed: () {
  //                       print('pressed cancel');
  //                       Navigator.pop(context, 0);
  //                     },
  //                     child: Row(
  //                       children: <Widget>[
  //                         Container(
  //                           child: Icon(
  //                             Icons.cancel,
  //                             color: Color(0xffb00bae3),
  //                           ),
  //                           margin: EdgeInsets.only(right: 10.0),
  //                         ),
  //                         Text(
  //                           'CANCEL',
  //                           style: TextStyle(fontWeight: FontWeight.bold),
  //                         )
  //                       ],
  //                     ),
  //                   ),
  //                   SimpleDialogOption(
  //                     onPressed: () {
  //                       print('pressed yes');
  //                       // DatabaseOperation.deleteChatList();
  //                       FirebaseAuth.instance.signOut().then((action) {
  //                         pref.clearUser();
  //                         Navigator.of(context).pushNamedAndRemoveUntil(
  //                             '/loginpage', (Route<dynamic> route) => false);
  //                       });
  //                     },
  //                     child: Row(
  //                       children: <Widget>[
  //                         Container(
  //                           child: Icon(
  //                             Icons.check_circle,
  //                             color: Color(0xffb00bae3),
  //                           ),
  //                           margin: EdgeInsets.only(right: 10.0),
  //                         ),
  //                         Text(
  //                           'YES',
  //                           style: TextStyle(fontWeight: FontWeight.bold),
  //                         )
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             )
  //           ],
  //         );
  //       });
  // }
}
