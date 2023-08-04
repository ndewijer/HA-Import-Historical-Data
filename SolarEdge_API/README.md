# Prepare API Result of Solaredge API into Home-Assistant


## Pulling data from Solaredge API

This script does not have build-in functionality to pull directly from API. Please call seperately and ave the data in a json file.
An example file has been supplied with this folder `solaredge.json`

Info from here:
https://knowledge-center.solaredge.com/sites/kc/files/se_monitoring_api.pdf


### Site Energy
Description: Return the site energy measurements.

Note: this API returns the same energy measurements that appear in the Site Dashboard.

URL: /site/{siteId}/energy

Example URL: https://monitoringapi.solaredge.com/site/1/energy?timeUnit=DAY&endDate=2013-05-30&startDate=2013-05-01&api_key=L4QLVQ1LOKCQX2193VSEICXW61NP6B1O

Method: GET

Accepted formats: JSON, XML and CSV

* Usage limitation: This API is limited to one year when using timeUnit=DAY (i.e., daily resolution) and to one month when
using timeUnit=QUARTER_OF_AN_HOUR or timeUnit=HOUR. This means that the period between endTime and startTime
should not exceed one year or one month respectively. If the period is longer, the system will generate error 403 with
proper description.

* Request: The following are parameters to include in the request:

| Parameter | Type    | Mandatory | Description                                                                                                  |
|-----------|---------|-----------|--------------------------------------------------------------------------------------------------------------|
| siteId    | Integer | Yes       | The site identifier                                                                                          |
| startDate | String  | Yes       | The start date to return energy measurement                                                                  |
| endDate   | String  | Yes       | The end date return energy measurement                                                                       |
| timeUnit  | String  | Yes       | Aggregation granularity. Default : DAY. Allowed values are: QUARTER_OF_AN_HOUR, HOUR, DAY, WEEK, MONTH, YEAR |

* Response: The response includes the requested time unit, the units of measurement (e.g. Wh), and the pairs of date and
energy for every date ({`"date":"2013-06-01 00:00:00","value":null`}).
The date is calculated based on the time zone of the site. “null” means there is no data for that time.

## Transforming into CSV for import into sqlite
The script parses the json file and starts up a counter.
The API returns the amount of energy generated in the timeperiod but Home-Assistant expects this number to increase like an odometer.

It also converts the datetime into unix timestamp that Home-Assistant is expecting.

It then saves the data into a csv.
