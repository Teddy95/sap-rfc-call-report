# SAP Call Report Function Module ⚗️

This project delivers a SAP rfc function module to call parameterized ALV based reports from other programming languages like Node.js or Python.
Create a new function module in SE80 paste the code from `ZRFC_CALL_REPORT.abap` into it and name it `ZRFC_CALL_REPORT`. After this step you can exec an ALV based report in SAP with node-rfc and pipe ALV output to Node.js.


### SAP settings for function module

<details>
	<summary>Attributes settings (enable rfc)</summary>
	<img src="/screenshots/enable_rfc.png" alt="Enable RFC" />
</details>

<details>
	<summary>Import parameters</summary>
	<img src="/screenshots/import_parameters.png" alt="Enable RFC" />
</details>

<details>
	<summary>Export parameters</summary>
	<img src="/screenshots/export_parameters.png" alt="Enable RFC" />
</details>

<details>
	<summary>Tables parameters</summary>
	<img src="/screenshots/tables_parameters.png" alt="Enable RFC" />
</details>

### Requirements

- SAP NetWeaver System
- SAP Developer Account
- Working installation of [SAP NW RFC SDK 7.50](https://support.sap.com/en/product/connectors/nwrfcsdk.html)
- Working installation of [node-rfc](https://github.com/SAP/node-rfc) (if you are using Node.js)

### Function module parameters

Importing:

| Parameter | Type                        | Length | Required | Description                                      |
| --------- | --------------------------- | ------ | :------: | ------------------------------------------------ |
| DELIMITER | Char                        | 1      | x        | Delimiter for data payload                       |
| REPORT    | Char                        | 25     | x        | Name of report you want to execute               |
| NOOUTPUT  | Char                        | 1      |          | Set to `X` if you only want to submit the report |
| SELECTION | Array of Objects (RSPARAMS) |        |          | Selection screen parameters                      |

Exporting:

| Parameter | Type                      | Description                       |
| --------- | ------------------------- | --------------------------------- |
| FIELDLIST | Array of Objects (TAB512) | Returning fieldlist of ALV output |
| DATA      | Array of Objects (TAB512) | Returning data from ALV output    |
| ERRORCODE | Int                       | Error code. 0 = successful        |
| ERRORMSG  | String                    | Error message                     |

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

const beautify = (data) => {
	var response = []

	data.DATA.forEach(record => {
		const values = record.WA.split(data.DELIMITER)
		var dataSet = {}

		for (var i = 0; i < values.length; i++) {
			dataSet[data.FIELDLIST[i].WA.split(data.DELIMITER)[0]] = values[i]
		}

		response.push(dataSet)
	})

	return response
}

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
			'DELIMITER': ';',				// Delimiter for returned payload
			'REPORT': 'ZQMRKTC_AUSW_REKL',	// Report name (in this example a custom report)
			'SELECTION': selection			// Optional: Selection screen parameters
		})

		// If there are no errors, transform result data & log it to console
		if (result.ERRORCODE === 0) {
			// Beautify report data (optional)
			const response = beautify(result)

			// Print data to console
			console.log(response)
		} else {
			console.log(result.ERRORMSG)
		}
	} catch (err) {
		console.log(err)
	}
}

callReport()
```
