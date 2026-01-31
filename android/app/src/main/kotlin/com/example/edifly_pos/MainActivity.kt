package com.example.edifly_pos

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.io.OutputStream
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val TAG = "PrinterNative"
    private val CHANNEL = "com.example.edifly_pos/printer"
    
    // Standard SPP UUID for Bluetooth Serial Port
    private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var bluetoothSocket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null
    private var connectedDevice: BluetoothDevice? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            Log.d(TAG, "Method called: ${call.method}")
            
            when (call.method) {
                "getPairedDevices" -> {
                    getPairedDevices(result)
                }
                "connect" -> {
                    val address = call.argument<String>("address")
                    if (address != null) {
                        connect(address, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Address is required", null)
                    }
                }
                "disconnect" -> {
                    disconnect(result)
                }
                "isConnected" -> {
                    val connected = bluetoothSocket?.isConnected == true
                    Log.d(TAG, "isConnected: $connected")
                    result.success(connected)
                }
                "printBytes" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes != null) {
                        Log.d(TAG, "printBytes called with ${bytes.size} bytes")
                        printBytes(bytes, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Bytes are required", null)
                    }
                }
                "printSimple" -> {
                    val text = call.argument<String>("text") ?: "TEST"
                    printSimple(text, result)
                }
                "printTSPL" -> {
                    val text = call.argument<String>("text") ?: "TEST"
                    val width = call.argument<Int>("width") ?: 50
                    val height = call.argument<Int>("height") ?: 30
                    val raw = call.argument<Boolean>("raw") ?: false
                    printTSPL(text, width, height, raw, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun getPairedDevices(result: MethodChannel.Result) {
        try {
            val pairedDevices = bluetoothAdapter?.bondedDevices
            val deviceList = mutableListOf<Map<String, String>>()
            
            pairedDevices?.forEach { device ->
                deviceList.add(mapOf(
                    "name" to (device.name ?: "Unknown"),
                    "address" to device.address
                ))
            }
            
            Log.d(TAG, "Found ${deviceList.size} paired devices")
            result.success(deviceList)
        } catch (e: SecurityException) {
            Log.e(TAG, "Permission error: ${e.message}")
            result.error("PERMISSION_ERROR", "Bluetooth permission denied", e.message)
        } catch (e: Exception) {
            Log.e(TAG, "Error getting devices: ${e.message}")
            result.error("ERROR", "Failed to get paired devices", e.message)
        }
    }
    
    private fun connect(address: String, result: MethodChannel.Result) {
        Log.d(TAG, "Connecting to: $address")
        
        Thread {
            try {
                // Disconnect existing connection first
                disconnectInternal()
                
                val device = bluetoothAdapter?.getRemoteDevice(address)
                if (device == null) {
                    Log.e(TAG, "Device not found: $address")
                    Handler(Looper.getMainLooper()).post {
                        result.error("DEVICE_NOT_FOUND", "Device not found", null)
                    }
                    return@Thread
                }
                
                Log.d(TAG, "Device found: ${device.name}")
                
                // Cancel discovery before connecting
                bluetoothAdapter?.cancelDiscovery()
                
                // Create socket and connect
                Log.d(TAG, "Creating RFCOMM socket...")
                bluetoothSocket = device.createRfcommSocketToServiceRecord(SPP_UUID)
                
                Log.d(TAG, "Connecting socket...")
                bluetoothSocket?.connect()
                
                Log.d(TAG, "Socket connected: ${bluetoothSocket?.isConnected}")
                
                // Get output stream
                outputStream = bluetoothSocket?.outputStream
                connectedDevice = device
                
                Log.d(TAG, "Output stream obtained: ${outputStream != null}")
                
                // Wait for printer to be ready
                Thread.sleep(1000)
                
                Handler(Looper.getMainLooper()).post {
                    Log.d(TAG, "Connection successful!")
                    result.success(true)
                }
                
            } catch (e: SecurityException) {
                Log.e(TAG, "Permission error: ${e.message}")
                Handler(Looper.getMainLooper()).post {
                    result.error("PERMISSION_ERROR", "Bluetooth permission denied", e.message)
                }
            } catch (e: IOException) {
                Log.e(TAG, "IO error: ${e.message}")
                disconnectInternal()
                Handler(Looper.getMainLooper()).post {
                    result.error("CONNECTION_ERROR", "Failed to connect: ${e.message}", null)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error: ${e.message}")
                disconnectInternal()
                Handler(Looper.getMainLooper()).post {
                    result.error("ERROR", "Connection failed: ${e.message}", null)
                }
            }
        }.start()
    }
    
    private fun disconnect(result: MethodChannel.Result) {
        Log.d(TAG, "Disconnecting...")
        disconnectInternal()
        result.success(true)
    }
    
    private fun disconnectInternal() {
        try {
            outputStream?.close()
            bluetoothSocket?.close()
        } catch (e: IOException) {
            Log.e(TAG, "Error closing: ${e.message}")
        }
        outputStream = null
        bluetoothSocket = null
        connectedDevice = null
    }
    
    private fun printBytes(bytes: ByteArray, result: MethodChannel.Result) {
        Log.d(TAG, "printBytes: ${bytes.size} bytes")
        
        Thread {
            try {
                if (outputStream == null) {
                    Log.e(TAG, "Output stream is null!")
                    Handler(Looper.getMainLooper()).post {
                        result.error("NOT_CONNECTED", "Output stream is null", null)
                    }
                    return@Thread
                }
                
                if (bluetoothSocket?.isConnected != true) {
                    Log.e(TAG, "Socket not connected!")
                    Handler(Looper.getMainLooper()).post {
                        result.error("NOT_CONNECTED", "Socket not connected", null)
                    }
                    return@Thread
                }
                
                Log.d(TAG, "Writing ${bytes.size} bytes directly...")
                
                // Write all at once first (simple approach)
                outputStream?.write(bytes)
                outputStream?.flush()
                
                Log.d(TAG, "Write and flush completed!")
                
                // Wait for printer to process
                Thread.sleep(500)
                
                Handler(Looper.getMainLooper()).post {
                    Log.d(TAG, "Print success!")
                    result.success(true)
                }
                
            } catch (e: IOException) {
                Log.e(TAG, "Write error: ${e.message}")
                Handler(Looper.getMainLooper()).post {
                    result.error("WRITE_ERROR", "Failed to write: ${e.message}", null)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error: ${e.message}")
                Handler(Looper.getMainLooper()).post {
                    result.error("ERROR", "Print failed: ${e.message}", null)
                }
            }
        }.start()
    }
    
    // Super simple print - just text with minimal ESC/POS
    private fun printSimple(text: String, result: MethodChannel.Result) {
        Log.d(TAG, "printSimple: $text")
        
        Thread {
            try {
                // Check connection and try to reconnect if needed
                if (outputStream == null || bluetoothSocket?.isConnected != true) {
                    Log.d(TAG, "Connection lost, attempting reconnect...")
                    
                    if (connectedDevice != null) {
                        try {
                            disconnectInternal()
                            bluetoothAdapter?.cancelDiscovery()
                            bluetoothSocket = connectedDevice?.createRfcommSocketToServiceRecord(SPP_UUID)
                            bluetoothSocket?.connect()
                            outputStream = bluetoothSocket?.outputStream
                            Log.d(TAG, "Reconnected successfully!")
                            Thread.sleep(500)
                        } catch (e: Exception) {
                            Log.e(TAG, "Reconnect failed: ${e.message}")
                            Handler(Looper.getMainLooper()).post {
                                result.error("NOT_CONNECTED", "Printer disconnected, please reconnect", null)
                            }
                            return@Thread
                        }
                    } else {
                        Handler(Looper.getMainLooper()).post {
                            result.error("NOT_CONNECTED", "Printer not connected", null)
                        }
                        return@Thread
                    }
                }
                
                // Minimal ESC/POS: just init + text + newlines
                val bytes = mutableListOf<Byte>()
                
                // ESC @ - Initialize
                bytes.add(0x1B.toByte())
                bytes.add(0x40.toByte())
                
                // Text as ASCII bytes
                text.forEach { char ->
                    bytes.add(char.code.toByte())
                }
                
                // Multiple line feeds to push paper out
                for (i in 1..6) {
                    bytes.add(0x0A.toByte())
                }
                
                val byteArray = bytes.toByteArray()
                Log.d(TAG, "Sending ${byteArray.size} bytes: ${byteArray.take(20).map { it.toInt() and 0xFF }}")
                
                outputStream?.write(byteArray)
                outputStream?.flush()
                
                Log.d(TAG, "Simple print sent!")
                
                // Wait longer for printer to process
                Log.d(TAG, "Waiting 2 seconds for printer to process...")
                Thread.sleep(2000)
                
                Log.d(TAG, "Done waiting, socket still connected: ${bluetoothSocket?.isConnected}")
                
                Handler(Looper.getMainLooper()).post {
                    result.success(true)
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "Simple print error: ${e.message}")
                Handler(Looper.getMainLooper()).post {
                    result.error("ERROR", e.message, null)
                }
            }
        }.start()
    }
    
    // Print using TSPL commands for label printers (D520BT-Z, etc)
    private fun printTSPL(text: String, width: Int, height: Int, raw: Boolean, result: MethodChannel.Result) {
        Log.d(TAG, "printTSPL: width=$width, height=$height, raw=$raw, textLen=${text.length}")
        
        Thread {
            try {
                // Check connection and try to reconnect if needed
                if (outputStream == null || bluetoothSocket?.isConnected != true) {
                    Log.d(TAG, "Connection lost, attempting reconnect...")
                    
                    if (connectedDevice != null) {
                        try {
                            // Close old connections
                            disconnectInternal()
                            
                            // Reconnect
                            bluetoothAdapter?.cancelDiscovery()
                            bluetoothSocket = connectedDevice?.createRfcommSocketToServiceRecord(SPP_UUID)
                            bluetoothSocket?.connect()
                            outputStream = bluetoothSocket?.outputStream
                            
                            Log.d(TAG, "Reconnected successfully!")
                            Thread.sleep(500)
                        } catch (e: Exception) {
                            Log.e(TAG, "Reconnect failed: ${e.message}")
                            Handler(Looper.getMainLooper()).post {
                                result.error("NOT_CONNECTED", "Printer disconnected, please reconnect", null)
                            }
                            return@Thread
                        }
                    } else {
                        Handler(Looper.getMainLooper()).post {
                            result.error("NOT_CONNECTED", "Printer not connected", null)
                        }
                        return@Thread
                    }
                }
                
                val tsplCommands: String
                
                if (raw) {
                    // Use raw TSPL command string directly
                    // Ensure it ends with proper termination
                    var cmd = text
                    if (!cmd.contains("PRINT")) {
                        cmd += "\r\nPRINT 1\r\n"
                    }
                    // Add FORMFEED to stop paper after print
                    if (!cmd.contains("FORMFEED")) {
                        cmd += "FORMFEED\r\n"
                    }
                    if (!cmd.contains("EOP")) {
                        cmd += "EOP\r\n"
                    }
                    tsplCommands = cmd
                } else {
                    // Build simple TSPL command
                    val sb = StringBuilder()
                    sb.append("SIZE $width mm, $height mm\r\n")
                    // Use GAP 0 for continuous paper, or small gap for label paper
                    sb.append("GAP 0 mm, 0 mm\r\n")  // Continuous mode
                    sb.append("DIRECTION 1\r\n")
                    sb.append("CLS\r\n")
                    
                    // TEXT x, y, font, rotation, x-scale, y-scale, "content"
                    sb.append("TEXT 10, 10, \"3\", 0, 1, 1, \"$text\"\r\n")
                    
                    sb.append("PRINT 1\r\n")      // Print 1 copy
                    sb.append("FORMFEED\r\n")     // Feed paper to cut position
                    sb.append("EOP\r\n")          // End of print
                    tsplCommands = sb.toString()
                }
                
                val bytes = tsplCommands.toByteArray(Charsets.US_ASCII)
                
                Log.d(TAG, "Sending TSPL (${bytes.size} bytes)")
                Log.d(TAG, "TSPL content preview: ${tsplCommands.take(100).replace("\r\n", "\\r\\n")}")
                
                outputStream?.write(bytes)
                outputStream?.flush()
                
                Log.d(TAG, "TSPL print sent!")
                Thread.sleep(2000)
                
                Handler(Looper.getMainLooper()).post {
                    result.success(true)
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "TSPL print error: ${e.message}")
                Handler(Looper.getMainLooper()).post {
                    result.error("ERROR", e.message, null)
                }
            }
        }.start()
    }
    
    override fun onDestroy() {
        disconnectInternal()
        super.onDestroy()
    }
}
