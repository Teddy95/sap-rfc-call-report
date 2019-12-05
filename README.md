# SAP Call Report Function Module

Create a new function module in SE80 and name it `ZRFC_CALL_REPORT`. After this step you can exec a alv based report in sap with node-rfc and pipe the alv output to Node.js.

### Call SAP Report with Node.js

> You need a working installation of [node-rfc](https://github.com/SAP/node-rfc)!

```javascript
// Include node-rfc
const rfcClient = require('node-rfc').Client

// Instantiate SAP System
const abapSystem = {
	user: 'USERNAME',
	passwd: 'S3cr3t_p4ssw0rd',
	ashost: 'sap-host',
	sysnr: '00',
	client: '100',
	lang: 'EN',
}

const client = new rfcClient(abapSystem)

const callReport = async () => {
	try {
		// Open client connection
		await client.open()

		// Create selection screen parameters
		var selection = []
		selection.push({
			'SELNAME': 'S_QMDAT',
			'KIND': 'S',
			'SIGN': 'I',
			'OPTION': 'BT',
			'LOW': '20190101',
			'HIGH': '20191205'
		})
		selection.push({
			'SELNAME': 'S_QMART',
			'KIND': 'S',
			'SIGN': 'I',
			'OPTION': 'BT',
			'LOW': 'R1',
			'HIGH': 'R2'
		})

		// Call Function Module 'ZRFC_CALL_REPORT'
		var result = await client.call('ZRFC_CALL_REPORT', {
			'DELIMITER': ';',
			'REPORT': 'ZQMRKTC_AUSW_REKL',
			'SELECTION': selection
		})

		// Beautify report data (optional)
		var response = []

		result.DATA.forEach(record => {
			const values = record.WA.split(result.DELIMITER)
			var dataSet = {}

			for (var i = 0; i < values.length; i++) {
				dataSet[result.FIELDLIST[i].WA.split(result.DELIMITER)[0]] = values[i]
			}

			response.push(dataSet)
		})

		// Print data to console
		console.log(response)
	} catch (err) {
		console.log(err)
	}
}

callReport()
```
