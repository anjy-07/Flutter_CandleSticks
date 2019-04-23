import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(RectsExample());
List<Data> data = [];
class RectsExample extends StatefulWidget {
  @override
  _RectsExampleState createState() => _RectsExampleState();
}

class Data {
  double open;
  double high;
  double low;
  double close;
  double volumeto;
  String date;

  Data(this.open, this.high, this.low, this.close, this.volumeto, this.date);
}

class _RectsExampleState extends State<RectsExample> {
  int _index = -1;
  
  // List data = [
  //   {"open": 117.5449, "high": 117.5700, "low": 117.3200, "close": 117.4300, "volumeto": 166377, "date" : "2019-03-29"},
  //   {"open": 116.1700, "high": 120.8200, "low": 116.0500, "close": 117.0500, "volumeto": 4000.0, "date" : "2019-03-22"},
  //   {"open": 110.9900, "high": 117.2500, "low": 110.9800, "close": 115.9100, "volumeto": 173532134, "date" : "2019-03-15"},
  //   {"open": 113.0200, "high": 113.2500, "low": 108.8000, "close": 110.5100, "volumeto": 110.5100, "date" : "2019-03-08"},
  //   {"open": 111.7600, "high": 113.2400, "low": 110.8800, "close": 112.5300, "volumeto": 119359497, "date" : "2019-03-01"},
  //   {"open": 107.7900, "high": 111.2000, "low": 106.2900, "close": 110.9700, "volumeto": 96472580, "date": "2019-02-22"},
  //   {"open": 106.2000, "high": 108.3000, "low": 104.9650,  "close": 108.2200, "volumeto": 110757176, "date" : "2019-02-15"},
  // ];
  String selectedName = "";
  List<Rect> rectangles = [];
  List<Sticks> lowSticks = [];
  List<Sticks> highsticks = [];
  List<TextPainter> gridLineTextPainters = [];
  List<TextPainter> gridLineTextPaintersY = [];
  List<int> marker = [];

  Future<String> getPost() async {
    Map<String, dynamic> decoded;
    String url =
        'https://www.alphavantage.co/query?function=TIME_SERIES_WEEKLY&symbol=MSFT&apikey=8C3O6CD2T8D50GO0';
    await http.get('$url').then((response) {
      decoded = json.decode(response.body)['Weekly Time Series'];
      int i = 0;
      for (var dates in decoded.keys) {
        if (i > 20) {
          break;
        } else {
          var date = decoded[dates];
          var dataObject = new Data(
              double.parse(date['1. open']),
              double.parse(date['2. high']),
              double.parse(date['3. low']),
              double.parse(date['4. close']),
              double.parse(date['5. volume']),
              dates[8] + dates[9]);
          data.add(dataObject);
          i++;
        }
      }
      if (data.length < 0) {
        print("IN fun");
      } else {
        setState(() {
          if (data.length > 0) print(data.length);
        });
      }
    });

    return "hi";
  }

