import 'dart:async';
import 'package:drive_me/config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:drive_me/widgets/divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../assistants/methods_assistant.dart';
import '../data_handler/app_data.dart';
import '../models/direction_details.dart';
import '../widgets/progress_dialog.dart';
import 'login_screen.dart';
import 'search_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  static const String idScreen = "mainScreen";
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    print("calling locate position");
    locatePosition();
    WidgetsBinding.instance.addPostFrameCallback((_) => locatePosition());

    print('calling the method get user');
    WidgetsBinding.instance.addPostFrameCallback((_) => MethodsAssistant.getCurrentUserInfo());

  }


  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  //final List<_PositionItem> _positionItems = <_PositionItem>[];
  GlobalKey<ScaffoldState> scaffoldKey =new GlobalKey<ScaffoldState>();
  final Completer<GoogleMapController> _controllerGM =
  Completer<GoogleMapController>();
  late GoogleMapController gmCtrl;
  double bottomPadding = 0;
  late Position  currentPosition ;
  var geoLocator = Geolocator();

  bool drawerOpen = true;

  DirectionDetail? tripDirectionDetails;

  List<LatLng> pLineCoordinates =[];
  Set<Polyline> polylineSet={};

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  double rideDetailsContainerHeight=0;
  double rideRequestContainerHeight=0;
  double searchContainerHeight = 300;

  DatabaseReference? rideRequestRef;




  void saveRideRequestInfo(){
    rideRequestRef =FirebaseDatabase.instance.ref().child("ride requests").push();
    var pickUp = Provider.of<AppData>(context,listen: false).pickUpLocation;
    var dropOff = Provider.of<AppData>(context,listen: false).dropOffLocation;

    Map pickUpLoc ={
      "latitude":pickUp!.latitude.toString(),
      "longitude":pickUp!.longitude.toString(),
    };
    Map dropOffLoc ={
      "latitude":dropOff!.latitude.toString(),
      "longitude":dropOff!.longitude.toString(),
    };

    Map rideInfoMap={
      "driver_id":"waiting",
      "payment_method":"cash",
      "pickUp": pickUpLoc,
      "dropOff":dropOffLoc,
      "created_at": DateTime.now().toString(),
      "rider_name": currentUserInfo!.name,
      "rider_phone": currentUserInfo!.phone,
      "pickup_address":pickUp.placeName,
      "dropoff_address":dropOff.placeName,

    };

    rideRequestRef!.set(rideInfoMap);
  }

  void cancelRideRequest(){
    rideRequestRef!.remove();
    resetApp();
  }

  displayRequestRideContainer(){
    setState(() {
      rideRequestContainerHeight=250;
       rideDetailsContainerHeight=0;
      bottomPadding = 250;
      drawerOpen=true;
    });
    saveRideRequestInfo();
  }
  resetApp(){
    setState(() {
      drawerOpen=true;
      searchContainerHeight=300;
      rideDetailsContainerHeight=0;
      rideRequestContainerHeight=0;
      bottomPadding = 300;
      polylineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();
    });
    locatePosition();
  }
  displayRideDetailsContainer()async
  {
    await getPlaceDirection();

    setState(() {
      searchContainerHeight=0;
      rideDetailsContainerHeight=230;
      bottomPadding = 230;
     drawerOpen=false;
    });

  }
  displayToastMessage(String message){
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 5,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }


  void locatePosition()async
  {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
    ].request();

    if (statuses[Permission.location]!.isDenied) {
      requestPermission(Permission.location);
    }
    else {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      currentPosition = position;
      LatLng llPosition = LatLng(position.latitude, position.longitude);

      CameraPosition cameraPosition = new CameraPosition(
          target: llPosition, zoom: 14);

      gmCtrl.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

      String address = await MethodsAssistant.searchCoordinatesAddress(
          position, context);
      print(address);
    }
  }

  var colorizeColors = [
    Colors.green,
    Colors.purple,
    Colors.pink,
    Colors.blue,
    Colors.yellow,
    Colors.red,
  ];

  var colorizeTextStyle = TextStyle(
    fontSize: 50.0,
    fontFamily: 'Signatra',

  );



  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );
  static const CameraPosition kenya = const CameraPosition(
    target: LatLng(1.286389, 36.817223),
    zoom: 14,
  );

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        title: Text('Drive me'),
      ),
      drawer: Container(
        color: Colors.white,
        width: 255,
        child: Drawer(
          child: ListView(
            children: [
              //drawer header
              Container(
                height: 165,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white),
                    child: Row(
                      children: [
                         Image.asset('images/user_icon.png',height: 65,width: 65,),
                        SizedBox(width: 16,),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Name',style: TextStyle(fontSize: 16),),
                            SizedBox(height: 6,),
                            Text('Visit Profile'),

                          ],
                        ),
                      ],
                    ),

                ),
              ),
              DividerWidget(),
              SizedBox(height: 12,),
              //drawer body controllers
              ListTile(
                leading: Icon(Icons.history),
                title: Text('History',style: TextStyle(fontSize: 15),),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Visit Profile',style: TextStyle(fontSize: 15),),
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text('About',style: TextStyle(fontSize: 15),),
              ),
              ListTile(
                onTap: (){
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(context, LoginScreen.idScreen, (route) => false);
                },
                leading: Icon(Icons.exit_to_app),
                title: Text('Logout',style: TextStyle(fontSize: 15),),
              ),


            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPadding),
            initialCameraPosition:kenya,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
           polylines: polylineSet,
            markers: markersSet,
            circles: circlesSet,
            mapType: MapType.normal,
            onMapCreated: (GoogleMapController controller)
            {
               _controllerGM.complete(controller);
               gmCtrl= controller;

               setState(() {
                 bottomPadding=300.0;
               });

               locatePosition();
            },

          ),
          //hamurger button for drawer
          Positioned(
            top: 38,
            left: 22,
            child: GestureDetector(
              onTap: (){
                if(drawerOpen){

                 scaffoldKey.currentState?.openDrawer();
                }
                else{
                  resetApp();
                }

              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 6,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ]
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(drawerOpen? Icons.menu : Icons.close),
                  radius: 20,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            right: 0,
            child:AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: Duration(milliseconds: 160),
              child: Container(
               height: searchContainerHeight,
                decoration:const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(15),
                      topRight:Radius.circular(15)) ,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),

                    ),

                  ]
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 18),
                  child: Column(
                    children: [
                          SizedBox(height: 6,),
                          Text('Hi there,',style: TextStyle(fontSize: 12),),
                          Text('Where to?',style: TextStyle(fontSize: 20),),
                           SizedBox(height: 20,),
                      GestureDetector(
                        onTap: ()async
                        {
                          var res = await Navigator.pushNamed(context, SearchScreen.idScreen);

                          if(res == "obtainDirection"){
                            displayRideDetailsContainer();
                          }

                        },
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 6,
                                  spreadRadius: 0.5,
                                  offset: Offset(0.7, 0.7),

                                ),

                              ]
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(Icons.search,color: Colors.blueAccent,),
                                SizedBox(width: 10,),
                                Text('Search drop off location')
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.0,),
                     Row(
                       children: [
                         Icon(Icons.home,color: Colors.grey,),
                         SizedBox(width: 12,),
                         Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                               Text(
                                   Provider.of<AppData>(context).pickUpLocation != null ?
                                   Provider.of<AppData>(context).pickUpLocation!.placeName :
                                       'Add Home',
                                 maxLines: 2,
                               ),
                             SizedBox(height: 4,),
                             Text('Your living home address',style: TextStyle(color: Colors.grey,fontSize: 12),),
                           ],
                         ),
                       ],
                     ),
                      SizedBox(height: 10.0,),
                      DividerWidget(),
                      SizedBox(height: 16.0,),
                      Row(
                        children: [
                          Icon(Icons.work,color: Colors.grey,),
                          SizedBox(width: 12,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Add Work'),
                              SizedBox(height: 4,),
                              Text('Your work address',style: TextStyle(color: Colors.grey,fontSize: 12),),
                            ],
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
              right: 0,
              left: 0,
              child:AnimatedSize(
                vsync: this,
                curve: Curves.bounceIn,
                duration: Duration(milliseconds: 160),
                child: Container(
                  height: rideDetailsContainerHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(16),topRight: Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 16,
                        spreadRadius: 0.5,
                        offset: Offset(0.7,0.7)
                      ),
                    ]
                  ),
                  child: Padding(
                    padding:  EdgeInsets.symmetric(vertical: 17),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          color: Colors.tealAccent[100],
                          child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16,),
                            child: Row(
                              children: [
                                Image.asset('images/taxi.png',height: 70,width: 80,),
                                SizedBox(width: 16,),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                     Text('Car',style: TextStyle(fontSize: 18),),
                                    Text(tripDirectionDetails!= null ?tripDirectionDetails!.distanceText :'',style: TextStyle(fontSize: 16,color: Colors.grey),)
                                  ],
                                ),
                                Expanded(
                                  child: Container(),
                                ),
                                Text(
                                  ((tripDirectionDetails!= null ? 'KSH ${MethodsAssistant.calculateFares(tripDirectionDetails!)}': '')),
                                  style: TextStyle(fontSize: 16,color: Colors.grey),)



                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20,),
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(FontAwesomeIcons.moneyCheckDollar,size: 18,color: Colors.black54,),
                              SizedBox(width: 16,),
                              Text('Cash'),
                              SizedBox(width: 6,),
                              Icon(Icons.keyboard_arrow_down,color: Colors.black54,size: 16,)
                            ],
                          ),
                        ),
                        SizedBox(height: 24,),
                        GestureDetector(
                          onTap: (){
                           displayRequestRideContainer();
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              padding: EdgeInsets.all(17),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Request',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.white),),

                                  //fonte awesome icon.taxi
                                  Icon(FontAwesomeIcons.taxi,color: Colors.white,size: 13,),

                                ],
                              ),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              )
          ),
          Positioned(
            bottom: 0,
             left: 0,
              right: 0,
            child: Container(
              height:rideRequestContainerHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topRight: Radius.circular(16),topLeft: Radius.circular(16)),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 16,
                    spreadRadius: 0.5,
                    offset: Offset(0.7,0.7),
                    color: Colors.black54
                  )
                ]
              ),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                     SizedBox(height: 12.0,),
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedTextKit(
                        animatedTexts: [
                          ColorizeAnimatedText(
                            'Requesting a ride ..',

                            colors: colorizeColors,
                            textStyle: colorizeTextStyle,
                              textAlign: TextAlign.center
                          ),
                          ColorizeAnimatedText(
                            'Please wait ..',
                            colors: colorizeColors,
                            textStyle: colorizeTextStyle,
                              textAlign: TextAlign.center
                          ),
                          ColorizeAnimatedText(
                            'Finding a driver',
                            colors: colorizeColors,
                            textStyle: colorizeTextStyle,
                            textAlign: TextAlign.center
                          ),

                        ],
                        isRepeatingAnimation: true,

                        onTap: () {
                          print("Tap Event");
                        },
                      ),
                    ),
                    SizedBox(height: 22.0,),
                    GestureDetector(
                      onTap: (){
                        cancelRideRequest();
                      },
                      child: Container(
                        height:60,
                        width:60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(width: 2,color: Colors.grey),

                        ),
                        child: Icon(Icons.close,size: 26,),
                      ),
                    ),
                    SizedBox(height: 10,),
                    Container(
                      width: double.infinity,
                      child: Text('Cancel Ride',textAlign: TextAlign.center,style: TextStyle(fontSize: 12),),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void>getPlaceDirection()async{
    var initialPos = Provider.of <AppData>(context,listen: false).pickUpLocation;
    var finalPos = Provider.of <AppData>(context,listen: false).dropOffLocation;

    var pickupLatLng = LatLng(initialPos!.latitude,initialPos!.longitude);
    var dropoffLatLng = LatLng(finalPos!.latitude,finalPos!.longitude);

    showDialog(
        context: context,
        barrierDismissible: false,

        builder: (BuildContext context){
          return ProgressDialog(message: 'Please wait...');
        });

    var details = await MethodsAssistant.obtainPlaceDirectionDetails(pickupLatLng, dropoffLatLng);

    setState(() {
      tripDirectionDetails = details;
    });


    Navigator.pop(context);

    print("This is encoded points::");
    print(details.encodedPoints);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodePolylinePointsResults = polylinePoints.decodePolyline(details.encodedPoints);

    pLineCoordinates.clear();

    if(decodePolylinePointsResults.isNotEmpty){
      decodePolylinePointsResults.forEach((PointLatLng pointLatLng) {
        pLineCoordinates.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));

      });
    }

    polylineSet.clear();
    setState(() {
      Polyline polyline =Polyline(
          polylineId: PolylineId('PolylineID'),
          color: Colors.pink,
          jointType: JointType.round,
          points: pLineCoordinates,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true
      );

      polylineSet.add(polyline);
    });

