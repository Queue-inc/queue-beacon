# queue-beacon

This is a weex plugin to receive iBeacon packets on iOS and Android devices.

## Install

```
Not ready
```

## Usage
### Initialization
To use this library, first you need to put the following code in your vue file.

```javascript
const queueBeacon = weex.requireModule('queueBeacon');
module.exports = {
	methods: {
		createAction: function() {
			queueBeacon.start({
				proximityUUID: "00000000-2F7F-1001-B000-001C4DE5FF78",
				identifier: "sample_identifier",
				major: "321",
				minor: "123"
			}, (result) => {
				console.log(result);
			});
		}
	}
}
```
*Notice: `major` and `minor` value are optional.*

### Structure of results
All callbacks are returned to `result` json object. The structure of every `result` is following:

```
{
	"name": "name_of_callback",
	"data": {
		"key1": "value1",
		"key2": "value2",
		...
	}
}	
```

There are 4 callbacks regarding to receiving packets of beacons as below:

- didRangeBeacons (called periodically when device detects beacons)

```
{
	"name": "didRangeBeacons",
	"data": {
		"identifier": (string),
		"proximityUUID": (string),
		"major": (number),
		"minor": (number),
		"beacons": [
			{
				"proximityUUID": (string),
				"major": (number),
				"minor": (number),
				"proximity": (string),
				"accuracy": (number),
				"rssi": (string)
			},
			{
				"proximityUUID": (string),
				"major": (number),
				"minor": (number),
				"proximity": (string),
				"accuracy": (number),
				"rssi": (string)
			},...
		]
	}
}
```

- didEnterRegion (called when device enters region of a specific beacon)

```
{
	"name": "didEnterRegion",
	"data": {
		"identifier": (string)
	}
}
```

- didExitRegion (called when device exits region of a specific beacon)

```
{
	"name": "didExitRegion",
	"data": {
		"identifier": (string)
	}
}
```

- didDetermineState (called when device determined state of nearby beacon)

```
{
	"name": "didDetermineState",
	"data": {
		"identifier": (string),
		"state": (string)
	}
}
```

### String constants
Some keys can have only several pattern strings.

- `proximity`
	- `Immediate`: accuracy < 0.5
	- `Near`: accuracy < 3.0
	- `Far`: accuracy >= 3.0
	- `Unknown`: accuracy < 0 or unknown

- `state`
	- `Inside`: inside the specific region
	- `Outside`: outside the specific region
	- `Unknown`: unknown