  List<Rect> buildRectangle() {
    // getPost();
    
    double _min;
    double _max;
    double _maxVolume;
    _min = double.infinity;
    _max = -double.infinity;
    _maxVolume = -double.infinity;

    for (var i in data) {
      if (i.high > _max) {
        _max = i.high.toDouble();
      }
      if (i.low < _min) {
        _min = i.low.toDouble();
      }
      if (i.volumeto > _maxVolume) {
        _maxVolume = i.volumeto.toDouble();
      }
    }

    double gridLineValue;
    for (int i = 0; i < 7; i++) {
      // Label grid lines
      gridLineValue = _max - (((_max - _min) / (7 - 1)) * i);
      String gridLineText;
      if (gridLineValue < 1) {
        gridLineText = gridLineValue.toStringAsPrecision(4);
      } else if (gridLineValue < 999) {
        gridLineText = gridLineValue.toStringAsFixed(2);
      } else {
        gridLineText = gridLineValue.round().toString().replaceAllMapped(
            new RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => "${m[1]},");
      }
      gridLineTextPainters.add(new TextPainter(
          text: new TextSpan(
              text: "\$" + gridLineText,
              style: new TextStyle(
                  color: Colors.grey,
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr));
      gridLineTextPainters[i].layout();
    }

    double height = 500 * (1 - 0.2);
    double width =
        411.42857142857144 - gridLineTextPainters[0].text.text.length * 6;

    final double heightNormalizer = height / (_max - _min);
    final double rectWidth = width / data.length;

    double rectLeft;
    double rectTop;
    double rectRight;
    double rectBottom;
    double lineWidth = 1;
    rectangles = [];

    for (int i = 0; i < data.length; i++) {
      rectLeft = (i * rectWidth) + lineWidth / 2;
      rectRight = ((i + 1) * rectWidth) - lineWidth / 2;

      gridLineTextPaintersY.add(new TextPainter(
          text: new TextSpan(
              text: data[i].date,
              style: new TextStyle(
                  color: Colors.grey,
                  fontSize: 5.0,
                  fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr));

      gridLineTextPaintersY[i].layout();

      if (data[i].open > data[i].close) {
        // Draw candlestick if decrease
        rectTop = height - (data[i].open - _min) * heightNormalizer;
        rectBottom = height - (data[i].close - _min) * heightNormalizer;

        rectangles.add(Rect.fromLTRB(rectLeft, rectTop, rectRight, rectBottom));
        marker.add(0);
      } else {
        rectTop = (height - (data[i].close - _min) * heightNormalizer) +
            lineWidth / 2;
        rectBottom =
            (height - (data[i].open - _min) * heightNormalizer) - lineWidth / 2;

        // print(rectLeft);
        // print(rectTop);
        // print(rectWidth);
        // print(rectBottom-rectTop);

        rectangles.add(
            Rect.fromLTWH(rectLeft, rectTop, rectWidth, rectBottom - rectTop));
        marker.add(1);
      }
      //       // Draw low/high candlestick wicks
      double low = height - (data[i].low - _min) * heightNormalizer;
      double high = height - (data[i].high - _min) * heightNormalizer;

      lowSticks.add(Sticks(rectLeft + rectWidth / 2 - lineWidth / 2, rectBottom,
          rectLeft + rectWidth / 2 - lineWidth / 2, low));
      highsticks.add(Sticks(
          rectLeft + rectWidth / 2, rectTop, rectLeft + rectWidth / 2, high));
    }
    return rectangles;
  }

  Widget showdialogBox(int index) {
    print("INSIDE FUNCcc");
    print(index);
    return new Container(
        decoration: new BoxDecoration(color: Colors.white),
        height: 300,
        width: 200,
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(3.0)),
          child: new Text("HIIII!!!!!"),
        ));
  }

  @override
  initState() {
    super.initState();
    getPost();
  }

  @override
  Widget build(BuildContext context) {
    if (data == null || data.length == 0) {
      print("hii");
      return MaterialApp(
        home: Scaffold(
          appBar: new AppBar(
            title: new Text("Loading..."),
          ),
        ),
      );
    } else {
      return MaterialApp(
          home: Scaffold(
        appBar: AppBar(
          title: const Text('!!!'),
          backgroundColor: Colors.black,
        ),
        body: Container(
          decoration: new BoxDecoration(color: Colors.black),
          child: Center(
              child: Stack(children: <Widget>[
            Rects(
              rects: buildRectangle(),
              lowsticks: lowSticks,
              highsticks: highsticks,
              marker: marker,
              selectedIndex: _index,
              gridLineTextPainters: gridLineTextPainters,
              gridLineTextPaintersY: gridLineTextPaintersY,
              onSelected: (index) {
                if (index != -1) {
                  setState(() {
                    _index = index;
                    selectedName = data[_index].date;
                    print(selectedName);
                  });
                  
                  //  showdialogBox(_index);
                }
              },
            ),
          ])),
        ),
      ));
    }
  }
}

class Rects extends StatelessWidget {
  final List<Rect> rects;
  final List<Sticks> lowsticks;
  final List<Sticks> highsticks;
  final List<int> marker;
  final List<TextPainter> gridLineTextPainters;
  final List<TextPainter> gridLineTextPaintersY;
  final void Function(int) onSelected;
  final int selectedIndex;

  const Rects({
    Key key,
    @required this.rects,
    @required this.lowsticks,
    @required this.highsticks,
    @required this.marker,
    @required this.gridLineTextPainters,
    @required this.gridLineTextPaintersY,
    @required this.onSelected,
    this.selectedIndex = -1,
  }) : super(key: key);
 

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onPanDown: (details) {
          RenderBox box = context.findRenderObject();
          final offset = box.globalToLocal(details.globalPosition);
          final index = rects.lastIndexWhere((rect) => rect.contains(offset));
          if (index != -1) {
            onSelected(index);
             Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SecondRoute()),
              );
            return;
          }
      },  
      
