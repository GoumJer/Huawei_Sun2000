Colleting the data from your Huawei SUN2000 inverter into Domoticz can be done, but it requires some work

1. **Try to get yourself a developers account for the data which is collecting. This request MUST be submitted by the company who installed your converter.**

   Send an email to "eu\_inverter\_support <at> huawei.com" with the following:

   I hereby request an openAPI user account to access the data from my inverter through the new FusionSolar API:
   System name: XXXXXXXXXXXXXXXXXX (serial no)
   Username: [your.email@somewhere.else]()
   Plant Name: City and adress
   SN Inverter: XXXXXXXXXXXXXXXXXXXX (serial no)

   You will receive an excel form to be filled and submitted by your installer (if not from them, it will be refused)

   **2. When the account is created you can use a (bash) script to retrieve the "real-time", hourly, daily and yearly data from their website which is updated every 5 minutes.**

   Real-time is updated every 5 minutes, so it's more "almost real time"

   I collect this data every 5 minutes and write it to Domoticz (real time data) en and to influx (hour, day and year) to produce nice graphs.

To get this working take the following steps:

- In Domoticz create 2 virtual sensors and note their respective index numbers.
  - “Zonnepanelen vandaag”, type general, subtype custom sensor
  - “Zonnepanelen lopende maand”, type general, subtype custom sensor
- Still in Domoticz, create a user variable named “Huawei\_XSRF\_token\_epoch”, type string
- Save the 2 attached files (HuaweiSolar.env & HuaweiSolar\_API.sh) in /home/pi/scripts/Huawei-solar
- Modify the file HuaweiSolar.env to suit your environment, I gues they eed no extra infomormation 😊
- Make the script executable: sudo chmod 755 HuaweiSolar.env

When all this is done, you’re ready to test, run the script with the RealTime parameter and review the output. If any error occurs, you can add the “Y” (without quotes) as second parameter to enable debug information.

Normal execution gives the following output, indicating that both devices (today and this month) have been updated:

pi@raspberry-4:~/huawei-solar $ ./HuaweiSolar\_API.sh RealTime

{

`        `"status" : "OK",

`        `"title" : "Update Device"

}

{

`        `"status" : "OK",

`        `"title" : "Update Device"

}

pi@raspberry-4:~/huawei-solar $
   
If testing gives no errors, you can use the entries in the file crontab as inspiration to automate regular updates to Domoticz.


