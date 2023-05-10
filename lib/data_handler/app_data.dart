
import 'package:flutter/cupertino.dart';

import '../models/address_model.dart';

class AppData extends ChangeNotifier
{
    Address? pickUpLocation,dropOffLocation;

   void updatePickUpLocationAddress(Address pickUpAddress)
   {
     pickUpLocation= pickUpAddress;
     notifyListeners();
   }
    void updateDropOffLocationAddress(Address dropOffAddress)
    {
      dropOffLocation=dropOffAddress;
      notifyListeners();
    }

}