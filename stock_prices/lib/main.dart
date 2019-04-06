import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


void main() => runApp(RectsExample());

class RectsExample extends StatefulWidget {
  @override
  _RectsExampleState createState() => _RectsExampleState();
}

class _RectsExampleState extends State<RectsExample> {
  int _index = -1;
  List data = [  
    {"open": 117.5449, "high": 117.5700, "low": 117.3200, "close": 117.4300, "volumeto": 166377, "date" : "2019-03-29"},
    {"open": 116.1700, "high": 120.8200, "low": 116.0500, "close": 117.0500, "volumeto": 4000.0, "date" : "2019-03-22"},
    {"open": 110.9900, "high": 117.2500, "low": 110.9800, "close": 115.9100, "volumeto": 173532134, "date" : "2019-03-15"},
    {"open": 113.0200, "high": 113.2500, "low": 108.8000, "close": 110.5100, "volumeto": 110.5100, "date" : "2019-03-08"},
    {"open": 111.7600, "high": 113.2400, "low": 110.8800, "close": 112.5300, "volumeto": 119359497, "date" : "2019-03-01"},
    {"open": 107.7900, "high": 111.2000, "low": 106.2900, "close": 110.9700, "volumeto": 96472580, "date": "2019-02-22"},
    {"open": 106.2000, "high": 108.3000, "low": 104.9650,  "close": 108.2200, "volumeto": 110757176, "date" : "2019-02-15"},
  ];
  String selectedName = "";
  List<Rect> rectangles = [];
  List<Sticks> lowSticks = [];
  List<Sticks> highsticks =[];
  List<int> marker=[];

  List<Rect> buildRectangle() {
    // MediaQueryData queryData;
    // queryData = MediaQuery.of(context);   
    // double width1 = queryData.size.width;
    // double height1 = queryData.size.height;
  

    double _min;
    double _max;
    double _maxVolume;
    _min = double.infinity;
    _max = -double.infinity;
    _maxVolume = -double.infinity;

    for (var i in data) {
      if (i["high"] > _max) {
        _max = i["high"].toDouble();
      }
      if (i["low"] < _min) {
        _min = i["low"].toDouble();
      }
      if (i["volumeto"] > _maxVolume) {
        _maxVolume = i["volumeto"].toDouble();
      }
    }
    double width = 411.42857142857144;
    double height = 400.0;

    
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

        if (data[i]["open"] > data[i]["close"]) {
          // Draw candlestick if decrease
          rectTop = height - (data[i]["open"] - _min) * heightNormalizer;
          rectBottom = height - (data[i]["close"] - _min) * heightNormalizer;
         
          rectangles.add(Rect.fromLTRB(rectLeft, rectTop, rectRight, rectBottom));
          marker.add(0);
        }else{
         
          rectTop = (height - (data[i]["close"] - _min) * heightNormalizer) +
              lineWidth / 2;
          rectBottom = (height - (data[i]["open"] - _min) * heightNormalizer) -
              lineWidth / 2;
        
          rectangles.add(Rect.fromLTWH(rectLeft, rectTop, rectWidth, rectBottom-rectTop));
           marker.add(1);
        }
    //       // Draw low/high candlestick wicks
      double low = height - (data[i]["low"] - _min) * heightNormalizer;
      double high = height - (data[i]["high"] - _min) * heightNormalizer;

      lowSticks.add(Sticks(rectLeft + rectWidth / 2 - lineWidth / 2 , rectBottom, rectLeft + rectWidth / 2 - lineWidth / 2, low));
      highsticks.add(Sticks(rectLeft + rectWidth / 2, rectTop , rectLeft + rectWidth / 2, high));     
    }
    return rectangles;
  }

  @override
  Widget build(BuildContext context) {

    AppBar appBar = AppBar(
    title: Text('Demo'),
    );
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Basic AppBar'),
          backgroundColor: Colors.black,
          
        ),
        body: Center(
            child: Rects(
            rects: buildRectangle(),
            lowsticks : lowSticks,
            highsticks: highsticks,
            marker: marker,
            selectedIndex: _index,
            onSelected: (index) {
              setState(() {
                print(index);
                _index = index;
                selectedName = data[_index]['date'];
                print(selectedName);
              });
            },
          ),
        )  
      ),   
    );
  }
}

class Rects extends StatelessWidget {
  final List<Rect> rects;
  final List<Sticks> lowsticks;
  final List<Sticks> highsticks;
  final List<int> marker;
  final void Function(int) onSelected;
  final int selectedIndex;

  const Rects({
    Key key,
    @required this.rects,
    @required this.lowsticks,
    @required this.highsticks,
    @required this.marker,
    @required this.onSelected,
    this.selectedIndex = -1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
   return new LimitedBox(
      maxHeight: 100,
      maxWidth: 300, 
      child : GestureDetector(
       onTapUp : (details) {
        RenderBox box = context.findRenderObject();
        final offset = box.globalToLocal(details.globalPosition);
        final index = rects.lastIndexWhere((rect) => rect.contains(offset));

        if (index != -1) {
          onSelected(index);
          return;
        }
       onSelected(-1);
      },
      child: CustomPaint(
        size: Size(411.42857142857144, 400.0),
        painter: _RectPainter(rects, lowsticks, highsticks, marker, selectedIndex),
      ),
     )   
   );
  }
}

class Sticks{
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
  Paint rectPaintLow = new Paint()
          ..color = Colors.red
          ..strokeWidth = 1;
  Paint rectPaintHigh = new Paint()
          ..color = Colors.green
          ..strokeWidth = 1;

  _RectPainter(this.rects, this.lowsticks, this.highsticks, this.marker, this.selectedIndex);

  @override
  void paint(Canvas canvas, Size size) {
    print(size);
    int i = 0;
    for (Rect rect in rects) {
      if(marker[i] == 0 )
        canvas.drawRect(rect, rectPaintLow);
      else
         canvas.drawRect(rect, rectPaintHigh);
      i++;
    }

    for(int i=0;i<lowsticks.length;i++){
       canvas.drawLine(
          new Offset(lowsticks[i].point1, lowsticks[i].point2),
          new Offset(lowsticks[i].point3 , lowsticks[i].point4),
          rectPaintLow
        );
    }

    for(int i=0;i<highsticks.length;i++){
      canvas.drawLine(
          new Offset(highsticks[i].point1, highsticks[i].point2),
          new Offset(highsticks[i].point3 , highsticks[i].point4),
          rectPaintHigh
        );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

