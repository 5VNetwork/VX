import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import android.util.Log
import io.tm.android.x_android.StringList
import io.tm.android.x_android.X_android
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.app.StatusBarManager
import android.content.ComponentName
import android.graphics.drawable.Icon
import androidx.annotation.RequiresApi
import androidx.core.graphics.drawable.IconCompat
import com5vnetwork.tm_android.MyTileService

class AndroidHostApiImpl(private val context: Context) : AndroidHostApi {
    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    override fun startXApiServer(config: ByteArray, callback: (Result<Unit>) -> Unit) {
        try {
            X_android.startApiServer(config)
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("", e.toString(), "")))
        }
        startMonitorDefaultNIC()
        callback(Result.success(Unit))
    }

    override fun generateTls(): ByteArray {
        return X_android.generateTls()
    }

    override fun redirectStdErr(path: String) {
        X_android.redirectStderr(path);
    }

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    override fun requestAddTile() {
        val drawableResourceId: Int = com5vnetwork.tm_android.R.drawable.tile_icon
//        if (drawableResourceId == 0) {
//            Log.e("QS", "No tile icon found")
//            return;
//        }

        val icon = IconCompat.createWithResource(
            context, drawableResourceId
        )

        val statusBarService = context.getSystemService(
            StatusBarManager::class.java
        )

        statusBarService.requestAddTileService(ComponentName(context, MyTileService::class.java),
            "VX",
            icon.toIcon(context),
            {}) { result ->
            Log.d("QS", "requestAddTileService result: $result")
        }
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private fun startMonitorDefaultNIC() {
        val connectivityManager = context.getSystemService(ConnectivityManager::class.java)
        // start monitor dns servers of the default nic
        val networkRequest = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .removeTransportType(NetworkCapabilities.TRANSPORT_VPN)
            .build()
        networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                super.onAvailable(network)
                Log.d("NetworkChangeMonitor", "Network is available $network")
//                networkCallback(network)
            }

            override fun onLinkPropertiesChanged(network: Network, linkProperties: LinkProperties) {
                super.onLinkPropertiesChanged(network, linkProperties)
                Log.d("NetworkChangeMonitor", "Link properties changed: $linkProperties")
                networkCallback(network)
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            connectivityManager.registerBestMatchingNetworkCallback(networkRequest, networkCallback!!, mainHandler)
        } else {
            networkCallback = null
        }
    }

    // get current active network and notify nic listeners
    private fun networkCallback(network: Network) {
        val connectivityManager = context.getSystemService(ConnectivityManager::class.java)
//        val active = connectivityManager.activeNetwork
        val linkProperties = connectivityManager.getLinkProperties(network)
        if (linkProperties != null) {
            val dnsServers = ArrayList<String?>()
            for (inetAddress in linkProperties.dnsServers) {
                dnsServers.add(inetAddress.hostAddress)
            }
            val dnsServerList = object : StringList {
                val l = linkProperties.dnsServers.size.toLong()
                val strings = dnsServers
                override fun get(var1: Long): String? {
                    return strings[var1.toInt()]
                }

                override fun len(): Long {
                    return l
                }
            }
            val linkAddresses = ArrayList<String?>()
            for (linkAddress in linkProperties.linkAddresses) {
                linkAddresses.add(linkAddress.address.hostAddress)
            }
            val nicAddressList = object : StringList {
                val l = linkProperties.linkAddresses.size.toLong()
                val strings = linkAddresses
                override fun get(var1: Long): String? {
                    return strings[var1.toInt()]
                }

                override fun len(): Long {
                    return l
                }
            }
            X_android.updateDefaultNICInfo(linkProperties.interfaceName, nicAddressList, dnsServerList)
        }
    }

}