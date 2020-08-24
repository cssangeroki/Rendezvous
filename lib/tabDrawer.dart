import 'package:flutter/material.dart';
import 'globalVar.dart';

class Tabs extends StatefulWidget {
  final Function refresh;

  Tabs({this.refresh});

  @override
  _TabsState createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        SizedBox(width: 24),
        MyTab(
            text: 'Venue',
            isSelected: Global.tabValue == 0,
            onTap: () => _updateValue(0)),
        MyTab(
            text: 'Info',
            isSelected: Global.tabValue == 1,
            onTap: () => _updateValue(1)),
        MyTab(
            text: 'Chat',
            isSelected: Global.tabValue == 2,
            onTap: () => _updateValue(2)),
      ],
    );
  }

  void _updateValue(int newValue) {
    widget.refresh();
    setState(() {
      //print("Changing into Tab ${newValue}");
      Global.tabValue = newValue;
    });
  }
}

class MyTab extends StatelessWidget {
  final String text;
  final bool isSelected;
  final Function onTap;

  const MyTab(
      {Key key, @required this.isSelected, @required this.text, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(5, 0, 5, 0),
      padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: InkWell(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        onTap: onTap,
        child: Container(
          child: Column(
            //crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                margin: EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSelected ? 20 : 17,
                    color: isSelected ? Colors.black : Colors.grey,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              Container(
                height: 6,
                width: 75,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isSelected
                      ? Color(Global.yellowColor)
                      : Color(Global.backgroundColor),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
