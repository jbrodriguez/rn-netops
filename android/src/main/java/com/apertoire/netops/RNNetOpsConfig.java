package com.apertoire.netops;

import com.facebook.react.bridge.ReadableMap;

public class RNNetOpsConfig {

  public String method;
  public ReadableMap headers;
  public String body;
  public Boolean cacheImage;
  public long timeout;
  public Boolean trusty;

  RNNetOpsConfig(ReadableMap options) {
    if(options == null)
      return;

    this.method = options.hasKey("method") ? options.getString("method").toUpperCase() : "GET";
    this.headers = options.hasKey("headers") ? options.getMap("headers") : null;
    this.body = options.hasKey("body") ? options.getString("body") : null;
    this.cacheImage = options.hasKey("cacheImage") ? options.getBoolean("cacheImage") : false;
    this.timeout = options.hasKey("timeout") ? options.getInt("timeout") : 60000;
    this.trusty = options.hasKey("trusty") ? options.getBoolean("trusty") : false;
  }
}