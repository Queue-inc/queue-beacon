package org.weex.plugin.queuebeacon;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.RemoteException;
import android.support.v4.app.ActivityCompat;
import android.util.Log;

import com.alibaba.weex.plugin.annotation.WeexModule;
import com.taobao.weex.annotation.JSMethod;
import com.taobao.weex.bridge.JSCallback;
import com.taobao.weex.common.WXModule;

import org.altbeacon.beacon.Beacon;
import org.altbeacon.beacon.BeaconConsumer;
import org.altbeacon.beacon.BeaconManager;
import org.altbeacon.beacon.BeaconParser;
import org.altbeacon.beacon.Identifier;
import org.altbeacon.beacon.MonitorNotifier;
import org.altbeacon.beacon.RangeNotifier;
import org.altbeacon.beacon.Region;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;

@WeexModule(name = "queueBeacon")
public class QueueBeaconModule extends WXModule implements BeaconConsumer, MonitorNotifier, RangeNotifier {

    private static final String TAG = "QueueBeaconModule";
    private static final String IBEACON_FORMAT = "m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24";
    private BeaconManager beaconManager;
    private JSCallback callback;

    public QueueBeaconModule(){
        Log.d(TAG, "module initialized");
    }

    private String getString(Identifier identifier) {
        if (identifier != null) {
            return identifier.toString();
        } else {
            return null;
        }
    }

    private String stringFromProximity(double proximity) {
        if (proximity < 0) {
            return "Unknown";
        } else if (proximity < 0.5) {
            return "Immediate";
        } else if (proximity < 3.0) {
            return "Near";
        } else {
            return "Far";
        }
    }

    private String stringFromState(int i) {
        switch (i) {
            case 0:
                return "Unknown";
            case 1:
                return "Inside";
            case 2:
                return "Outside";
            default:
                return "Unknown";
        }
    }

    @JSMethod
    public void start(HashMap<String, Object> params, JSCallback callback) {
        Log.d(TAG, "module started");
        this.callback = callback;
        String proximityUUID = (String)params.get("proximityUUID");
        String identifier = (String)params.get("identifier");
        String majorString = (String)params.get("major");
        String minorString = (String)params.get("minor");
        Identifier uuid = Identifier.parse(proximityUUID);
        Identifier major = null, minor = null;
        if (majorString != null) {
            major = Identifier.parse(majorString);
        }
        if (minorString != null) {
            minor = Identifier.parse(minorString);
        }
        Region beaconRegion = new Region(identifier, uuid, major, minor);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Android M Permission check
            if (mWXSDKInstance.getContext().checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions((Activity) mWXSDKInstance.getContext(), new String[]{Manifest.permission.ACCESS_COARSE_LOCATION}, 1);
            }
        }
        beaconManager = BeaconManager.getInstanceForApplication(mWXSDKInstance.getContext());
        beaconManager.getBeaconParsers().add(new BeaconParser().setBeaconLayout(IBEACON_FORMAT));
        beaconManager.bind(this);
        try {
            beaconManager.startRangingBeaconsInRegion(beaconRegion);
        } catch (RemoteException e) {
            e.printStackTrace();
        }
        Log.d(TAG, "ranging started");
    }

    @JSMethod
    public void stop() {
        beaconManager.unbind(this);
    }

    @Override
    public void onBeaconServiceConnect() {
        beaconManager.addMonitorNotifier(this);
        beaconManager.addRangeNotifier(this);
    }

    @Override
    public void didEnterRegion(Region region) {
        Log.d(TAG, "didEnterRegion");
        HashMap<String, Object> result = new HashMap<>();
        result.put("name", "didEnterRegion");
        HashMap<String, Object> data = new HashMap<>();
        String uuid = getString(region.getId1());
        String major = getString(region.getId2());
        String minor = getString(region.getId3());
        data.put("identifier", region.getUniqueId());
//        data.put("uuid", uuid);
//        data.put("major", major);
//        data.put("minor", minor);
        result.put("data", data);
        callback.invokeAndKeepAlive(result);
    }

    @Override
    public void didExitRegion(Region region) {
        Log.d(TAG, "didExitRegion");
        HashMap<String, Object> result = new HashMap<>();
        result.put("name", "didExitRegion");
        HashMap<String, Object> data = new HashMap<>();
        String uuid = getString(region.getId1());
        String major = getString(region.getId2());
        String minor = getString(region.getId3());
        data.put("identifier", region.getUniqueId());
//        data.put("uuid", uuid);
//        data.put("major", major);
//        data.put("minor", minor);
        result.put("data", data);
        callback.invokeAndKeepAlive(result);
    }

    @Override
    public void didDetermineStateForRegion(int i, Region region) {
        Log.d(TAG, "didDetermineState");
        HashMap<String, Object> result = new HashMap<>();
        result.put("name", "didDetermineState");
        HashMap<String, Object> data = new HashMap<>();
        String uuid = getString(region.getId1());
        String major = getString(region.getId2());
        String minor = getString(region.getId3());
        data.put("identifier", region.getUniqueId());
        data.put("state", stringFromState(i));
//        data.put("uuid", uuid);
//        data.put("major", major);
//        data.put("minor", minor);
        result.put("data", data);
        callback.invokeAndKeepAlive(result);
    }

    @Override
    public void didRangeBeaconsInRegion(Collection<Beacon> beacons, Region region) {
        Log.d(TAG, "didRangeBeacons");
        HashMap<String, Object> result = new HashMap<>();
        result.put("name", "didRangeBeacons");
        HashMap<String, Object> data = new HashMap<>();
        data.put("identifier", region.getUniqueId());
        data.put("proximityUUID", getString(region.getId1()));
        data.put("major", getString(region.getId2()));
        data.put("minor", getString(region.getId3()));
        ArrayList<HashMap<String, Object>> beaconsList = new ArrayList<>();
        for (Beacon beacon : beacons) {
            HashMap<String, Object> beaconMap = new HashMap<>();
            beaconMap.put("proximityUUID", getString(beacon.getId1()));
            beaconMap.put("major", getString(beacon.getId2()));
            beaconMap.put("minor", getString(beacon.getId3()));
            beaconMap.put("proximity", stringFromProximity(beacon.getDistance()));
            beaconMap.put("accuracy", beacon.getDistance());
            beaconMap.put("rssi", beacon.getRssi());
            beaconsList.add(beaconMap);
        }
        data.put("beacons", beaconsList);
        result.put("data", data);
        callback.invokeAndKeepAlive(result);
    }

    @Override
    public Context getApplicationContext() {
        return mWXSDKInstance.getContext();
    }

    @Override
    public void unbindService(ServiceConnection serviceConnection) {
        this.unbindService(serviceConnection);
    }

    @Override
    public boolean bindService(Intent intent, ServiceConnection serviceConnection, int i) {
        return this.bindService(intent, serviceConnection, i);
    }
}