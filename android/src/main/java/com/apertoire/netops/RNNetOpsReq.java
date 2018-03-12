package com.apertoire.netops;

import android.util.Log;
import android.os.Build;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.modules.network.TLSSocketFactory;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.SocketTimeoutException;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;

import java.util.concurrent.TimeUnit;

import okhttp3.Call;
import okhttp3.ConnectionSpec;
import okhttp3.Headers;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import okhttp3.TlsVersion;

public class RNNetOpsReq implements Runnable {

	private static final String TAG = "RNNetOpsReq";

  ReactApplicationContext ctx;
  String url;
  RNNetOpsConfig options;
  OkHttpClient client;
  Callback callback;

  String destPath;

  public RNNetOpsReq(ReactApplicationContext context, String url, ReadableMap options, OkHttpClient client, final Callback callback) {
		this.ctx = context;
		this.url = url;
		this.options = new RNNetOpsConfig(options);
		this.client = client;
		this.callback = callback;
  }

  @Override
  public void run() {
		// look for cached result if `cacheImage` is true
		if (this.options.cacheImage) {
			String cacheKey = RNNetOpsUtils.getMD5(this.url);

			this.destPath = ctx.getFilesDir() + "/rnno_" + cacheKey + ".png";
			
			File file = new File(this.destPath);
			if (file.exists()) {
				callback.invoke(null, 0, file.getAbsolutePath());
				return;
			}
		}

		// do some networking
		OkHttpClient.Builder clientBuilder;

		try {
			// use trusty SSL socket
			if (this.options.trusty) {
				clientBuilder = RNNetOpsUtils.getUnsafeOkHttpClient(this.client);
			} else {
				clientBuilder = client.newBuilder();
			}

			final Request.Builder builder = new Request.Builder();
			try {
				builder.url(new URL(this.url));
			} catch (MalformedURLException e) {
				e.printStackTrace();
			}

			// set headers
			if (this.options.headers != null) {
				ReadableMapKeySetIterator it = this.options.headers.keySetIterator();
				while (it.hasNextKey()) {
					String key = it.nextKey();
					String value = this.options.headers.getString(key);
					builder.header(key.toLowerCase(), value);
				}
			}

			// null reqBody for 'GET', user defined for 'POST', 'PUT', 'PATCH'
			RequestBody reqBody = null;
			if (this.options.method.equalsIgnoreCase("post") || this.options.method.equalsIgnoreCase("put") || this.options.method.equalsIgnoreCase("patch")) {
				String cType = this.options.headers.hasKey("content-type") ? this.options.headers.getString("content-type") : "";
				MediaType mType = MediaType.parse(cType);
				reqBody = RequestBody.create(mType, this.options.body);
			}

			builder.method(this.options.method, reqBody);

			if (this.options.timeout >= 0) {
				clientBuilder.connectTimeout(this.options.timeout, TimeUnit.MILLISECONDS);
				clientBuilder.readTimeout(this.options.timeout, TimeUnit.MILLISECONDS);
			}

			// handle prelollipop versions gracefully
      OkHttpClient client = enableTls12OnPreLollipop(clientBuilder).build();
			
			final Request request = builder.build();

			// make sure it's available in the closure
			final String destPath = this.destPath;

			// this is the actual network transmission
			client.newCall(request).enqueue(new okhttp3.Callback() {
				@Override
				public void onFailure(Call call, IOException e) {
					// check if this error caused by socket timeout
					if(e.getClass().equals(SocketTimeoutException.class)) {
							callback.invoke(RNNetOpsUtils.createException("SocketTimeoutException", 1, "request timed out"), 1, null);
					} else {
							callback.invoke(RNNetOpsUtils.createException("ConnectException", 2, e.getLocalizedMessage()), 2, null);
					}
				}

				@Override
				public void onResponse(Call call, final Response resp) throws IOException {

					if (options.cacheImage) {
						InputStream ins = resp.body().byteStream();

						File file = new File(destPath);
						FileOutputStream os = new FileOutputStream(file);

						int read;
						byte [] buffer = new byte[10240];
						while ((read = ins.read(buffer)) != -1) {
							os.write(buffer, 0, read);
						}

						ins.close();
						os.flush();
						os.close();

						callback.invoke(null, resp.code(), file.getAbsolutePath());
					} else {
						callback.invoke(null, resp.code(), new String(resp.body().bytes(), "UTF-8"));
					}

					resp.body().close();
				}
			});
		} catch (Exception error) {
			error.printStackTrace();
			callback.invoke(RNNetOpsUtils.createException("Exception", 3, "RNNetOps request error: " + error.getMessage() + error.getCause()), 3, null);
		}
	}

	public static OkHttpClient.Builder enableTls12OnPreLollipop(OkHttpClient.Builder client) {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN && Build.VERSION.SDK_INT <= Build.VERSION_CODES.KITKAT) {
			try {
				client.sslSocketFactory(new TLSSocketFactory());

				ConnectionSpec cs = new ConnectionSpec.Builder(ConnectionSpec.MODERN_TLS)
								.tlsVersions(TlsVersion.TLS_1_2)
								.build();

				List< ConnectionSpec > specs = new ArrayList < > ();
				specs.add(cs);
				specs.add(ConnectionSpec.COMPATIBLE_TLS);
				specs.add(ConnectionSpec.CLEARTEXT);

				client.connectionSpecs(specs);
			} catch (Exception exc) {
				Log.e(TAG, exc.toString());
			}
		}

		return client;
	}
}