      child: CustomPaint(
        size: Size(411.42857142857144, 500.0),
        painter: _RectPainter(rects, lowsticks, highsticks, marker,
            gridLineTextPainters, gridLineTextPaintersY, selectedIndex),
      ),
    );
  }
}

class SecondRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Second Route"),
      ),
      body: Center(
        child: RaisedButton(
          onPressed: () {
             Navigator.pop(context);
            // Navigate back to first route when tapped.
          },
          child: Text('Go back!'),
        ),
      ),
    );
  }
}

class Sticks {
  double point1;
  double point2;
  double point3;
  double point4;
  Sticks(this.point1, this.point2, this.point3, this.point4);
}

class _RectPainter extends CustomPainter {
  final List<Rect> rects;
  final int selectedIndex;
  final List<Sticks> lowsticks;
  final List<Sticks> highsticks;
  final List<int> marker;
  List<TextPainter> gridLineTextPainters;
  List<TextPainter> gridLineTextPaintersY;
  Paint rectPaintLow = new Paint()
    ..color = Colors.red
    ..strokeWidth = 1;
  Paint rectPaintHigh = new Paint()
    ..color = Colors.green
    ..strokeWidth = 1;
  Paint rectPaintSticks = new Paint()
    ..color = Colors.grey[200]
    ..strokeWidth = 1;

  _RectPainter(
      this.rects,
      this.lowsticks,
      this.highsticks,
      this.marker,
      this.gridLineTextPainters,
      this.gridLineTextPaintersY,
      this.selectedIndex);

