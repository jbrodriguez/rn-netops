
package com.apertoire.netops;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.Callback;

import android.content.Context;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.util.Log;

import java.net.InetAddress;
import java.net.Inet4Address;
import java.net.UnknownHostException;
import java.net.SocketException;
import java.nio.ByteOrder;
import java.util.Map;
import java.net.NetworkInterface;
import java.util.Enumeration;
import java.net.NetworkInterface;
import java.lang.Runtime;
import java.lang.InterruptedException;
import java.io.IOException;
import com.facebook.react.bridge.GuardedAsyncTask;
import java.net.Socket;
import java.net.InetSocketAddress;
import java.net.ConnectException;

import com.facebook.react.modules.network.OkHttpClientProvider;
import okhttp3.OkHttpClient;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import net.mafro.android.wakeonlan.MagicPacket;

public class RNNetOpsModule extends ReactContextBaseJavaModule {
  WifiManager wifi;
  InetAddress inet;

  private final OkHttpClient mClient;
  static final ExecutorService pool = Executors.newCachedThreadPool();

  static final String TAG = "RNNetOps";

  private final ReactApplicationContext reactContext;

  public RNNetOpsModule(ReactApplicationContext reactContext) {
    super(reactContext);

    wifi = (WifiManager)reactContext.getApplicationContext()
            .getSystemService(Context.WIFI_SERVICE);

    mClient = OkHttpClientProvider.getOkHttpClient();
    
    this.reactContext = reactContext;
  }

  @Override
  public String getName() {
    return "RNNetOps";
  }

  @ReactMethod
  public void getIPAddress(final Callback callback) {
    String ipAddress = null;

    try {
      for (Enumeration<NetworkInterface> en = NetworkInterface.getNetworkInterfaces(); en.hasMoreElements();) {
        NetworkInterface intf = en.nextElement();
        for (Enumeration<InetAddress> enumIpAddr = intf.getInetAddresses(); enumIpAddr.hasMoreElements();) {
          InetAddress inetAddress = enumIpAddr.nextElement();
          if (!inetAddress.isLoopbackAddress()) {
            ipAddress = inetAddress.getHostAddress();
          }
        }
      }
    } catch (Exception ex) {
      Log.e(TAG, ex.toString());
    }

    callback.invoke(ipAddress);
  }

  @ReactMethod
  public void ping(final String url, final Integer timeout, final Callback callback) {
      boolean found = false;

      Runtime runtime = Runtime.getRuntime();
      try
      {

          String command = String.format("/system/bin/ping -c1 -W %d %s", timeout / 1000, url);
          Process  mIpAddrProcess = java.lang.Runtime.getRuntime().exec(command);
          int returnVal = mIpAddrProcess.waitFor();
          found = (returnVal==0);
      }
      catch (InterruptedException ignore)
      {
          ignore.printStackTrace();
          System.out.println(" Exception:"+ignore);
      }
      catch (IOException e)
      {
          e.printStackTrace();
          System.out.println(" Exception:"+e);
      }

      callback.invoke(found);
  }

  @ReactMethod
  public void wake(final String mac, final String ip, final Callback callback) {
    String formattedMac = null;

    try {
      formattedMac = MagicPacket.send(mac, ip);

    } catch(IllegalArgumentException iae) {
      Log.e(TAG, iae.getMessage());
    } catch(Exception e) {
      Log.e(TAG, e.getMessage());
    }

    callback.invoke(formattedMac);
  }

  @ReactMethod
  public void poke(final String host, final String port, final Integer timeout, final Callback callback) {
		new GuardedAsyncTask<Void, Void>(getReactApplicationContext()) {
			@Override
			protected void doInBackgroundGuarded(Void ...params) {
        boolean found = false;
        int portNum = Integer.parseInt(port);

        try {
            Socket socket = new Socket();
            socket.connect(new InetSocketAddress(host, portNum), timeout);
            socket.close();
            found = true;
        } catch(ConnectException ce) {
            // ce.printStackTrace();
            System.out.println(" Exception:"+ce);
        } catch (Exception ex) {
            // ex.printStackTrace();
            System.out.println(" Exception:"+ex);
        }

        callback.invoke(found);
      }
		}.execute();
  }

  @ReactMethod
  public void fetch(final String url, final ReadableMap options, final Callback callback) {
    pool.execute(new RNNetOpsReq(this.reactContext, url, options, this.mClient, callback));
  }
}