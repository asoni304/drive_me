
import 'package:drive_me/config.dart';
import 'package:drive_me/models/address_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../data_handler/app_data.dart';
import '../models/direction_details.dart';
import '../models/user.dart';
import 'request_assistant.dart';

class MethodsAssistant
{

  static Future<String> searchCoordinatesAddress(
  Position position, context) async {
  String placeAddress = "";
  String st1,st2,st3,st4;
  String lat = position.latitude.toString();
  String lng = position.longitude.toString();
  String url =
  "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$mapKey";

  var response = await RequestAssistant.getRequest(url);

  if (response != "failed") {
    // 4,7,6,9
 // placeAddress = response["results"][0]["formatted_address"];
    st1 = response["results"][0]["address_components"][1]["long_name"];
    st2 = response["results"][0]["address_components"][4]["long_name"];
    st3 = response["results"][0]["address_components"][5]["long_name"];
    st4 = response["results"][0]["address_components"][2]["long_name"];

    placeAddress = st1 + ", " + st2 + ", " + st3;

    Address userPickUp = new Address(
      longitude: position.longitude,
      latitude: position.latitude,
      placeFormattedAddress: response["results"][0]["formatted_address"],
      placeId: placeAddress,
      placeName: placeAddress);

  Provider.of<AppData>(context,listen: false).updatePickUpLocationAddress(userPickUp);
  }

  return placeAddress;
  }
 static Future<DirectionDetail> obtainPlaceDirectionDetails(LatLng initialPosition, LatLng finalPosition)async
{
  String directionUrl = "https://maps.googleapis.com/maps/api/directions/json?origin=${initialPosition.latitude},${initialPosition.longitude}&destination=${finalPosition.latitude},${finalPosition.longitude}&key=$mapKey";

  var res = await RequestAssistant.getRequest(directionUrl);

  if(res == "failed"){
    return DirectionDetail(
      distanceValue: 0,
      durationValue: 0,
      distanceText: "",
      durationText: "",
      encodedPoints: "",
    );
  }
  DirectionDetail directionDetail = DirectionDetail(
    distanceValue: res["routes"][0]["legs"][0]["distance"]["value"],
    durationValue: res["routes"][0]["legs"][0]["duration"]["value"],
    distanceText: res["routes"][0]["legs"][0]["distance"]["text"],
    durationText: res["routes"][0]["legs"][0]["duration"]["text"],
    encodedPoints: res["routes"][0]["overview_polyline"]["points"],
  );

  return directionDetail;
}

static int calculateFares(DirectionDetail directionDetail)
{
  //in terms of USD
  double timeTraveledFare = (directionDetail.durationValue / 60) * 0.2; //per minute
  double distanceTraveledFare = (directionDetail.distanceValue /1000) * 0.2; //per km
  double fareTotalInUSD = timeTraveledFare + distanceTraveledFare;

 // convert to ksh 1$ = 150ksh
  double fareTotalInKSH = fareTotalInUSD * 150;
return fareTotalInKSH.truncate();
}

static void getCurrentUserInfo()async
{
  firebaseUser = await FirebaseAuth.instance.currentUser!;
  String userId = firebaseUser!.uid;
  DatabaseReference reference = FirebaseDatabase.instance.ref().child("users").child(userId);

  reference.once().then((event) {
    if(event.snapshot.value != null){
      currentUserInfo = Users.fromSnapshot(event.snapshot);
    }
  });


}

}