  @override
  void paint(Canvas canvas, Size size) {
    print(size);
    double width = size.width;
    final double height = size.height * (1 - 0.2); // volumeprop - 0.2

    width = size.width - gridLineTextPainters[0].text.text.length * 6;
    Paint gridPaint = new Paint()
      ..color = Colors.grey[800]
      ..strokeWidth = 1;

    double gridLineDist = height / (7 - 1);
    double gridLineY;

    // Draw grid lines
    for (int i = 0; i < 7; i++) {
      gridLineY = (gridLineDist * i).round().toDouble();
      // print(gridLineY);
      canvas.drawLine(
          new Offset(0.0, gridLineY), new Offset(width, gridLineY), gridPaint);

      // Label grid lines
      gridLineTextPainters[i]
          .paint(canvas, new Offset(width + 2.0, gridLineY - 6.0));
    }

    int i = 0;
    final double rectWidth = width / 21;
    gridLineY = 0;

    for (Rect rect in rects) {
      if (marker[i] == 0)
        canvas.drawRect(rect, rectPaintLow);
      else
        canvas.drawRect(rect, rectPaintHigh);

      canvas.drawLine(
          new Offset(gridLineY, 0), new Offset(gridLineY, height), gridPaint);
      gridLineY = gridLineY + rectWidth;

      gridLineTextPaintersY[i].paint(canvas, new Offset(gridLineY, height));
      i++;
    }

    for (int i = 0; i < lowsticks.length; i++) {
      canvas.drawLine(
          new Offset(lowsticks[i].point1, lowsticks[i].point2),
          new Offset(lowsticks[i].point3, lowsticks[i].point4),
          rectPaintSticks);
    }

    for (int i = 0; i < highsticks.length; i++) {
      canvas.drawLine(
          new Offset(highsticks[i].point1, highsticks[i].point2),
          new Offset(highsticks[i].point3, highsticks[i].point4),
          rectPaintSticks);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_candlesticks/flutter_candlesticks.dart';

// void main() {
//   List sampleData = [
//     {"open": 117.5449, "high": 117.5700, "low": 117.3200, "close": 117.4300, "volumeto": 166377, "date" : "2019-03-29"},
//     {"open": 116.1700, "high": 120.8200, "low": 116.0500, "close": 117.0500, "volumeto": 4000.0, "date" : "2019-03-22"},
//     {"open": 110.9900, "high": 117.2500, "low": 110.9800, "close": 115.9100, "volumeto": 173532134, "date" : "2019-03-15"},
//     {"open": 113.0200, "high": 113.2500, "low": 108.8000, "close": 110.5100, "volumeto": 110.5100, "date" : "2019-03-08"},
//     {"open": 111.7600, "high": 113.2400, "low": 110.8800, "close": 112.5300, "volumeto": 119359497, "date" : "2019-03-01"},
//     {"open": 107.7900, "high": 111.2000, "low": 106.2900, "close": 110.9700, "volumeto": 96472580, "date": "2019-02-22"},
//     {"open": 106.2000, "high": 108.3000, "low": 104.9650,  "close": 108.2200, "volumeto": 110757176, "date" : "2019-02-15"},
//   ];

//   runApp(
//     new MaterialApp(
//       home: new Scaffold(
//         body: new Center(
//           child: new Container(
//             height: 500.0,
//             child: new OHLCVGraph(
//                 data: sampleData,
//     enableGridLines: true,
//     volumeProp: 0.2,
//     gridLineAmount: 5,
//     gridLineColor: Colors.grey[300],
//     gridLineLabelColor: Colors.grey
//             ),
//           ),
//         ),
//       )
//     )
//   );

// }

// class OHLCVGraph extends StatelessWidget {
//   OHLCVGraph({
//     Key key,
//     @required this.data,
//     this.lineWidth = 1.0,
//     this.fallbackHeight = 100.0,
//     this.fallbackWidth = 300.0,
//     this.gridLineColor = Colors.grey,
//     this.gridLineAmount = 5,
//     this.gridLineWidth = 0.5,
//     this.gridLineLabelColor = Colors.grey,
//     this.labelPrefix = "\$",
//     @required this.enableGridLines,
//     @required this.volumeProp,
//     this.increaseColor = Colors.green,
//     this.decreaseColor = Colors.red,
//   })  : assert(data != null),
//         super(key: key);

//   /// OHLCV data to graph  /// List of Maps containing open, high, low, close and volumeto
//   /// Example: [["open" : 40.0, "high" : 75.0, "low" : 25.0, "close" : 50.0, "volumeto" : 5000.0}, {...}]
//   final List data;

//   /// All lines in chart are drawn with this width
//   final double lineWidth;

//   /// Enable or disable grid lines
//   final bool enableGridLines;

//   /// Color of grid lines and label text
//   final Color gridLineColor;
//   final Color gridLineLabelColor;

//   /// Number of grid lines
//   final int gridLineAmount;

//   /// Width of grid lines
//   final double gridLineWidth;

//   /// Proportion of paint to be given to volume bar graph
//   final double volumeProp;

//   /// If graph is given unbounded space,
//   /// it will default to given fallback height and width
//   final double fallbackHeight;
//   final double fallbackWidth;

//   /// Symbol prefix for grid line labels
//   final String labelPrefix;

//   /// Increase color
//   final Color increaseColor;

//   /// Decrease color
//   final Color decreaseColor;

//   @override
//   Widget build(BuildContext context) {
//     return new LimitedBox(
//       maxHeight: fallbackHeight,
//       maxWidth: fallbackWidth,
//       child: new CustomPaint(
//         size: Size.infinite,
//         painter: new _OHLCVPainter(data,
//             lineWidth: lineWidth,
//             gridLineColor: gridLineColor,
//             gridLineAmount: gridLineAmount,
//             gridLineWidth: gridLineWidth,
//             gridLineLabelColor: gridLineLabelColor,
//             enableGridLines: enableGridLines,
//             volumeProp: volumeProp,
//             labelPrefix: labelPrefix,
//             increaseColor: increaseColor,
//             decreaseColor: decreaseColor),
//       ),
//     );
//   }
// }

// class _OHLCVPainter extends CustomPainter {
//   _OHLCVPainter(this.data,
//       {@required this.lineWidth,
//       @required this.enableGridLines,
//       @required this.gridLineColor,
//       @required this.gridLineAmount,
//       @required this.gridLineWidth,
//       @required this.gridLineLabelColor,
//       @required this.volumeProp,
//       @required this.labelPrefix,
//       @required this.increaseColor,
//       @required this.decreaseColor});

//   final List data;
//   final double lineWidth;
//   final bool enableGridLines;
//   final Color gridLineColor;
//   final int gridLineAmount;
//   final double gridLineWidth;
//   final Color gridLineLabelColor;
//   final String labelPrefix;
//   final double volumeProp;
//   final Color increaseColor;
//   final Color decreaseColor;

//   double _min;
//   double _max;
//   double _maxVolume;

//   List<TextPainter> gridLineTextPainters = [];
//   TextPainter maxVolumePainter;

//   numCommaParse(number) {
//     return number.round().toString().replaceAllMapped(
//         new RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},");
//   }

//   update() {
//     _min = double.infinity;
//     _max = -double.infinity;
//     _maxVolume = -double.infinity;
//     for (var i in data) {
//       if (i["high"] > _max) {
//         _max = i["high"].toDouble();
//       }
//       if (i["low"] < _min) {
//         _min = i["low"].toDouble();
//       }
//       if (i["volumeto"] > _maxVolume) {
//         _maxVolume = i["volumeto"].toDouble();
//       }
//     }

//     if (enableGridLines) {
//       double gridLineValue;
//       for (int i = 0; i < gridLineAmount; i++) {
//         // Label grid lines
//         gridLineValue = _max - (((_max - _min) / (gridLineAmount - 1)) * i);

//         String gridLineText;
//         if (gridLineValue < 1) {
//           gridLineText = gridLineValue.toStringAsPrecision(4);
//         } else if (gridLineValue < 999) {
//           gridLineText = gridLineValue.toStringAsFixed(2);
//         } else {
//           gridLineText = gridLineValue.round().toString().replaceAllMapped(
//               new RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
//               (Match m) => "${m[1]},");
//         }

//         gridLineTextPainters.add(new TextPainter(
//             text: new TextSpan(
//                 text: labelPrefix + gridLineText,
//                 style: new TextStyle(
//                     color: gridLineLabelColor,
//                     fontSize: 10.0,
//                     fontWeight: FontWeight.bold)),
//             textDirection: TextDirection.ltr));
//         gridLineTextPainters[i].layout();
//       }

//       // Label volume line
//       maxVolumePainter = new TextPainter(
//           text: new TextSpan(
//               text: "\$" + numCommaParse(_maxVolume),
//               style: new TextStyle(
//                   color: gridLineLabelColor,
//                   fontSize: 10.0,
//                   fontWeight: FontWeight.bold)),
//           textDirection: TextDirection.ltr);
//       maxVolumePainter.layout();
//     }
//   }

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (_min == null || _max == null || _maxVolume == null) {
//       update();
//     }

//     final double volumeHeight = size.height * volumeProp;
//     final double volumeNormalizer = volumeHeight / _maxVolume;

//     double width = size.width;

//     print("size height");
//     print(size.height);

//     final double height = size.height * (1 - volumeProp);
//     print("hright");
//     print(height);

//     if (enableGridLines) {
//       width = size.width - gridLineTextPainters[0].text.text.length * 6;
//       Paint gridPaint = new Paint()
//         ..color = gridLineColor
//         ..strokeWidth = gridLineWidth;

//       double gridLineDist = height / (gridLineAmount - 1);
//       print(height);
//       print("gridlinedis");
//       print(gridLineAmount);
//       print(gridLineDist);
//       double gridLineY;

//       // Draw grid lines
//       for (int i = 0; i < gridLineAmount; i++) {
//         gridLineY = (gridLineDist * i).round().toDouble();
//         canvas.drawLine(new Offset(0.0, gridLineY),
//             new Offset(width, gridLineY), gridPaint);

//             print(gridLineY);

//         // Label grid lines
//         gridLineTextPainters[i]
//             .paint(canvas, new Offset(width + 2.0, gridLineY - 6.0));
//       }

//       // Label volume line
//       maxVolumePainter.paint(canvas, new Offset(0.0, gridLineY + 2.0));
//     }

//     final double heightNormalizer = height / (_max - _min);
//     final double rectWidth = width / data.length;

//     double rectLeft;
//     double rectTop;
//     double rectRight;
//     double rectBottom;

//     Paint rectPaint;

//     // Loop through all data
//     for (int i = 0; i < data.length; i++) {
//       rectLeft = (i * rectWidth) + lineWidth / 2;
//       rectRight = ((i + 1) * rectWidth) - lineWidth / 2;

//       double volumeBarTop = (height + volumeHeight) -
//           (data[i]["volumeto"] * volumeNormalizer - lineWidth / 2);
//       double volumeBarBottom = height + volumeHeight + lineWidth / 2;

//       if (data[i]["open"] > data[i]["close"]) {
//         // Draw candlestick if decrease
//         rectTop = height - (data[i]["open"] - _min) * heightNormalizer;
//         rectBottom = height - (data[i]["close"] - _min) * heightNormalizer;
//         rectPaint = new Paint()
//           ..color = decreaseColor
//           ..strokeWidth = lineWidth;

//         Rect ocRect =
//             new Rect.fromLTRB(rectLeft, rectTop, rectRight, rectBottom);
//         canvas.drawRect(ocRect, rectPaint);

//         // Draw volume bars
//         Rect volumeRect = new Rect.fromLTRB(
//             rectLeft, volumeBarTop, rectRight, volumeBarBottom);
//         canvas.drawRect(volumeRect, rectPaint);
//       } else {
//         // Draw candlestick if increase
//         rectTop = (height - (data[i]["close"] - _min) * heightNormalizer) +
//             lineWidth / 2;
//         rectBottom = (height - (data[i]["open"] - _min) * heightNormalizer) -
//             lineWidth / 2;
//         rectPaint = new Paint()
//           ..color = increaseColor
//           ..strokeWidth = lineWidth;

//         canvas.drawLine(new Offset(rectLeft, rectBottom - lineWidth / 2),
//             new Offset(rectRight, rectBottom - lineWidth / 2), rectPaint);
//         canvas.drawLine(new Offset(rectLeft, rectTop + lineWidth / 2),
//             new Offset(rectRight, rectTop + lineWidth / 2), rectPaint);
//         canvas.drawLine(new Offset(rectLeft + lineWidth / 2, rectBottom),
//             new Offset(rectLeft + lineWidth / 2, rectTop), rectPaint);
//         canvas.drawLine(new Offset(rectRight - lineWidth / 2, rectBottom),
//             new Offset(rectRight - lineWidth / 2, rectTop), rectPaint);

//       }

//       // Draw low/high candlestick wicks
//       double low = height - (data[i]["low"] - _min) * heightNormalizer;
//       double high = height - (data[i]["high"] - _min) * heightNormalizer;
//       canvas.drawLine(
//           new Offset(rectLeft + rectWidth / 2 - lineWidth / 2, rectBottom),
//           new Offset(rectLeft + rectWidth / 2 - lineWidth / 2, low),
//           rectPaint);
//       canvas.drawLine(
//           new Offset(rectLeft + rectWidth / 2 - lineWidth / 2, rectTop),
//           new Offset(rectLeft + rectWidth / 2 - lineWidth / 2, high),
//           rectPaint);
//     }
//   }

//   @override
//   bool shouldRepaint(_OHLCVPainter old) {
//     return data != old.data ||
//         lineWidth != old.lineWidth ||
//         enableGridLines != old.enableGridLines ||
//         gridLineColor != old.gridLineColor ||
//         gridLineAmount != old.gridLineAmount ||
//         gridLineWidth != old.gridLineWidth ||
//         volumeProp != old.volumeProp ||
//         gridLineLabelColor != old.gridLineLabelColor;
//   }
// }
