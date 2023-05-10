
class PlacePredictions
{
 late String secondary_text;
 late String main_text;
 late String place_id;

 PlacePredictions({required this.main_text, required this.place_id, required this.secondary_text});

 PlacePredictions.fromJson(Map<String,dynamic> json)
 {
       main_text=json["structured_formatting"]["main_text"];
       place_id= json["place_id"];
       secondary_text=json["structured_formatting"]["secondary_text"];
 }
 //  Map<String, dynamic> toJson() => {
 //   'place_id': place_id,
 //   'main_text': main_text,
 //   'secondary_text':secondary_text
 // };

}