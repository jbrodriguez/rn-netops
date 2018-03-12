import { NativeModules } from 'react-native'

const { RNNetOps } = NativeModules

export default {
	ipAddress: () =>
		new Promise(resolve => {
			RNNetOps.getIPAddress(ip => {
				resolve(ip)
			})
		}),

	ping: (url, timeout) =>
		new Promise(resolve => {
			RNNetOps.ping(url, timeout, found => {
				resolve(found)
			})
		}),

	wake: (mac, ip) =>
		new Promise(resolve => {
			RNNetOps.wake(mac, ip, formattedMac => {
				resolve(formattedMac)
			})
		}),

	poke: (host, port, timeout) =>
		new Promise(resolve => {
			RNNetOps.poke(host, port, timeout, found => {
				resolve(found)
			})
		}),

	// Create an HTTP request.
	// @param  {string} url Request target url string.
	// @param  {object} options Configuration options for the fetch request, which can be.
	// 		@param  {string} method HTTP method, should be `GET`, `POST`, `PUT`, `DELETE`
	// 		@param  {object} headers HTTP request headers.
	// 		@param  {string} body HTTP request body.
	// 		@param  {boolean} cacheImage Use the url as a cache key (md5'd) and use a png
	//			extension for the file.
	// 		@param  {number} timeout Request timeout in millionseconds.
	// 		@param  {boolean} trusty If true, the request can be made against self-signed certs.
	// @return {Promise}
	//         This promise instance also contains a Customized method `progress`for
	//         register progress event handler.
	fetch: (url, options) =>
		new Promise((resolve, reject) => {
			RNNetOps.fetch(url, options, (err, status, data) => {
				// console.log(`fetch-err(${JSON.stringify(err)})-data(${JSON.stringify(data)})`)
				if (err) {
					reject(err)
				} else {
					resolve({ status, data })
				}
			})
		}),
}