LatLngBounds latLngBounds;
if(pickupLatLng.latitude > dropoffLatLng.latitude && pickupLatLng.longitude> dropoffLatLng.longitude){
  latLngBounds =LatLngBounds(southwest: dropoffLatLng, northeast: pickupLatLng);
}
else if(pickupLatLng.latitude > dropoffLatLng.latitude)
{
  latLngBounds =LatLngBounds(southwest: LatLng(dropoffLatLng.latitude, pickupLatLng.longitude), northeast: LatLng(pickupLatLng.latitude, dropoffLatLng.longitude));
}
else if(pickupLatLng.longitude > dropoffLatLng.longitude)
{
  latLngBounds =LatLngBounds(southwest: LatLng(pickupLatLng.latitude, dropoffLatLng.longitude), northeast: LatLng(dropoffLatLng.latitude, pickupLatLng.longitude));
}
else{
  latLngBounds =LatLngBounds(southwest: pickupLatLng, northeast: dropoffLatLng);
}
gmCtrl.animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

Marker pickuplocMarker = Marker(
  icon:BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
    infoWindow: InfoWindow(title: initialPos.placeName,snippet: "my location"),
    position: pickupLatLng,
    markerId: MarkerId('pickupId')
);

    Marker dropofflocMarker = Marker(
        icon:BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
        infoWindow: InfoWindow(title: finalPos.placeName,snippet: "destination"),
        position: dropoffLatLng,
        markerId: MarkerId('dropoffId')
    );

    setState(() {

      markersSet.add(pickuplocMarker);
      markersSet.add(dropofflocMarker);
    });

    Circle pickupCircle = Circle(

        circleId: CircleId('pickUpCircleId') ,
      fillColor: Colors.cyan,
      center: pickupLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.yellowAccent,

    );
    Circle dropoffCircle = Circle(

      circleId: CircleId('dropOffCircleId') ,
      fillColor: Colors.purple,
      center: dropoffLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.purpleAccent,

    );

    setState(() {
      circlesSet.add(pickupCircle);
      circlesSet.add(dropoffCircle);

    });

  }
  Future<void> requestPermission(Permission permission) async {
    await permission.request();
  }
}

