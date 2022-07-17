# Colleting the data from your Huawei SUN2000 inverter to Domoticz (and Influx.)

**Requirements**
- Raspberry (or other linux environment) with jq installed
- Huawei developer account
- These scripts (with some customisation)

**1. Raspberry Pi or other hardware**

   These scripts have been developed and testen on Raspberry Pi. It can of course be installed on almost any linux system without issues, but you're on your own :-). This Raspberry must have internet access.

   At least it is required to install jq, a small utility used to process json output.
   On Raspberry: 
   > sudo apt update

   > sudo apt install -y jq

**2. Try to get yourself a developers account for the data which is collecting. This request MUST be submitted by the company who installed your converter.**

   Send an email to "eu\_inverter\_support at huawei.com" with the following:

   I hereby request an openAPI user account to access the data from my inverter through the new FusionSolar API:  
   System name: XXXXXXXXXXXXXXXXXX (serial no, found on the label on your converter)  
   Username: [your.email@somewhere.else]()  
   Plant Name: City and adress  
   SN Inverter: XXXXXXXXXXXXXXXXXXXX (serial no, found on the label on your converter)  

   You will receive an excel form to be filled and submitted by your installer (if not from them, it will be refused).

**3. When the account is created you can use these (bash) scripts to retrieve the "real-time", hourly, daily and yearly data from their website which is updated every 5 minutes.**

Real-time is updated every 5 minutes, so it's more "almost real time". I collect this data every 5 minutes and write it to Domoticz (real time data) en and to influx (hour, day and year) to produce nice graphs.

To get this working take the following steps:

- Install jq on your system. We will need it to process the retreived data.

- In Domoticz create 2 virtual sensors and note their respective index numbers.
  - "Solarpanels Today", type general, subtype custom sensor
  - "Solarpanels this month", type general, subtype custom sensor

- Still in Domoticz, create a user variable named "Huawei\_XSRF\_token\_epoch", type string. Give this variable the value 0.

- Save the attached files (HuaweiSolar.env, HuaweiSolar\_API.sh) in /home/pi/scripts/Huawei-solar
- Make the script executable: 
  > sudo chmod 755 HuaweiSolar\_API.env

- Make the file last_token writable
  > sudo chmod 644 HuaweiSolar\last.token

- Modify the file get_token.sh to be able to retreive a fresh token when required
  Against all practices this script has a hardcoded password, I have not been able to use this from a variable. Any good suggestion is welcome.

  The only change that is required in this file is changing the test MYPASSWORD by your own password

- Modify the file HuaweiSolar.env to suit your environment, additional information is in the file.

  Some extra information about the Huawei section: userName and systemCode (password) you will receive from Huawei. The station code can be retreived using the script with the parameter "SetUp" (next step, but userName and systemcode must be present for that). 

- Run "./Huawei_Solar_API.sh SetUp" from the directory where you placed the files (default is /home/pi/scripts/Huawei-solar)  

  This will collect your station-ID from Huawei and print it (with some more info) on the screen. Put this ID in the HuaweiSolar.env file
  
When all this is done, you’re ready to go, run the script with the RealTime parameter and review the output. If any error occurs, you can add the "Y" (without quotes) as second parameter to enable debug information.

Normal execution gives the following output, indicating that both devices (today and this month) have been updated:

>pi@raspberry-4:~/huawei-solar $ ./HuaweiSolar\_API.sh RealTime
>
>{
>
>`        `"status" : "OK",
>
>`        `"title" : "Update Device"
>
>}
>
>{
>
>`        `"status" : "OK",
>
>`        `"title" : "Update Device"
>
>}
>
>pi@raspberry-4:~/huawei-solar $
   
If testing gives no errors, you can use the entries in the file crontab as inspiration to automate regular updates to Domoticz.

Note: If you do not want or need to send (hour/day/year) data directly to influx just only run the script every 5 minutes with the RealTime parameter which will send data to Domoticz only


