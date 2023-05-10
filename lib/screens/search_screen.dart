import 'package:drive_me/assistants/request_assistant.dart';
import 'package:drive_me/data_handler/app_data.dart';
import 'package:drive_me/models/address_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/placePredictions.dart';
import '../widgets/divider.dart';
import '../widgets/progress_dialog.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  static const idScreen = "searchScreen";

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController pickUpCtrl = TextEditingController();
  TextEditingController dropOffCtrl = TextEditingController();
  List<PlacePredictions> placePredictionList =[];

  @override
  Widget build(BuildContext context) {
    String placeAddress = Provider.of<AppData>(context).pickUpLocation!.placeName ?? "";
    pickUpCtrl.text = placeAddress;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 215,

              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 6,
                    spreadRadius: 0.5,
                    offset: Offset(0.7, 0.7)
                  ),
                ]
              ),
              child: Padding(
                  padding: EdgeInsets.only(left: 25,top: 20,right: 25,bottom: 20),
                child: Column(
                  children: [
                    SizedBox(height: 5,),
                    Stack(
                      children: [
                        GestureDetector(
                            onTap:(){
                              Navigator.pop(context);
                            },
                            child: Icon(Icons.arrow_back)),
                        Center(
                          child: Text('Set drop off',style: TextStyle(fontSize: 18),),
                        ),
                      ],
                    ),
                    SizedBox(height: 16,),
                    Row(
                      children: [
                        Image.asset('images/pickicon.png',height: 16,width: 16,),
                        SizedBox(width: 18,),
                        Expanded(
                          child:Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(5.0),

                            ),
                            child: Padding(
                              padding: EdgeInsets.all(3.0),
                              child: TextField(
                                controller: pickUpCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Pick up location',
                                  fillColor: Colors.grey[400],
                                  filled:true,
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.only(left: 11,top: 8,bottom: 8,),
                                ),
                              ),
                            ),
                          ) ,
                        ),

                      ],
                    ),
                    SizedBox(height: 10,),
                    Row(
                      children: [
                        Image.asset('images/desticon.png',height: 16,width: 16,),
                        SizedBox(width: 18,),
                        Expanded(
                          child:Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(5.0),

                            ),
                            child: Padding(
                              padding: EdgeInsets.all(3.0),
                              child: TextField(
                                onChanged: (val){
                                  getPlace(val) ;
                                },
                                controller: dropOffCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Drop off location',
                                  fillColor: Colors.grey[400],
                                  filled:true,
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.only(left: 11,top: 8,bottom: 8,),
                                ),
                              ),
                            ),
                          ) ,
                        ),

                      ],
                    ),
                  ],
                ),
              ),
            ),

            //tile for displaying results
            (placePredictionList.length > 0) ?
                Padding(padding: EdgeInsets.symmetric(vertical: 8,horizontal: 16),
                child: ListView.separated(
                    padding: EdgeInsets.all(0),
                    itemBuilder: (context,index){
                      return PredictionTile(placePredictions: placePredictionList[index]);
                    },
                    separatorBuilder: (BuildContext context,int index)=>DividerWidget(),
                    itemCount: placePredictionList.length,
                shrinkWrap: true,
                  physics: ClampingScrollPhysics(),
                ),
                ) :
                Container()
          ],
        ),
      ),
    );
  }
  void getPlace(String placeName)async{
 if(placeName.length>1){
   String autoCompleteUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=$mapKey&sessionToken=1234567890&components=country:ke";

   var res = await RequestAssistant.getRequest(autoCompleteUrl) ;

   if(res=="failed"){
     return;
   }

   if(res["status"]== "OK")
   {
       var predictions = res["predictions"];
       var placeList = (predictions as List).map((e) =>PlacePredictions.fromJson(e)).toList();
       setState(() {
         placePredictionList=placeList;
       });

   }
 }
  }
}

class PredictionTile extends StatelessWidget {
final PlacePredictions placePredictions;
PredictionTile({required this.placePredictions});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
      getPlaceAddressDetails(placePredictions.place_id, context);
      },
      child: Container(
        child:Column(
          children: [
            SizedBox(height: 8,),
            Row(
              children: [
                Icon(Icons.location_pin) ,
                SizedBox(width: 14,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(placePredictions.main_text,overflow:TextOverflow.ellipsis,style: TextStyle(fontSize: 16),),
                      SizedBox(height: 3,),
                      Text(placePredictions.secondary_text,overflow:TextOverflow.ellipsis,style: TextStyle(fontSize: 12,color: Colors.grey),),
                    //  SizedBox(height: 3,),

                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8,),
          ],
        ),
      ),
    );
  }

  void getPlaceAddressDetails(String placeId,context)async{

    showDialog(
        context: context,
        barrierDismissible: false,

        builder: (BuildContext context){
          return ProgressDialog(message: 'Setting drop off ,Please wait...');
        });

    String placeDetailsUrl= "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey";


    var res = await RequestAssistant.getRequest(placeDetailsUrl);

    Navigator.pop(context);
    if(res == "failed"){
      return;
    }
    if(res["status"] == "OK")
    {
       Address address = Address(
           longitude:res["result"]["geometry"]["location"]["lat"],
           latitude: res["result"]["geometry"]["location"]["lng"],
           placeFormattedAddress: '',
           placeId: placeId,
           placeName: res["result"]["name"]


       );

       Provider.of<AppData>(context,listen: false).updateDropOffLocationAddress(address);
       print(address.placeName);

       Navigator.pop(context,"obtainDirection");
    }
  }
}

