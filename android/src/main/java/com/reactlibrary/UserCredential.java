package com.reactlibrary;
import com.facebook.react.bridge.ReadableMap;

public class UserCredential {
    private String username;
    private String password;
    private String hostname;
    private String port;
	private Boolean ssl;


    public UserCredential(ReadableMap obj){
        this.hostname = obj.getString("hostname");
        this.port = (obj.getType("port") == ReadableType.Number) ? String.valueOf(obj.getInt("port")) : obj.getString("port");
        this.username = obj.getString("username");
        this.password = obj.getString("password");
		this.ssl = obj.hasKey("ssl") ? obj.getBoolean("ssl") : false;
    }

    public String getHostname(){
        return hostname;
    }

    public String getPort() {
        return port;
    }

    public String getUsername() {
        return username;
    }

    public String getPassword(){
        return password;
    }
	
	public String getSSL() {
        return ssl;
    }
}